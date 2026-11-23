#!/usr/bin/env bash
export LC_ALL=C
US=$'\037'
printf -v now '%(%s)T' -1
PAGE_KB=$(( $(getconf PAGESIZE 2>/dev/null || echo 4096) / 1024 ))

rd() { REPLY=; [ -r "$1" ] && { IFS= read -r REPLY < "$1"; } 2>/dev/null; }
trim() { REPLY="${1#"${1%%[![:space:]]*}"}"; REPLY="${REPLY%"${REPLY##*[![:space:]]}"}"; }
has() { command -v "$1" >/dev/null 2>&1; }
driver() { REPLY=; local k v; [ -r "$1/uevent" ] && while IFS='=' read -r k v; do [ "$k" = DRIVER ] && REPLY=$v; done < "$1/uevent"; }
emit() {
    local s=$1 i=$2 n=$3 sm=$4 m=$5 rx=$6 tx=$7 si=$8 r=$9
    shift 9
    local IFS=$US
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t0\n' "$s" "$i" "${n//$'\t'/ }" "${sm//$'\t'/ }" "${m:-0}" "${rx:-0}" "${tx:-0}" "${si:-0}" "$r" "$*"
}

declare -A MOD SVC
while read -r spid sname; do
    [ -r "/proc/$spid/statm" ] && read -r _ sres _ < "/proc/$spid/statm" && SVC[$sname]=$(( ${SVC[$sname]:-0} + sres * PAGE_KB ))
done < <(pgrep -lx 'iwd|NetworkManager|wpa_supplicant|systemd-networkd|dhcpcd|bluetoothd' 2>/dev/null)
mb() { REPLY="$(( $1 / 1024 )).$(( $1 % 1024 * 10 / 1024 )) MB"; }
service() {
    REPLY=
    local s out=
    for s in "$@"; do [ -n "${SVC[$s]}" ] && { mb "${SVC[$s]}"; out+="${out:+, }$s $REPLY"; }; done
    REPLY=$out
}
[ -r /proc/modules ] && while read -r name size _; do MOD[$name]=$(( size / 1024 )); done < /proc/modules

internet() {
    local -A ADDR
    local ifn fam addr gw gwdev dns k v d n state carrier type kind rx tx speed mac mtu drv ssid sig freq txr rxr conn since rate sum line via rxp txp rxe txe rxd txd sec bss svc
    service iwd NetworkManager wpa_supplicant systemd-networkd dhcpcd; svc=$REPLY
    while read -r _ ifn fam addr _; do ADDR[$ifn]+="${ADDR[$ifn]:+, }$addr"; done < <(ip -o addr show 2>/dev/null)
    read -r _ _ gw _ gwdev _ < <(ip route show default 2>/dev/null)
    while read -r k v _; do [ "$k" = nameserver ] && dns+="${dns:+, }$v"; done < /etc/resolv.conf 2>/dev/null
    for d in /sys/class/net/*; do
        n=${d##*/}
        [ "$n" = lo ] && continue
        rd "$d/operstate"; state=$REPLY
        rd "$d/carrier"; carrier=$REPLY
        [ "$state" = up ] || { [ "$state" = unknown ] && [ "$carrier" = 1 ]; } || continue
        rd "$d/type"; type=$REPLY
        if [ -d "$d/wireless" ] || [ -d "$d/phy80211" ]; then kind="Wi-Fi"
        elif [ -e "$d/tun_flags" ] || [ "$type" = 65534 ]; then kind="VPN tunnel"
        elif [ -d "$d/bridge" ]; then kind="Bridge"
        elif [ ! -e "$d/device" ]; then kind="Virtual"
        elif [[ $(readlink -f "$d/device") == */usb* ]]; then kind="USB network"
        else kind="Ethernet"; fi
        rd "$d/statistics/rx_bytes"; rx=$REPLY
        rd "$d/statistics/tx_bytes"; tx=$REPLY
        rd "$d/statistics/rx_packets"; rxp=$REPLY
        rd "$d/statistics/tx_packets"; txp=$REPLY
        rd "$d/statistics/rx_errors"; rxe=$REPLY
        rd "$d/statistics/tx_errors"; txe=$REPLY
        rd "$d/statistics/rx_dropped"; rxd=$REPLY
        rd "$d/statistics/tx_dropped"; txd=$REPLY
        rd "$d/address"; mac=$REPLY
        rd "$d/mtu"; mtu=$REPLY
        rd "$d/speed"; speed=$REPLY
        driver "$d/device"; drv=$REPLY
        ssid=; sig=; freq=; txr=; rxr=; conn=; since=0; rate=; via=(); sec=; bss=
        if [ "$gwdev" = "$n" ]; then via=("Gateway=$gw"); [ -n "$dns" ] && via+=("DNS=$dns"); fi
        if [ "$kind" = "Wi-Fi" ]; then
            if has iw; then
                while IFS= read -r line; do
                    case "$line" in
                        *SSID:*) ssid=${line#*SSID: } ;;
                        *signal:*) sig=${line#*signal: } ;;
                        *freq:*) freq="${line#*freq: } MHz" ;;
                        *"tx bitrate:"*) txr=${line#*tx bitrate: }; txr=${txr%% *} ;;
                        *"rx bitrate:"*) rxr=${line#*rx bitrate: }; rxr=${rxr%% *} ;;
                        "Connected to "*) bss=${line#Connected to }; bss=${bss%% *} ;;
                    esac
                done < <(iw dev "$n" link 2>/dev/null)
                conn=$(iw dev "$n" station dump 2>/dev/null | awk '/connected time/ { print $3; exit }')
            elif has iwctl; then
                while IFS= read -r line; do
                    trim "$line"; line=$REPLY
                    case "$line" in
                        "Connected network"*) trim "${line#Connected network}"; ssid=$REPLY ;;
                        RSSI*) trim "${line#RSSI}"; sig=$REPLY ;;
                        Frequency*) trim "${line#Frequency}"; freq="$REPLY MHz" ;;
                        Security*) trim "${line#Security}"; sec=$REPLY ;;
                        ConnectedBss*) trim "${line#ConnectedBss}"; bss=$REPLY ;;
                        TxBitrate*) trim "${line#TxBitrate}"; txr=$(( ${REPLY%% *} / 1000 )) ;;
                        RxBitrate*) trim "${line#RxBitrate}"; rxr=$(( ${REPLY%% *} / 1000 )) ;;
                    esac
                done < <(iwctl station "$n" show 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')
            elif has nmcli; then
                IFS=: read -r _ ssid txr sig < <(nmcli -t -f ACTIVE,SSID,RATE,SIGNAL dev wifi 2>/dev/null | grep '^yes')
                txr=${txr%% *}; sig="${sig}%"
            fi
            if [ -z "$sig" ]; then
                while read -r ifn _ _ v _; do [ "$ifn" = "$n:" ] && sig="${v%.} dBm"; done < /proc/net/wireless 2>/dev/null
            fi
            [ -n "$conn" ] && since=$(( now - conn ))
            [ -n "$txr" ] && rate="$txr Mbit/s"
            sum="Wi-Fi${ssid:+ · $ssid}${sig:+ · $sig}"
        else
            [ -n "$speed" ] && [ "$speed" -gt 0 ] 2>/dev/null && rate="$speed Mbit/s"
            sum="$kind${rate:+ · $rate}"
        fi
        emit Internet "net:$n" "$n" "$sum" "${MOD[${drv//-/_}]:-0}" "$rx" "$tx" "$since" "$rate" \
            "Type=$kind" "State=$state" ${ssid:+"Network=$ssid"} ${sig:+"Signal=$sig"} ${freq:+"Frequency=$freq"} \
            ${rxr:+"RX rate=$rxr Mbit/s"} ${txr:+"TX rate=$txr Mbit/s"} ${ADDR[$n]:+"Address=${ADDR[$n]}"} \
            ${sec:+"Security=$sec"} ${bss:+"Access point=$bss"} ${mac:+"MAC=$mac"} "${via[@]}" ${mtu:+"MTU=$mtu"} \
            "Packets=${rxp:-0} received, ${txp:-0} sent" "Errors=${rxe:-0} receive, ${txe:-0} send" "Dropped=${rxd:-0} receive, ${txd:-0} send" \
            ${drv:+"Driver=$drv"} ${svc:+"Service memory=$svc"}
    done
}

bluetooth() {
    has bluetoothctl || return
    local mac name line key val nm icon bat prof extra svc
    service bluetoothd; svc=$REPLY
    while read -r key mac name; do
        [ "$key" = Device ] && [ -n "$mac" ] || continue
        nm=$name; icon=; bat=; prof=; extra=()
        while IFS= read -r line; do
            trim "$line"; line=$REPLY
            key=${line%%:*}; val=${line#*: }
            case "$key" in
                Name) nm=$val ;;
                Icon) icon=$val ;;
                "Battery Percentage") bat=${val##*(}; bat=${bat%)*} ;;
                UUID) trim "${val%%(*}"; prof+="${prof:+, }$REPLY" ;;
                Alias|Class|Paired|Bonded|Trusted|Blocked|LegacyPairing|Modalias|RSSI|TxPower) extra+=("$key=$val") ;;
            esac
        done < <(timeout 2 bluetoothctl info "$mac" 2>/dev/null)
        emit Bluetooth "bt:$mac" "$nm" "${icon:-device}${bat:+ · battery $bat%}" 0 0 0 0 "" \
            "Address=$mac" ${icon:+"Type=$icon"} ${bat:+"Battery=$bat%"} "${extra[@]}" ${prof:+"Profiles=$prof"} ${svc:+"Service memory=$svc (shared by all Bluetooth devices)"}
    done < <(timeout 2 bluetoothctl devices Connected 2>/dev/null)
}

network() {
    has ss || return
    { ls -l /proc/[0-9]*/exe 2>/dev/null; echo ---; ps -eo pid=,etimes= 2>/dev/null; echo ---; ss -tunapiHO 2>/dev/null; } | awk -v now="$now" -v US="$US" -v GS=$'\035' -v RS2=$'\036' -v page="$PAGE_KB" '
        function loop(a) { return a ~ /^(127\.|\[::1\]|::1|\[::ffff:127\.)/ }
        function add(list, v,   k) { k = list SUBSEP v; if (k in has) return; has[k] = 1; n[list]++; if (n[list] <= 14) txt[list] = txt[list] (txt[list] == "" ? "" : ", ") v }
        $0 == "---" { part++; next }
        part == 0 {
            if (!match($0, /\/proc\/[0-9]+\/exe -> /)) next
            pid = substr($0, RSTART + 6, RLENGTH - 14)
            exe = substr($0, RSTART + RLENGTH)
            sub(/ \(deleted\)$/, "", exe); sub(/.*\//, "", exe)
            if (exe == "") next
            exeOf[pid] = exe
            pids[exe] = pids[exe] " " pid
            next
        }
        part == 1 { et[$1] = $2; next }
        {
            proto = $1; state = $2; lo = $5; peer = $6
            comm = "system services"; pid = 0
            if (match($0, /users:\(\("[^"]*",pid=[0-9]+/)) {
                s = substr($0, RSTART + 9, RLENGTH - 9)
                comm = s; sub(/",pid=.*/, "", comm)
                pid = s; sub(/.*pid=/, "", pid)
            }
            app = comm
            if (pid in exeOf && exeOf[pid] !~ /^(python[0-9.]*|node|electron[0-9]*|java|bash|sh|ruby|perl|bwrap)$/) app = exeOf[pid]
            listening = (state == "LISTEN" || peer ~ /:\*$/)
            if (listening) {
                if (loop(lo)) next
                port = lo; sub(/.*:/, "", port)
                listen[app]++; add("L" app, proto "/" port)
            } else {
                if (loop(peer)) next
                conns[app]++; add("P" app, peer)
            }
            apps[app] = 1
            if (pid) { add("I" app, pid); own[app] = own[app] " " pid; socks[pid]++ }
            if (match($0, /bytes_sent:[0-9]+/)) tx[app] += substr($0, RSTART + 11, RLENGTH - 11)
            if (match($0, /bytes_received:[0-9]+/)) rx[app] += substr($0, RSTART + 15, RLENGTH - 15)
        }
        END {
            for (app in apps) {
                list = (app in pids) ? pids[app] : own[app]
                c = split(list, p, " "); priv = 0; shared = 0; oldest = 0; procs = 0; known = 0; rows = ""
                delete done
                for (i = 1; i <= c; i++) {
                    if (p[i] in done) continue
                    done[p[i]] = 1
                    f = "/proc/" p[i] "/statm"; own_kb = 0
                    if ((getline line < f) > 0) { split(line, m, " "); own_kb = (m[2] - m[3]) * page; priv += m[2] - m[3]; if (m[3] > shared) shared = m[3] } else { close(f); continue }
                    close(f)
                    procs++
                    f = "/proc/" p[i] "/comm"; cm = ""
                    if ((getline line < f) > 0) cm = line
                    close(f)
                    f = "/proc/" p[i] "/stat"; th = ""
                    if ((getline line < f) > 0) { sub(/^.*\) /, "", line); split(line, m, " "); th = m[18] }
                    close(f)
                    f = "/proc/" p[i] "/cmdline"; kd = ""
                    if ((getline line < f) > 0) {
                        if (match(line, /--type=[a-zA-Z-]+/)) kd = substr(line, RSTART + 7, RLENGTH - 7)
                        else if (match(line, /-contentproc/)) { kd = line; gsub(/\0+$/, "", kd); sub(/.*\0/, "", kd) }
                    }
                    close(f)
                    age = 0
                    if (p[i] in et) { known = 1; age = now - et[p[i]]; if (et[p[i]] > oldest) oldest = et[p[i]] }
                    if (procs <= 80) rows = rows (rows == "" ? "" : RS2) p[i] GS cm GS kd GS own_kb GS th GS age GS (socks[p[i]] + 0)
                }
                mem = (priv + shared) * page
                sum = (conns[app] + 0) " connection" (conns[app] == 1 ? "" : "s") (listen[app] ? " · " listen[app] " listening" : "")
                d = "Processes=" procs
                d = d US "Connections=" (conns[app] + 0)
                if (listen[app]) d = d US "Listening on=" txt["L" app] (n["L" app] > 14 ? " …" : "")
                if (txt["P" app] != "") d = d US "Remote=" txt["P" app] (n["P" app] > 14 ? " … +" (n["P" app] - 14) : "")
                if (procs > 1) d = d US "Shared memory=" sprintf("%.1f MB", shared * page / 1024) " used by all of them together"
                d = d US "Bandwidth=TCP only, QUIC/UDP not counted"
                if (rows != "") d = d US "@procs=" rows
                printf "Network\tproc:%s\t%s\t%s\t%d\t%.0f\t%.0f\t%d\t\t%s\t%d\n", app, app, sum, mem, rx[app], tx[app], (known ? now - oldest : 0), d, procs
            }
        }' | sort -t$'\t' -k3,3
}

devices() {
    local d n vendor product vid pid speed serial rem dur power ver cls kinds drvs mem i ic sub proto k drv since loc name
    for d in /sys/bus/usb/devices/*; do
        n=${d##*/}
        [[ $n == *:* || $n == usb* ]] && continue
        rd "$d/idVendor"; vid=$REPLY
        [ -n "$vid" ] || continue
        rd "$d/idProduct"; pid=$REPLY
        rd "$d/bDeviceClass"; cls=$REPLY
        rd "$d/removable"; rem=$REPLY
        [ "$cls" = 09 ] && [ "$rem" != removable ] && continue
        rd "$d/manufacturer"; vendor=$REPLY
        rd "$d/product"; product=$REPLY
        rd "$d/speed"; speed=$REPLY
        rd "$d/serial"; serial=$REPLY
        rd "$d/power/connected_duration"; dur=$REPLY
        rd "$d/bMaxPower"; power=$REPLY
        rd "$d/version"; trim "$REPLY"; ver=$REPLY
        kinds=; drvs=; mem=0
        for i in "$d"/"$n":*; do
            [ -d "$i" ] || continue
            rd "$i/bInterfaceClass"; ic=$REPLY
            rd "$i/bInterfaceSubClass"; sub=$REPLY
            rd "$i/bInterfaceProtocol"; proto=$REPLY
            case "$ic" in
                01) k=Audio ;; 02|0a) k=Network ;; 06) k=Camera ;; 07) k=Printer ;; 08) k=Storage ;; 09) k=Hub ;;
                0b) k="Smart card" ;; 0e) k=Video ;; e0) k=Wireless; [ "$sub$proto" = 0101 ] && k=Bluetooth ;;
                03) k=HID; [ "$sub" = 01 ] && { [ "$proto" = 01 ] && k=Keyboard; [ "$proto" = 02 ] && k=Mouse; } ;;
                *) k= ;;
            esac
            [ -n "$k" ] && [[ ", $kinds, " != *", $k, "* ]] && kinds+="${kinds:+, }$k"
            driver "$i"; drv=$REPLY
            if [ -n "$drv" ] && [[ " $drvs " != *" $drv "* ]]; then drvs+="${drvs:+ }$drv"; mem=$(( mem + ${MOD[${drv//-/_}]:-0} )); fi
        done
        since=0; [ -n "$dur" ] && since=$(( now - dur / 1000 ))
        case "$rem" in removable) loc=external ;; fixed) loc=internal ;; *) loc= ;; esac
        name=${product:-$vid:$pid}
        emit Devices "usb:$n" "$name" "${kinds:-USB device}${loc:+ · $loc}${vendor:+ · $vendor}" "$mem" 0 0 "$since" "${speed:+$speed Mbit/s}" \
            ${vendor:+"Vendor=$vendor"} "Product=$name" "USB ID=$vid:$pid" ${serial:+"Serial=$serial"} ${kinds:+"Type=$kinds"} \
            ${loc:+"Location=$loc"} "Port=$n" ${speed:+"Speed=$speed Mbit/s"} ${ver:+"USB version=$ver"} ${power:+"Max power=$power"} ${drvs:+"Drivers=$drvs"}
    done
    for d in /sys/bus/thunderbolt/devices/*; do
        n=${d##*/}
        [[ -d $d && $n != domain* && $n != *-0 && $n != *:* ]] || continue
        rd "$d/device_name"; product=$REPLY
        rd "$d/vendor_name"; vendor=$REPLY
        emit Devices "tb:$n" "${product:-Thunderbolt $n}" "Thunderbolt${vendor:+ · $vendor}" 0 0 0 0 "" ${vendor:+"Vendor=$vendor"} "Port=$n"
    done
}

power() {
    local d n type online status cap pw cur volt bat model usbt watts
    for d in /sys/class/power_supply/*; do
        rd "$d/type"
        [ "$REPLY" = Battery ] || continue
        rd "$d/status"; status=$REPLY
        rd "$d/capacity"; cap=$REPLY
        rd "$d/power_now"; pw=$REPLY
        if [ -z "$pw" ]; then
            rd "$d/current_now"; cur=$REPLY
            rd "$d/voltage_now"; volt=$REPLY
            [ -n "$cur" ] && [ -n "$volt" ] && pw=$(( cur / 1000 * volt / 1000 ))
        fi
        [ -n "$pw" ] && watts="$(( pw / 1000000 )).$(( pw % 1000000 / 100000 )) W"
        bat="${cap:+$cap%}${status:+ $status}"
    done
    for d in /sys/class/power_supply/*; do
        n=${d##*/}
        rd "$d/type"; type=$REPLY
        [ "$type" = Battery ] && continue
        rd "$d/online"; online=$REPLY
        [ "$online" = 1 ] || continue
        rd "$d/model_name"; model=$REPLY
        rd "$d/usb_type"; usbt=$REPLY
        emit Power "pwr:$n" "Power cable" "${type:-AC}${bat:+ · battery $bat}" 0 0 0 0 "$watts" \
            "Supply=$n" "Type=${type:-AC}" ${model:+"Model=$model"} ${usbt:+"USB type=$usbt"} ${bat:+"Battery=$bat"} ${watts:+"Battery power=$watts"}
    done
}

displays() {
    local name desc w h hz scale make model serial d st mode
    if has hyprctl && has jq; then
        while IFS=$'\t' read -r name desc w h hz scale make model serial; do
            [ -n "$name" ] || continue
            emit Displays "disp:$name" "$name" "${desc:-display} · ${w}x${h}" 0 0 0 0 "${hz%.*} Hz" \
                "Connector=$name" ${make:+"Make=$make"} ${model:+"Model=$model"} ${serial:+"Serial=$serial"} "Resolution=${w}x${h}" "Refresh=$hz Hz" "Scale=$scale" \
                "Location=$([[ $name == eDP* || $name == LVDS* ]] && echo internal || echo external)"
        done < <(hyprctl -j monitors 2>/dev/null | jq -r '.[] | [.name, .description, .width, .height, .refreshRate, .scale, .make, .model, .serial] | map(tostring) | @tsv' 2>/dev/null)
    else
        for d in /sys/class/drm/card*-*; do
            rd "$d/status"; st=$REPLY
            [ "$st" = connected ] || continue
            name=${d##*/}; name=${name#card*-}
            rd "$d/modes"; mode=$REPLY
            emit Displays "disp:$name" "$name" "${mode:-display}" 0 0 0 0 "" "Connector=$name" ${mode:+"Resolution=$mode"}
        done
    fi
}

storage() {
    local b n rem path size model stat mnt dev mp fs _
    for b in /sys/block/*; do
        n=${b##*/}
        [[ $n == loop* || $n == zram* || $n == dm-* || $n == ram* ]] && continue
        rd "$b/removable"; rem=$REPLY
        path=$(readlink -f "$b")
        [[ $rem = 1 || $path == */usb* || $n == mmcblk* ]] || continue
        rd "$b/size"; size=$REPLY
        [ "${size:-0}" -gt 0 ] 2>/dev/null || continue
        rd "$b/device/model"; trim "$REPLY"; model=$REPLY
        read -r _ _ rs _ _ _ ws _ < "$b/stat" 2>/dev/null
        mnt=
        while read -r dev mp _; do [[ $dev == /dev/$n* ]] && mnt+="${mnt:+, }$mp"; done < /proc/mounts
        emit Storage "blk:$n" "${model:-$n}" "$(( size / 2097152 )) GB${mnt:+ · mounted}" 0 "$(( ${rs:-0} * 512 ))" "$(( ${ws:-0} * 512 ))" 0 "" \
            "Device=/dev/$n" "Size=$(( size / 2097152 )) GB" ${mnt:+"Mounted at=$mnt"} "Bandwidth=read is download, write is upload"
    done
    while read -r dev mp fs _; do
        case "$fs" in nfs|nfs4|cifs|smb3|fuse.sshfs|9p|ceph|glusterfs|fuse.rclone|davfs)
            emit Storage "mnt:$mp" "$mp" "$fs · $dev" 0 0 0 0 "" "Source=$dev" "Type=$fs" "Mounted at=$mp" ;;
        esac
    done < /proc/mounts
}

sessions() {
    has who || return
    local user tty rest host
    while read -r user tty rest; do
        [[ $rest == *"("*")"* ]] || continue
        host=${rest##*(}; host=${host%)*}
        [[ $host == :* || $host == tty* || $host == wayland* || $host == seat* || -z $host ]] && continue
        emit Sessions "ses:$tty" "$user@$host" "remote login · $tty" 0 0 0 0 "" "User=$user" "From=$host" "Terminal=$tty"
    done < <(who 2>/dev/null)
}

[ $# -gt 0 ] || set -- internet bluetooth network devices power displays storage sessions
for part in "$@"; do
    case "${part,,}" in internet|bluetooth|network|devices|power|displays|storage|sessions) "${part,,}" ;; esac
done
exit 0

#!/bin/sh
R="${DOLPHIN_ROOTFS:-}"
case "$1" in
    theme)
        [ -d "$2" ] && [ -n "$3" ] || exit 1
        mkdir -p "$R/usr/share/plymouth/themes" && cp -rT "$2" "$R/usr/share/plymouth/themes/$3" || exit 1
        [ -n "$R" ] || plymouth-set-default-theme -R "$3"
        ;;
    hook)
        f="$R/etc/mkinitcpio.conf"
        [ -f "$f" ] || exit 1
        grep -qE '^HOOKS=.*\bplymouth\b' "$f" && exit 0
        cp -f "$f" "$f.bak" || exit 1
        if grep -qE '^HOOKS=\([^)]*\bsystemd\b' "$f"; then sed -i -E 's/^(HOOKS=\([^)]*\bsystemd\b)/\1 plymouth/' "$f"
        elif grep -qE '^HOOKS=\([^)]*\budev\b' "$f"; then sed -i -E 's/^(HOOKS=\([^)]*\budev\b)/\1 plymouth/' "$f"
        else exit 1; fi
        [ -n "$R" ] || mkinitcpio -P
        ;;
    splash)
        ok=""
        for e in "$R"/boot/loader/entries/*.conf "$R"/efi/loader/entries/*.conf; do
            [ -f "$e" ] && grep -q '^options[[:space:]]' "$e" || continue
            cp -f "$e" "$e.bak"
            sed -i -E -e '/^options[[:space:]]/{/(^|[[:space:]])quiet([[:space:]]|$)/!s/[[:space:]]*$/ quiet/}' -e '/^options[[:space:]]/{/(^|[[:space:]])splash([[:space:]]|$)/!s/[[:space:]]*$/ splash/}' "$e"
            ok=1
        done
        [ -n "$ok" ] && exit 0
        f="$R/etc/kernel/cmdline"
        if [ -s "$f" ]; then
            cp -f "$f" "$f.bak"
            sed -i -E -e '1{/(^|[[:space:]])quiet([[:space:]]|$)/!s/[[:space:]]*$/ quiet/}' -e '1{/(^|[[:space:]])splash([[:space:]]|$)/!s/[[:space:]]*$/ splash/}' "$f"
            [ -n "$R" ] || mkinitcpio -P
            exit 0
        fi
        f="$R/etc/default/grub"
        if grep -qs '^GRUB_CMDLINE_LINUX_DEFAULT=' "$f"; then
            cp -f "$f" "$f.bak"
            sed -i -E -e "/^GRUB_CMDLINE_LINUX_DEFAULT=/{/(=|[[:space:]\"'])quiet([[:space:]\"']|\$)/!s/([\"'])[[:space:]]*\$/ quiet\\1/}" -e "/^GRUB_CMDLINE_LINUX_DEFAULT=/{/(=|[[:space:]\"'])splash([[:space:]\"']|\$)/!s/([\"'])[[:space:]]*\$/ splash\\1/}" "$f"
            [ -n "$R" ] || grub-mkconfig -o /boot/grub/grub.cfg
            exit 0
        fi
        exit 3
        ;;
    greeter)
        [ -f "$2/Interface/Greeter/Greeter.qml" ] || exit 1
        f="$R/etc/greetd/config.toml"
        mkdir -p "$R/etc/greetd" || exit 1
        [ -f "$f" ] && cp -f "$f" "$f.bak"
        printf '[terminal]\nvt = 1\n\n[default_session]\ncommand = "env QT_WAYLAND_DISABLE_WINDOWDECORATION=1 cage -s -- qs -p %s/Interface/Greeter/Greeter.qml >/dev/null 2>&1"\nuser = "greeter"\n' "$2" > "$f" || exit 1
        [ -n "$R" ] && exit 0
        for d in sddm ly gdm lightdm lxdm; do systemctl disable "$d" >/dev/null 2>&1; done
        systemctl enable greetd
        ;;
    hush)
        [ -n "$R" ] && exit 0
        systemctl mask plymouth-halt.service plymouth-kexec.service plymouth-poweroff.service plymouth-reboot.service
        ;;
    *) exit 2 ;;
esac

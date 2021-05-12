#!/bin/bash

# called by dracut
check() {
    # No point trying to support lvm if the binaries are missing
    require_binaries lvm || return 1

    return 0
}

# called by dracut
depends() {
    # We depend on dm_mod being loaded
    echo systemd
    return 0
}


installkernel() {
    hostonly='' instmods dm-snapshot
}

# called by dracut
install() {
    local _i

    inst lvm
    inst lvmetad

    inst_rules 11-dm-lvm.rules 69-dm-lvm-metad.rules 95-dm-notify.rules 10-dm.rules 13-dm-disk.rules 10-dm.rules

    inst /etc/lvm/lvm.conf
    inst_libdir_file "libdevmapper-event-lvm*.so"

    inst_multiple \
        $systemdsystemunitdir/lvm2-lvmetad.socket \
        $systemdsystemunitdir/sysinit.target.wants/lvm2-lvmetad.socket \
        $systemdsystemunitdir/lvm2-lvmetad.service \
        $systemdsystemunitdir/lvm2-pvscan@.service \
        $systemdsystemunitdir/lvm2-monitor.service \
        $systemdsystemunitdir/sysinit.target.wants/lvm2-monitor.service \
        $systemdutildir/system-generators/lvm2-activation-generator

    inst_multiple -o thin_dump thin_restore thin_check thin_repair \
                  cache_dump cache_restore cache_check cache_repair \
                  era_check era_dump era_invalidate era_restore \
                    lvmconfig

}

#!/bin/bash

# called by dracut
check() {
    # No point trying to support lvm if the binaries are missing
    return 0
}

# called by dracut
depends() {
    # We depend on dm_mod being loaded
    echo systemd
    return 0
}

# called by dracut
install() {
  inst_multiple \
    $systemdsystemunitdir/veritysetup-pre.target \
    $systemdsystemunitdir/veritysetup.target \
    $systemdutildir/system-generators/systemd-veritysetup-generator \
    /usr/lib/systemd/systemd-veritysetup
  dracut_instmods dm-verity
  $SYSTEMCTL -q --root "$initdir" add-wants sysinit.target veritysetup.target
}

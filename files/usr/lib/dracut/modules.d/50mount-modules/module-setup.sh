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
  inst mkdir
  inst cut
  inst uname
  inst grep
  inst /usr/bin/mount-modules-dir
  inst $systemdsystemunitdir/sysinit.target.wants/mount-modules.service
  inst $systemdsystemunitdir/mount-modules.service
}

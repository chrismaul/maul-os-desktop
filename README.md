# Maul OS Desktop

## Install

1. Boot in live cd or running os
   1. Install docker, systemd-boot, btrfs
1. Make EFI boot directory, label the fs BOOT
1. Install systemd-boot bootctl install
1. encrypt root disk with uuid =bed94fe4-038f-493f-8fac-e7f273138738 then make lvm on top of it

1. Make lvm vg called root
1. Make a lvm lv for the same amount of data about 100M
1. Format the lv with btrfs, with fs label of `data`
   1. create subvolume etc/NetworkManager/system-connections . optionally copy the etc/NetworkManager/system-connections from running machine
   1. create subvolume var/lib/firstboot
   1. create subvolume var/lib/systemd/home
1. mount the btrfs data subvolume var/lib/systemd/home add a settings.conf file to the fs with the following content

```
FIRSTBOOT_LOCALE=en_US.UTF-8
FIRSTBOOT_KEYMAP=us
FIRSTBOOT_TIMEZONE=America/New_York
FIRSTBOOT_HOSTNAME=$HOSTNAME
FIRSTBOOT_MACHINE_ID=$MACHINEID
```

1. mount the sub volume for var/lib/systemd/home.
1. make a lv for the new user
1. and make systemd-homed user
1. update the user for systemd to have the proper imagePath. Remove it from the PerMachine block to general
   1. Copy the file and edit it, then run sudo homectl update chris --identity=$PWD/chris.identity. Be sure only include general json bits, so delete items like the key
1. I set it up systemd homed on the livecd then copy the config over
1. When setting the homed user you may need to run kpartx -a $DEV because it is not a disk. The device need to end in -homed
1. run the main docker image by do `docker run --rm -it --privileged -v /dev:/dev -v /:/host $IMAGE`

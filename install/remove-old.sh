#!/bin/bash
VG_NAME=${VG_NAME:-root}
if [ -z "$BOOT_DIR" ]
then
  export BOOT_DIR=/boot
fi

if ! findmnt $BOOT_DIR > /dev/null
then
  mkdir -p $BOOT_DIR
  mount LABEL=BOOT $BOOT_DIR
fi
KEEP_OLD=${1:-7}
if [ -n "$KEEP_OLD" ]
then
  DEVICES=""
  for DEV_TYPE in modules maul-os
  do
    DEVICES="$DEVICES $(ls /dev/$VG_NAME/$DEV_TYPE-* | grep -v '-verity$' | sort -rV | tail -n +$KEEP_OLD)"
    DEVICES="$DEVICES $(ls /dev/$VG_NAME/$DEV_TYPE-*-verity | sort -rV | tail -n +$KEEP_OLD)"
  done
  for i in $DEVICES
  do
    lvremove -fy $i
  done
  for KERNEL in $(ls $BOOT_DIR/EFI/Linux/maul-os-* | sort -rV | tail -n +$KEEP_OLD)
  do
    rm $KERNEL
  done
fi
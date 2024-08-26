#!/system/bin/sh

BINPATH="$MODPATH/bin"

. ${BINPATH}/constants.sh || abort
. ${BINPATH}/bootimg.sh || abort

unpack
/data/adb/magisk/magiskboot cpio ramdisk.cpio \
"rm overlay.d/init.bootanim.rc" \
|| abort "! Unable to patch ramdisk"
repack

ui_print "- overlay.d script was removed successfully"

touch /data/adb/modules/LateBootanim/remove
touch $MODPATH/remove

rm -rf $MODPATH/bin
rm -rf $MODPATH/overlay.d

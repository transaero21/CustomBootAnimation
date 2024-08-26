#!/system/bin/sh

BINPATH="$MODPATH/bin"

. ${BINPATH}/constants.sh || abort
. ${BINPATH}/bootimg.sh || abort

unpack
/data/adb/magisk/magiskboot cpio ramdisk.cpio \
"mkdir 0750 overlay.d" \
"add 0700 overlay.d/init.bootanim.rc ${MODPATH}/overlay.d/init.bootanim.rc" \
|| abort "! Unable to patch ramdisk"
repack

ui_print "- overlay.d script was added successfully"

rm -rf $MODPATH/bin
rm -rf $MODPATH/overlay.d

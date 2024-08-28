#!/system/bin/sh

function unpack() {
    is_mounted /data || mount /data || is_mounted /cache || mount /cache
    mount_partitions
    check_data
    get_flags
    find_boot_image

    [ -z $BOOTIMAGE ] && abort "! Unable to detect target image"
    ui_print "- Target image: $BOOTIMAGE"

    $magiskboot unpack "$BOOTIMAGE"

    case $? in
        0 ) ;;
        1 )
            abort "! Unsupported/Unknown image format"
            ;;
        2 )
            abort "! ChromeOS boot image detected"
            ;;
        * )
            abort "! Unable to unpack boot image"
            ;;
    esac
}

function repack() {
    ui_print "- Repacking boot image"
    $magiskboot repack "$BOOTIMAGE" || abort "! Unable to repack boot image"

    ui_print "- Flashing new boot image"
    flash_image new-boot.img "$BOOTIMAGE"
    case $? in
        1)
            abort "! Insufficient partition size"
            ;;
        2)
            abort "! $BOOTIMAGE is read only"
            ;;
    esac
    $magiskboot cleanup
    rm -f new-boot.img
}

. /data/adb/magisk/util_functions.sh
magiskboot="/data/adb/magisk/magiskboot"

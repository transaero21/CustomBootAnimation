#!/system/bin/sh

function keyinit() {
    ui_print "- Intialize volume keys, press any volume key..."
    if (timeout 10 /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" >$TMPDIR/events); then
        return 0
    else
        return 1
    fi
}

function handlekey() {
    ui_print "  Waiting for further input..."
    while true; do
        /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" >$TMPDIR/events
        if ($(cat $TMPDIR/events 2>/dev/null | /system/bin/grep VOLUME >/dev/null)); then
            break
        fi
    done
    if ($(cat $TMPDIR/events 2>/dev/null | /system/bin/grep VOLUMEUP >/dev/null)); then
        ui_print "  Detected Volume Up"
        return 0
    else
        ui_print "  Detected Volume Down"
        return 1
    fi
}

if keyinit; then
    ui_print "  Volume keys initialized successfully"
else 
    abort "  Unable to detect volume keys"
fi

ui_print ""

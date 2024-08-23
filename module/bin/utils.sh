#!/system/bin/sh

function validate_bootanimation() {
    local file="$1"
    if unzip -l "$file" | grep -q "desc.txt"; then
        return 0
    else
        return 1
    fi
}

function get_modpath_file() {
    local path="$1"
    case "${path}" in
        /system*) echo "${MODPATH}${path}" ;;
        *) echo "${MODPATH}/system${path}" ;;
    esac
}

function handle_permissions() {
    local dest="$1"
    if [ -d "$dest" ]; then
        set_perm "$dest" 0 0 0755
    elif [ -f "$dest" ]; then
        set_perm "$dest" 0 0 0644
    fi
}

#!/system/bin/sh

ui_print ""

BINPATH="$MODPATH/bin"

. ${BINPATH}/constants.sh || abort
. ${BINPATH}/utils.sh || abort
. ${BINPATH}/keyhandler.sh || abort

sleep 0.5
ui_print "- Analyzing bootanimation executable and library..."

if [ ! -f "$BOOTANIMATION_EXEC_PATH" ] || [ ! -f "$BOOTANIMATION_LIB_PATH" ]; then
    abort "  This device does not have bootanimation support"
fi

SUPPORTED_ANIMATION_FILES=$(strings "$BOOTANIMATION_LIB_PATH" | grep -E '^/.+\.zip$' | awk '
{
    key = "5";  # Default to "5" for "/other" if not matched

    if ($0 ~ /^\/apex\//) key = "1";
    else if ($0 ~ /^\/product\//) key = "2";
    else if ($0 ~ /^\/oem\//) key = "3";
    else if ($0 ~ /^\/system\//) key = "4";

    print key "\t" $0;
}' | sort -n | cut -f2-)
if [ -z "$SUPPORTED_ANIMATION_FILES" ]; then
    abort "  Failed to get supported animations"
fi

SUPPORTED_ANIMATION_FILES_TYPES=$(echo "$SUPPORTED_ANIMATION_FILES" | awk -F'/' '{print $NF}' | sed 's/.zip$//' | sort -u)
if [ -z "$SUPPORTED_ANIMATION_FILES_TYPES" ]; then
    abort "  Failed to get supported animation file types"
fi

ui_print "  Successfully analyzed"

sleep 0.5
ui_print ""
ui_print "- Scanning for boot animations in: ${SEARCH_DIR}"

ZIP_FILES=$(find "${SEARCH_DIR}" -name '*.zip')
VALID_BOOTANIMATIONS_FILE="${TMPDIR}/valid_bootanimations"
: > "$VALID_BOOTANIMATIONS_FILE"

ui_print "  Almost done..."

echo "${ZIP_FILES}" | while IFS= read -r file; do
    if validate_bootanimation "${file}"; then
        echo "${file}" >> "$VALID_BOOTANIMATIONS_FILE"
    fi
done

if [ ! -s "$VALID_BOOTANIMATIONS_FILE" ]; then
    abort "  No valid boot animations found in ${SEARCH_DIR}"
else
    ui_print "  Found $(wc -l < "$VALID_BOOTANIMATIONS_FILE") boot animations"
fi

while true; do
    sleep 0.5
    ui_print ""
    ui_print "- Select boot animation"
    ui_print "  Vol Up -> Switch boot animation"
    ui_print "  Vol Down -> Select boot animation"
    

    sleep 0.5
    ui_print ""
    counter=1
    while IFS= read -r line; do
        ui_print "  [$counter] $(basename "${line}") ($(dirname "${line}"))"
        counter=$((counter + 1))
    done < "${VALID_BOOTANIMATIONS_FILE}"


    POS=1
    TOTAL=$(wc -l < "${VALID_BOOTANIMATIONS_FILE}")

    while true; do
        ui_print ""
        ui_print "  Selected option: $POS"
        handlekey && POS="$((POS + 1))" || break
        [[ "$POS" -gt "$TOTAL" ]] && POS=1
    done

    NEW_ANIMATION_FILE="$(sed -n "${POS}p" < "$VALID_BOOTANIMATIONS_FILE")"
    ui_print ""
    ui_print "  Selected $(basename "${NEW_ANIMATION_FILE}") ($(dirname "${NEW_ANIMATION_FILE}"))"

    sleep 0.5
    ui_print ""
    ui_print "- Select the animation file type"
    ui_print "  Vol Up -> Switch file type"
    ui_print "  Vol Down -> Select file type"

    sleep 0.5
    ui_print ""
    counter=1
    for type in $SUPPORTED_ANIMATION_FILES_TYPES; do
        ui_print "  [$counter] $type"
        counter=$((counter + 1))
    done

    POS=1
    TOTAL=$(echo "$SUPPORTED_ANIMATION_FILES_TYPES" | wc -w)

    while true; do
        ui_print ""
        ui_print "  Selected option: $POS"
        handlekey && POS="$((POS + 1))" || break
        [[ "$POS" -gt "$TOTAL" ]] && POS=1
    done

    ANIMATION_FILE_TYPE=$(echo -e "$SUPPORTED_ANIMATION_FILES_TYPES" | sed -n "${POS}p")

    sleep 0.5
    ui_print ""
    ui_print "- Select boot animation path to replace (for ${ANIMATION_FILE_TYPE})"
    ui_print "  Options are sorted in order of application"
    ui_print "  Vol Up -> Switch file type"
    ui_print "  Vol Down -> Select file type"

    sleep 0.5
    ui_print ""
    counter=1
    for file in $SUPPORTED_ANIMATION_FILES; do
        mathed=$(echo "${file}" | grep "${ANIMATION_FILE_TYPE}.zip")
        if [ -n "${mathed}" ]; then
            modpath_file="$(get_modpath_file "${mathed}")" 
            if [[ -f "${modpath_file}" && -f "${file}" ]]; then
                ui_print "  [$counter] $mathed [Exist, Replaced]"
            elif [ -f "${file}" ];then
                ui_print "  [$counter] $mathed [Exist]"
            elif [ -f "${modpath_file}" ];then
                ui_print "  [$counter] $mathed [Replaced]"
            else
                ui_print "  [$counter] $mathed"
            fi
            counter=$((counter + 1))
        fi
    done

    while true; do
        ui_print ""
        ui_print "  Selected option: $POS"
        handlekey && POS="$((POS + 1))" || break
        [[ "$POS" -gt "$TOTAL" ]] && POS=1
    done

    counter=1
    for file in $SUPPORTED_ANIMATION_FILES; do
        mathed=$(echo "${file}" | grep "${ANIMATION_FILE_TYPE}.zip")
        if [ -n "${mathed}" ]; then
            if [ "$counter" -eq "$POS" ]; then
                TARGET_ANIMATION_FILE="${file}"
                break
            fi
            counter=$((counter + 1))
        fi
    done

    sleep 0.5
    ui_print ""
    ui_print "- Replacing ${TARGET_ANIMATION_FILE}"
    if [ -f "${NEW_ANIMATION_FILE}" ]; then
        ui_print "  Revalidating boot animation..."
        if validate_bootanimation "${NEW_ANIMATION_FILE}"; then
            ui_print "  Moving boot animation to module's directory..."
            modpath_file="$(get_modpath_file "${TARGET_ANIMATION_FILE}")"
            mkdir -p "$(dirname "${modpath_file}")"
            cp -f "$NEW_ANIMATION_FILE" "${modpath_file}"
        else
            abort "  Invalid boot animation file"
        fi
    else
        abort "  File not found at the provided path"
    fi
    ui_print "  Animation successfully changed"

    sleep 0.5
    ui_print ""
    ui_print "- Do you want to replace anything else?"
    ui_print "  Vol Up -> Yes"
    ui_print "  Vol Down -> No"
    ui_print ""

    if ! handlekey; then
        break
    fi
done

ui_print ""
ui_print "- Setting permissions..."

find "${MODPATH}/system" | while read -r path; do
    src=$(echo "$path" | sed "s|^${MODPATH}||")
    dest="${MODPATH}${src}"

    if [[ -f "$src" || -d "$src" ]]; then
        # Manually copy permissions and ownership, --reference isn't supported =(
        src_perms=$(stat -c %a "$src")
        src_uid=$(stat -c %u "$src")
        src_gid=$(stat -c %g "$src")

        if ! chmod "$src_perms" "$dest" || ! chown "$src_uid:$src_gid" "$dest"; then
            handle_permissions "$dest"
        fi
    else
        handle_permissions "$dest"
    fi
done

rm -rf $MODPATH/bin

ui_print ""

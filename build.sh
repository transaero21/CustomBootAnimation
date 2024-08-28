#!/bin/bash

MODULES=("custom-boot-animation" "late-bootanim" "revert-late-bootanim")
COMMON_DIR="common"
TMP_DIR="tmp_build_dir"

declare -A VARS
VARS=(
    [version]="$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo '1.0.0')"
    [versionCode]="$(($(git tag | wc -l) > 0 ? $(git tag | wc -l) : 1))"
)

mkdir -p "$TMP_DIR"

for MODULE in "${MODULES[@]}"; do
    MODULE_DIR="$TMP_DIR/$MODULE"
    COMMON_PROP="$COMMON_DIR/module.prop"
    MODULE_PROP="$MODULE_DIR/module.prop"

    cp -r "$MODULE" "$TMP_DIR/"
    rsync -avq --exclude="module.prop" "$COMMON_DIR/" "$MODULE_DIR/"

    if ! [[ $(tail -c1 "$MODULE_PROP" | wc -l) -gt 0 ]]; then
        echo "" >> "$MODULE_PROP"
    fi

    while IFS= read -r pair || [ -n "$pair" ]; do
        key=$(echo "$pair" | cut -d '=' -f 1)
        value=$(echo "$pair" | cut -d '=' -f 2-)
        if grep -q "^$key=" "$MODULE_PROP"; then
            sed -i '' "s/^$key=.*/$key=$value/" "$MODULE_PROP"
        else
            echo "$pair" >> "$MODULE_PROP"
        fi
    done < "$COMMON_PROP"

    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^[^#]*\${([^}]+)} ]]; then
            var_name="${BASH_REMATCH[1]}"
            if [[ -z "${VARS[$var_name]}" ]]; then
                echo "Error: Variable \${$var_name} not found"
                exit 1
            fi
            sed -i '' "s/\${$var_name}/${VARS[$var_name]}/g" "$MODULE_PROP"
        fi
    done < "$MODULE_PROP"

    MODULE_ID=$(grep '^id=' "$MODULE_PROP" | cut -d '=' -f 2)
    MODULE_VERSION=$(grep '^version=' "$MODULE_PROP" | cut -d '=' -f 2)
    if [ -z "$MODULE_ID" ] || [ -z "$MODULE_VERSION" ]; then
        echo "Error: Module id or version not found in $MODULE_PROP"
        continue
    fi

    ZIP_NAME="${MODULE_ID}-v${MODULE_VERSION}.zip"
    cd "$MODULE_DIR" || exit
    zip -rq "../../$ZIP_NAME" ./*
    cd ../..

    echo "Processed $MODULE: $MODULE_ID -> $ZIP_NAME"
done

rm -rf "$TMP_DIR"
echo "Cleaned up temporary build directory"

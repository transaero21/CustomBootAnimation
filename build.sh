#!/bin/bash

MODULES=("custom-boot-animation")
COMMON_DIR="common"
TMP_DIR="tmp_build_dir"

setup_tmp_dir() {
  mkdir -p "$TMP_DIR"
  for MODULE in "${MODULES[@]}"; do
    cp -r "$MODULE" "$TMP_DIR/"
    cp -r "$COMMON_DIR/." "$TMP_DIR/$MODULE/"
    echo "Set up $MODULE in temporary directory with common files"
  done
}

zip_modules() {
  for MODULE in "${MODULES[@]}"; do
    MODULE_ID=$(grep '^id=' "$TMP_DIR/$MODULE/module.prop" | cut -d '=' -f 2)
    MODULE_VERSION=$(grep '^version=' "$TMP_DIR/$MODULE/module.prop" | cut -d '=' -f 2)
    if [ -z "$MODULE_ID" ] || [ -z "$MODULE_VERSION" ]; then
      echo "Error: Module id or version not found in $MODULE/module.prop"
      continue
    fi

    ZIP_NAME="${MODULE_ID}-v${MODULE_VERSION}.zip"
    cd "$TMP_DIR/$MODULE" || exit
    zip -r "../../$ZIP_NAME" ./*
    cd ../..
    echo "Zipped $MODULE into $ZIP_NAME"
  done
}

clean_up() {
  rm -rf "$TMP_DIR"
  echo "Cleaned up temporary build directory"
}

setup_tmp_dir
zip_modules
clean_up

#!/usr/bin/env bash +e

ISO_NAME=`ls "$ISO_DIR"`
ENV_NAME=MOS_CI_"${{ISO_NAME}}${{ENV_CHANGER}}"
ISO_ID=`echo "$ISO_NAME" | cut -f3 -d-`
ISO_PATH="$ISO_DIR/$ISO_NAME"

echo "ENV_NAME=$ENV_NAME" > "$ENV_INJECT_PATH"
echo "ISO_ID=$ISO_ID" >> "$ENV_INJECT_PATH"
echo "ISO_PATH=$ISO_PATH" >> "$ENV_INJECT_PATH"
#!/usr/bin/env bash

PREFIX='MOS_CI_'

echo 'Trying to erase all MOS_CI environments...'

sudo dos.py list > temp
while read -r LINE
do
set -e
if [[ "$LINE" == "$PREFIX"* ]]; then
sudo dos.py erase "$LINE" || true
fi
done < temp

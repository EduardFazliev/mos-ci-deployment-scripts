set +e
ISO_NAME=`ls "$ISO_DIR"`
ISO_ID=`echo "$ISO_NAME" | cut -f3 -d-`

# Generate file for build-name plugin
SNAPSHOT=`echo $SNAPSHOT_NAME | sed 's/ha_deploy_//'`
echo "$ISO_ID"_"$SNAPSHOT" > build-name-setter.info

ENV_NAME=MOS_CI_"$ISO_NAME"

REPORT_PATH="$REPORT_PREFIX"/"$ENV_NAME"_"$SNAPSHOT_NAME"
echo "BUILD=$BUILD_URL" >> "$ENV_INJECT_PATH"
echo "REPORT_PATH=$REPORT_PATH" >> "$ENV_INJECT_PATH"
echo "$REPORT_PATH" > ./param.pm

virtualenv venv
. venv/bin/activate
pip install -U pip
pip install tox
tox -e {tox_test_name} -- -v -E "$ENV_NAME" -S "$SNAPSHOT_NAME"
deactivate
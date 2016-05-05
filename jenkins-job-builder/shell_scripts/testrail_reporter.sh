echo "$ISO_ID.$SNAPSHOT_NAME" > build-name-setter.info

virtualenv testrail
. testrail/bin/activate

git clone https://github.com/gdyuldin/testrail_reporter.git
cd testrail_reporter
git checkout stable
python setup.py install

. "$TESTRAIL_FILE"

# if we need to change SUITE
if [ -n "$SUITE" ];
then
TESTRAIL_SUITE="$SUITE"
export TESTRAIL_SUITE="$SUITE"
fi

# if we need to change MILESTONE
if [ -n "$MILESTONE" ];
then
TESTRAIL_MILESTONE="$MILESTONE"
export TESTRAIL_MILESTONE="$MILESTONE"
fi

if [[ "$TESTRAIL_TEMPLATE_ALTER" == 'TRUE' ]] ;
then
report -v --iso-id "$ISO_ID" --env-description "$TEST_GROUP" --testrail-url  "$TESTRAIL_URL" --testrail-user  "$TESTRAIL_USER" --testrail-password "$TESTRAIL_PASSWORD" --testrail-project "$TESTRAIL_PROJECT" --testrail-milestone "$TESTRAIL_MILESTONE" --testrail-suite "$TESTRAIL_SUITE" --test-results-link "$BUILD" "$REPORT_FILE" --testrail-name-template 'custom_test_group.title' --xunit-name-template 'classname.methodname'
else
report -v --iso-id "$ISO_ID" --env-description "$TEST_GROUP" --testrail-url  "$TESTRAIL_URL" --testrail-user  "$TESTRAIL_USER" --testrail-password "$TESTRAIL_PASSWORD" --testrail-project "$TESTRAIL_PROJECT" --testrail-milestone "$TESTRAIL_MILESTONE" --testrail-suite "$TESTRAIL_SUITE" --test-results-link "$BUILD" "$REPORT_FILE"
fi

sudo mkdir -p "$REPORT_PREFIX"/"$ENV_NAME"_"$SNAPSHOT_NAME" && sudo cp "$REPORT_FILE" "$REPORT_PREFIX"/"$ENV_NAME"_"$SNAPSHOT_NAME" && sudo cp test.log sudo cp "$REPORT_FILE" "$REPORT_PREFIX"/"$ENV_NAME"_"$SNAPSHOT_NAME" || true


deactivate
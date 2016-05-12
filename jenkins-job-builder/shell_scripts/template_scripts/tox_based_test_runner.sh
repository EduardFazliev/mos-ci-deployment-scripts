set +e

if [[ {name} == 'Ironic' ]]; then
wget https://raw.githubusercontent.com/EduardFazliev/mos-ci-deployment-scripts/feature/jjb/jenkins-job-builder/python_scripts/ironic/proxy.py
nohup python proxy.py  &>proxy.log </dev/null &
PID=`echo $!`
echo "PROXY_PID=$PID" >> "$ENV_INJECT_PATH"
fi

rm -rf mos-integration-tests
git clone https://github.com/Mirantis/mos-integration-tests.git
cd mos-integration-tests

virtualenv venv
. venv/bin/activate
pip install -U pip
pip install tox

printenv || true

tox -e {tox_test_name} -- -v -E "$ENV_NAME" -S "$SNAPSHOT_NAME"
deactivate

cp "$REPORT_FILE" ../
cp *.log ../

sudo mkdir -p "$REPORT_PREFIX"/"$ENV_NAME"_"$SNAPSHOT_NAME" && \
sudo cp "$REPORT_FILE" "$REPORT_PREFIX"/"$ENV_NAME"_"$SNAPSHOT_NAME" && \
sudo cp *.log "$REPORT_PREFIX"/"$ENV_NAME"_"$SNAPSHOT_NAME" \
|| true
deactivate

sudo dos.py destroy "$ENV_NAME"

if [[ {name} == 'Ironic' ]]; then
sudo kill -9 "$PROXY_PID" || true
fi

exit 0
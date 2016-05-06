#!/usr/bin/env bash -e

rm -rf mos-integration-tests
git clone https://github.com/Mirantis/mos-integration-tests.git
cd mos-integration-tests

virtualenv tests
. tests/bin/activate

pip install -U pip
pip install -r requirements.txt
py.test {test_path} -E "$ENV_NAME" -S "$SNAPSHOT_NAME" -v

deactivate
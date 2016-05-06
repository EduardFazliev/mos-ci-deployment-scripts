#!/usr/bin/env bash +e

virtualenv venv
. venv/bin/activate
pip install -U pip
pip install tox
tox -e {tox_test_name} -- -v -E "$ENV_NAME" -S "$SNAPSHOT_NAME"
deactivate
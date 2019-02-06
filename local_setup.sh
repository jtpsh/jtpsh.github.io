#!/bin/bash

python3 -m venv jtp-env
test -e && source jtp-env/bin/activate
pip install wheel
pip install -r requirements.txt


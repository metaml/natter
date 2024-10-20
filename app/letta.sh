#!/usr/bin/env sh
set -e

cd /ami

nix develop

make db-creds-rds
make openai-api-key

export LANG=en_US.UTF-8
export PIP_PREFIX=$(pwd)/venv/pypi
export PATH=$(pwd)/bin:$PIP_PREFIX/bin:$PATH
unset SOURCE_DATE_EPOCH

[ ! -f .creds ]          || source .creds
[ ! -f .creds-rds ]      || source .creds-rds
[ ! -f .openai-api-key ] || source .openai-api-key

python -m venv ./venv
. ./venv/bin/activate
pip install --requirement=requirements.txt
letta start

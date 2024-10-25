#!/usr/bin/env bash
set -e

export LANG=en_US.UTF-8
export VENV_PREFIX=$(pwd)/venv
export PATH=$(pwd)/bin:$VENV_PREFIX/bin:$PATH
unset SOURCE_DATE_EPOCH

[ ! -f .creds-rds ]      || source .creds-rds
[ ! -f .openai-api-key ] || source .openai-api-key

letta server

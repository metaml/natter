#!/usr/bin/env python

import os
for p in os.getenv('PYTHONPATH').split(':'):
  print(p)
print('len(PYTHONPATH)=', len(os.getenv('PYTHONPATH')))

from pathlib import Path
import boto3
import shlex
import subprocess as subproc
import sys

# @todo: remove code dupe without being dependent on model.__init__.py
def openai_api_key() -> str:
  c = boto3.client('secretsmanager')
  s = c.get_secret_value(SecretId='openai-api-key')['SecretString']
  c.close()
  return s

if __name__ == '__main__':
  try:
    os.environ['OPENAI_API_KEY'] = openai_api_key()
    args = shlex.split('letta server')
    res = subproc.run(args, text=True)
  except Exception as e:
    print("exception: ", e, file=sys.stderr)
    sys.exit(0)

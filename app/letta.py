#!/usr/bin/env python

import os
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
  path = os.getenv('PYTHONPATH')
  paths = path.split(':')
  for p in paths:
    print(p)
  print('PYTHONPATH lines:', len(paths))
  print('PYTHONPATH characters:', len(path))
  print('env $ROOT_DIR=', os.getenv('ROOT_DIR'))

  root_dir = os.getenv('ROOT_DIR')
  if root_dir:
    os.chdir(root_dir)
  else:
    os.chdir('/static')
  print("ROOT_DIR=", os.getcwd())

  os.environ['AWS_DEFAULT_REGION'] = 'us-east-2'
  os.environ['OPENAI_API_KEY'] = openai_api_key()

  print("OAK =", os.getenv('OPENAI_API_KEY'))

  try:
    args = shlex.split('letta server --host 0.0.0.0')
    res = subproc.run(args, text=True)
  except Exception as e:
    print("exception: ", e, file=sys.stderr)
    sys.exit(0)

#!/usr/bin/env python

from pathlib import Path
import model.aws as aws
import os
import shlex
import subprocess as subproc
import sys

if __name__ == '__main__':
  try:
    os.environ['OPENAI_API_KEY'] = aws.openai_api_key()
    letta = "letta server"
    arg = shlex.split(letta)
    res = subproc.run(arg, text=True)
  except Exception as e:
    print("exception: ", e, file=sys.stderr)
    sys.exit(0)

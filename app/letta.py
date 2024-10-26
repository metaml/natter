#!/usr/bin/env python

from pathlib import Path
import os
import shlex
import subprocess as subproc
import sys

if __name__ == '__main__':
  try:
    letta = "letta server"
    arg = shlex.split(letta)
    res = subproc.run(arg, text=True)
  except Exception as e:
    print("exception: ", e, file=sys.stderr)
    sys.exit(0)

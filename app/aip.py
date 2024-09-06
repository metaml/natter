#!/usr/bin/env python

import shlex
import subprocess as subproc
import sys

if __name__ == '__main__':
  try:
    arg = shlex.split("uvicorn aip:aip --host 0.0.0.0 --port 443")
    res = subproc.run(arg, text=True)
  except Excepton as e:
    print("exception: ", e, file=sys.stderr)
    sys.exit(0)

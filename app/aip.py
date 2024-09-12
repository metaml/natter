#!/usr/bin/env python

import os
import shlex
import subprocess as subproc
import sys

if __name__ == '__main__':
  dev = os.getenv('AIP_DEVELOPMENT')
  port, log = None, None
  if dev:
    port, log = 8000, "debug"
  else:
    port, log = 80, "info"

  try:
    arg = shlex.split(f"uvicorn aip:aip --host 0.0.0.0 --port {port} --log-level {log}")
    res = subproc.run(arg, text=True)
  except Excepton as e:
    print("exception: ", e, file=sys.stderr)
    sys.exit(0)

#!/usr/bin/env python

from pathlib import Path
import os
import shlex
import subprocess as subproc
import sys

if __name__ == '__main__':
  ami_root = Path(os.path.abspath(__file__)).parents[1].absolute()
  os.environ['PYTHONPATH'] = f"{ami_root}/lib:{os.getenv('PYTHONPATH')}"
  os.environ['AWS_DEFAULT_REGION'] = 'us-east-2'

  port, log = 8000, "info"
  try:
    arg = shlex.split(f"uvicorn aip:aip --workers 8 --host 0.0.0.0 --port {port} --log-level {log}")
    res = subproc.run(arg, text=True)
  except Excepton as e:
    print("exception: ", e, file=sys.stderr)
    sys.exit(0)

#!/usr/bin/env python

from pathlib import Path
import os
import shlex
import subprocess as subproc
import sys

if __name__ == '__main__':
  os.environ['AWS_DEFAULT_REGION'] = 'us-east-2'
  ip, port, key, cert = "0.0.0.0", 8000, "etc/key.pem", "etc/cert.pem"
  try:
   uvicorn = None
   if not os.getenv("MODE"): # prod
     key = f"/{key}"
     cert = f"/{cert}"
     uvicorn = f"uvicorn aip:aip --workers 8 --host {ip} --port {port} --ssl-keyfile {key} --ssl-certfile {cert}"
   else: # dev
     uvicorn = f"uvicorn aip:aip --reload --host {ip} --port {port}  --ssl-keyfile {key} --ssl-certfile {cert}"

   arg = shlex.split(uvicorn)
   res = subproc.run(arg, text=True)
  except Exception as e:
    print("exception: ", e, file=sys.stderr)
    sys.exit(0)

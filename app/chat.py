#!/usr/bin/env python3.12

from model.chat import ChatRequest, Message
from termcolor import colored
import json
import requests as req
import sys

#url = 'http://alb-1952262379.us-east-2.elb.amazonaws.com/talk'
url = 'http://localhost:8000/talk'

while True:
  msgin = input(colored("member> ", "green"))
  if msgin.lower() == "quit":
    break
  chat_req = ChatRequest(messages = [Message(content=msgin, role="Mike"), ], stream = False)
  res = req.post(url, data=chat_req.model_dump_json()).json()
  msg = res['messages'][0]['content']
  print(colored("friend>", "cyan"), msg)

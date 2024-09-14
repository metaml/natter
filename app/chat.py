#!/usr/bin/env python3.12

from model.chat import ChatRequest, Message
from termcolor import colored
import json
import requests as req
import sys

url = 'http://alb-1952262379.us-east-2.elb.amazonaws.com/talk'
#url = 'http://localhost:8000/talk'

while True:
  mem_msg = input(colored("member> ", "green"))
  if mem_msg.lower() == "quit":
    break
  #print("# mem_msg=", mem_msg)
  chat_req = ChatRequest(messages = [Message(content=mem_msg)], stream = False)
  res = req.post(url, data=chat_req.model_dump_json()).json()
  #print("# res=", res)
  msg = res['messages'][0]['content']
  print(colored("friend>", "cyan"), msg)

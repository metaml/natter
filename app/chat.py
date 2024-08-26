#!/usr/bin/env python3.12

from model.chat import ChatRequest, Message
from termcolor import colored
import json 
import requests as req
import sys

url = 'http://localhost:8000/chat/'

while True:
  mem_msg = input(colored("member> ", "green"))
  if mem_msg.lower() == "quit":
    break
  chat_req = ChatRequest(messages = [Message(content=mem_msg)], stream = False)
  res = req.post(url, data=chat_req.model_dump_json()).json()
  idx = res['id']
  msg = res['choices'][0]['message']['content']
  print(colored("friend>", "cyan"), msg, "[", idx, "]")

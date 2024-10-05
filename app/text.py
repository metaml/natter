#!/usr/bin/env python3.12

from model.globals import clients
from termcolor import colored
import asyncio as aio
import argparse
import json
import model.__init__
import model.aws as aws
import model.text as text
import openai
import requests as req
import sys

def parser_args():
  parser = argparse.ArgumentParser(description='text analysis ops')
  subparsers = parser.add_subparsers(dest='op', help='ops')

  sum_parser = subparsers.add_parser('summary', help='summary')
  sum_parser.add_argument('summary', nargs='+', type=str, help='text summary')

  sent_parser = subparsers.add_parser('sentiment', help='sentiment')
  sent_parser.add_argument('sentiment', nargs='+', type=str, help='text sentiment')

  det_parser = subparsers.add_parser('details', help='details')
  det_parser.add_argument('details', nargs='+', type=str, help='text details')

  thm_parser = subparsers.add_parser('themes', help='themes')
  thm_parser.add_argument('themes', nargs='+', type=str, help='text themes')

  ent_parser = subparsers.add_parser('entities', help='entities')
  ent_parser.add_argument('entities', nargs='+', type=str, help='text entities')

  ana_parser = subparsers.add_parser('analysis', help='analysis')
  ana_parser.add_argument('analysis', nargs='+', type=str, help='text analysis')

  evt_parser = subparsers.add_parser('events', help='events')
  evt_parser.add_argument('events', nargs='+', type=str, help='text events')

  que_parser = subparsers.add_parser('question', help='question')
  que_parser.add_argument('question', nargs='+', type=str, help='text question')

  return parser

def init_clients():
  client_args = {}
  client_args["api_key"] = aws.openai_api_key()
  clients["openai"] = openai.AsyncOpenAI(**client_args)
  return clients

if __name__ == '__main__':
  clients = init_clients()

  res = None
  parser = parser_args()
  args = parser.parse_args()
  match args.op:
    case 'summary':
      txt = args.summary[0]
      res = aio.run(text.summary(txt))
    case 'sentiment':
      txt = args.sentiment[0]
      res = aio.run(text.sentiment(txt))
    case 'details':
      txt = args.details[0]
      res = aio.run(text.details(txt))
    case 'themes':
      txt = args.themes[0]
      res = aio.run(text.themes(txt))
    case 'entities':
      txt = args.entities[0]
      res = aio.run(text.entities(txt))
    case 'analysis':
      print(args.analysis)
      txt = args.analysis[0]
      res = aio.run(text.analysis(txt))
    case 'events':
      print(args.events)
      txt = args.events[0]
      res = aio.run(text.events(txt))
    case 'question':
      print(args.question)
      txt = args.question[0]
      res = aio.run(text.question(txt))

  if res != None:
    print(res['choices'][0]['message']['content'])
  else:
    parser.print_help()

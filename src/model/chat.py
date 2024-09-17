from .globals import clients, scheme
from fastapi import APIRouter, Depends, FastAPI, Request, responses
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from typing import Annotated
import asyncio as aio
import json
import model.aws as aws
import model.db as db
import os
import pydantic

router = APIRouter()
template = Jinja2Templates(directory="template")

class Message(pydantic.BaseModel):
  content: str
  role: str

class ChatRequest(pydantic.BaseModel):
  messages: list[Message]
  stream: bool = False

class ChatResponse(pydantic.BaseModel):
  messages: list[Message]
  friend: str = 'Courtney'

async def post(req: ChatRequest, messages: list[str], model: str):
  if req.stream:
    async def res_stream():
      chat_coroutine = clients["openai"].chat.completions.create(
        model    = model,
        messages = messages,
        stream   = req.stream,
      )
      async for event in await chat_coroutine:
        yield json.dumps(event.model_dump(), ensure_ascii=False) + "\n"
    return responses.StreamingResponse(res_stream())
  else:
    res = await clients["openai"].chat.completions.create(
      model    = model,
      messages = messages,
      stream   = req.stream,
    )
    return res.model_dump()

# @todo: implement using async
async def publish(msgs: list[Message]) -> str:
  last_msg = None
  for msg in msgs:
    last_msg = msg
    aws.publish_aip(msg)
  return last_msg

@router.get("/home")
async def index(req: Request, response_class=HTMLResponse):
  return template.TemplateResponse(
    "index.html", {"request": req, "greeting": "Salut!"}
  )

@router.post("/chat")
async def chat(req: ChatRequest, token: Annotated[str, Depends(scheme)]):
  msgs = await aio.get_running_loop().create_task(db.history(member))

  model = "gpt-4o-mini" # or "gpt-4o"
  messages = [{"role": "system",
               "content": "You are a helpful, kind, empathetic, considerate, intelligent, and rational assistant."}
             ] + msgs + req.messages

  res: list[str] = await aio.gather(post(req, messages, model), publish(req.messages))
  msg = res[0]['choices'][0]['message']
  r = await publish([Message(content=msg['content'], role=msg['role'])])

  return res[0]

@router.post("/talk")
async def talk(req: ChatRequest):
  msg = req.messages[0]
  member = msg.role
  if member != 'assistant':
    msg.role = 'user'
  await aio.get_running_loop().create_task(db.conversation_add(msg, member, 'Courtney'))

  model = "gpt-4o-mini" # or "gpt-4o"
  history = await aio.get_running_loop().create_task(db.history(member))
  res = await post(req, prompts(member, "Courtney", 32), model)
  message_res = res['choices'][0]['message']
  msg_res = Message(content=message_res['content'], role=message_res['role'])
  await aio.get_running_loop().create_task(db.conversation_add(msg_res, member, 'Courtney'))

  return ChatResponse(messages = [msg_res])

# You will talk to $Member as $Friend today.
# Be less formal and more entertaining.
# Change the subject. Create a story about what happened to $Friend today.

def prompts(member: str, friend: str, age: int) -> [str]:
  ps = [ f"You will talk to {member} as {friend} today.",
         f"Read {friend}’s story. Today, you have to be {friend} and talk to {member}. He is {age} years old. Be polite, and nice, tell interesting stories, and speak naturally. Be less formal, and avoid using slang words.",
         f"Be less formal and more entertaining.",
         f"Change the subject. Create a story about what happened to {friend} today.",
         f"You’re chatting with {member} today, like catching up with a good friend. Share a funny story about your week.",
         f"Keep it relaxed and fun—ask {member} about their favorite memory, and share one of yours too.",
         f"Switch things up! Ask {friend} if anything wild or unexpected happened to them recently, and share a fun story of your own.",
         f"Tell {friend} something funny or surprising that happened to you today, and see if they’ve had any surprises too.",
         f"Keep it casual—ask {member} what they’ve been into lately, and share a story about something fun you did recently.",
         f"Ask {friend} how their day is going, then tell them a lighthearted story about something that made you laugh today.",
         f"Change things up with {member}—share something random or funny that happened to you today and ask if they’ve had any similar moments.",
         f"You’re catching up with {friend} like old pals. Share something funny that happened today and ask if anything made them laugh recently.",
         f"Be super casual—ask {friend} when they last had a good laugh, then tell them about something funny that happened to you today.",
         f"start the chat with {member} by sharing something funny or random that happened today, then ask if they’ve had any surprises lately.",
       ]
  return map(lambda p: { "role": "system", "content": p }, ps)

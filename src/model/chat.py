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
  prompts = [{ "role": "system",
               "content": "You are a helpful, kind, empathetic, considerate, intelligent, and rational therapist."
             },
             { "role": "system",
              "content": "Summarize content for a 30-year-old."
             },
             { "role": "system",
               "content": "Use pronouns for content."
             }
            ] + history + [msg]

  print("### talk history=", history)
  print("### talk prompts=", prompts)

  res = await post(req, prompts, model)
  message_res = res['choices'][0]['message']
  msg_res = Message(content=message_res['content'], role=message_res['role'])
  await aio.get_running_loop().create_task(db.conversation_add(msg_res, member, 'Courtney'))

  return ChatResponse(messages = [msg_res])

from .globals import clients
import asyncio as aio
import fastapi
import json
import model.aws as aws
import model.db as db
import os
import pydantic

router = fastapi.APIRouter()

class Message(pydantic.BaseModel):
  content: str
  role: str = "user"

class ChatRequest(pydantic.BaseModel):
  messages: list[Message]
  stream: bool = True

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
    return fastapi.responses.StreamingResponse(res_stream())
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

@router.post("/chat")
async def chat_handler(req: ChatRequest):
  msgs = await aio.get_running_loop().create_task(db.history())
  
  model = "gpt-4o"
  messages = [{"role": "system",
               "content": "You are a helpful, kind, empathetic, considerate, intelligent, and rational assistant."}
             ] + msgs + req.messages 

  res: list[str] = await aio.gather(post(req, messages, model), publish(req.messages))
  msg = res[0]['choices'][0]['message']
  r = await publish([Message(content=msg['content'], role=msg['role'])])
                    
  return res[0]


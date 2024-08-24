from .globals import clients
import fastapi
import json
import os
import pydantic

router = fastapi.APIRouter()

class Message(pydantic.BaseModel):
  content: str
  role: str = "user"

class ChatRequest(pydantic.BaseModel):
  messages: list[Message]
  stream: bool = True

@router.post("/chat")
async def chat_handler(req: ChatRequest):
  model = "gpt-4o-mini"
  messages = [{"role": "system",
               "content": "You are a helpful, kind, empathetic, considerate, intelligent, and rational friend."}
             ] + req.messages

  if req.stream:
    async def response_stream():
      chat_coroutine = clients["openai"].chat.completions.create(
        model    = model,
        messages = messages,
        stream   = req.stream,
      )
      async for event in await chat_coroutine:
        yield json.dumps(event.model_dump(), ensure_ascii=False) + "\n"
    return fastapi.responses.StreamingResponse(response_stream())
  else:
    response = await clients["openai"].chat.completions.create(
      model    = model,
      messages = messages,
      stream   = False,
    )
    return response.model_dump()

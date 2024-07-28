import fastapiport json
import os
import pydantic

from .globals import clients

router = fastapi.APIRouter()

class Message(pydantic.BaseModel):
  content: str
  role: str = "user"

class ChatRequest(pydantic.BaseModel):
  messages: list[Message]
  stream: bool = True

@router.post("/chat")
async def chat_handler(chat_request: ChatRequest):
  messages = [{"role": "system",
               "content": "You are a helpful assistant."}
             ] + chat_request.messages
  model = "gpt-4-0125-preview"

  if chat_request.stream:
    async def response_stream():
      chat_coroutine = clients["openai"].chat.completions.create(
        model    = model,
        messages = messages,
        stream   = True,
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

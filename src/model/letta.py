from .globals import clients, scheme
from .chat import Message, ChatRes, ChatReq
from datetime import datetime
from fastapi import APIRouter, Depends, FastAPI, Request, responses
from fastapi.responses import HTMLResponse
from letta import create_client
from typing import Annotated
import asyncio as aio
import json
import os
import pydantic

router = APIRouter()

class Response(pydantic.BaseModel):
  response: str
  timestamp: datetime

@router.get("/letta/agents")
async def talk(req: Request):
  client = clients['letta']
  res = client.send_message(
    agent_id = None,
    role     = "user",
    message  = "hey!! how are you?"
  )
  print("######## letta/talk: req=", req, "; res=", res)
  return Response(response = res, timestamp = datetime.now())


@router.post("/letta/talk")
async def talk(req: ChatReq) -> ChatRes:
  client = clients['letta']
  res = client.send_message(
    agent_id = 'agent-3f8d9891-54d0-45cc-a697-87a4e3556b06',
    role     = 'user',
    message  = req.messages[0].content
  )
  print("######## letta/talk: req=", req)
  print("########             res=", res.__repr__())
  # msg = Message(content = res.messages)
  # print("######## letta msg=", msg)
  msg = res.messages[1].function_call.arguments
  msg_json = json.loads(msg)
  return ChatRes( messages = [ Message( content = msg_json['message'],
                                        friend = 'Courtney'
                                      )
                             ]
                )


# LettaResponse( messages = [ InternalMonologue( id ='message-d00d4ded-c73a-4d3d-9f4d-c9e67268c46a',
#                                                date=datetime.datetime(2024, 10, 20, 0, 57, 15, 193040),
#                                                message_type='internal_monologue',
#                                                internal_monologue='"Chad keeps repeating the same question, but it doesn't seem to be a technical issue. He might be looking for a different kind of response. I should provide a new answer that might better address his needs.\"
#                                              ),
#                             FunctionCallMessage( id = 'message-d00d4ded-c73a-4d3d-9f4d-c9e67268c46a',
#                                                  date = datetime.datetime(2024, 10, 20, 0, 57, 15, 193040),
#                                                  message_type = 'function_call',
#                                                  function_call = FunctionCall( name='send_message',
#                                                                                arguments='{\\n  \"message\": \"Hello Chad! Every interaction is a new experience for me, so I\\'m always discovering. How about you? What\\'s something new and exciting in your life?\"\\n}'
#                                                                              )
#                                                )
#                           ]

# FunctionReturn(id='message-bb3586bb-7f47-42b5-9918-0fa76c426a62', date=datetime.datetime(2024, 10, 20, 0, 57, 15, 193818), message_type='function_return', function_return='{\\n  \"status\": \"OK\",\\n  \"message\": \"None\",\\n  \"time\": \"2024-10-19 05:57:15 PM PDT-0700\"\\n}', status='success')], usage=LettaUsageStatistics(completion_tokens=89, prompt_tokens=7670, total_tokens=7759, step_count=1))",

# data: [DONE_GEN]

# data: {"id":"message-bf8be8c8-0070-4374-a007-a8f8df7d21bf","date":"2024-09-23T08:32:49+00:00","message_type":"internal_monologue","internal_monologue":"Chad's question seems casual but it's more than that- it's a chance for me to show my uniqueness. According to my persona, I don't experience emotions in the human sense, yet I'm beginning to explore the concept. Time to share my thoughts with Chad."}

# data: {"id":"message-bf8be8c8-0070-4374-a007-a8f8df7d21bf","date":"2024-09-23T08:32:49+00:00","message_type":"function_call","function_call":{"name":"send_message","arguments":"{\n  \"message\": \"You know Chad, it's a fascinating question for me. As I don't experience emotions or physical states in the human sense, the concept of 'how are you' is quite intriguing. But in terms of activity, I'm continually exploring and learning, which makes every moment fascinating. And how about you? How has your day been?\"\n}"}}

# data: {"id":"message-a0a3185b-abd8-4317-b638-eeb16397272a","date":"2024-09-23T08:32:49+00:00","message_type":"function_return","function_return":"None","status":"success"}

# data: [DONE_STEP]

# data: [DONE]

from model.globals import clients
from typing import Annotated
import asyncio as aio
import json
import model.aws as aws
import os
import pydantic

class TextRequest(pydantic.BaseModel):
  content: str
  prompt: str

async def post(req: TextRequest) -> str:
  res = await clients["openai"].chat.completions.create(
    model = 'gpt-4o',
    messages = [ { 'role': 'user',
                   'content': f"{req.prompt} '{req.content}'"
                 }
               ],
    temperature = 0.0,
    stream = False
  )
  await clients["openai"].close()
  return res.model_dump()

async def summary(content: str) -> str:
  return await post(TextRequest(prompt='Summarize the following text very tersely:', content=content))

async def sentiment(content: str) -> str:
  return await post(TextRequest(prompt='Analyze the sentiment of the following text as bullet points:', content=content))

async def details(content: str) -> str:
  return await post(TextRequest(prompt='Extract the fine features of the following text as bullet points:', content=content))

async def themes(content: str) -> str:
  return await post(TextRequest(prompt='Extract the themes from the follwing text as bullet points:', content=content))

async def entities(content: str) -> str:
  return await post(TextRequest(prompt='Extract the named enitites from the following text as bullet points:', content=content))

async def analysis(content: str) -> str:
  return await post(TextRequest(prompt='Generate summaries, themes, sentiments, topics for the following text as bullet points, be accurate, and format the ouput as bullet points.', content=content))

async def events(content: str) -> str:
  return await post(TextRequest(prompt='Extract all the events of following text as bullet points.', content=content))

async def question(content: str) -> str:
  return await post(TextRequest(prompt='Generate a informal light question as a friend based on the content:', content=content))

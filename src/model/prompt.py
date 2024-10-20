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

class Prompt(pydantic.BaseModel):
  prompt: str
  member: str
  friend: str
  enabled: bool

class GetPromptsReq(pydantic.BaseModel):
  member: str
  friend: str

class PromptsReq(pydantic.BaseModel):
  prompt: str
  friend_id: str
  member_id: str
  enabled: bool

class PromptRes(pydantic.BaseModel):
  prompts: list[Prompt]

@router.post("/prompts")
async def prompts(req: GetPromptsReq):
  ps = await aio.get_running_loop().create_task(db.prompts('system', 'system'))
  return ps

@router.post("/prompts/system")
async def prompts(req: GetPromptsReq):
  ps = await aio.get_running_loop().create_task(db.prompts_system('system', 'system'))
  return ps

@router.post("/prompts/add")
async def prompts_add(req: PromptsReq):
  print(req)
  b = await db.prompts_add(req.prompt, req.member_id, req.friend_id, req.enabled)
  print(b)
  return b

@router.post("/prompts/update")
async def prompts_update(req: PromptsReq):
  print(req)
  b = await db.prompts_update(req.prompt, req.member_id, req.friend_id, req.enabled)
  print(b)
  return b

async def prompts_system(member, friend):
  ps_db = await aio.get_running_loop().create_task(db.prompts('system', 'system'))
  ps = []
  for i, p in enumerate(ps_db):
    pn = p['prompt'].replace('{member}', member).replace('{friend}', friend)
    ps.append({'content': pn, 'role': 'system'})
  return ps

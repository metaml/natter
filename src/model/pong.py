from .globals import clients, scheme
from fastapi import APIRouter, Depends, FastAPI, Request, responses
from fastapi.responses import HTMLResponse
from typing import Annotated
from datetime import datetime
import asyncio as aio
import json
import os
import pydantic

router = APIRouter()

class Pong(pydantic.BaseModel):
  response: str
  timestamp: datetime

@router.get("/ping")
async def ping(req: Request):
  ts = datetime.now()
  return Pong(response = "pong", timestamp = ts)

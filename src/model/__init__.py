from .aws import openai_api_key
from .globals import clients
from environs import Env
from fastapi.middleware.cors import CORSMiddleware
import contextlib
import fastapi
import logging
import openai
import os

@contextlib.asynccontextmanager
async def lifespan(app: fastapi.FastAPI):
  key = os.getenv("OPENAI_API_KEY")
  if key == None:
    key = openai_api_key()
  client_args = {}
  client_args["api_key"] = key
  clients["openai"] = openai.AsyncOpenAI(**client_args,)
  yield
  await clients["openai"].close()

def create_app():
  if not os.getenv("AIP_DEVELOPMENT"):
    logging.basicConfig(level=logging.DEBUG)
  else:
    logging.basicConfig(level=logging.INFO)

  origins = Env().list("ALLOWED_ORIGINS", ["http://localhost", "http://localhost:8080"])

  app = fastapi.FastAPI(docs_url="/", lifespan=lifespan)
  app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
  )

  from . import chat  # noqa
  app.include_router(chat.router)
  
  return app

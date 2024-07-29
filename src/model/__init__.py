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
  client_args = {}
  client_args["api_key"] = os.getenv("OPENAI_API_KEY")
  clients["openai"] = openai.AsyncOpenAI(**client_args,)
  yield
  await clients["openai"].close()

def create_app():
  env = Env()
  if not os.getenv("RUNNING_IN_PRODUCTION"):
    env.read_env(".env")
    logging.basicConfig(level=logging.DEBUG)

  app = fastapi.FastAPI(docs_url="/", lifespan=lifespan)
  origins = env.list("ALLOWED_ORIGINS", ["http://localhost", "http://localhost:8080"])

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

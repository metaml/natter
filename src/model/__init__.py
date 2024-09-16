from .aws import openai_api_key
from .globals import clients
from environs import Env
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from fastapi.staticfiles import StaticFiles
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
  clients["openai"] = openai.AsyncOpenAI(**client_args)

  yield
  await clients["openai"].close()

def app():
  if not os.getenv("DEV_AMI"):
    logging.basicConfig(level=logging.DEBUG)
  else:
    logging.basicConfig(level=logging.INFO)

  origins = Env().list("ALLOWED_ORIGINS", ["http://localhost",
                                           "https://localhost",
                                           "http://localhost:8000",
                                           "http://127.0.0.1:8000",
                                           "https://localhost:8000",
                                           "http://localhost:8080",
                                           "https://localhost:8000",
                                          ]
                      )
  app = fastapi.FastAPI(docs_url="/", lifespan=lifespan)

  # fastapi only references relative directory paths
  app.mount("/static", StaticFiles(directory="static"), name="static")
  app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
  )

  from . import chat, user, pong
  app.include_router(chat.router)
  app.include_router(user.router)
  app.include_router(pong.router)

  return app

from .aws import openai_api_key, credentials
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

# only when MODE == 'DEV' is for development otherwise it's production
# all MODE = 'DEV" parameters are set here

@contextlib.asynccontextmanager
async def lifespan(app: fastapi.FastAPI):
  key = os.getenv("OPENAI_API_KEY")
  if key == None:
    key = openai_api_key()

  u, p, h = credentials()
  clients['password-db'] = p
  if os.getenv('MODE') == 'DEV':
    clients['user-db'] = 'aip-dev'
    clients['password-db'] = p
    clients['host-db'] = 'localhost'
    clients['db'] = 'aip-dev'
  else:
    clients['user-db'] = u
    clients['password-db'] = p
    clients['host-db'] = h
    clients['db'] = 'aip'

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

  origins = Env().list("ALLOWED_ORIGINS", [ "http://alb-1952262379.us-east-2.elb.amazonaws.com",
                                            "http://alb-1952262379.us-east-2.elb.amazonaws.com:8000",
                                            "http://localhost",
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

  from . import chat, prompt, pong, user
  app.include_router(chat.router)
  app.include_router(pong.router)
  app.include_router(prompt.router)
  app.include_router(user.router)

  return app

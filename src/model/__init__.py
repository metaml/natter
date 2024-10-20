from .aws import openai_api_key, credentials
from .globals import clients
from environs import Env
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from fastapi.staticfiles import StaticFiles
from letta import create_client
import contextlib
import fastapi
import logging
import openai
import os
import ssl

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
  client_args['api_key'] = key
  clients['openai'] = openai.AsyncOpenAI(**client_args)

  clients['letta'] = create_client(base_url="http://localhost:8283")

  # @todo: run uvicore all within a pthyon app
  # ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
  # ssl_context.load_cert_chain('etc/cert.pem', keyfile='etc/key.pem')
  # clients['ssl_context'] = ssl_context

  yield
  await clients["openai"].close()

def app():
  if not os.getenv("MODE"): # prod
    logging.basicConfig(level=logging.INFO)
  else:
    logging.basicConfig(level=logging.DEBUG)

  origins = Env().list("ALLOWED_ORIGINS", [ "https://alb-64c71258f6c9e59f.elb.us-east-2.amazonaws.com",
                                            "https://alb-64c71258f6c9e59f.elb.us-east-2.amazonaws.com:8000",
                                            "https://localhost:8000"
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

  from . import chat, letta, pong, prompt, user
  app.include_router(chat.router)
  app.include_router(letta.router)
  app.include_router(pong.router)
  app.include_router(prompt.router)
  app.include_router(user.router)

  return app

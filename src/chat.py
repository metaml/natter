from . import app
from .chat import chat
from .user import token

aip = app()

@app.get("/")
async def root():
  return {"message": "Hello, World!"}

import os
from dotenv import load_dotenv

load_dotenv()

def openai() -> str:
  return os.getenv('OPENAI_API_KEY')


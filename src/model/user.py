from .globals import scheme
from datetime import datetime, timedelta, timezone
from fastapi import Depends, FastAPI, HTTPException, APIRouter, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from passlib.context import CryptContext
from pydantic import BaseModel, Field
from typing import Annotated
import asyncio as aio
import jwt
import model.db as db

SECRET_KEY = "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7"
ALGORITHM = "HS256"
EXPIRATION = 30 # min.

router = APIRouter()

class Message(BaseModel):
  content: str
  role: str;

class Member(BaseModel):
  email: str
  first_name: str
  last_name: str
  password: str # hash of password_plain
  disabled: bool = Field(default = True)
  def full_name(self):
    return self.first_name + " " + self.last_name

class Friend(BaseModel):
  first_name: str
  last_name: str
  def full_name(self):
    return self.first_name + " " + self.last_name

class Token(BaseModel):
  token: str
  token_type: str

class TokenData(BaseModel):
  email: str | None = None

context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password_plain(password_plain, password) -> bool:
  return context.verify(password_plain, password)

# hash of password_plain
async def hash(password_plain) -> str:
  return context.hash(password_plain)

def member_db(email: str) -> Member:
  return db.member(email)

async def authenticate(email: str, password_plain: str) -> Member:
  memdb = await aio.get_running_loop().create_task(member_db(email))
  print("######## member_db=", memdb)
  if not memdb:
    return None
  if not verify_password_plain(password_plain, m.password):
    return None
  return membdb

def token_jwt(data: dict, expiration: timedelta):
  encode = data.copy()
  expire = datetime.now(timezone.utc) + expiration
  encode.update({"exp": expire})
  return jwt.encode(encode, SECRET_KEY, algorithm=ALGORITHM)

async def current_member(token: Annotated[str, Depends(scheme)]):
  credentials_exception = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="wrong credentials",
    headers={"WWW-Authenticate": "Bearer"},
  )

  try:
    payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    email: str = payload.get("sub")
    if email is None:
      raise credentials_exception
    token_data = TokenData(email=email)
  except InvalidTokenError:
    raise credentials_exception

  member = member_db(email=token_data.email)
  if member is None:
    raise credentials_exception
  return member

@router.get("/member", response_model=Member)
async def member(member: Annotated[Member, Depends(current_member)],
                 token: Annotated[str, Depends(scheme)]
                ):
  if member.disabled:
    raise HTTPException(status_code=400, detail="member not enabled")
  return member

@router.post("/member/add", response_model=Member)
async def member_add(member: Member) -> bool:
  if member.disabled:
    raise HTTPException(status_code=400, detail="member not enabled")
  member.password = await hash(member.password)
  if await db.member_add(member) == None: # mutates member.password
    raise HTTPException(status_code=503, detail="member add failed")
  return member

@router.post("/token")
async def token(form: Annotated[OAuth2PasswordRequestForm, Depends()]) -> Token:
  member = await authenticate(form.username, form.password)
  if not member:
    raise HTTPException(
      status_code=status.HTTP_401_UNAUTHORIZED,
      detail="incorrect email or password",
      headers={"WWW-Authenticate": "Bearer"},
    )
  delta = timedelta(minutes=EXPIRATION)
  token = token_jwt(data={"sub": member.email}, expiration=delta)
  return Token(token=token, token_type="bearer")

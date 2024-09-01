from .globals import scheme
from datetime import datetime, timedelta, timezone
from fastapi import Depends, FastAPI, HTTPException, APIRouter, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from passlib.context import CryptContext
from pydantic import BaseModel, Field
from typing import Annotated
import jwt

SECRET_KEY = "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

router = APIRouter()

class Message(BaseModel):
  content: str
  role: str = "user"
  
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
def password(password_plain) -> str:
  return context.hash(password_plain)

def member(email: str) -> Member:
  return Member(email = email,
                first_name = 'Foo',
                last_name = 'Bar',
                password = password("foo"))

def authenticate(email: str, password_plain: str) -> Member:
  m = member(email)
  if not m:
    return None
  if not verify_password_plain(password_plain, m.password):
    return None
  return m

def token_jwt(data: dict, expiration: timedelta):
  encode = data.copy()
  expire = datetime.now(timezone.utc) + expiration
  encode.update({"exp": expire})
  encode_jwt = jwt.encode(encode, SECRET_KEY, algorithm=ALGORITHM)
  return encode_jwt
  
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
    token_data = TokenData(membmer=member)
  except InvalidTokenError:
    raise credentials_exception

  member = member(email=token_data.email)

  if member is None:
    raise credentials_exception

  return member

async def current_member(current_member: Annotated[member, Depends(current_member)]):
  if current_member.disabled:
    raise HTTPException(status_code=400, detail="member not enabled")
  return current_user

@router.post("/token")
async def token(form: Annotated[OAuth2PasswordRequestForm, Depends()]) -> Token:
  member = authenticate(form.username, form.password)
  if not member:
    raise HTTPException(
      status_code=status.HTTP_401_UNAUTHORIZED,
      detail="incorrect email or password",
      headers={"WWW-Authenticate": "Bearer"},
    )
  delta = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
  token = token_jwt(data={"sub": member.email}, expiration=delta)
  return Token(token=token, token_type="bearer")

# @app.get("/users/me/", response_model=User)
# async def read_users_me(
#     current_user: Annotated[User, Depends(get_current_active_user)],
# ):
#     return current_user


# @app.get("/users/me/items/")
# async def read_own_items(
#     current_user: Annotated[User, Depends(get_current_active_user)],
# ):
#     return [{"item_id": "Foo", "owner": current_user.username}]

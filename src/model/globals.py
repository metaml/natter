from fastapi.security import OAuth2PasswordBearer

clients = {}

scheme = OAuth2PasswordBearer(tokenUrl="token")



from .globals import clients
from model.user import Member
import asyncio
import asyncpg
import datetime as date
import json
import model.aws as aws
import pydantic
import traceback

# @todo: refactor to call credentials outside of history
async def history(member: str):
  u, p, h = aws.credentials()
  recs = []
  try:
    c = await asyncpg.connect(user=u, password=p, database='aip', host=h)
    recs = await c.fetch("select message from conversation where member_id='" + member + "' order by created_at")
    await c.close()
  except Exception as e:
    print("exception:", e)
  return [json.loads(r[0]) for r in recs]

async def conversation_add(msg, member, friend):
  u, p, h = aws.credentials()
  if msg.role == 'assistant':
    stype = 'friend'
  else:
    stype = 'member'
  print("### conversation_add: msg=", msg)
  try:
    c = await asyncpg.connect(user=u, password=p, database='aip', host=h)
    await c.execute('insert into conversation (member_id, friend_id, friend_type, speaker_type, line, message) values ($1, $2, $3, $4, $5, $6)',
                    member,
                    friend,
                    'human',
                    stype,
                    msg.content,
                    json.dumps(msg.__dict__)
                   )
    await c.close()
  except Exception as e:
    print("exception:", e)

async def member(email: str) -> Member:
  u, p, h = aws.credentials()
  recs = []
  try:
    c = await asyncpg.connect(user=u, password=p, database='aip', host=h)
    recs = await c.fetchrow('select * from member where email=$1', email)
    await c.close()
  except Exception as e:
    print("exception:", e)

  if recs == None:
    return None
  else:
    return [json.loads(r[0]) for r in recs]

async def member_add(member: Member) -> bool:
  u, p, h = aws.credentials()
  try:
    c = await asyncpg.connect(user=u, password=p, database='aip', host=h)
    await c.execute('''insert into member (email, password, first_name, last_name, disabled)
                                   values ($1, $2, $3, $4, $5)''',
                    member.email, member.password, member.first_name, member.last_name, True
                   )
    await c.close()
  except Exception:
    print(traceback.format_exc())
    return False
  return True

async def prompts(member: str, friend: str = 'system'):
  try:
    c = await asyncpg.connect(user=clients['user-db'],
                              password=clients['password-db'],
                              database='aip',
                              host=clients['host-db'],
                             )
    recs = await c.fetch('select prompt, member_id, friend_id from prompt where member_id=$1 and friend_id=$2', member, friend)
    rows = [dict(rec) for rec in recs]
    await c.close()
    return rows
  except Exception as e:
    print("exception:", e)

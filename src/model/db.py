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
  u, p, h, db = clients['user-db'], clients['password-db'], clients['host-db'], clients['db']
  recs = []
  try:
    c = await asyncpg.connect(user=u, password=p, database=db, host=h)
    recs = await c.fetch("select message from conversation where member_id='" + member + "' order by created_at")
    await c.close()
  except Exception as e:
    print("exception:", e)
  return [json.loads(r[0]) for r in recs]

async def conversation_add(msg, member, friend):
  u, p, h, db = clients['user-db'], clients['password-db'], clients['host-db'], clients['db']
  if msg.role == 'assistant':
    stype = 'friend'
  else:
    stype = 'member'
  print("- conversation_add: msg=", msg)
  try:
    c = await asyncpg.connect(user=u, password=p, database=db, host=h)
    await c.execute('''insert into conversation (member_id, friend_id, friend_type, speaker_type, line, message)
                                   values ($1, $2, $3, $4, $5, $6)
                       on conflict do nothing''',
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
  u, p, h, db = clients['user-db'], clients['password-db'], clients['host-db'], clients['db']
  recs = []
  try:
    c = await asyncpg.connect(user=u, password=p, database=db, host=h)
    recs = await c.fetchrow('select * from member where email=$1', email)
    await c.close()
  except Exception as e:
    print("exception:", e)

  if recs == None:
    return None
  else:
    return [json.loads(r[0]) for r in recs]

async def member_add(member: Member) -> bool:
  u, p, h, db = clients['user-db'], clients['password-db'], clients['host-db'], clients['db']
  try:
    c = await asyncpg.connect(user=u, password=p, database=db, host=h)
    await c.execute('''insert into member (email, password, first_name, last_name, disabled)
                                   values ($1, $2, $3, $4, $5)''',
                    member.email, member.password, member.first_name, member.last_name, True
                   )
    await c.close()
  except Exception:
    print(traceback.format_exc())
    return False
  return True

async def prompts(member_id: str, friend_id: str = 'system'):
  u, p, h, db = clients['user-db'], clients['password-db'], clients['host-db'], clients['db']
  recs = None
  try:
    c = await asyncpg.connect(user=u, password=p, database=db, host=h)
    recs = await c.fetch('select prompt, member_id, friend_id, enabled from prompt where member_id=$1 and friend_id=$2', member_id, friend_id)
    rows = [dict(rec) for rec in recs]
    await c.close()
    return rows
  except Exception as e:
    print("exception:", e)

async def prompts_add(prompt, member_id, friend_id, enabled) -> bool:
  u, p, h, db = clients['user-db'], clients['password-db'], clients['host-db'], clients['db']
  try:
    c = await asyncpg.connect(user=u, password=p, database=db, host=h)
    await c.execute('''insert into prompt (prompt, member_id, friend_id, enabled)
                                   values ($1, $2, $3, $4)
                       on conflict do nothing''',
                    prompt, member_id, friend_id, enabled
                   )
    await c.close()
  except Exception:
    print(traceback.format_exc())
    return False
  return True

async def prompts_update(prompt, member_id, friend_id, enabled) -> bool:
  u, p, h, db = clients['user-db'], clients['password-db'], clients['host-db'], clients['db']
  try:
    c = await asyncpg.connect(user=u, password=p, database=db, host=h)
    await c.execute('''update prompt set enabled=$1 where prompt=$2 and member_id=$3 and friend_id=$4''',
                    enabled, prompt, member_id, friend_id
                   )
    await c.close()
  except Exception:
    print(traceback.format_exc())
    return False
  return True

async def prompts_system():
  u, p, h, db = clients['user-db'], clients['password-db'], clients['host-db'], clients['db']
  recs = None
  try:
    c = await asyncpg.connect(user=u, password=p, database=db, host=h)
    recs = await c.fetch('select prompt, member_id, friend_id, enabled from prompt where member_id=$1 and friend_id=$2 and enabled is true', 'system', 'system')
    await c.close()
    if recs == None:
      print('- recs=', recs)
      return []
    else:
      print('- recs=', recs)
      rows = [dict(rec) for rec in recs]
      return rows
  except Exception as e:
    print("exception:", e)

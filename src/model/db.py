import asyncio
import asyncpg
import json
import model.aws as aws

# @todo: refactor to call credentials outside of history
async def history():
  u, p, h = aws.credentials()
  recs = []
  try:
    c = await asyncpg.connect(user=u, password=p, database='aip', host=h)
    recs = await c.fetch('select message from conversation order by created_at')
    await c.close()
  except Exception as e:
    print("exception:", e)
  return [json.loads(r[0]) for r in recs]

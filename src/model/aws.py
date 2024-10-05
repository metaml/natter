import boto3
import json
import model.aws as aws
import model.chat as chat

def openai_api_key() -> str:
  c = boto3.client('secretsmanager')
  return c.get_secret_value(SecretId='openai-api-key')['SecretString']

def publish_aip(msg: chat.Message) -> str:
  aip_arn = "arn:aws:sns:us-east-2:975050288432:aip"
  return publish(msg, aip_arn)

def publish(msg: chat.Message, arn: str, msg_struct: str='json') -> str:
  # my goodness! what a stupid API!
  msg_json = {'default': msg.json()}
  c = boto3.client("sns")
  print('######## publish: msg_json=', msg_json)
  return c.publish(Message=json.dumps(msg_json),
                   MessageStructure=msg_struct,
                   TopicArn=arn,
                   Subject='ITM'
                  )['MessageId']

def credentials():
  sec = boto3.client(service_name='secretsmanager', region_name='us-east-2')
  u = user(sec)
  p = passwd(sec)
  return u['SecretString'], p['SecretString'], "aip.c7eaoykysgcc.us-east-2.rds.amazonaws.com"

def user(sec):
  return sec.get_secret_value(SecretId='db-user')

def passwd(sec):
  return sec.get_secret_value(SecretId='db-password')

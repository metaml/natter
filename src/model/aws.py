from model.chat import Message
import boto3
import json
import model.aws as aws
import pydantic

def openai_api_key() -> str:
  c = boto3.client('secretsmanager')
  s = c.get_secret_value(SecretId='openai-api-key')['SecretString']
  c.close()
  return s

def publish_aip(msg: Message) -> str:
  return publish(msg, "arn:aws:sns:us-east-2:975050288432:aip")

def publish(msg: Message, arn: str) -> str:
  default = json.dumps({ "default": msg.json() })
  #default_json = json.dumps(default)
  c = boto3.client("sns")
  r = c.publish(Message=default,
                MessageStructure='json',
                TopicArn='arn:aws:sns:us-east-2:975050288432:aip',
                Subject='itm'
               )['MessageId']
  c.close()
  return r

def publish_sns(msg_json) -> str:
  c = boto3.client("sns")
  r = c.publish(Message=msg_json,
                MessageStructure='json',
                TopicArn='arn:aws:sns:us-east-2:975050288432:aip',
                Subject='itm'
                )['MessageId']
  c.close()
  return r

def credentials():
  sec = boto3.client(service_name='secretsmanager', region_name='us-east-2')
  u = user(sec)
  p = passwd(sec)
  c = u['SecretString'], p['SecretString'], "aip.c7eaoykysgcc.us-east-2.rds.amazonaws.com"
  sec.close()
  return c

def user(sec):
  return sec.get_secret_value(SecretId='db-user')

def passwd(sec):
  return sec.get_secret_value(SecretId='db-password')

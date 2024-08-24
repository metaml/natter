import boto3
import json

def openai_api_key() -> str:
  c = boto3.client('secretsmanager')
  return c.get_secret_value(SecretId='openai-api-key')['SecretString']

def publish_aip(msg: str) -> str:
  aip = "arn:aws:sns:us-east-2:975050288432:aip"
  return(aip, msg)

def publish(msg: str, arn: str, msg_struct: str='json') -> str:
  c = boto3.client("sns")
  return c.publish(Message=json.dumps({'default': json.dumps(msg)}),
                   TopicArn=arn,
                   MessageStructure=msg_struct
                  )

                               

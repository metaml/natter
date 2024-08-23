import boto3

def open_api_key() -> str:
  c = boto3.client('secretsmanager')
  return c.get_secret_value(SecretId='openai-api-key')



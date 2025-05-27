import json
import os
import logging
import uuid
from datetime import datetime, timezone
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

session = boto3.session.Session()
region = session.region_name

dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')
# ses = boto3.client('ses')

def _validate_environment():
    """
    Checks the Lambda environment variables
    """
    logger.info("[_validate_environment]: checking required env vars...")

    if "TABLE_NAME" not in os.environ:
        raise KeyError("TABLE_NAME is not set in the environment variables")
    if "SNS_TOPIC_ARN" not in os.environ:
        raise KeyError("SNS_TOPIC_ARN is not set in the environment variables")
    # if "SES_SOURCE_EMAIL" not in os.environ:
    #     raise KeyError("SES_SOURCE_EMAIL is not set in the environment variables")

    logger.info("[_validate_environment]: env vars are valid")

def lambda_handler(event, context):
    # Print the event for debugging
    print("Received event:", json.dumps(event, indent=2))

    # Validate environment variables
    _validate_environment()

    TABLE_NAME = os.environ['TABLE_NAME']
    SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
    # topic = sns.Topic(arn=SNS_TOPIC_ARN)
    # SES_SOURCE_EMAIL = os.environ['SES_SOURCE_EMAIL']

    # Initialize SNS wrapper
    # SNS = SnsWrapper(sns)

    # Parse & validate
    body = json.loads(event.get('body','{}'))
    name  = body.get('name')
    email = body.get('email')
    if not name or not email:
        return { 'statusCode': 400, 'body': json.dumps({'error':'name & email required'}) }

    # Build item
    item_id   = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()
    item = {
        'id': item_id,
        'timestamp': timestamp,
        'name': name,
        'email': email,
        'is_production': False
    }

    # Store in DynamoDB
    table = dynamodb.Table(TABLE_NAME)
    table.put_item(Item=item)

    # Notify via SNS
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject='New Registration',
        Message=json.dumps(item),
    )

    # # Send confirmation email via SES
    # ses.send_email(
    #     Source=SES_SOURCE_EMAIL,
    #     Destination={'ToAddresses':[email]},
    #     Message={
    #     'Subject':{'Data':'Registration Confirmation'},
    #     'Body':{'Text':{'Data':f"Hello {name},\n\nThanks for registering! Your ID: {item_id}"}}
    #     }
    # )

    # 4) Return success
    return {
        'statusCode': 200,
        'headers': {'Content-Type':'application/json'},
        'body': json.dumps({'message':'Registration successful','id':item_id})
    }
import json
import os
import uuid
from datetime import datetime, timezone
import boto3

dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')
ses = boto3.client('ses')

TABLE_NAME = os.environ['TABLE_NAME']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
SES_SOURCE_EMAIL = os.environ['SES_SOURCE_EMAIL']

def lambda_handler(event, context):
    # Print the event for debugging
    print("Received event:", json.dumps(event, indent=2))
    
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
        'email': email
    }

    # 1) Store in DynamoDB
    table = dynamodb.Table(TABLE_NAME)
    table.put_item(Item=item)

    # 2) Notify via SNS
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject='New Registration',
        Message=json.dumps(item),
    )

    # 3) Send confirmation email via SES
    ses.send_email(
        Source=SES_SOURCE_EMAIL,
        Destination={'ToAddresses':[email]},
        Message={
        'Subject':{'Data':'Registration Confirmation'},
        'Body':{'Text':{'Data':f"Hello {name},\n\nThanks for registering! Your ID: {item_id}"}}
        }
    )

    # 4) Return success
    return {
        'statusCode': 200,
        'headers': {'Content-Type':'application/json'},
        'body': json.dumps({'message':'Registration successful','id':item_id})
    }
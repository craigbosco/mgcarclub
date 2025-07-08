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
    body = event
    
    # Extract required fields
    firstName = body.get('firstName')
    lastName = body.get('lastName')
    email = body.get('email')
    attendees = body.get('attendees')
    registrationType = body.get('registrationType')
    
    # Validate required fields
    if not firstName or not lastName or not email or not attendees or not registrationType:
        return { 'statusCode': 400, 'body': json.dumps({'error':'firstName, lastName, email, attendees, and registrationType are required'}) }
    
    # Extract optional fields
    amount = body.get('amount', '')
    paymentDetails = body.get('paymentDetails', '')
    is_production = body.get('is_production', True)

    # Build item
    item_id   = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()
    item = {
        'id': item_id,
        'timestamp': timestamp,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'attendees': attendees,
        'registrationType': registrationType,
        'amount': amount,
        'paymentDetails': paymentDetails,
        'is_production': is_production
    }

    # Store in DynamoDB
    table = dynamodb.Table(TABLE_NAME)
    table.put_item(Item=item)
    logger.info(f"[lambda_handler]: Stored item {item_id} in DynamoDB table {TABLE_NAME}")

    # Build the message for SNS
    message = f"""
    New event registration received:
    
    - ID: {item_id}
    - Registration Type: {registrationType}
    - Name: {firstName} {lastName}
    - Email: {email}
    - Number of Attendees: {attendees}
    - Amount Paid: {amount}
    - Payment Details: {paymentDetails}
    - Timestamp: {timestamp}
    """

    # Notify via SNS
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=f'New Event Registration: {registrationType}',
        Message=message,
    )

    # # Send confirmation email via SES
    # ses.send_email(
    #     Source=SES_SOURCE_EMAIL,
    #     Destination={'ToAddresses':[email]},
    #     Message={
    #     'Subject':{'Data':'Registration Confirmation'},
    #     'Body':{'Text':{'Data':f"Hello {firstName} {lastName},\n\nThanks for registering! Your ID: {item_id}"}}
    #     }
    # )

    # 4) Return success
    return {
        'statusCode': 200,
        'headers': {'Content-Type':'application/json'},
        'body': json.dumps({'message':'Registration successful','id':item_id})
    }
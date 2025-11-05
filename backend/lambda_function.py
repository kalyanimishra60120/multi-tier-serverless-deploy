import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('ServerlessAppData')

def lambda_handler(event, context):
    # Insert a sample item
    table.put_item(Item={
        'id': '1',
        'message': 'Hello from Lambda + DynamoDB!'
    })
    
    # Fetch the item back
    response = table.get_item(Key={'id': '1'})
    item = response.get('Item', {})
    
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps(item)
    }

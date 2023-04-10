import json
import urllib.parse
import boto3


s3 = boto3.client('s3')
#pytest, moto- testing + oop

def lambda_handler(event, context):
    bucket = event['detail']['bucket']['name']
    key = urllib.parse.unquote_plus(event['detail']['object']['key'],
                                    encoding='utf-8')

    try:
        response = s3.get_object(Bucket=bucket, Key=key)
        lines = response['Body'].read().decode('utf-8').split('\n')

        count = 0
        for line in lines:
            if 'error' in line.lower():
                count += 1
        print(f'file - {key} have - {count} errors')
        return {
            'statusCode': 200,
            'body': json.dumps({'error_count': count})
        }

    except Exception as e:
        print(e)
        print('Error getting object {} from bucket {}. Make sure \
              they exist and your bucket is in the same region as \
              this function.'.format(key, bucket))
        raise e

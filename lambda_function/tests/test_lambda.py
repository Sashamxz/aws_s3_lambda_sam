import boto3
from moto import mock_s3
# from app import lambda_handler
from lambda_function.s3_log_manager import S3LogManager


@mock_s3
def test_lambda_handler():
    s3 = boto3.client('s3', region_name='us-east-1')
    s3.create_bucket(Bucket='my-test-bucket')
    s3.upload_file('local_file.txt')
    # lambda_handler(event, context)


@mock_s3
def test_count_error_lines():
    bucket_name = 'test_bucket'
    s3 = boto3.client('s3', region_name='us-east-1')
    s3.create_bucket(Bucket=bucket_name)
    test_file_key = 'test_key'
    test_file_contents = 'This is a test log file with error\n \
                          This is another test log file\n'
    s3.put_object(Body=test_file_contents, Bucket=bucket_name,
                  Key=test_file_key)

    s3_log_manager = S3LogManager(bucket_name, test_file_key)

    count = s3_log_manager.count_error_lines()

    assert count == 1, f'Expected count: 1, Actual count: {count}'

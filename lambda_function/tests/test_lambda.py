import os
import boto3
import moto
import pytest

from lambda_function.s3_log_manager import S3LogManager


@pytest.fixture
def s3_log_manager():
    # configure s3 virtual service using moto
    with moto.mock_s3():

        # create a test bucket
        s3 = boto3.client('s3', region_name='us-east-1')
        s3.create_bucket(Bucket='test_bucket')
        # create a text file in the bucket
        s3.put_object(Body=b'Test data', Bucket='test_bucket', Key='test.log')

        # Create an instance of the S3 LogManager
        s3_manager = S3LogManager('test_bucket', 'test.log', './test')
        yield s3_manager


# test downloaded file in s3 bucket
def test_download(s3_manager):
    s3_manager._download()
    assert os.path.exists(s3_manager.default_local_path)


# test lines method
def test_lines(s3_manager):
    lines = s3_manager.lines
    assert isinstance(lines, str)
    assert 'Test data' in lines


# test method process_line
def test_process_lines(s3_manager):
    result = []

    def func(line):
        result.append(line)

    s3_manager.process_lines(func)
    assert len(result) > 0

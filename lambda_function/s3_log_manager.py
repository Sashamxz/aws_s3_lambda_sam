import os
from typing import Callable, Generator, List
import boto3
from botocore import exceptions as bt_exceptions


class S3LogManager:

    def __init__(self, bucket: str, key: str,
                 default_local_path: str = '/tmp'):
        self.bucket = bucket
        self.key = key
        self.s3 = boto3.client('s3')
        self.default_local_path = default_local_path

    def _download(self) -> None:
        if not os.path.exists(self.default_local_path):
            os.makedirs(self.default_local_path)
            print(f"Directory created: {self.default_local_path}")

        try:
            self.s3.download_file(self.bucket, self.key,
                                  self.default_local_path)
        except bt_exceptions.ClientError as e:
            print(f"File download error: {e}")

    @property
    def lines(self) -> Generator[str]:
        response = self.s3.get_object(Bucket=self.bucket, Key=self.key)
        body = response['Body']
        for line in body.iter_lines():
            yield line.decode('utf-8')

    def process_lines(self, processors: List[Callable]) -> None:
        for processor in processors:
            for line in self.lines:
                processor(line)

    def process_all_file(self, processors: List[Callable]) -> None:
        for processor in processors:
            processor(self.lines)

import os
import boto3


class S3LogManager:

    def __init__(self, bucket, key, default_local_path):
        self.bucket = bucket
        self.key = key
        self.s3 = boto3.client('s3')
        self.default_local_path = default_local_path

    def _download(self):
        if not os.path.exists(self.default_local_path):
            os.makedirs(self.default_local_path)
            print(f"Directory created: {self.default_local_path}")

        try:
            self.s3.head_object(Bucket=self.bucket, Key=self.key)
            self.s3.download_file(self.bucket, self.key,
                                  self.default_local_path)
        except Exception as e:
            print(f"File download error: {e}")

    @property
    def line(self):
        response = self.s3.get_object(Bucket=self.bucket, Key=self.key)
        body = response['Body']
        for line in body.iter_lines():
            yield line.decode('utf-8')

    def process_lines(self, func):
        func(self.line)

    def process_all_file(self, func):
        all_lines = '\n'.join(list(self.line))
        func(all_lines)

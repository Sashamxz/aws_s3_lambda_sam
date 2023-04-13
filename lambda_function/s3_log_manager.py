import boto3


class S3LogManager:

    def __init__(self, bucket, key, default_local_path):
        self.bucket = bucket
        self.key = key
        self.s3 = boto3.client('s3')
        self.default_local_path = default_local_path

    def _download(self):
        self.s3.download_file(self.bucket, self.key, self.default_local_path)

    @property
    def _lines(self):
        if self._lines_cache is None:
            response = self.s3.get_object(Bucket=self.bucket, Key=self.key)
            self._lines_cache = response['Body'].read().decode('utf-8')
        return self._lines_cache

    def process_one_line(self, func):
        lines = self._lines.split('\n')
        for line in lines:
            func(line)

    def process_all_file(self, func):
        func(self._lines)

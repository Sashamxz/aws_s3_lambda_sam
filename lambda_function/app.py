import json
import urllib.parse
from datetime import datetime
from lambda_function.s3_log_manager import S3LogManager


def lambda_handler(event, context):
    bucket = event['detail']['bucket']['name']
    key = urllib.parse.unquote_plus(event['detail']['object']['key'],
                                    encoding='utf-8')
    default_local_path = '../downloaded_files'

    try:
        s3_file = S3LogManager(bucket, key, default_local_path)
        s3_file.process_lines(calculate_request_time)
        print(f'file - {key} has been analized')
        return {
            'statusCode': 200,
            'body': json.dumps({'body': None})
        }

    except Exception as e:
        print(e)
        print('Error getting object {} from bucket {}. Make sure \
              they exist and your bucket is in the same region as \
              this function.'.format(key, bucket))
        raise e


def calculate_request_time(line):
    if "send_data" in line and "response" in line:
        send_data_str = line.split("send_data:")[1].split(" ")[0]
        response_str = line.split("response:")[1].split(" ")[0]

        send_data = datetime.strptime(send_data_str, '%Y-%m-%d %H:%M:%S')
        response = datetime.strptime(response_str, '%Y-%m-%d %H:%M:%S')
        duration = response - send_data

        print("Request time: {} seconds".format(duration.total_seconds()))
    else:
        print('No one request in log file')


# def create_file_with_err(file_contents):
#     error_lines = [line for line in file_contents if 'error' in line.lower()]
#     if error_lines:
#         new_file_name = 'error_log.txt'
#         if os.path.exists(new_file_name):
#             i = 1
#             while os.path.exists(f'error_log_{i}.txt'):
#                 i += 1
#             new_file_name = f'error_log_{i}.txt'
#         with open(new_file_name, 'w') as f:
#             f.write('\n'.join(error_lines))
#         print(f'File "{new_file_name}" has been created with error logs.')
#         return new_file_name
#     else:
#         print('No error logs found.')
#         return None

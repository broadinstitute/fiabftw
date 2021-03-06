from googleapiclient.discovery import build
from oauth2client.service_account import ServiceAccountCredentials
import json


def get_svc_acct_field(json_credentials, field):
    json_dict = json.loads(open(json_credentials))
    return json_dict[field]


def create_directory_service(user_email, svc_acct_json_path):
    """Build and returns an Admin SDK Directory service object authorized with the service accounts
    that act on behalf of the given user.

    Args:
      user_email: The email of the user. Needs permissions to access the Admin APIs.
    Returns:
      Admin SDK directory service object.
    """

    credentials = ServiceAccountCredentials.from_json_keyfile_name(
        svc_acct_json_path,
        scopes=['https://www.googleapis.com/auth/admin.directory.user',
                'https://www.googleapis.com/auth/admin.directory.group'])

    credentials = credentials.create_delegated(user_email)

    return build('admin', 'directory_v1', credentials=credentials)


def create_compute_service(svc_acct_json_path):
    credentials = ServiceAccountCredentials.from_json_keyfile_name(
        svc_acct_json_path,
        scopes=['https://www.googleapis.com/auth/admin.directory.user',
                'https://www.googleapis.com/auth/admin.directory.group'])

    return build('compute', 'v1', credentials=credentials)

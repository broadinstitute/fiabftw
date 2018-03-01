from googleapiclient.discovery import build
from oauth2client.service_account import ServiceAccountCredentials
import sys, os
import json

CWD = os.getcwd()


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
        scopes=['https://www.googleapis.com/auth/admin.directory.user'])

    credentials = credentials.create_delegated(user_email)

    return build('admin', 'directory_v1', credentials=credentials)


def add_user(service, user_json):
    data = json.load(open(os.path.join(CWD, user_json)))
    print "Adding user {0}".format(data['primaryEmail'])
    service.users().insert(body=data).execute()


if __name__ == '__main__':
    user_email = sys.argv[1]
    svc_acct = os.path.join(CWD, sys.argv[2])

    directory = create_directory_service(user_email, svc_acct)
    add_user(directory, 'google-apps-domain/TestUser.json')

import sys, os
from common import create_directory_service

CWD = os.getcwd()


def add_user(service, user_data):
    print "Adding user {0}".format(user_data['primaryEmail'])
    service.users().insert(body=user_data).execute()


def make_admin(service, user_key):
    print "Setting user {0} as admin".format(user_key)
    service.users().makeAdmin(body={"status": True}, userKey=user_key).execute()


def add_group(service, group_name, group_email):
    data = {"name": group_name,
            "email": group_email}
    service.groups().insert(body=data).execute()


def set_up_firecloud_users(service, domain, passwd):
    # Add google user and make admin
    google_user = {
        "primaryEmail": "google@{0}".format(domain),
        "name": {
            "givenName": "Google",
            "familyName": "Admin"
        },
        "suspended": False,
        "password": passwd
    }

    add_user(service, google_user)
    make_admin(service, google_user["primaryEmail"])

    # Add billing user
    billing_user = {
        "primaryEmail": "billing@{0}".format(domain),
        "name": {
            "givenName": "Firecloud",
            "familyName": "Billing"
        },
        "suspended": False,
        "password": passwd
    }
    add_user(service, billing_user)


def set_up_firecloud_groups(service, domain, env, google_proj):
    add_group(service, "FC Admins", "fc-ADMINS@{0}".format(domain))
    add_group(service, "FC Comms", "fc-COMMS@{0}".format(domain))
    add_group(service, "FC Curators", "fc-CURATORS@{0}".format(domain))
    add_group(service, "FireCloud Project Owners", "firecloud-project-owners@{0}".format(domain))
    add_group(service, "Firecloud Project Editors - fiab", "firecloud-project-editors-{0}@{1}".format(env, domain))
    add_group(service, "firecloud-{0}@{1}.iam.gserviceaccount.com".format(env, google_proj), "proxy_servacct@{0}".format(domain))



if __name__ == '__main__':
    domain = sys.argv[1]
    user_email = sys.argv[2]
    svc_acct = os.path.join(CWD, sys.argv[3])
    env = sys.argv[4]
    google_proj = sys.argv[5]

    directory = create_directory_service(user_email, svc_acct)
    set_up_firecloud_users(directory, domain, "xxx")
    set_up_firecloud_groups(directory, domain, env, google_proj)

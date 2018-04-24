import sys, os
from common import create_directory_service

CWD = os.getcwd()


def add_user_to_group(service, user_key, group_key, role="MEMBER"):
    body = {"email": user_key,
            "role": role}
    service.members.insert(groupKey=group_key, body=body).execute()


def initialize_admin(service, admin_email, domain):
    print("Adding admin user {0} to the following groups:".format(admin_email))
    print("FC Admins")
    add_user_to_group(service, admin_email, "fc-ADMINS@{0}".format(domain), role="OWNER")
    print("FireCloud Project Owners")
    add_user_to_group(service, admin_email, "firecloud-project-owners@{0}".format(domain))
    print("...done.")


def add_svc_accts_to_project_editors(service, env, domain, svc_accts_file):
    to_add = ["rawls", "cromwell", "sam", "leonardo"]
    f = open(svc_accts_file, 'r')
    for x in f.readlines():
        if any(s in x for s in to_add):
            print("adding user {0} to Firecloud Project Editors".format(x))
            add_user_to_group(service, x, "firecloud-project-editors-{0}@{1}".format(env, domain))


def add_svc_acct_to_proxy_group(service, env, google_proj):
    add_user_to_group(service, "firecloud-{0}@{1}.iam.gserviceaccount.com".format(env, google_proj),
                      "firecloud-{0}@{1}.iam.gserviceaccount.com".format(env, google_proj))


if __name__ == '__main__':
    domain = sys.argv[1]
    user_email = sys.argv[2]
    svc_acct = os.path.join(CWD, sys.argv[3])
    env = sys.argv[4]
    google_proj = sys.argv[5]
    svc_accts_list = sys.argv[6]

    directory = create_directory_service(user_email, svc_acct)

    initialize_admin(directory, user_email, domain)
    add_svc_accts_to_project_editors(directory, env, domain, svc_accts_list)
    add_svc_acct_to_proxy_group(directory, env, google_proj)

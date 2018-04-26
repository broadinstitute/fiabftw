import sys, os
import json
import subprocess
import passgen


def password_create():
    return passgen.passgen()


def populate_secret(secret_path, secret):
    pass


def find_missing_secrets(secrets, env):
    env = {"environment": env}
    for s,v in secrets.iteritems():
        k = s[s.find("(")+1:s.find(")")]
        secret_path = subprocess.check_output(k, shell=True, env=env)

        try:
            process = subprocess.check_output("vault read {0}".format(secret_path), shell=True)

        except subprocess.CalledProcessError as e:
            print e.returncode
            for x in v:
                print x


if __name__ == '__main__':
    secrets_file_path = sys.argv[1]
    env = sys.argv[2]
    print secrets_file_path
    with open(secrets_file_path) as f:
        secrets_file = json.load(f)

    find_missing_secrets(secrets_file, env)
    # TODO: parse keyword for action

import sys, os
import json
import subprocess

def find_missing_secrets(secrets):
    os.system("export environment=fiab")
    for s,v in secrets.iteritems():
        k = s[s.find("(")+1:s.find(")")]
        secret_path = os.popen(k).read()

        # TODO: check for non-zero exit call
        r = subprocess.check_output(["vault", "read", secret_path])
        print r
        #os.system("vault read {0}".format(secret_path))


if __name__ == '__main__':
    secrets_file_path = sys.argv[1]
    print secrets_file_path
    with open(secrets_file_path) as f:
        secrets_file = json.load(f)

    find_missing_secrets(secrets_file)
    # TODO: parse keyword for action

import sys, os
import json
import subprocess
import passgen
import argparse


def password_create():
    return passgen.passgen()


def AES256_create():
    return passgen.passgen(length=43, letters=True, case='both') + "="


class Secret:
    """
    A Vault secret.
    """
    UNSETABLE_PATHS = ["-account.json", "-oauth-credential.json", "client_id"]
    UNSETABLE_FIELDS = ["client_id", "project_id", ".crt"]

    def __init__(self, path, field, value=None):
        self.path = path
        self.field = field
        self.value = value or self.create_secret(path, field)

    def create_secret(self, path, field):
        if [p for p in self.UNSETABLE_PATHS if p in path] or [f for f in self.UNSETABLE_FIELDS if f in field]:
            return None
        elif field == "value":
            path_suffix = path.split("/")[-1]
            self.create_secret(path, path_suffix)
        elif "password" in field or field == "signing-secret":
            return password_create()
        elif field == "gcs_tokenEncryptionKey" or field == "cryptokey" or field == "workflow_options_encryption_key":
            return AES256_create()
        elif "user" in field or "name" in field:
            return path.split("/")[4]
        elif "list" in field:
            return "[]"
        else:
            return "unused"


class MultiSecret:

    def __init__(self, path, body):
        self.path = path
        self.body = body
        self.body_secrets = [Secret(path, k, v) for k, v in body.iteritems()]


def vault_overwrite_json(m_secret):
    """
    Overwrites a vault secret with a json dict
    :param m_secret: A MultiSecret
    :return: shell subprocess output
    """
    with open("secret.json", 'w') as f:
        f.write(json.dumps(m_secret.body))
    f.close()
    print "Writing...", m_secret.path
    print m_secret.body
    return subprocess.check_output("vault write {0} @secret.json".format(m_secret.path), shell=True)


def vault_read_secret(path, field=None):
    """
    Reads out a json map of a vault secret.
    :param path: path to the secret (string)
    :param field: Specific field to read.  If None, reads all fields.
    :return: A dcit of the secret if it exists
    """
    if field:
        json_dict = subprocess.check_output("vault read -format=json -field={0} {1}".format(field, path), shell=True)
    else:
        json_dict = subprocess.check_output("vault read -format=json {0}".format(path), shell=True)

    return json.loads(json_dict)['data']


def vault_overwrite_field(secret):
    """
    Overwrites a specific field in a vault secret
    :param secret: A Secret
    :return: shell subprocess output
    """
    print "Writing...", secret.path
    print secret.field, " : ", secret.value
    return subprocess.check_output("vault write {0} {1}={2}".format(secret.path, secret.field, secret.value), shell=True)


def vault_edit_field(secret, body=None):
    """
    Modifies an existing field or adds a new field in a vault secret, without overwriting the other fields.
    :param secret: A secret
    :return: shell subprocess output
    """
    if not body:
        body = vault_read_secret(secret.path)
    body[secret.field] = secret.value
    print "Editing...", secret.path
    print secret.field, " : ", secret.value
    return vault_overwrite_json(MultiSecret(secret.path, body))


def overwrite_secret(secret_path, body):
    sub_secrets = {}
    for f,x in body.iteritems():
        s = Secret(secret_path, f, x)
        if s.value:
            sub_secrets[f] = s.value

    if sub_secrets:
        vault_overwrite_json(MultiSecret(secret_path, sub_secrets))


def edit_secret(secret_path, field, value=None):
    secret = Secret(secret_path, field, value)
    return vault_edit_field(secret)


def populate_secret(secret_path, body, overwrite=False):
    """
    Populates a secret into vault.  If overwrite == True, will overwrite the secret with the given body.
    Else, if no value exists at the secret path, will write the given body.
          if a value exists at the secret path but the secret dict is missing a field, will write that field -> value from the body
    In all cases, if value == None will generate a value for appropriate secrets
    :param secret_path: path to the secret (string)
    :param body: a dict of field -> value (dict)
    :param overwrite: if True, will always overwrite secret.  Else, will check for secret existence (bool)
    :return: None
    """
    try:
        existing_secret = vault_read_secret(secret_path)
        for k, v in body.iteritems():
            new_secret = Secret(secret_path, k, v)
            if k not in existing_secret.keys():
                vault_edit_field(new_secret, body=existing_secret)
            else:
                if overwrite and new_secret.value:
                    vault_edit_field(new_secret, body=existing_secret)

    except subprocess.CalledProcessError as e:
        overwrite_secret(secret_path, body)


def populate_secrets_from_file(secrets, env, overwrite=False):
    env = {"environment": env}
    for s,v in secrets.iteritems():
        k = s[s.find("(")+1:s.find(")")]
        secret_path = subprocess.check_output(k, shell=True, env=env)
        body = {x.split(".")[0]: None for x in v}
        populate_secret(secret_path, body, overwrite=overwrite)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--env', type=str)
    parser.add_argument('--fromFile', type=str, help='path to secrets json file')
    parser.add_argument('--path', type=str)
    parser.add_argument('--fields', nargs='+', type=str)
    parser.add_argument('--values', nargs='+', type=str)
    parser.add_argument('--overwrite', action='store_true')

    args = parser.parse_args()
    env = args.env or "fiab"

    if args.fromFile:
        with open(args.fromFile) as f:
            secrets_file = json.load(f)
        populate_secrets_from_file(secrets_file, env, overwrite=args.overwrite)
    elif args.path and args.fields:
        if args.values and len(args.fields) == len(args.values):
            body = {args.fields[i]: args.values[i] for i in range(len(args.fields))}
        else:
            body = {args.fields[i]: None for i in range(len(args.fields))}
        populate_secret(args.path, body, overwrite=args.overwrite)
    else:
        print("Please provide the correct command line arguments!")
        sys.exit(1)

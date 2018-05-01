import sys, os
import json
import subprocess
import passgen


def password_create():
    return passgen.passgen()


def vault_overwrite_json(secret_path, secret_dict):
    with open("secret.json", 'w') as f:
        f.write(json.dumps(secret_dict))
    f.close()
    return subprocess.check_output("vault write {0} @secret.json".format(secret_path), shell=True)


def vault_read_secret(path, field=None):
    if field:
        return subprocess.check_output("vault read -format=json -field={0} {1}".format(field, path), shell=True)
    else:
        return subprocess.check_output("vault read -format=json {0}".format(path), shell=True)


def vault_overwrite_field(secret_path, field, value):
    return subprocess.check_output("vault write {0} {1}={2}".format(secret_path, field, value), shell=True)


def vault_edit_field(secret_path, field, value):
    json_dict = vault_read_secret(secret_path) # TODO
    secrets = json.loads(json_dict)['data']
    secrets[field] = value
    return vault_overwrite_json(secret_path, secrets)


def create_secret(secret_path, secret_field):
    print secret_path, secret_field
    if secret_field == "value":
        path_suffix = secret_path.split("/")[-1]
        create_secret(secret_path, path_suffix)
    elif "password" in secret_field or secret_field == "signing-secret":
        return password_create()
    elif "user" in secret_field or "name" in secret_field:
        return secret_path.split("/")[4]
    else:
        return None


def overwrite_secret(secret_path, secret_fields):
    if len(secret_fields) > 1:
        sub_secrets = {}
        for f in secret_fields:
            sub_secrets[f] = create_secret(secret_path, f)
        print "Secrets for {0}".format(secret_path)
        print sub_secrets
        print "\n"
        vault_write = vault_overwrite_json(secret_path, sub_secrets)

    else:
        field = secret_fields[0]
        secret = create_secret(secret_path, field)
        print "Secret for {0}: {1}".format(secret_path, secret)
        print "\n"
        vault_write = vault_overwrite_field(secret_path, field, create_secret(secret_path, field))


def edit_secret(secret_path, field):
    s = create_secret(secret_path, field)
    return vault_edit_field(secret_path, field, s)


def populate_secrets(secrets, env, overwrite=True):
    env = {"environment": env}
    for s,v in secrets.iteritems():
        k = s[s.find("(")+1:s.find(")")]
        secret_path = subprocess.check_output(k, shell=True, env=env)

        if overwrite:
            overwrite_secret(secret_path, v)

        else:
            try:
                vault_read_secret(secret_path)
                # if secret exists, check that all keys exist
                for x in v:
                    try:
                        vault_read_secret(secret_path, field=x)
                    except subprocess.CalledProcessError as e:
                        edit_secret(secret_path, x)

            except subprocess.CalledProcessError as e:
                overwrite_secret(secret_path, v)


def test_overwrite():
    vault_edit_field("secret/dsde/firecloud/fiab/thurloe/thurloe.conf", "sendgrid_apiKey", "test")


if __name__ == '__main__':
    secrets_file_path = sys.argv[1]
    env = sys.argv[2]
    with open(secrets_file_path) as f:
        secrets_file = json.load(f)

    populate_secrets(secrets_file, env)

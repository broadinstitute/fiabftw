from tos_common import create_tos, create_client
import sys, os

HOST_NAME = os.environ.get("HOST_NAME")
TOS_VERSION = os.environ.get("TOS_VERSION", 1)

print "\nCreating ToS..."
client = create_client()
create_tos(client, HOST_NAME, TOS_VERSION)

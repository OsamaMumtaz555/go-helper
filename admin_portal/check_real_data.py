import json
import os
import requests
from google.oauth2 import service_account
import google.auth.transport.requests

service_account_path = "serviceAccountKey.json"
with open(service_account_path) as f:
    info = json.load(f)

creds = service_account.Credentials.from_service_account_info(
    info, scopes=["https://www.googleapis.com/auth/cloud-platform"]
)

# Refresh token
request = google.auth.transport.requests.Request()
creds.refresh(request)
token = creds.token

# Fetch users
project_id = info["project_id"]
db_url = f"https://firestore.googleapis.com/v1/projects/{project_id}/databases/(default)/documents/users"
headers = {"Authorization": f"Bearer {token}"}

print(f"Querying: {db_url}")
resp = requests.get(db_url, headers=headers)
if resp.status_code == 200:
    docs = resp.json().get('documents', [])
    print(f"Total documents in 'users': {len(docs)}")
    for d in docs:
        print(f"Doc Name: {d['name']}")
        fields = d.get('fields', {})
        user_type = fields.get('userType', {}).get('stringValue', 'N/A')
        status = fields.get('status', {}).get('stringValue', 'N/A')
        print(f" - Type: {user_type}, Status: {status}")
else:
    print(f"Error {resp.status_code}: {resp.text}")

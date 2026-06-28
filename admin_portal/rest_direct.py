import json
import requests
import os
import google.auth
import google.auth.transport.requests

# Use service account to get access token
# (requires google-auth)
from google.oauth2 import service_account

service_account_path = "serviceAccountKey.json"
if not os.path.exists(service_account_path):
    print("Error: serviceAccountKey.json not found")
    exit(1)

with open(service_account_path) as f:
    info = json.load(f)

scoped_credentials = service_account.Credentials.from_service_account_info(
    info, scopes=["https://www.googleapis.com/auth/cloud-platform"]
)
request = google.auth.transport.requests.Request()
scoped_credentials.refresh(request)
token = scoped_credentials.token

project_id = info["project_id"]
db_url = f"https://firestore.googleapis.com/v1/projects/{project_id}/databases/(default)/documents/users"

headers = {"Authorization": f"Bearer {token}"}
print(f"Fetching users from REST API: {db_url}")

response = requests.get(db_url, headers=headers)
if response.status_code == 200:
    data = response.json()
    documents = data.get("documents", [])
    print(f"Total documents returned by REST: {len(documents)}")
    for doc in documents:
        # Simple extraction of some fields
        fields = doc.get("fields", {})
        uid = doc.get("name").split("/")[-1]
        user_type = fields.get("userType", {}).get("stringValue", "N/A")
        status = fields.get("status", {}).get("stringValue", "N/A")
        name = fields.get("fullName", {}).get("stringValue", "N/A")
        print(f"UID: {uid}, Type: {user_type}, Status: {status}, Name: {name}")
else:
    print(f"Error {response.status_code}: {response.text}")

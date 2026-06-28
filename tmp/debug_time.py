import os
import sys
import time
from datetime import datetime, timezone

sys.path.append(r'c:\Users\HP\Downloads\go_helper\admin_portal')
os.chdir(r'c:\Users\HP\Downloads\go_helper\admin_portal')

from google.oauth2 import service_account
import google.auth.transport.requests

info = __import__('json').load(open('serviceAccountKey.json'))
creds = service_account.Credentials.from_service_account_info(
    info, scopes=["https://www.googleapis.com/auth/cloud-platform"]
)

auth_req = google.auth.transport.requests.Request()
creds.refresh(auth_req)

print(f"Now (time.time()): {time.time()}")
print(f"Now (datetime.now()): {datetime.now()}")
print(f"Now (datetime.now(timezone.utc)): {datetime.now(timezone.utc)}")
print(f"Expiry: {creds.expiry}")
print(f"Expiry Timestamp: {creds.expiry.timestamp()}")
print(f"Diff: {creds.expiry.timestamp() - time.time()}")

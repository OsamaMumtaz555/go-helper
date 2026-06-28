import json
import os
from datetime import datetime, timezone
import google.auth
import google.auth.transport.requests
from google.oauth2 import service_account

# Check system time as seen by Python
now_utc = datetime.now(timezone.utc)
print(f"Python sees UTC: {now_utc.isoformat()}")

service_account_path = "serviceAccountKey.json"
with open(service_account_path) as f:
    info = json.load(f)

creds = service_account.Credentials.from_service_account_info(
    info, scopes=["https://www.googleapis.com/auth/cloud-platform"]
)

# Attempt refresh
request = google.auth.transport.requests.Request()
try:
    print("Attempting to refresh token manually...")
    creds.refresh(request)
    print("Token refreshed successfully!")
    print(f"Token: {creds.token[:10]}...")
except Exception as e:
    print(f"Refresh failed: {e}")
    # Check if we can see the JWT it generated?
    # Usually internal to the library, but let's check iat
    # google.oauth2.service_account handles this via its refresh mechanism.

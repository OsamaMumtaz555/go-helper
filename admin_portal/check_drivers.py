import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore_v1.services.firestore.transports import FirestoreRestTransport
from google.cloud.firestore import Client
import os
import json

service_account_path = "serviceAccountKey.json"
if not os.path.exists(service_account_path):
    print("Error: serviceAccountKey.json not found")
    exit(1)

# Load info for project_id
with open(service_account_path) as f:
    info = json.load(f)

cred = credentials.Certificate(service_account_path)
try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app(cred)

# Force REST transport manually
transport = FirestoreRestTransport(credentials=cred.get_credential())
db = Client(project=info["project_id"], credentials=cred.get_credential(), transport=transport)

print("Checking users collection (via REST)...")
users_ref = db.collection('users')

# Get all users to see what we have
all_users = list(users_ref.get())
print(f"Total users in 'users' collection: {len(all_users)}")

for user in all_users:
    u_dict = user.to_dict()
    print(f"User ID: {user.id}, Type: {u_dict.get('userType')}, Status: {u_dict.get('status')}, Name: {u_dict.get('fullName')}")

print("\nQuerying for pending drivers...")
pending = list(users_ref.where("userType", "==", "driver").where("status", "==", "pending").get())
print(f"Found {len(pending)} pending drivers.")

for d in pending:
    print(f"- {d.to_dict().get('fullName')} ({d.id})")

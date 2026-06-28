import firebase_admin
from firebase_admin import credentials, firestore
import os
import time

# Fix for gRPC hangs on some Windows environments
os.environ["GRPC_DNS_RESOLVER"] = "native"

service_account_path = "serviceAccountKey.json"
if not os.path.exists(service_account_path):
    print("Error: serviceAccountKey.json not found")
    exit(1)

cred = credentials.Certificate(service_account_path)
try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app(cred)

db = firestore.client()

print("Checking users collection (with GRPC_DNS_RESOLVER=native)...", flush=True)
users_ref = db.collection('users')

start = time.time()
try:
    # Use a timeout if possible, but Firestore doesn't support it directly in get() easily
    all_users = list(users_ref.limit(5).get())
    print(f"Fetched {len(all_users)} users in {time.time()-start:.2f}s")
    for user in all_users:
        u_dict = user.to_dict()
        print(f"User ID: {user.id}, Type: {u_dict.get('userType')}, Status: {u_dict.get('status')}")
except Exception as e:
    print(f"Error after {time.time()-start:.2f}s: {e}")

import firebase_admin
from firebase_admin import credentials, firestore
import time
from google.cloud import firestore as gc_firestore

print("Init REST...")
cred = credentials.Certificate("serviceAccountKey.json")
try:
    app = firebase_admin.get_app()
except ValueError:
    app = firebase_admin.initialize_app(cred)

db = gc_firestore.Client(credentials=cred.get_credential(), project=app.project_id, transport='rest')
print("Getting 1 user with REST transport...")
start = time.time()
try:
    docs = db.collection("users").limit(1).get()
    print(f"Got {len(docs)} users in {time.time() - start:.2f}s")
except Exception as e:
    print("Error:", e)

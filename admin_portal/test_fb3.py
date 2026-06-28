import firebase_admin
from firebase_admin import credentials, firestore
import time

print("Init...", flush=True)
cred = credentials.Certificate("serviceAccountKey.json")
try:
    firebase_admin.get_app()
except:
    firebase_admin.initialize_app(cred)
db = firestore.client()

start = time.time()
try:
    val = db.collection('users').count().get()
    count = val[0][0].value
    print(f"Users count: {count} in {time.time()-start:.2f}s", flush=True)
except Exception as e:
    print("Error:", e, flush=True)

start = time.time()
try:
    docs = db.collection('users').get()
    print(f"Docs fetched: {len(docs)} in {time.time()-start:.2f}s", flush=True)
except Exception as e:
    print("Error:", e, flush=True)

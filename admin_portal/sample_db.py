import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("serviceAccountKey.json")
try:
    app = firebase_admin.get_app()
except ValueError:
    app = firebase_admin.initialize_app(cred)

db = firestore.client()
print("Collection 'users' (1 sample):")
users = db.collection('users').limit(1).get()
for u in users:
    print(f"ID: {u.id} - Data: {u.to_dict()}")

print("\nCollection 'rides' (1 sample):")
rides = db.collection('rides').limit(1).get()
for r in rides:
    print(f"ID: {r.id} - Data: {r.to_dict()}")

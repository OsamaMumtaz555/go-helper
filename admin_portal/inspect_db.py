import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud import firestore as gc_firestore

cred = credentials.Certificate("serviceAccountKey.json")
try:
    app = firebase_admin.get_app()
except ValueError:
    app = firebase_admin.initialize_app(cred)

# Force REST transport
db = gc_firestore.Client(credentials=cred.get_credential(), project=app.project_id, transport='rest')
print("Collections in the database (via REST):")
collections = db.collections()
for coll in collections:
    print(f"- {coll.id}")

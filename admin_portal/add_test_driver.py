import firebase_admin
from firebase_admin import credentials, firestore
import os

service_account_path = "serviceAccountKey.json"
if not os.path.exists(service_account_path):
    print("Error: serviceAccountKey.json not found")
    exit(1)

cred = credentials.Certificate(service_account_path)
firebase_admin.initialize_app(cred)
db = firestore.client()

print("Attempting to add a test driver...")
test_user = {
    "fullName": "Test Driver",
    "email": "test@example.com",
    "phone": "+1234567890",
    "userType": "driver",
    "status": "pending",
    "vehicleModel": "Toyota Camry",
    "licensePlate": "TEST123",
    "serviceType": "ride",
    "createdAt": firestore.SERVER_TIMESTAMP
}

try:
    doc_ref = db.collection('users').add(test_user)
    print(f"Successfully added test driver with ID: {doc_ref[1].id}")
except Exception as e:
    print(f"Failed to add driver: {e}")

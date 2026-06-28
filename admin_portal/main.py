import sys
import io
import threading
import firebase_admin
from firebase_admin import credentials, firestore
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
import os
from datetime import datetime
import traceback
import requests
import time
from dotenv import load_dotenv
from google.oauth2 import service_account

# Load environment variables
load_dotenv()

# Fix for gRPC hangs on some Windows environments
os.environ["GRPC_DNS_RESOLVER"] = "native"

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

app = FastAPI()
firebase_initialized = False
db = None
last_error = None

# Custom REST client to bypass gRPC hangs on Windows
class RestFirestore:
    def __init__(self, service_account_path):
        with open(service_account_path) as f:
            self.info = __import__('json').load(f)
        self.project_id = self.info['project_id']
        self.creds = service_account.Credentials.from_service_account_info(
            self.info, scopes=["https://www.googleapis.com/auth/cloud-platform"]
        )
        self.session = requests.Session()
        self._token = None
        self._token_expiry = 0

    def get_token(self):
        # Cache token to avoid expensive network refresh on every call
        now = time.time()
        if not self._token or now > self._token_expiry - 60:
            auth_req = __import__('google.auth.transport.requests').auth.transport.requests.Request()
            self.creds.refresh(auth_req)
            self._token = self.creds.token
            # creds.expiry is a datetime object usually naive but meant as UTC
            if hasattr(self.creds, 'expiry') and self.creds.expiry:
                from datetime import timezone
                expiry = self.creds.expiry
                if expiry.tzinfo is None:
                    expiry = expiry.replace(tzinfo=timezone.utc)
                self._token_expiry = expiry.timestamp()
            else:
                self._token_expiry = now + 3500
            print(f"[AUTH] Token refreshed (expires in {int(self._token_expiry - now)}s)")
        return self._token

    def collection(self, name):
        return RestCollection(self, name)

    def document(self, path):
        return RestDocRef(self, path)

class RestDocRef:
    def __init__(self, client, path):
        self.client = client
        self.path = path

    def update(self, data):
        url = f"https://firestore.googleapis.com/v1/projects/{self.client.project_id}/databases/(default)/documents/{self.path}"
        # Convert data to Firestore JSON fields
        fields = {}
        update_mask = []
        for k, v in data.items():
            update_mask.append(f"updateMask.fieldPaths={k}")
            if isinstance(v, str): fields[k] = {"stringValue": v}
            elif isinstance(v, bool): fields[k] = {"booleanValue": v}
            elif isinstance(v, int): fields[k] = {"integerValue": str(v)}
        
        headers = {"Authorization": f"Bearer {self.client.get_token()}"}
        mask_str = "&".join(update_mask)
        url += f"?{mask_str}"
        
        resp = self.client.session.patch(url, json={"fields": fields}, headers=headers)
        if resp.status_code != 200:
            raise Exception(f"Update failed {resp.status_code}: {resp.text}")
        return True

    def delete(self):
        url = f"https://firestore.googleapis.com/v1/projects/{self.client.project_id}/databases/(default)/documents/{self.path}"
        headers = {"Authorization": f"Bearer {self.client.get_token()}"}
        resp = self.client.session.delete(url, headers=headers)
        if resp.status_code != 200:
            raise Exception(f"Delete failed {resp.status_code}: {resp.text}")
        return True

class RestCollection:
    def __init__(self, client, name):
        self.client = client
        self.name = name
        self.filters = []

    def where(self, field, op, val):
        self.filters.append((field, op, val))
        return self

    def get(self):
        # Use documentation list method for simplicity in this bridge
        url = f"https://firestore.googleapis.com/v1/projects/{self.client.project_id}/databases/(default)/documents/{self.name}"
        headers = {"Authorization": f"Bearer {self.client.get_token()}"}
        
        # Note: Filtering via REST API is complex. For the admin portal dashboard,
        # we'll fetch recently modified records and filter in-memory for speed/safety.
        resp = self.client.session.get(url, headers=headers)
        if resp.status_code != 200:
            raise Exception(f"REST Error {resp.status_code}: {resp.text}")
        
        docs = resp.json().get('documents', [])
        results = []
        for d in docs:
            fields = d.get('fields', {})
            data = self._parse_fields(fields)
            doc_id = d.get('name').split('/')[-1]
            
            # Apply filters in-memory
            match = True
            for f_field, f_op, f_val in self.filters:
                val = data.get(f_field)
                # Specialized logic: if status is requested and missing, treat it as "pending"
                if f_field == "status" and val is None:
                    val = "pending"
                
                if f_op == "==":
                    if val != f_val: match = False; break
                elif f_op == "in":
                    if val not in f_val: match = False; break
            
            if match:
                results.append(RestDoc(doc_id, data))
        return results

    def count(self):
        # Simulation of count for the dashboard
        return RestCount(len(self.get()))

    def _parse_fields(self, fields):
        parsed = {}
        for k, v in fields.items():
            if 'stringValue' in v: parsed[k] = v['stringValue']
            elif 'booleanValue' in v: parsed[k] = v['booleanValue']
            elif 'integerValue' in v: parsed[k] = int(v['integerValue'])
            elif 'timestampValue' in v: parsed[k] = v['timestampValue']
            elif 'mapValue' in v: parsed[k] = self._parse_fields(v['mapValue'].get('fields', {}))
        return parsed

class RestDoc:
    def __init__(self, id, data):
        self.id = id
        self._data = data
    def to_dict(self): return self._data

class RestCount:
    def __init__(self, val): self.value = val
    def get(self): return [[RestCountValue(self.value)]]

class RestCountValue:
    def __init__(self, val): self.value = val

# Global cache for real-time counts to keep the dashboard snappy
class DashboardCache:
    def __init__(self):
        self.counts = {
            "total_users": 0, "drivers": 0, "customers": 0,
            "active_rides": 0, "pending_drivers": 0,
            "approved_drivers": 0, "rejected_drivers": 0
        }
        self.recent_rides = []
        self.pending_drivers = []
        self.approved_drivers = []
        self.rejected_drivers = []
        self.lock = threading.Lock()

cache = DashboardCache()

def update_counts_loop():
    """Periodic background loop to update dashboard counts."""
    while True:
        try:
            update_counts_once()
        except:
            pass
        time.sleep(20)

def update_counts_once():
    """Single pass of fetching data from Firestore with in-memory filtering for speed."""
    global last_error
    if not firebase_initialized: return
    try:
        start_sync = time.time()
        # Fetch all users once instead of 5 separate filtered calls
        all_users = rest_db.collection('users').get()
        
        u_count = len(all_users)
        c_count = 0
        pending = []
        approved = []
        rejected = []
        
        for u in all_users:
            data = u.to_dict()
            u_type = data.get('userType')
            u_status = data.get('status', 'pending') # Default to pending if missing
            
            if u_type == "customer":
                c_count += 1
            elif u_type == "driver":
                driver_data = {**data, 'uid': u.id}
                if u_status == "approved": approved.append(driver_data)
                elif u_status == "rejected": rejected.append(driver_data)
                else: pending.append(driver_data)
        
        # Fetch active rides (smaller collection usually)
        # Filtering for "accepted", "picking", "on_ride" in-memory after one fetch
        all_rides = rest_db.collection('rides').get()
        active_rides = []
        for r in all_rides:
            r_data = r.to_dict()
            if r_data.get('status') in ["accepted", "picking", "on_ride"]:
                active_rides.append({**r_data, 'id': r.id})

        with cache.lock:
            cache.counts["total_users"] = u_count
            cache.counts["customers"] = c_count
            cache.counts["active_rides"] = len(active_rides)
            cache.counts["pending_drivers"] = len(pending)
            cache.counts["approved_drivers"] = len(approved)
            cache.counts["rejected_drivers"] = len(rejected)
            cache.counts["drivers"] = len(pending) + len(approved) + len(rejected)
            
            cache.pending_drivers = pending
            cache.approved_drivers = approved
            cache.rejected_drivers = rejected
            cache.recent_rides = active_rides[:15]
        
        last_error = None
        duration = time.time() - start_sync
        print(f"[OK] Dashboard synchronized in {duration:.2f}s. Pending: {len(pending)}")
        
        last_error = None
        print(f"[OK] Dashboard updated. Pending drivers: {len(pending)}")
    except Exception as e:
        last_error = f"Bridge Error: {str(e)}"
        if "invalid_grant" in str(e).lower():
            last_error = "AUTH ERROR: System clock may be out of sync. Please check your Windows time settings (Date/Time > Sync now)."
        print(f"[ERROR] Sync failed: {e}")

# Initialize Firebase and Rest Bridge
service_account_path = "serviceAccountKey.json"
rest_db = None
service_account_info = None

# Load Firebase credentials from environment variable (for deployment) or file (for local)
if os.getenv('FIREBASE_CREDENTIALS'):
    # Production: Load from environment variable
    try:
        import json
        service_account_info = json.loads(os.getenv('FIREBASE_CREDENTIALS'))
        print("[OK] Loaded Firebase credentials from environment variable.")
    except Exception as e:
        print(f"[ERROR] Failed to parse FIREBASE_CREDENTIALS env var: {e}")
elif os.path.exists(service_account_path):
    # Local: Load from file
    try:
        with open(service_account_path) as f:
            service_account_info = __import__('json').load(f)
        print("[OK] Loaded Firebase credentials from serviceAccountKey.json")
    except Exception as e:
        print(f"[ERROR] Failed to load serviceAccountKey.json: {e}")
else:
    print("[WARN] No Firebase credentials found (neither env var nor file).")

# Initialize Firebase services if credentials are available
if service_account_info:
    # Initialize REST Bridge first since it's the most reliable
    try:
        # Create temporary file for RestFirestore (it expects a file path)
        import tempfile
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as temp_file:
            import json
            json.dump(service_account_info, temp_file)
            temp_path = temp_file.name
        
        rest_db = RestFirestore(temp_path)
        firebase_initialized = True 
        print("[OK] REST Bridge initialized for dashboard data.")
        
        # Clean up temp file
        try:
            os.remove(temp_path)
        except:
            pass
            
    except Exception as e:
        print(f"[ERROR] REST Bridge init: {e}")
        last_error = f"REST Bridge Error: {str(e)}"

    # Best-effort initialization of standard Firebase
    try:
        cred = credentials.Certificate(service_account_info)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("[OK] Firebase Admin initialized (best effort).")
    except Exception as e:
        print(f"[WARN] Firebase Admin init failed/skipped: {e}")

    if firebase_initialized:
        # Start cache population loop
        threading.Thread(target=update_counts_loop, daemon=True).start()

templates = Jinja2Templates(directory="templates")

@app.get("/", response_class=HTMLResponse)
async def dashboard(request: Request):
    display_error = last_error
    if not firebase_initialized:
        display_error = "Firebase not found. Check if serviceAccountKey.json is in the admin_portal folder."

    return templates.TemplateResponse(
        request=request,
        name="index.html",
        context={
            "error": display_error,
            "counts": cache.counts,
            "rides": cache.recent_rides,
            "pending_drivers": cache.pending_drivers,
            "approved_drivers": cache.approved_drivers,
            "rejected_drivers": cache.rejected_drivers,
        }
    )

@app.get("/api/stats")
async def get_stats():
    return cache.counts

@app.post("/approve-driver/{uid}")
async def approve_driver(uid: str):
    if not firebase_initialized:
        raise HTTPException(status_code=500, detail="Firebase not initialized")
    try:
        # Use our REST bridge to avoid hangs
        rest_db.document(f"users/{uid}").update({"status": "approved"})
        # Success - update dashboard cache immediately
        update_counts_once()
        return JSONResponse(content={"status": "success"})
    except Exception as e:
        print(f"[ERROR] Approving driver: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/reject-driver/{uid}")
async def reject_driver(uid: str):
    if not firebase_initialized:
        raise HTTPException(status_code=500, detail="Firebase not initialized")
    try:
        rest_db.document(f"users/{uid}").update({"status": "rejected"})
        update_counts_once()
        return JSONResponse(content={"status": "success"})
    except Exception as e:
        print(f"[ERROR] Rejecting driver: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/revoke-driver/{uid}")
async def revoke_driver(uid: str):
    if not firebase_initialized:
        raise HTTPException(status_code=500, detail="Firebase not initialized")
    try:
        # Revoke returns them to "pending" status
        rest_db.document(f"users/{uid}").update({"status": "pending"})
        update_counts_once()
        return JSONResponse(content={"status": "success"})
    except Exception as e:
        print(f"[ERROR] Revoking driver: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/dashboard")
async def get_dashboard():
    if not firebase_initialized:
        raise HTTPException(status_code=500, detail="Firebase not initialized")
    try:
        with cache.lock:
            return {
                "counts": cache.counts,
                "recent_rides": cache.recent_rides,
                "drivers": {
                    "pending": cache.pending_drivers,
                    "approved": cache.approved_drivers,
                    "rejected": cache.rejected_drivers
                }
            }
    except Exception as e:
        print(f"[ERROR] Getting dashboard: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    # Use environment variables if set, otherwise defaults
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))
    print(f"[START] Admin Portal on http://{host}:{port}")
    uvicorn.run(app, host=host, port=port)

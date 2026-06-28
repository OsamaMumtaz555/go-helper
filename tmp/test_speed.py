import time
import os
import sys

# Path to the admin_portal
sys.path.append(r'c:\Users\HP\Downloads\go_helper\admin_portal')

try:
    from main import RestFirestore
    
    os.chdir(r'c:\Users\HP\Downloads\go_helper\admin_portal')
    service_account_path = 'serviceAccountKey.json'
    if not os.path.exists(service_account_path):
        print(f"Error: {service_account_path} not found")
        sys.exit(1)
        
    db = RestFirestore(service_account_path)
    
    print("Testing 'users' collection fetch speed...")
    start = time.time()
    try:
        users = db.collection('users').get()
        end = time.time()
        print(f"Fetched {len(users)} users in {end - start:.2f} seconds")
    except Exception as e:
        print(f"Error fetching users: {e}")
    
    print("Testing 'rides' collection fetch speed...")
    start = time.time()
    try:
        rides = db.collection('rides').get()
        end = time.time()
        print(f"Fetched {len(rides)} rides in {end - start:.2f} seconds")
    except Exception as e:
        print(f"Error fetching rides: {e}")

except Exception as e:
    print(f"Error: {e}")

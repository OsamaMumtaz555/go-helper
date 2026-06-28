# Check if Python is installed
if (!(Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Python is not installed. Please install Python to run the admin portal." -ForegroundColor Red
    exit
}

Write-Host "--- Go Helper Admin Portal Setup ---" -ForegroundColor Cyan

# Check for serviceAccountKey.json
if (!(Test-Path "serviceAccountKey.json")) {
    Write-Host "Warning: serviceAccountKey.json not found in admin_portal folder." -ForegroundColor Yellow
    Write-Host "Please download it from Firebase Console (Project Settings > Service Accounts)." -ForegroundColor Yellow
}

# Install dependencies
Write-Host "Installing dependencies..."
python -m pip install -r requirements.txt

# Start the server
Write-Host "Starting Admin Portal on http://localhost:8000" -ForegroundColor Green
python main.py

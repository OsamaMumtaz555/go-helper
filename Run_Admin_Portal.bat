@echo off
setlocal
cd /d %~dp0admin_portal

title Go Helper Admin Portal

echo ==========================================
echo    Go Helper Admin Portal Launcher
echo ==========================================
echo.

:: Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python not found!
    echo Please install Python from https://python.org
    pause
    exit /b 1
)

:: Check for serviceAccountKey.json
if not exist "serviceAccountKey.json" (
    echo [WARNING] serviceAccountKey.json not found.
    echo The portal will start but Firebase connection may fail.
    echo.
)

:: Install requirements (only if needed)
echo [1/2] Checking dependencies...
python -m pip install -r requirements.txt -q --disable-pip-version-check
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install dependencies.
    pause
    exit /b 1
)
echo [OK] Dependencies ready.
echo.

:: Start the portal
echo [2/2] Starting Admin Portal...
echo.
echo ==========================================
echo  Open in browser: http://localhost:8000
echo ==========================================
echo.
echo  Press CTRL+C to stop the server.
echo.

python main.py

echo.
echo [INFO] Server stopped.
pause

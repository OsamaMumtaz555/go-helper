@echo off
echo ================================================
echo Firebase Credentials for Render Deployment
echo ================================================
echo.
echo Copy the entire output below and paste it into
echo Render's FIREBASE_CREDENTIALS environment variable
echo.
echo ================================================
echo.
type admin_portal\serviceAccountKey.json
echo.
echo ================================================
echo.
echo Instructions:
echo 1. Select all the JSON above (Ctrl+A)
echo 2. Copy it (Ctrl+C)
echo 3. Go to Render Dashboard - Environment tab
echo 4. Add new environment variable:
echo    Key: FIREBASE_CREDENTIALS
echo    Value: (paste the JSON)
echo 5. Save and redeploy
echo.
pause

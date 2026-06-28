# 🔧 Troubleshooting Guide

## Common Issues and Solutions

---

## 1. GitHub Push Issues

### ❌ "Secret detected" error
**Solution**: Already fixed! We created a clean commit without secrets.

### ❌ "File too large" error  
**Solution**: APK files are now in `.gitignore` and won't be pushed.

### ✅ How to verify push succeeded:
```bash
git log --oneline -1
# Should show: "Clean commit: GoHelper app with OSM search..."
```

---

## 2. Render Deployment Issues

### ❌ Build fails with "requirements.txt not found"
**Problem**: Root directory not set correctly  
**Solution**: 
- In Render dashboard → Settings
- Set **Root Directory** to: `admin_portal`
- Click **Save Changes**
- Redeploy

### ❌ "Firebase not initialized" or "serviceAccountKey.json not found"
**Problem**: Missing environment variable  
**Solution**:
1. Run `GET_FIREBASE_CREDENTIALS.bat`
2. Copy the entire JSON output
3. In Render dashboard → Environment tab
4. Add variable:
   - Key: `FIREBASE_CREDENTIALS`
   - Value: (paste the JSON)
5. Click **Save Changes**
6. Service will auto-redeploy

### ❌ "Invalid JSON" error
**Problem**: Environment variable has formatting issues  
**Solution**:
- Make sure JSON is on ONE LINE
- No extra quotes around the JSON
- Copy EXACTLY from serviceAccountKey.json
- Should start with `{` and end with `}`

### ❌ Build is stuck or timing out
**Problem**: Free tier can be slow  
**Solution**:
- Wait 10 minutes for first build
- Check logs for actual errors
- If truly stuck, cancel and redeploy

### ❌ Service shows "Live" but URL shows error
**Problem**: Runtime error in Python code  
**Solution**:
- Click **Logs** in Render dashboard
- Look for Python error messages
- Check for missing environment variables

---

## 3. Admin Portal Runtime Issues

### ❌ Dashboard shows "Firebase not found"
**Check**:
1. Is `FIREBASE_CREDENTIALS` environment variable set?
2. In Render → Environment → look for `FIREBASE_CREDENTIALS`
3. If missing, add it and redeploy

### ❌ Dashboard shows zeros for all counts
**Possible causes**:
1. Firebase credentials incorrect
2. No data in Firebase yet
3. Network/API issues

**Solution**:
- Check Render logs for Firebase connection errors
- Verify Firebase credentials are correct
- Test that Firebase project has data

### ❌ "AUTH ERROR: System clock may be out of sync"
**Solution**:
- This happens on Render sometimes
- Usually resolves itself in a few minutes
- If persistent, check Render status page

---

## 4. Flutter App Issues

### ❌ Location search not working
**Check**:
- Internet connection required
- Using OpenStreetMap Nominatim API (free, no key needed)
- Type at least 2 characters to trigger search

### ❌ APK not installing on phone
**Possible causes**:
- Need to enable "Install from Unknown Sources"
- APK corrupted during transfer

**Solution**:
- Settings → Security → Enable Unknown Sources
- Re-copy APK file from:
  ```
  e:\go_helper\go_helper\build\app\outputs\flutter-apk\app-release.apk
  ```

### ❌ Need to rebuild APK
**Solution**:
```bash
cd e:\go_helper\go_helper
flutter clean
flutter build apk --release
```

---

## 5. Local Admin Portal Issues

### ❌ Run_Admin_Portal.bat fails
**Check**:
1. Python installed? `python --version`
2. In correct directory?
3. serviceAccountKey.json exists in admin_portal folder?

**Solution**:
```bash
cd e:\go_helper\admin_portal
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

### ❌ "Port already in use" error
**Solution**:
- Another service using port 8000
- Stop other service or change port:
  ```bash
  python main.py --port 8001
  ```

---

## 6. Git Issues

### ❌ Can't push - "rejected"
**Solution**:
```bash
git pull origin main
git push origin main
```

### ❌ Accidentally committed secrets
**Solution**: Already fixed! But if it happens again:
```bash
# Add to .gitignore first
echo "admin_portal/serviceAccountKey.json" >> .gitignore

# Create clean branch
git checkout --orphan clean-main
git add .
git commit -m "Clean commit"
git push origin clean-main:main --force
```

### ❌ Need to undo last commit
**Solution**:
```bash
git reset --soft HEAD~1  # Keeps changes
# or
git reset --hard HEAD~1  # Discards changes
```

---

## 📞 Still Stuck?

### Check These Files:
1. `GITHUB_PUSH_SUCCESS.md` - GitHub status
2. `RENDER_DEPLOYMENT_STEPS.md` - Deployment guide
3. `DEPLOY_QUICK_START.md` - Quick reference
4. `ARCHITECTURE.md` - Project structure

### Logs to Check:
- **Render Logs**: Render dashboard → Logs tab
- **Local Logs**: Terminal output when running admin portal
- **Git Status**: `git status` and `git log`

### Verify Setup:
```bash
# Check git status
git status

# Check remote
git remote -v

# Check deployed files
git ls-files | findstr admin_portal

# Verify no secrets
git ls-files | findstr serviceAccountKey
# (should show nothing)
```

---

## ✅ Quick Health Check

Run these commands to verify everything is OK:

```bash
# 1. Check git is clean
git status

# 2. Check secrets are excluded
git ls-files | findstr serviceAccountKey
# Should be empty!

# 3. Check admin portal files exist
dir admin_portal\*.py

# 4. Check deployment configs exist
dir admin_portal\render.yaml
dir admin_portal\Procfile
dir admin_portal\requirements.txt
```

All good? Time to deploy! 🚀

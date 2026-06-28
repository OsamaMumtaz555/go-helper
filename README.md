# 🚗 GoHelper - Ride Sharing App

A complete ride-sharing solution with Flutter mobile app and Python admin portal.

**Repository**: https://github.com/OsamaMumtaz555/go-helper

---

## 📱 Features

### Mobile App (Flutter)
- 🗺️ **OpenStreetMap Integration** - Real-time location search (FREE, no API key)
- 👤 **Dual User Types** - Customer & Driver modes
- 🚕 **Multiple Services** - Bike, Car, Cab, Courier, Mechanic
- 💰 **Real-time Fare Calculation** - Distance-based pricing
- 💬 **In-app Chat** - Driver-Customer communication
- 📍 **GPS Tracking** - Real-time ride tracking
- 📜 **Ride History** - Track all past rides
- 🔔 **Push Notifications** - Ride updates
- 🔐 **Firebase Auth** - Secure authentication

### Admin Portal (Python/FastAPI)
- 📊 **Dashboard** - Real-time stats and analytics
- ✅ **Driver Approval** - Review and approve driver applications
- 👥 **User Management** - View customers and drivers
- 🚗 **Ride Monitoring** - Active rides tracking
- 🔄 **REST API** - Fast Firebase integration
- 🌐 **Web Interface** - Modern responsive design

---

## 🚀 Quick Start

### 📲 Install Mobile App

**APK Location:**
```
e:\go_helper\go_helper\build\app\outputs\flutter-apk\app-release.apk
```

**To install:**
1. Copy APK to your Android phone
2. Enable "Install from Unknown Sources"
3. Tap APK to install

### 🖥️ Run Admin Portal Locally

**Easy way:**
```batch
Run_Admin_Portal.bat
```

**Manual way:**
```bash
cd admin_portal
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

Open: http://localhost:8000

---

## ☁️ Deploy Admin Portal

### Quick Deploy to Render (FREE)

**Step 1**: Code is already on GitHub ✅

**Step 2**: Follow the guide
- See: `RENDER_DEPLOYMENT_STEPS.md`
- Or: `DEPLOY_QUICK_START.md`

**Step 3**: Get Firebase credentials
```batch
GET_FIREBASE_CREDENTIALS.bat
```

**Step 4**: Deploy on Render
1. Sign up at https://render.com
2. Create Web Service from GitHub
3. Set Root Directory: `admin_portal`
4. Add `FIREBASE_CREDENTIALS` environment variable
5. Deploy!

**Full instructions**: See `DEPLOY_ADMIN_PORTAL.md`

---

## 📂 Project Structure

```
go_helper/
├── go_helper/              # Flutter mobile app
│   ├── lib/
│   │   ├── screens/        # All app screens
│   │   ├── services/       # API services (Firebase, OSM)
│   │   ├── shared/         # Reusable widgets
│   │   └── utils/          # Helper functions
│   ├── android/            # Android config
│   ├── ios/                # iOS config
│   └── pubspec.yaml        # Dependencies
│
├── admin_portal/           # Python admin dashboard
│   ├── main.py             # FastAPI server
│   ├── templates/          # HTML templates
│   ├── requirements.txt    # Python dependencies
│   ├── render.yaml         # Render config
│   ├── Procfile            # Start command
│   └── runtime.txt         # Python version
│
└── Documentation/
    ├── ARCHITECTURE.md              # Complete architecture
    ├── GITHUB_PUSH_SUCCESS.md       # Git status
    ├── RENDER_DEPLOYMENT_STEPS.md   # Deploy guide
    ├── DEPLOY_QUICK_START.md        # Quick deploy
    ├── OSM_LOCATION_SEARCH.md       # Location search
    └── TROUBLESHOOTING.md           # Common issues
```

---

## 🛠️ Tech Stack

### Mobile App
- **Framework**: Flutter 3.x
- **Language**: Dart
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Maps**: OpenStreetMap + Nominatim API
- **State**: Provider pattern

### Admin Portal
- **Framework**: FastAPI (Python)
- **Template**: Jinja2
- **Database**: Firebase Firestore
- **Deployment**: Render.com
- **API**: REST with Firebase Admin SDK

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| `README.md` (this file) | Project overview |
| `ARCHITECTURE.md` | Complete project structure |
| `GITHUB_PUSH_SUCCESS.md` | Git push status |
| `RENDER_DEPLOYMENT_STEPS.md` | Step-by-step deployment |
| `DEPLOY_QUICK_START.md` | 5-minute deploy guide |
| `DEPLOY_ADMIN_PORTAL.md` | Full deployment docs |
| `OSM_LOCATION_SEARCH.md` | Location search feature |
| `TROUBLESHOOTING.md` | Common issues & fixes |
| `BUILD_SUCCESS.md` | Build instructions |

---

## 🔧 Development

### Build Android APK
```bash
cd go_helper
flutter clean
flutter build apk --release
```

APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### Run Flutter App (Development)
```bash
cd go_helper
flutter run
```

### Test Admin Portal Locally
```bash
cd admin_portal
python main.py
```

---

## 🔐 Security

### ✅ What's Protected
- Firebase credentials (in `.gitignore`)
- APK files (too large, excluded)
- Environment variables (for deployment)
- Clean git history (no secrets in commits)

### 🔒 Environment Variables

For Render deployment, set these:

| Variable | Source | Required |
|----------|--------|----------|
| `FIREBASE_CREDENTIALS` | Copy from `serviceAccountKey.json` | Yes |
| `PORT` | Auto-set by Render | Auto |
| `PYTHON_VERSION` | Set in `runtime.txt` | Auto |

---

## 📊 Features Checklist

### Mobile App
- [x] User authentication (Email/Password)
- [x] Customer mode
- [x] Driver mode
- [x] Real-time location search (OSM)
- [x] Multiple ride services
- [x] Fare calculation
- [x] Driver matching
- [x] In-app chat
- [x] Ride history
- [x] Profile management
- [x] Push notifications

### Admin Portal
- [x] Dashboard with stats
- [x] Driver approval system
- [x] User management
- [x] Ride monitoring
- [x] Real-time updates
- [x] REST API integration
- [x] Responsive design
- [x] Deployment ready

---

## 🚀 Deployment Status

| Component | Status | URL |
|-----------|--------|-----|
| GitHub Repo | ✅ Live | https://github.com/OsamaMumtaz555/go-helper |
| Mobile App | ✅ Built | APK available locally |
| Admin Portal (Local) | ✅ Ready | Run `Run_Admin_Portal.bat` |
| Admin Portal (Cloud) | ⏳ Pending | Follow `RENDER_DEPLOYMENT_STEPS.md` |

---

## 🐛 Troubleshooting

Having issues? Check `TROUBLESHOOTING.md` for:
- GitHub push problems
- Render deployment errors
- Admin portal issues
- Mobile app problems
- Common fixes

---

## 📝 Git Workflow

### Make Changes
```bash
# Edit your files
git add .
git commit -m "Description of changes"
git push origin main
```

### Check Status
```bash
git status
git log --oneline -5
```

### Verify No Secrets
```bash
git ls-files | findstr serviceAccountKey
# Should show nothing!
```

---

## 📞 Support

- **Repository**: https://github.com/OsamaMumtaz555/go-helper
- **Issues**: Use GitHub Issues tab
- **Docs**: See Documentation folder
- **Render Support**: https://render.com/docs

---

## 🎉 What's Working

✅ Flutter app with all features  
✅ OSM location search (FREE)  
✅ Firebase integration  
✅ Admin portal with real-time data  
✅ Code on GitHub (no secrets)  
✅ Deployment configs ready  
✅ Complete documentation  
✅ Local development setup  
✅ APK built and ready  

---

## 🔜 Next Steps

1. **Deploy Admin Portal** (10 minutes)
   - Follow `RENDER_DEPLOYMENT_STEPS.md`
   - Get FREE hosting on Render
   
2. **Test Everything**
   - Install APK on phone
   - Test location search
   - Create test ride
   - Check admin portal

3. **Share App**
   - Share APK file
   - Or publish to Play Store
   - Or use Firebase App Distribution

---

## 📄 License

Private project - All rights reserved

---

## 👤 Author

**Osama Mumtaz**
- GitHub: [@OsamaMumtaz555](https://github.com/OsamaMumtaz555)
- Repository: [go-helper](https://github.com/OsamaMumtaz555/go-helper)

---

**Built with ❤️ using Flutter & Python**

Last updated: June 28, 2026

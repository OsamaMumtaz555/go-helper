# Google Maps API Setup Guide

## 🗺️ Enable Real Location Search

The app now supports **real-time location search** using Google Places API instead of hardcoded cities. Follow these steps to enable it:

---

## Step 1: Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the following APIs:
   - **Places API**
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Geocoding API**

4. Go to **Credentials** → **Create Credentials** → **API Key**
5. Copy your API key

---

## Step 2: Configure Android

### Add API Key to AndroidManifest.xml

Open: `go_helper/android/app/src/main/AndroidManifest.xml`

Add inside `<application>` tag:

```xml
<application>
    ...
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
</application>
```

---

## Step 3: Configure iOS

### Add API Key to AppDelegate.swift

Open: `go_helper/ios/Runner/AppDelegate.swift`

Add at the top:
```swift
import GoogleMaps
```

Update the `application` function:
```swift
override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
```

---

## Step 4: Add API Key to Flutter Code

### Option A: Hardcode (Quick Testing)

Open: `go_helper/lib/services/places_service.dart`

Replace:
```dart
static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
```

With:
```dart
static const String _apiKey = 'AIzaSyC-xxxxxxxxxxxxxxxxxxxxxxxxxxx';
```

### Option B: Environment Variable (Production - Recommended)

1. Create `.env` file in `go_helper/`:
```
GOOGLE_MAPS_API_KEY=AIzaSyC-xxxxxxxxxxxxxxxxxxxxxxxxxxx
```

2. Add to `.gitignore`:
```
*.env
```

3. Update `places_service.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

static String get apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
```

4. Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0

flutter:
  assets:
    - .env
```

5. Load in `main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load();
  runApp(MyApp());
}
```

---

## Step 5: Install Dependencies

```bash
cd go_helper
flutter pub get
```

---

## Step 6: Restrict API Key (Security)

### For Android
1. Go to Google Cloud Console → Credentials
2. Click your API key
3. Under "Application restrictions":
   - Select "Android apps"
   - Add your package name: `com.example.go_helper`
   - Add your SHA-1 fingerprint:
   
```bash
# Get SHA-1
cd android
./gradlew signingReport
```

### For iOS
1. Under "Application restrictions":
   - Select "iOS apps"
   - Add your bundle ID: `com.example.goHelper`

### API Restrictions
- Enable only these APIs:
  - Places API
  - Geocoding API
  - Maps SDK for Android
  - Maps SDK for iOS

---

## Step 7: Test the Feature

1. Run the app:
```bash
flutter run
```

2. Go to **Home → Find Ride**
3. Tap on the location field
4. Type any address (e.g., "Blue Area Islamabad")
5. You should see real Google Places suggestions!

---

## 🆓 Free Tier Limits

Google provides free monthly quota:
- **Places Autocomplete**: $0 for first 1,000 requests/month
- **Place Details**: First 1,000 free
- **Geocoding**: First 40,000 free

For small/medium apps, you'll likely stay within free limits.

---

## 🔒 Security Best Practices

1. **Never commit API keys to Git**
   - Use `.env` files
   - Add to `.gitignore`

2. **Restrict API key usage**
   - Limit to your app's package name
   - Enable only required APIs

3. **Monitor usage**
   - Set up billing alerts
   - Check Google Cloud Console regularly

4. **Use backend proxy (Production)**
   - Call Places API from your backend
   - Prevents key exposure in client app

---

## 🐛 Troubleshooting

### "API key not found" error
- Check if key is added to AndroidManifest.xml / AppDelegate.swift
- Verify `places_service.dart` has the key

### "This API project is not authorized" error
- Enable Places API in Google Cloud Console
- Wait 5-10 minutes after enabling

### No search results
- Check internet connection
- Verify API key restrictions allow your app
- Check API quotas in Google Cloud Console

### iOS build fails
- Run `pod install` in ios folder
- Update Podfile if needed

---

## 📱 Features Enabled

✅ Real-time place search (worldwide, default Pakistan)
✅ GPS current location detection
✅ Address suggestions as you type
✅ Place details with coordinates
✅ Reverse geocoding (lat/lng to address)

---

## 🚀 Next Steps

Once configured, users can:
1. Search **any real location** (not just cities)
2. Find specific addresses, landmarks, businesses
3. Get accurate coordinates for navigation
4. Use current GPS location
5. Search across Pakistan or worldwide

---

## 📞 Need Help?

If you encounter issues:
1. Check [Google Maps Platform Documentation](https://developers.google.com/maps/documentation)
2. Verify API key configuration
3. Check app logs for detailed errors
4. Ensure billing is enabled on Google Cloud (required even for free tier)

---

**Last Updated**: June 3, 2026

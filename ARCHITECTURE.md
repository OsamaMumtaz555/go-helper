# Go Helper - Complete Project Architecture

## 📋 Project Overview
**Go Helper** is a comprehensive ride-hailing and vehicle service platform with separate interfaces for customers, drivers, and administrators. The project consists of a Flutter mobile application and a Python-based admin web portal.

---

## 🏗️ High-Level Architecture

```
go-helper/
├── go_helper/              # Flutter Mobile Application (Customer & Driver)
├── admin_portal/           # Python Web Admin Portal
├── Run_Admin_Portal.bat    # Windows launcher for admin portal
└── ARCHITECTURE.md         # This file
```

---

## 📱 Flutter Mobile Application Structure

### **Root Level** (`go_helper/`)
```
go_helper/
├── lib/                    # Main application code
├── android/                # Android-specific configuration
├── ios/                    # iOS-specific configuration
├── assets/                 # Images, fonts, and static resources
├── test/                   # Unit and widget tests
├── pubspec.yaml            # Flutter dependencies and configuration
└── .gitignore              # Git ignore rules
```

---

## 📂 Detailed Folder Structure

### **1. lib/** - Main Application Code

#### **Entry Points**
```
lib/
├── main.dart               # Application entry point, Firebase initialization
└── app.dart                # Root widget, theme configuration, routing setup
```

#### **2. lib/screens/** - UI Screens (Feature-based organization)

##### **Authentication Screens** (`screens/auth/`)
```
screens/auth/
├── welcome_screen.dart              # Initial landing page with branding
├── onboarding_screen.dart           # Feature introduction carousel
├── login_screen.dart                # Email/password login for customers
├── signup_screen.dart               # Customer registration
├── driver_signup_screen.dart        # Driver/partner registration with vehicle info
├── driver_pending_screen.dart       # Waiting screen for driver approval status
└── forget_password/
    ├── forgot_password_email.dart   # Email input for password reset
    ├── forgot_password_otp.dart     # OTP verification
    └── create_new_password.dart     # New password creation
```

**Purpose**: Handle user authentication, onboarding, and account recovery.

##### **Home Screens** (`screens/home/`)
```
screens/home/
├── home_screen.dart         # Main customer dashboard with service categories
├── services_tab.dart        # Service selection interface
└── alerts_screen.dart       # Notifications and alerts display
```

**Purpose**: Primary navigation hub for customers to access services.

##### **Ride Management** (`screens/rides/`)
```
screens/rides/
├── serviceselection_screen.dart     # Choose ride type (bike, car, rickshaw)
├── findride_screen.dart             # Real-time driver matching with map
├── ride_history_screen.dart         # Past rides with details and receipts
├── cancel_ride_reason_screen.dart   # Cancellation flow with reason selection
└── ride_started/
    ├── ride_started_screen.dart     # Active ride tracking interface
    └── widgets/
        ├── driver_info_section.dart # Driver details card
        ├── chat_section.dart        # In-ride messaging
        └── blue_dotted_divider.dart # Visual separator
```

**Purpose**: Complete ride lifecycle from booking to completion.

##### **Driver Screens** (`screens/driver/`)
```
screens/driver/
├── driver_home_screen.dart   # Driver dashboard with online/offline toggle
├── driver_ride_screen.dart   # Active ride management for drivers
├── vehicle_info_screen.dart  # Vehicle registration and details
└── earnings_screen.dart      # Driver earnings and payment history
```

**Purpose**: Driver-specific features for ride acceptance and management.

##### **Profile & Settings** (`screens/profile/`, `screens/settings/`)
```
screens/profile/
└── profile_screen.dart       # User profile with personal info

screens/settings/
└── settings_screen.dart      # App preferences and account settings
```

##### **Support & Promos** (`screens/support/`, `screens/promos/`)
```
screens/support/
└── help_support_screen.dart  # Help center and customer support

screens/promos/
└── promos_screen.dart        # Promotional offers and discounts
```

##### **Admin Screens** (`screens/admin/`)
```
screens/admin/
├── admin_login_screen.dart      # Admin authentication
└── admin_dashboard_screen.dart  # Admin overview (redirects to web portal)
```

**Purpose**: Admin access point (main admin features are in the web portal).

##### **Miscellaneous** (`screens/misc/`)
```
screens/misc/
└── placeholder_screen.dart   # Generic placeholder for future features
```

---

#### **3. lib/shared/** - Reusable Components

##### **Layouts** (`shared/layouts/`)
```
shared/layouts/
└── bottom_nav_bar.dart       # Bottom navigation with Home, Rides, Promos, Profile
```

##### **Widgets** (`shared/widgets/`)
```
shared/widgets/
├── AppDrawer.dart                   # Side navigation drawer
├── map_container.dart               # Google Maps integration wrapper
├── ultra_minimal_from_to.dart       # Pickup/dropoff location selector
├── blue_dotted_divider.dart         # Styled divider component
├── category_section.dart            # Service category cards
├── driver_request_card.dart         # Driver info card in ride booking
├── drivers_viewing_section.dart     # Available drivers list
└── fare_adjustment_section.dart     # Fare breakdown display
```

**Purpose**: Reusable UI components used across multiple screens.

---

#### **4. lib/services/** - Business Logic & API Integration

```
services/
└── auth_service.dart         # Firebase Authentication wrapper
                              # - User login/signup
                              # - Password reset
                              # - Session management
```

**Purpose**: Centralized service layer for backend communication.

---

#### **5. lib/model/** - Data Models

```
model/
├── driver_request_model.dart # Driver profile and ride request data
└── chat_message.dart         # In-ride chat message structure
```

**Purpose**: Data classes for type-safe data handling.

---

#### **6. lib/utils/** - Utilities & Constants

```
utils/
├── fare_calculator.dart      # Dynamic fare calculation logic
└── Constants/
    ├── colors.dart           # App color palette
    ├── text_strings.dart     # Localized text constants
    ├── image_strings.dart    # Asset path constants
    └── shadow.dart           # Shadow style definitions
```

**Purpose**: Helper functions and app-wide constants.

---

#### **7. lib/features/** - Feature Modules (Future Expansion)

```
features/
└── authentication/
    └── controllers.onboarding/  # Onboarding state management (placeholder)
```

**Purpose**: Modular feature organization for scalability.

---

## 🌐 Admin Web Portal Structure

### **admin_portal/** - Python FastAPI Application

```
admin_portal/
├── main.py                      # FastAPI server with REST endpoints
├── requirements.txt             # Python dependencies
├── serviceAccountKey.json       # Firebase Admin SDK credentials
├── .env                         # Environment variables
├── start_admin.ps1              # PowerShell launcher script
├── templates/
│   └── index.html               # Admin dashboard UI (single-page app)
└── test scripts/
    ├── add_test_driver.py       # Seed test driver data
    ├── check_drivers.py         # Verify driver records
    ├── check_native.py          # Test native Firebase connection
    ├── check_real_data.py       # Validate production data
    ├── inspect_db.py            # Database inspection tool
    ├── rest_direct.py           # REST API testing
    ├── sample_db.py             # Sample data generator
    ├── test_auth_final.py       # Auth flow testing
    ├── test_fb.py               # Firebase connectivity test
    └── test_fb3.py              # Advanced Firebase tests
```

### **Admin Portal Features**

#### **main.py** - Core Backend
- **REST API Endpoints**:
  - `GET /` - Dashboard with live statistics
  - `GET /api/stats` - Real-time counts (users, drivers, rides)
  - `GET /api/dashboard` - Complete dashboard data
  - `POST /approve-driver/{uid}` - Approve pending driver
  - `POST /reject-driver/{uid}` - Reject driver application
  - `POST /revoke-driver/{uid}` - Revoke driver approval

- **Custom REST Firestore Client**:
  - Bypasses gRPC issues on Windows
  - Token caching for performance
  - In-memory filtering for speed

- **Background Data Sync**:
  - 20-second refresh cycle
  - Caches driver lists (pending, approved, rejected)
  - Active ride monitoring

#### **templates/index.html** - Frontend Dashboard
- **Live Statistics Cards**:
  - Total users
  - Active drivers
  - Pending approvals
  - Active rides
  - Rejected drivers

- **Driver Management Tabs**:
  - Pending: Review and approve/reject
  - Approved: View active drivers, revoke access
  - Rejected: Review rejected applications

- **Real-time Updates**:
  - Auto-refresh every 20 seconds
  - Live ride activity feed
  - Driver status changes

---

## 🔥 Firebase Backend Structure

### **Firestore Collections**

```
Firestore Database
├── users/                          # User accounts
│   ├── {userId}/
│   │   ├── email: string
│   │   ├── fullName: string
│   │   ├── phone: string
│   │   ├── userType: "customer" | "driver"
│   │   ├── status: "pending" | "approved" | "rejected"  # For drivers
│   │   ├── vehicleModel: string    # Driver only
│   │   ├── licensePlate: string    # Driver only
│   │   └── serviceType: string     # Driver only
│
├── rides/                          # Ride records
│   ├── {rideId}/
│   │   ├── customerId: string
│   │   ├── driverId: string
│   │   ├── status: "pending" | "accepted" | "picking" | "on_ride" | "completed" | "cancelled"
│   │   ├── pickupLocation: GeoPoint
│   │   ├── dropoffLocation: GeoPoint
│   │   ├── fare: number
│   │   ├── serviceType: string
│   │   ├── createdAt: timestamp
│   │   └── completedAt: timestamp
│
└── chats/                          # In-ride messaging
    └── {rideId}/
        └── messages/
            ├── {messageId}/
            │   ├── senderId: string
            │   ├── text: string
            │   └── timestamp: timestamp
```

### **Firebase Authentication**
- Email/password authentication
- User role management (customer, driver, admin)
- Password reset flow

### **Firebase Storage** (Future)
- Driver license photos
- Vehicle registration documents
- Profile pictures

---

## 🎨 Design System

### **Color Palette** (`utils/Constants/colors.dart`)
- **Primary**: Blue accent for CTAs
- **Secondary**: Supporting colors
- **Status Colors**: Success (green), warning (amber), error (red)
- **Neutrals**: Grays for text and backgrounds

### **Typography**
- **Headings**: Bold, large sizes
- **Body**: Regular weight, readable sizes
- **Captions**: Small, muted colors

### **Components**
- **Cards**: Elevated with shadows
- **Buttons**: Rounded, full-width primary actions
- **Forms**: Outlined text fields with validation
- **Maps**: Full-screen with overlays

---

## 🔄 User Flows

### **Customer Flow**
1. **Onboarding** → Welcome → Login/Signup
2. **Home** → Select service category
3. **Service Selection** → Choose vehicle type
4. **Find Ride** → Enter locations → Match with driver
5. **Ride Started** → Track in real-time → Chat with driver
6. **Ride Complete** → Rate driver → View receipt

### **Driver Flow**
1. **Signup** → Enter vehicle details → Submit for approval
2. **Pending** → Wait for admin approval
3. **Approved** → Driver Home → Toggle online
4. **Ride Request** → Accept → Navigate to pickup
5. **Ride Active** → Update status → Complete ride
6. **Earnings** → View payment history

### **Admin Flow**
1. **Admin Login** → Access web portal
2. **Dashboard** → View live statistics
3. **Driver Approvals** → Review pending applications
4. **Approve/Reject** → Update driver status
5. **Monitor** → Track active rides and users

---

## 🛠️ Technology Stack

### **Mobile App**
- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: StatefulWidget (can migrate to Provider/Riverpod)
- **Maps**: Google Maps Flutter
- **Backend**: Firebase (Auth, Firestore, Cloud Functions)
- **Real-time**: Firestore listeners

### **Admin Portal**
- **Backend**: Python 3.13 + FastAPI
- **Frontend**: HTML/CSS/JavaScript (Vanilla)
- **Database**: Firebase Firestore (REST API)
- **Auth**: Firebase Admin SDK
- **Server**: Uvicorn ASGI

### **Build Tools**
- **Android**: Gradle 8.11.1, AGP 8.9.1, Kotlin 2.1.0
- **iOS**: CocoaPods, Xcode
- **Admin**: pip, virtual environment

---

## 📦 Dependencies

### **Flutter** (`pubspec.yaml`)
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.10.0
  firebase_auth: ^5.3.4
  cloud_firestore: ^5.6.0
  google_maps_flutter: ^2.10.0
  geolocator: ^13.0.2
  intl: ^0.20.1
  flutter_native_splash: ^2.4.3
```

### **Admin Portal** (`requirements.txt`)
```
fastapi
uvicorn
firebase-admin
python-multipart
jinja2
python-dotenv
```

---

## 🚀 Running the Project

### **Mobile App**
```bash
cd go_helper
flutter pub get
flutter run
```

### **Admin Portal**
```bash
# Windows
Run_Admin_Portal.bat

# Manual
cd admin_portal
pip install -r requirements.txt
python main.py
# Access at http://localhost:8000
```

### **Build APK**
```bash
cd go_helper
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk
```

---

## 🔐 Security Considerations

1. **Firebase Rules**: Implement Firestore security rules
2. **API Keys**: Store in environment variables
3. **Admin Access**: Separate authentication for admin portal
4. **Data Validation**: Server-side validation for all inputs
5. **HTTPS**: Use SSL for admin portal in production

---

## 📈 Future Enhancements

### **Mobile App**
- [ ] Push notifications for ride updates
- [ ] In-app payments (Stripe/PayPal)
- [ ] Driver ratings and reviews
- [ ] Ride scheduling
- [ ] Multi-language support
- [ ] Dark mode

### **Admin Portal**
- [ ] Advanced analytics dashboard
- [ ] User management (ban/suspend)
- [ ] Fare configuration
- [ ] Promo code management
- [ ] Export reports (CSV/PDF)
- [ ] Real-time ride tracking map

### **Backend**
- [ ] Cloud Functions for automated workflows
- [ ] Firebase Cloud Messaging
- [ ] Automated driver verification
- [ ] Payment processing integration
- [ ] Ride matching algorithm optimization

---

## 📝 File Naming Conventions

- **Screens**: `{feature}_screen.dart` (e.g., `login_screen.dart`)
- **Widgets**: `{component}_widget.dart` or descriptive name
- **Models**: `{entity}_model.dart` (e.g., `driver_request_model.dart`)
- **Services**: `{service}_service.dart` (e.g., `auth_service.dart`)
- **Constants**: Lowercase with underscores (e.g., `colors.dart`)

---

## 🤝 Contributing Guidelines

1. Follow Flutter style guide
2. Use meaningful commit messages
3. Test on both Android and iOS
4. Update this architecture doc for major changes
5. Keep dependencies up to date

---

## 📞 Support

For issues or questions:
- GitHub: https://github.com/OsamaMumtaz555/go-helper
- Admin Portal: http://localhost:8000

---

**Last Updated**: May 22, 2026
**Version**: 1.0.0
**Maintained by**: Go Helper Development Team

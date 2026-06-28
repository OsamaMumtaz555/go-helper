import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_helper/screens/auth/driver_pending_screen.dart';
import 'package:go_helper/screens/driver/driver_home_screen.dart';
import 'package:go_helper/screens/admin/admin_dashboard_screen.dart';
import 'package:go_helper/screens/auth/driver_signup_screen.dart';
import 'package:go_helper/screens/auth/forget_password/forgot_password_email.dart';
import 'package:go_helper/screens/home/home_screen.dart';
import 'package:go_helper/screens/auth/login_screen.dart';
import 'package:go_helper/screens/auth/onboarding_screen.dart';
import 'package:go_helper/screens/auth/signup_screen.dart';
import 'package:go_helper/screens/auth/welcome_screen.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:go_helper/services/auth_service.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      print("Firebase initialization error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: HColors.primary,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'Loading Go Helper...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'GoHelper',
      debugShowCheckedModeBanner: false,
      theme: _buildThemeData(),
      home: const RootWrapper(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/driver-signup': (context) => const DriverSignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordEmailScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/driver-home': (context) => const DriverHomeScreen(),
      },
    );
  }

  ThemeData _buildThemeData() {
    return ThemeData(
      primaryColor: HColors.primary,
      scaffoldBackgroundColor: Colors.white,
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: HColors.primary,
        primary: HColors.primary,
        secondary: HColors.secondary,
        background: Colors.white,
        surface: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HColors.greyshade),
        ),
      ),
    );
  }
}

class RootWrapper extends StatelessWidget {
  const RootWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Logged in - now check role with realtime updates
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final userType = userData['userType'] ?? 'customer';

                if (userType == 'driver') {
                  final isApprovedField = userData['isApproved'] == true;
                  final driverStatus = userData['status'] ?? 'pending';
                  
                  // Support both the manual flag and the status-based approval
                  if (isApprovedField || driverStatus == 'approved') {
                    return const DriverHomeScreen();
                  } else if (driverStatus == 'rejected') {
                    return const DriverPendingScreen(status: 'rejected');
                  } else {
                    // pending — show waiting screen
                    return const DriverPendingScreen(status: 'pending');
                  }
                } else if (userType == 'admin') {
                  return const AdminDashboardScreen();
                } else {
                  return const HomeScreen();
                }
              }
              
              // Fallback if doc doesn't exist yet
              return const HomeScreen();
            },
          );
        } else {
          // Not logged in
          return const OnboardingScreen();
        }
      },
    );
  }
}

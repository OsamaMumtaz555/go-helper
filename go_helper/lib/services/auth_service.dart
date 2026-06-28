import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// This class is the "Brain" of the app. It handles security, logins, and the database.
class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance; // Handles "Keys" or Passwords
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Handles "Records" or Folders

  // GoogleSignIn 5.4.2 uses constructor with optional parameters
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );

  // ========== GOOGLE SIGN IN ==========
  Future<User?> signInWithGoogle() async {
    try {
      print("🚀 Google SignIn starting...");

      // 1. Sign out first if already signed in (clean state)
      if (_googleSignIn.currentUser != null) {
        await _googleSignIn.signOut();
      }

      // 2. Trigger Google SignIn
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print("❌ User cancelled Google SignIn");
        return null;
      }

      print("✅ Google user received: ${googleUser.email}");

      // 3. Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print(
        "✅ Google auth received - Access Token: ${googleAuth.accessToken != null}",
      );
      print("✅ Google auth received - ID Token: ${googleAuth.idToken != null}");

      // 4. Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("✅ Firebase credential created");

      // 5. Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      print("✅ Firebase sign in successful");
      print("✅ User UID: ${userCredential.user?.uid}");

      // 6. Check if user exists in Firestore
      final user = userCredential.user;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          print("💾 New Google user, saving to Firestore...");

          // New user - Save to Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email ?? '',
            'fullName': user.displayName ?? 'Google User',
            'phone': user.phoneNumber ?? '',
            'userType': 'customer',
            'createdAt': DateTime.now(),
            'profileCompleted': false,
            'photoURL': user.photoURL ?? '',
            'provider': 'google',
            'emailVerified': user.emailVerified,
          });

          print("✅ User saved to Firestore");
        } else {
          print("✅ Existing Google user found in Firestore");
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("❌ Google SignIn Firebase Error: ${e.code} - ${e.message}");

      // Handle specific Google sign in errors
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
              'An account already exists with the same email address but different sign-in credentials.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid authentication credentials.';
          break;
        case 'operation-not-allowed':
          errorMessage =
              'Google sign in is not enabled. Please contact support.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        default:
          errorMessage = _getAuthErrorMessage(e.code);
      }

      throw errorMessage;
    } catch (e) {
      print("❌ Google SignIn Error: $e");
      throw "Google sign in failed. Please try again.";
    }
  }

  // Google SignOut
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      print("✅ Google SignOut successful");
    } catch (e) {
      print("❌ Google SignOut Error: $e");
    }
  }

  // Stream of user
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // Current user getter
  User? get currentUser {
    return _auth.currentUser;
  }

  // This creates a standard Customer account
  Future<User?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String userType = 'customer',
  }) async {
    try {
      // 1. Create the secure login in the global system
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      // 2. Save the user's details (Name, Phone) into our local records
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email.trim(),
        'fullName': fullName,
        'phone': phone,
        'userType': userType,
        'createdAt': DateTime.now(),
        'profileCompleted': false,
        'provider': 'email',
        'emailVerified': false,
      });

      print("✅ User signed up ");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("❌ Sign Up Error Code: ${e.code}");
      print("❌ Sign Up Error Message: ${e.message}");
      print("❌ Sign Up Error Plugin: ${e.plugin}");
      print("❌ Sign Up Error StackTrace: ${e.stackTrace}");
      throw _getAuthErrorMessage(e.code);
    } catch (e, stackTrace) {
      print("❌ Sign Up Unknown Error: $e");
      print("❌ Sign Up Unknown StackTrace: $stackTrace");
      throw "An unknown error occurred: $e";
    }
  }

  // Sign Up Driver with Email/Password
  Future<User?> signUpDriver({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String vehicleModel,
    required String licensePlate,
    required String serviceType, // e.g., 'mechanic', 'courier'
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      // Save driver data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email.trim(),
        'fullName': fullName,
        'phone': phone,
        'userType': 'driver',
        'vehicleModel': vehicleModel,
        'licensePlate': licensePlate,
        'serviceType': serviceType,
        'isOnline': false,
        'isApproved': false, // Requires admin approval
        'status': 'pending',  // pending | approved | rejected
        'rating': 5.0,
        'totalRides': 0,
        'createdAt': DateTime.now(),
        'profileCompleted': true,
        'provider': 'email',
      });

      print("✅ Driver signed up and saved to Firestore");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("❌ Driver Sign Up Error: ${e.code} - ${e.message}");
      throw _getAuthErrorMessage(e.code);
    } catch (e) {
      print("❌ Driver Sign Up Unknown Error: $e");
      throw "An unknown error occurred: $e";
    }
  }

  // This lets a user into the app if their Email and Password match our records
  Future<User?> login(String email, String password) async {
    try {
      // Send credentials to Firebase to check if they are correct
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print("✅ User logged in: ${userCredential.user?.email}");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("❌ Login Error: ${e.code} - ${e.message}");
      throw _getAuthErrorMessage(e.code);
    } catch (e) {
      print("❌ Login Unknown Error: $e");
      throw "An unknown error occurred: $e";
    }
  }

  // Forget Password
  Future<void> forgetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      print("✅ Password reset email sent to: $email");
    } on FirebaseAuthException catch (e) {
      print("❌ Forget Password Error: ${e.code}");
      throw _getAuthErrorMessage(e.code);
    } catch (e) {
      print("❌ Forget Password Error: $e");
      throw "Failed to send reset email. Please try again.";
    }
  }

  // Sign Out (both Firebase and Google)
  Future<void> signOut() async {
    try {
      // Google sign out if signed in with Google
      if (_googleSignIn.currentUser != null) {
        await signOutGoogle();
      }

      // Firebase sign out
      await _auth.signOut();

      print("✅ Complete sign out successful");
    } catch (e) {
      print("❌ SignOut Error: $e");
      throw "Sign out failed. Please try again.";
    }
  }

  // Update User Profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      if (_auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update(data);
        print("✅ Profile updated successfully");
      }
    } catch (e) {
      print("❌ Update Profile Error: $e");
      throw "Profile update failed. Please try again.";
    }
  }

  // Get User Data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (_auth.currentUser != null) {
        DocumentSnapshot doc =
            await _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .get();

        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print("❌ Get User Data Error: $e");
      return null;
    }
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  // Get user ID
  String? getUserId() {
    return _auth.currentUser?.uid;
  }

  // Get user email
  String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  // Helper: Firebase error to user-friendly message
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign in is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      default:
        return 'An error occurred ($errorCode). Please try again.';
    }
  }
}

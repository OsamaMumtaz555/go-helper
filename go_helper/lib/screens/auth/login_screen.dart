import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_helper/services/auth_service.dart';
import 'package:go_helper/utils/Constants/shadow.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:go_helper/utils/constants/image_strings.dart';

// This is the Login Screen where users enter their email and password
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive calculations
    final logoSize = screenWidth * 0.35;
    final buttonWidth = screenWidth * 0.55;
    final buttonHeight = screenHeight * 0.065;
    final socialButtonSize = screenWidth * 0.18;
    final borderRadius = screenWidth * 0.05;
    final borderWidth = screenWidth * 0.007;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.04),

                // -- SECTION 1: App Logo --
                Image.asset(
                  HImages.appLogo,
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: screenHeight * 0.03),

                // -- SECTION 2: User Inputs (Email and Password) --
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email or Phone Number',
                    labelStyle: TextStyle(
                      color: HColors.secondary,
                      fontSize: screenWidth * 0.04,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: const BorderSide(color: HColors.primary),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.02,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email or phone number';
                    }
                    if (value.contains('@') && !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.025),

                // ========== PASSWORD FIELD ==========
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(
                      color: HColors.secondary,
                      fontSize: screenWidth * 0.04,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: HColors.primary,
                        size: screenWidth * 0.06,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: const BorderSide(color: HColors.primary),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.02,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.025),

                // ========== REMEMBER ME & FORGOT PASSWORD ==========
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value!;
                        });
                      },
                      activeColor: HColors.primary,
                    ),
                    Text(
                      'Remember me',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: HColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: HColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.04),

                // -- SECTION 3: Sign In Action --
                Container(
                  width: buttonWidth,
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: borderWidth,
                    ),
                    boxShadow: HShadows.greyShadowStrong,
                  ),
                  child: TextButton(
                    onPressed: _isLoading ? null : _signIn, // When clicked, it runs the login logic
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                    ),
                    child:
                        _isLoading
                            ? SizedBox(
                              width: screenWidth * 0.06,
                              height: screenWidth * 0.06,
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                                color: HColors.primary,
                              ),
                            )
                            : Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w600,
                                color: HColors.primary,
                              ),
                            ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),

                // ========== OR SIGN IN WITH ==========
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey.shade400, thickness: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: Text(
                        'Or sign in with',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey.shade400, thickness: 1),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),

                // ========== SOCIAL LOGIN BUTTONS ==========
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      icon: 'assets/icons/google_icon.png',
                      onPressed:
                          _isLoading
                              ? null
                              : _signInWithGoogle, // ✅ Google SignIn
                      buttonSize: socialButtonSize,
                      borderRadius: borderRadius,
                      borderWidth: borderWidth,
                      screenWidth: screenWidth,
                    ),
                    SizedBox(width: screenWidth * 0.05),
                    _buildSocialButton(
                      icon: 'assets/icons/apple_icon.png',
                      onPressed:
                          _isLoading ? null : _signInWithApple, // Placeholder
                      buttonSize: socialButtonSize,
                      borderRadius: borderRadius,
                      borderWidth: borderWidth,
                      screenWidth: screenWidth,
                    ),
                    SizedBox(width: screenWidth * 0.05),
                    _buildSocialButton(
                      icon: 'assets/icons/x_icon.png',
                      onPressed:
                          _isLoading ? null : _signInWithTwitter, // Placeholder
                      buttonSize: socialButtonSize,
                      borderRadius: borderRadius,
                      borderWidth: borderWidth,
                      screenWidth: screenWidth,
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.05),

                // ========== DON'T HAVE ACCOUNT ==========
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: HColors.primary,
                      ),
                    ),
                    TextButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                Navigator.pushNamed(context, '/signup');
                              },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w600,
                          color: HColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Social Login Button Widget
  Widget _buildSocialButton({
    required String icon,
    required VoidCallback? onPressed,
    required double buttonSize,
    required double borderRadius,
    required double borderWidth,
    required double screenWidth,
  }) {
    return Container(
      width: buttonSize,
      height: buttonSize * 0.65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey.shade300, width: borderWidth),
        boxShadow: HShadows.greyShadowStrong,
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Image.asset(
          icon,
          width: screenWidth * 0.06,
          height: screenWidth * 0.06,
        ),
      ),
    );
  }

  // ========== SIGN IN WITH GOOGLE ==========
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = await AuthService().signInWithGoogle();

      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ========== SIGN IN WITH APPLE (PLACEHOLDER) ==========
  Future<void> _signInWithApple() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apple SignIn coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // ========== SIGN IN WITH TWITTER (PLACEHOLDER) ==========
  Future<void> _signInWithTwitter() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Twitter SignIn coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // This is the logical core that connects to Firebase to check credentials
  Future<void> _signIn() async {
    // 1. First, make sure the user filled everything correctly
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Show a loading circle so the user knows it's working
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // 3. We send the email/password to Firebase for verification
      User? user = await AuthService().login(email, password);

      if (user != null) {
        // 4. If correct, take them to the Home Page
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      // 5. If something is wrong (like a bad password), show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      // 6. Stop showing the loading circle
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

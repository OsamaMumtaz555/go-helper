import 'package:flutter/material.dart';
import 'package:go_helper/services/auth_service.dart'; // AuthService import karein
import 'package:go_helper/utils/constants/colors.dart';

// This is the Sign Up screen where new users create a fresh account
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _agreeToPolicies = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false; // Loading state ke liye

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _sponsorController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(); // Form validation ke liye

  // DROP SHADOW EFFECT CONSTANTS
  static List<BoxShadow> get _dropShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.8),
      blurRadius: 12,
      offset: const Offset(0, 6),
      spreadRadius: 0.5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive calculations
    final logoSize = screenWidth * 0.3;
    final buttonWidth = screenWidth * 0.55;
    final buttonHeight = screenHeight * 0.065;
    final socialButtonSize = screenWidth * 0.18;
    final borderRadius = screenWidth * 0.05;
    final borderWidth = screenWidth * 0.007;
    final fieldSpacing = screenHeight * 0.02;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.07,
            vertical: 20,
          ),
          child: Form(
            key: _formKey, // Form key add karein
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.03),

                // ========== FULL NAME FIELD ==========
                _buildTextFieldWithDropShadow(
                  controller: _fullNameController,
                  labelText: 'Full Name',
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  borderRadius: borderRadius,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fieldSpacing),

                // ========== EMAIL FIELD ==========
                _buildTextFieldWithDropShadow(
                  controller: _emailController,
                  labelText: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  borderRadius: borderRadius,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fieldSpacing),

                // ========== PHONE FIELD ==========
                _buildTextFieldWithDropShadow(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  borderRadius: borderRadius,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (value.length < 10) {
                      return 'Phone number must be at least 10 digits';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fieldSpacing),

                // ========== SPONSOR BY FIELD ==========
                _buildTextFieldWithDropShadow(
                  controller: _sponsorController,
                  labelText: 'Sponsored By (Optional)',
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  borderRadius: borderRadius,
                ),
                SizedBox(height: fieldSpacing),

                // ========== PASSWORD FIELD ==========
                _buildPasswordFieldWithDropShadow(
                  controller: _passwordController,
                  labelText: 'Password',
                  obscureText: _obscurePassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  borderRadius: borderRadius,
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
                SizedBox(height: fieldSpacing),

                // ========== CONFIRM PASSWORD FIELD ==========
                _buildPasswordFieldWithDropShadow(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  borderRadius: borderRadius,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.03),

                // ========== AGREE TO POLICIES CHECKBOX ==========
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToPolicies,
                      onChanged: (value) {
                        setState(() {
                          _agreeToPolicies = value!;
                        });
                      },
                      activeColor: HColors.primary,
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'I agree to the ',
                          style: TextStyle(
                            fontSize: screenWidth * 0.025,
                            color: Colors.grey.shade700,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: TextStyle(
                                fontSize: screenWidth * 0.025,
                                color: HColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' and ',
                              style: TextStyle(
                                fontSize: screenWidth * 0.025,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                fontSize: screenWidth * 0.025,
                                color: HColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // -- SECTION 2: Final Action (Create Account Button) --
                Container(
                  width: buttonWidth,
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    color: HColors.primary,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: HColors.primary.withOpacity(0.5),
                      width: borderWidth,
                    ),
                    boxShadow: _dropShadow,
                  ),
                  child: TextButton(
                    onPressed:
                        _isLoading ? null : _signUp, // Runs the account creation task
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
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),

                // ========== OR SIGN UP WITH ==========
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
                        'Or sign up with',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: HColors.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey.shade400, thickness: 1),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),

                // ========== SOCIAL BUTTONS ==========
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButtonWithDropShadow(
                      icon: 'assets/icons/google_icon.png',
                      onPressed:
                          _isLoading ? null : () {}, // Disable when loading
                      buttonSize: socialButtonSize,
                      borderRadius: borderRadius,
                      borderWidth: borderWidth,
                      screenWidth: screenWidth,
                    ),
                    SizedBox(width: screenWidth * 0.05),
                    _buildSocialButtonWithDropShadow(
                      icon: 'assets/icons/apple_icon.png',
                      onPressed: _isLoading ? null : () {},
                      buttonSize: socialButtonSize,
                      borderRadius: borderRadius,
                      borderWidth: borderWidth,
                      screenWidth: screenWidth,
                    ),
                    SizedBox(width: screenWidth * 0.05),
                    _buildSocialButtonWithDropShadow(
                      icon: 'assets/icons/x_icon.png',
                      onPressed: _isLoading ? null : () {},
                      buttonSize: socialButtonSize,
                      borderRadius: borderRadius,
                      borderWidth: borderWidth,
                      screenWidth: screenWidth,
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.05),

                // ========== ALREADY HAVE ACCOUNT ==========
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    TextButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              },
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w600,
                          color: HColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/driver-signup');
                  },
                  child: Text(
                    'Want to earn with us? Join as a Partner',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.bold,
                      color: HColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Text Field Widget WITH DROP SHADOW
  Widget _buildTextFieldWithDropShadow({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    required double screenWidth,
    required double screenHeight,
    required double borderRadius,
    FormFieldValidator<String>? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: _dropShadow,
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: HColors.secondary,
            fontSize: screenWidth * 0.04,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: HColors.primary, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.02,
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  // Password Field Widget WITH DROP SHADOW
  Widget _buildPasswordFieldWithDropShadow({
    required TextEditingController controller,
    required String labelText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required double screenWidth,
    required double screenHeight,
    required double borderRadius,
    FormFieldValidator<String>? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: _dropShadow,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: HColors.secondary,
            fontSize: screenWidth * 0.04,
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: HColors.primary,
              size: screenWidth * 0.06,
            ),
            onPressed: onToggleVisibility,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: HColors.primary, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.02,
          ),
        ),
        validator: validator,
      ),
    );
  }

  // Social Button Widget WITH DROP SHADOW
  Widget _buildSocialButtonWithDropShadow({
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
        color: HColors.primary,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: HColors.primary.withOpacity(0.5),
          width: borderWidth,
        ),
        boxShadow: _dropShadow,
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
          color: Colors.white,
        ),
      ),
    );
  }

  // This is the core logic that saves the new user info to the database
  Future<void> _signUp() async {
    // 1. Check if the form is filled correctly
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Check if the user agreed to the rules
    if (!_agreeToPolicies) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms & Conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 3. Show a loading circle
    setState(() {
      _isLoading = true;
    });

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // 4. Send the new user data to Firebase to create the account
      final user = await AuthService().signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        userType: 'customer', 
      );

      if (user != null) {
        // 5. If successful, welcome them and take them to the Home Page
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      // 6. If there's an error (like "Email already used"), show it here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      // 7. Hide the loading circle
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _sponsorController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

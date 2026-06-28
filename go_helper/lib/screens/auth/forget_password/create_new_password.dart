import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:go_helper/utils/constants/image_strings.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  static List<BoxShadow> get _dropShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 6),
      spreadRadius: 0.5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final logoSize = screenWidth * 0.3;
    final buttonWidth = screenWidth * 0.55;
    final buttonHeight = screenHeight * 0.065;
    final borderRadius = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: 20,
          ),
          child: Column(
            children: [
              // ========== BACK BUTTON ==========
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    size: screenWidth * 0.07,
                    color: HColors.primary,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // ========== CENTER LOGO ==========
              Center(
                child: Image.asset(
                  HImages.appLogo,
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // ========== CREATE NEW PASSWORD TEXT ==========
              Text(
                'Create New Password',
                style: TextStyle(
                  fontSize: screenWidth * 0.065,
                  fontWeight: FontWeight.bold,
                  color: HColors.primary,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // ========== DESCRIPTION TEXT ==========
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Text(
                  'Your new password must be different from previously used passwords. Make sure it\'s strong and secure.',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.04),

              // ========== NEW PASSWORD FIELD ==========
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: _dropShadow,
                ),
                child: TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(
                      color: HColors.secondary,
                      fontSize: screenWidth * 0.04,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: HColors.primary,
                      size: screenWidth * 0.06,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: HColors.primary,
                        size: screenWidth * 0.06,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: const BorderSide(
                        color: HColors.primary,
                        width: 2.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.02,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.025),

              // ========== CONFIRM PASSWORD FIELD ==========
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: _dropShadow,
                ),
                child: TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: TextStyle(
                      color: HColors.secondary,
                      fontSize: screenWidth * 0.04,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: HColors.primary,
                      size: screenWidth * 0.06,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: HColors.primary,
                        size: screenWidth * 0.06,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: const BorderSide(
                        color: HColors.primary,
                        width: 2.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.02,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),

              // ========== PROCEED BUTTON ==========
              Container(
                width: buttonWidth,
                height: buttonHeight,
                decoration: BoxDecoration(
                  color: HColors.primary,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: HColors.primary.withOpacity(0.5),
                    width: screenWidth * 0.007,
                  ),
                  boxShadow: _dropShadow,
                ),
                child: TextButton(
                  onPressed: () {
                    _updatePassword();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                  child: Text(
                    'Update Password',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  void _updatePassword() {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill both password fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Updating password to: $newPassword');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate to login screen after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

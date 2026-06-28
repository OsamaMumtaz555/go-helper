import 'package:flutter/material.dart';
import 'package:go_helper/screens/auth/forget_password/forgot_password_otp.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:go_helper/utils/constants/image_strings.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  final TextEditingController _emailController = TextEditingController();

  // Drop Shadow Effect
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

    final logoSize = screenWidth * 0.35;
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
              //  BACK BUTTON (Top Left) 
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

              //  CENTER LOGO 
              Center(
                child: Image.asset(
                  HImages.appLogo,
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // FORGOT PASSWORD TEXT (Blue) 
              Text(
                'Forgot Your Password?',
                style: TextStyle(
                  fontSize: screenWidth * 0.065,
                  fontWeight: FontWeight.bold,
                  color: HColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.02),

              //  DESCRIPTION TEXT 
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Text(
                  'Don\'t worry! It happens. Please enter the email address associated with your account. We\'ll send you a One-Time Password (OTP) to reset your password.',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.04),

              //  EMAIL FIELD (With Icon & Shadow) 
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: _dropShadow,
                ),
                child: TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(
                      color: HColors.secondary,
                      fontSize: screenWidth * 0.04,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: HColors.primary,
                      size: screenWidth * 0.06,
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
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              SizedBox(height: screenHeight * 0.04),

              // ========== SEND OTP BUTTON ==========
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
                    _sendOTP();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                  child: Text(
                    'Send OTP',
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

  void _sendOTP() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Sending OTP to: $email');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForgotPasswordOTPScreen(email: email),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

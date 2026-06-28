import 'package:flutter/material.dart';
import 'package:go_helper/screens/auth/forget_password/create_new_password.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:go_helper/utils/constants/image_strings.dart';

class ForgotPasswordOTPScreen extends StatefulWidget {
  final String email;

  const ForgotPasswordOTPScreen({super.key, required this.email});

  @override
  State<ForgotPasswordOTPScreen> createState() =>
      _ForgotPasswordOTPScreenState();
}

class _ForgotPasswordOTPScreenState extends State<ForgotPasswordOTPScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  static List<BoxShadow> get _dropShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 6),
      spreadRadius: 0.5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupOTPAutoMove();
  }

  void _setupOTPAutoMove() {
    for (int i = 0; i < _otpControllers.length; i++) {
      _otpControllers[i].addListener(() {
        if (_otpControllers[i].text.length == 1 &&
            i < _otpControllers.length - 1) {
          FocusScope.of(context).requestFocus(_otpFocusNodes[i + 1]);
        }
        if (_otpControllers[i].text.isEmpty && i > 0) {
          FocusScope.of(context).requestFocus(_otpFocusNodes[i - 1]);
        }
      });
    }
  }

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
              // BACK BUTTON 
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

              //  ENTER OTP TEXT
              Text(
                'Enter OTP',
                style: TextStyle(
                  fontSize: screenWidth * 0.065,
                  fontWeight: FontWeight.bold,
                  color: HColors.primary,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              //  DESCRIPTION TEXT ==========
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Text(
                  'We have sent a 6-digit OTP to your email ${widget.email}. Please enter it below to verify your account.',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.04),

              // ========== OTP INPUT FIELDS ==========
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: screenWidth * 0.12,
                      height: screenWidth * 0.15,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(borderRadius),
                          boxShadow: _dropShadow,
                        ),
                        child: TextFormField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
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
                          ),
                        ),
                      ),
                    );
                  }),
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
                    _verifyOTP();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                  child: Text(
                    'Proceed',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // ========== RESEND OTP BUTTON ==========
              TextButton(
                onPressed: () {
                  _resendOTP();
                },
                child: Text(
                  'Resend OTP',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                    color: HColors.primary,
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

  void _verifyOTP() {
    String otp = '';
    for (var controller in _otpControllers) {
      otp += controller.text;
    }

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits of OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Verifying OTP: $otp');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateNewPasswordScreen()),
    );
  }

  void _resendOTP() {
    print('Resending OTP to ${widget.email}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New OTP sent to ${widget.email}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}

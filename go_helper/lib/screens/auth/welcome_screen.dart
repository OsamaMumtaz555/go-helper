import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:go_helper/utils/constants/image_strings.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically navigate to home screen after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ========== LOGO ==========
            Image.asset(
              HImages.appLogo,
              width: screenWidth * 0.4,
              height: screenWidth * 0.4,
              fit: BoxFit.contain,
            ),
            SizedBox(height: screenHeight * 0.05),

            // ========== WELCOME TEXT ==========
            Text(
              'Welcome to GoHelper!',
              style: TextStyle(
                fontSize: screenWidth * 0.08,
                fontWeight: FontWeight.bold,
                color: HColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.02),

            // ========== SUBTITLE TEXT ==========
            Text(
              'Your all-in-one solution for daily needs',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.1),

            // ========== LOADING INDICATOR ==========
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(HColors.primary),
              strokeWidth: 3,
            ),
            SizedBox(height: screenHeight * 0.02),

            // ========== LOADING TEXT ==========
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';

class CancelRideButton extends StatelessWidget {
  final Function onPressed;
  final double screenWidth;

  const CancelRideButton({
    super.key,
    required this.onPressed,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => onPressed(),
        style: ElevatedButton.styleFrom(
          backgroundColor: HColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.03,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
          ),
          elevation: 3,
          shadowColor: HColors.primary.withOpacity(0.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.close, size: screenWidth * 0.045),
            SizedBox(width: screenWidth * 0.02),
            Text(
              'Cancel Ride',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';

class PaymentSection extends StatelessWidget {
  final int fare;
  final double screenWidth;

  const PaymentSection({
    super.key,
    required this.fare,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: HColors.primary,
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        Container(
          padding: EdgeInsets.all(screenWidth * 0.035),
          decoration: BoxDecoration(
            color: HColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            border: Border.all(
              color: HColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fare',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: HColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Rs $fare',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: HColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

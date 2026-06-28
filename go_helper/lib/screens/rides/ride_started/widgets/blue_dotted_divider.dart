import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';

class BlueDottedDivider extends StatelessWidget {
  final double screenWidth;

  const BlueDottedDivider({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
      child: Row(
        children: List.generate(
          20,
          (index) => Expanded(
            child: Container(
              height: 1.2,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: HColors.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

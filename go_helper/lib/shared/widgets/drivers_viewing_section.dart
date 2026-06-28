import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';

class DriversViewingSection extends StatelessWidget {
  final List<String> driverImages;

  const DriversViewingSection({super.key, required this.driverImages});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Text
        Text(
          'Drivers viewing your post',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),

        // Driver Images
        Row(
          children: [
            ...driverImages
                .take(3)
                .map(
                  (image) => Container(
                    margin: EdgeInsets.only(left: screenWidth * 0.01),
                    width: screenWidth * 0.08,
                    height: screenWidth * 0.08,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: HColors.primary, width: 2),
                      image: DecorationImage(
                        image: AssetImage(image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

            if (driverImages.length > 3)
              Container(
                margin: EdgeInsets.only(left: screenWidth * 0.01),
                width: screenWidth * 0.08,
                height: screenWidth * 0.08,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HColors.primary.withOpacity(0.1),
                  border: Border.all(color: HColors.primary),
                ),
                child: Center(
                  child: Text(
                    '+${driverImages.length - 3}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.025,
                      fontWeight: FontWeight.bold,
                      color: HColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

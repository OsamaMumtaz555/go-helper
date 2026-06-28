import 'package:flutter/material.dart';
import 'package:go_helper/model/driver_request_model.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:go_helper/shared/widgets/blue_dotted_divider.dart';

class DriverInfoSection extends StatelessWidget {
  final DriverRequest driver;
  final String etaMinutes;
  final Function onContactDriver;
  final double screenWidth;

  const DriverInfoSection({
    super.key,
    required this.driver,
    required this.etaMinutes,
    required this.onContactDriver,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildArrivingInfo(),
          SizedBox(height: screenWidth * 0.04),
          BlueDottedDivider(screenWidth: screenWidth),
          SizedBox(height: screenWidth * 0.04),
          _buildDriverProfile(),
        ],
      ),
    );
  }

  Widget _buildArrivingInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Driver is arriving in',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: HColors.primary.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: screenWidth * 0.01),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: etaMinutes,
                      style: TextStyle(
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.bold,
                        color: HColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: ' mins',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                        color: HColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                driver.carModel,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w600,
                  color: HColors.primary,
                ),
              ),
              SizedBox(height: screenWidth * 0.01),
              Text(
                driver.licensePlate,
                style: TextStyle(
                  fontSize: screenWidth * 0.033,
                  color: HColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: screenWidth * 0.18,
          height: screenWidth * 0.18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
            image: DecorationImage(
              image: AssetImage(driver.imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverProfile() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: screenWidth * 0.1,
              height: screenWidth * 0.1,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(driver.imagePath),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: HColors.primary, width: 1.5),
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.bold,
                    color: HColors.primary,
                  ),
                ),
                SizedBox(height: screenWidth * 0.005),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: screenWidth * 0.03,
                      color: Colors.amber,
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Text(
                      '${driver.rating} (${driver.totalRides} rides)',
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: HColors.primary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Container(
          width: screenWidth * 0.1,
          height: screenWidth * 0.1,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: HColors.primary, width: 1.2),
          ),
          child: IconButton(
            onPressed: () => onContactDriver(),
            icon: Icon(
              Icons.phone,
              color: HColors.primary,
              size: screenWidth * 0.04,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

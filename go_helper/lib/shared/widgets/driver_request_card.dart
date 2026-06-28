import 'package:flutter/material.dart';
import 'package:go_helper/model/driver_request_model.dart';

import 'package:go_helper/utils/constants/colors.dart';

class DriverRequestCard extends StatelessWidget {
  final DriverRequest driver;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const DriverRequestCard({
    super.key,
    required this.driver,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(screenWidth),
            SizedBox(height: screenWidth * 0.03),
            _buildDriverInfo(screenWidth),
            SizedBox(height: screenWidth * 0.03),
            _buildActionButtons(screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Driver Request',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: HColors.primary,
          ),
        ),
        if (driver.isNew)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenWidth * 0.01,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            child: Text(
              'NEW',
              style: TextStyle(
                fontSize: screenWidth * 0.025,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDriverInfo(double screenWidth) {
    return Row(
      children: [
        // Driver Image
        Container(
          width: screenWidth * 0.15,
          height: screenWidth * 0.15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: HColors.primary, width: 2),
            image: DecorationImage(
              image: AssetImage(driver.imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.04),

        // Driver Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driver.name,
                style: TextStyle(
                  fontSize: screenWidth * 0.042,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenWidth * 0.01),
              _buildInfoRow(
                screenWidth,
                Icons.star,
                Colors.amber,
                '${driver.rating} (${driver.totalRides} rides)',
              ),
              _buildInfoRow(
                screenWidth,
                Icons.credit_card,
                Colors.grey.shade600,
                'CNIC: ${driver.cnic}',
              ),
              _buildInfoRow(
                screenWidth,
                Icons.directions_car,
                Colors.grey.shade600,
                '${driver.carModel} • ${driver.licensePlate}',
              ),
              _buildInfoRow(
                screenWidth,
                Icons.access_time,
                Colors.grey.shade600,
                'ETA: ${driver.eta} • ${driver.distance} away',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    double screenWidth,
    IconData icon,
    Color color,
    String text,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.01),
      child: Row(
        children: [
          Icon(icon, size: screenWidth * 0.035, color: color),
          SizedBox(width: screenWidth * 0.01),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Rs ${driver.fare}',
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
            color: HColors.primary,
          ),
        ),
        Row(
          children: [
            // Decline Button
            _buildCircleButton(
              screenWidth,
              Colors.red.withOpacity(0.1),
              Icons.close,
              Colors.red,
              onReject,
            ),
            SizedBox(width: screenWidth * 0.03),
            // Accept Button
            _buildCircleButton(
              screenWidth,
              Colors.green.withOpacity(0.1),
              Icons.check,
              Colors.green,
              onAccept,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleButton(
    double screenWidth,
    Color backgroundColor,
    IconData icon,
    Color iconColor,
    VoidCallback onPressed,
  ) {
    return Container(
      width: screenWidth * 0.12,
      height: screenWidth * 0.12,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor, size: screenWidth * 0.05),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

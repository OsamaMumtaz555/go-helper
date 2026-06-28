import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';

class TripLocationsSection extends StatelessWidget {
  final String fromLocation;
  final String toLocation;
  final double screenWidth;

  const TripLocationsSection({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Current Trip',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: HColors.primary,
          ),
        ),
        SizedBox(height: screenWidth * 0.03),
        _buildLocationTile(
          icon: Icons.location_on,
          label: 'From',
          location: fromLocation,
        ),
        SizedBox(height: screenWidth * 0.02),
        _buildLocationTile(
          icon: Icons.location_on_outlined,
          label: 'To',
          location: toLocation,
        ),
      ],
    );
  }

  Widget _buildLocationTile({
    required IconData icon,
    required String label,
    required String location,
  }) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: HColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(color: HColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.08,
            height: screenWidth * 0.08,
            decoration: BoxDecoration(
              color: HColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: HColors.primary, size: screenWidth * 0.04),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: HColors.primary.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: screenWidth * 0.005),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                    color: HColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

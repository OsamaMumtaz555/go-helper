import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: screenWidth * 0.18, // Height increase thoda sa
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: screenWidth * 0.015, // Top & bottom margin for spacing
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          screenWidth * 0.08,
        ), // All sides circular
        border: Border.all(color: HColors.primary, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: HColors.secondary.withOpacity(0.18),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, -5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              context: context,
              icon: Icons.home,
              label: 'Home',
              index: 0,
              isSelected: currentIndex == 0,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.local_offer,
              label: 'Services',
              index: 1,
              isSelected: currentIndex == 1,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.notifications,
              label: 'Alert',
              index: 2,
              isSelected: currentIndex == 2,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.person,
              label: 'Profile',
              index: 3,
              isSelected: currentIndex == 3,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.history,
              label: 'History',
              index: 4,
              isSelected: currentIndex == 4,
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Container(
        constraints: BoxConstraints(minWidth: screenWidth * 0.15),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.015,
          vertical: screenWidth * 0.015,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? HColors.primary
                      : HColors.primary.withOpacity(0.6),
              size: screenWidth * 0.06,
            ),
            SizedBox(height: screenWidth * 0.008),
            Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.028,
                color:
                    isSelected
                        ? HColors.primary
                        : HColors.primary.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (isSelected)
              Container(
                margin: EdgeInsets.only(top: screenWidth * 0.004),
                width: screenWidth * 0.012,
                height: screenWidth * 0.012,
                decoration: const BoxDecoration(
                  color: HColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

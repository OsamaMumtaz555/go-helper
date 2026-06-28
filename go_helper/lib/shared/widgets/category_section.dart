import 'package:flutter/material.dart';
import 'package:go_helper/utils/Constants/image_strings.dart';
import 'package:go_helper/utils/constants/colors.dart';

class CategorySection extends StatefulWidget {
  final Function(String) onCategorySelected; // ADD THIS PARAMETER

  const CategorySection({
    super.key,
    required this.onCategorySelected, // ADD THIS
  });

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  String? _selectedMainCategory;
  String? _selectedSubCategory;
  String? _selectedRouteType;
  String? _selectedCaptainFilter;
  String? _selectedCompanionType;
  bool _showSubOptions = false;
  bool _showRouteOptions = false;
  bool _showCaptainOptions = false;
  final bool _showCompanionOptions = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Title - Primary Blue Color
        Padding(
          padding: EdgeInsets.only(bottom: screenWidth * 0.04),
          child: Text(
            'Select Your Category',
            style: TextStyle(
              fontSize: screenWidth * 0.038,
              fontWeight: FontWeight.bold,
              color: HColors.primary,
            ),
          ),
        ),

        // Main Categories Row
        Row(
          children: [
            // Mechanic Assistance
            Expanded(
              child: _buildMainCategoryCard(
                context: context,
                title: 'Mechanic Assistance',
                subtitle: 'With Crane',
                iconAsset: HImages.mechanicIcon,
                isSelected: _selectedMainCategory == 'mechanic',
                onTap: () {
                  setState(() {
                    _selectedMainCategory = 'mechanic';
                    _selectedSubCategory = null;
                    _showSubOptions = true;
                    _showRouteOptions = false;
                    _showCaptainOptions = false;
                  });
                  widget.onCategorySelected('mechanic');
                },
              ),
            ),

            SizedBox(width: screenWidth * 0.04),

            // Courier
            Expanded(
              child: _buildMainCategoryCard(
                context: context,
                title: 'Courier',
                subtitle: 'With Van',
                iconAsset: HImages.courierIcon,
                isSelected: _selectedMainCategory == 'courier',
                onTap: () {
                  setState(() {
                    _selectedMainCategory = 'courier';
                    _selectedSubCategory = null;
                    _showSubOptions = true;
                    _showRouteOptions = false;
                    _showCaptainOptions = false;
                  });
                  widget.onCategorySelected('courier');
                },
              ),
            ),
          ],
        ),

        SizedBox(height: screenWidth * 0.05),
      ],
    );
  }

  Widget _buildMainCategoryCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String iconAsset,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.02),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
          border: Border.all(
            color: isSelected ? HColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08), // Much lighter for better performance
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon - Original Color (No tint)
            Image.asset(
              iconAsset,
              width: screenWidth * 0.15,
              height: screenWidth * 0.15,
              // NO COLOR FILTER - Original color
            ),
            SizedBox(height: screenWidth * 0.02),

            // Title - Primary Blue when selected
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w600,
                color: isSelected ? HColors.primary : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenWidth * 0.005),

            // Subtitle - Primary Blue when selected
            Text(
              subtitle,
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                color: isSelected ? HColors.primary : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Optional: In methods ko rakh sakte hain ya remove kar sakte hain
  // Kyunki ab yeh ServiceSelectionScreen mein honge
  Widget _buildSubCategorySection(BuildContext context) {
    return Container(); // Empty for now
  }

  Widget _buildRouteTypeSection(BuildContext context) {
    return Container(); // Empty for now
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(); // Empty for now
  }

  Widget _buildCourierOptions(BuildContext context) {
    return Container(); // Empty for now
  }

  void _showCaptainSelectionDialog(BuildContext context) {
    // Will be in ServiceSelectionScreen
  }
}

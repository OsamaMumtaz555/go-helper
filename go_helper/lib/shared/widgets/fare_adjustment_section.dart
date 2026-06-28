import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';

class FareAdjustmentSection extends StatefulWidget {
  final int initialFare;
  final ValueChanged<int> onFareChanged;

  const FareAdjustmentSection({
    super.key,
    required this.initialFare,
    required this.onFareChanged,
  });

  @override
  State<FareAdjustmentSection> createState() => _FareAdjustmentSectionState();
}

class _FareAdjustmentSectionState extends State<FareAdjustmentSection> {
  late int _currentFare;

  @override
  void initState() {
    super.initState();
    _currentFare = widget.initialFare;
  }

  @override
  void didUpdateWidget(covariant FareAdjustmentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFare != oldWidget.initialFare) {
      setState(() {
        _currentFare = widget.initialFare;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Offering Your Price',
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
            color: HColors.primary,
          ),
        ),
        SizedBox(height: screenWidth * 0.03),

        // FARE [-] [Rs 200] [+]
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Heading Text "Fare"
            Text(
              'Fare',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w600,
                color: HColors.primary,
              ),
            ),

            SizedBox(width: screenWidth * 0.04),

            // Minus Button
            _buildFareButton(screenWidth, Icons.remove, () {
              if (_currentFare > 100) {
                setState(() {
                  _currentFare -= 5;
                  widget.onFareChanged(_currentFare);
                });
              }
            }),

            SizedBox(width: screenWidth * 0.04),

            // Fare Amount
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenWidth * 0.015,
              ),
              decoration: BoxDecoration(
                color: HColors.primary,
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                boxShadow: [
                  BoxShadow(
                    color: HColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Rs $_currentFare',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            SizedBox(width: screenWidth * 0.04),

            // Plus Button
            _buildFareButton(screenWidth, Icons.add, () {
              setState(() {
                _currentFare += 5;
                widget.onFareChanged(_currentFare);
              });
            }),
          ],
        ),

        SizedBox(height: screenWidth * 0.02),

        // Optional Text
        Text(
          'Adjust fare to attract more drivers (Optional)',
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFareButton(
    double screenWidth,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      width: screenWidth * 0.1,
      height: screenWidth * 0.1,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: HColors.primary, size: screenWidth * 0.05),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

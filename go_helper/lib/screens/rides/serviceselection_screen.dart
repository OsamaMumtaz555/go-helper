import 'package:flutter/material.dart';
import 'package:go_helper/screens/rides/findride_screen.dart';
import 'package:go_helper/shared/widgets/ultra_minimal_from_to.dart';
import 'package:go_helper/shared/widgets/map_container.dart';
import 'package:go_helper/shared/layouts/bottom_nav_bar.dart';
import 'package:go_helper/utils/Constants/image_strings.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_helper/utils/fare_calculator.dart';

class ServiceSelectionScreen extends StatefulWidget {
  final String selectedCategory;
  final String? fromLocation;
  final String? toLocation;
  final LatLng? fromCoordinates;
  final LatLng? toCoordinates;

  const ServiceSelectionScreen({
    super.key,
    required this.selectedCategory,
    this.fromLocation,
    this.toLocation,
    this.fromCoordinates,
    this.toCoordinates,
  });

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  int _currentIndex = 0;
  String? _selectedSubCategory;
  String _fromAddress = 'Current Location';
  String _toAddress = 'Enter Destination';

  // Coordinates (needed for SimpleFromToSection callbacks)
  LatLng? _fromLocation;
  LatLng? _toLocation;

  // For Courier Fare
  int _courierFare = 250;
  Map<String, int>? _fareOptions;
  String _selectedTier = 'Budget';

  @override
  void initState() {
    super.initState();
    _fromAddress = widget.fromLocation ?? 'Current Location';
    _toAddress = widget.toLocation ?? 'Enter Destination';
    _fromLocation = widget.fromCoordinates;
    _toLocation = widget.toCoordinates;
    _calculateFare();
  }

  void _calculateFare() {
    print("📍 ServiceSelectionScreen: Calculating Fare...");
    
    if (_fromLocation != null && _toLocation != null) {
      const Distance distance = Distance();
      double distanceInKm = distance.as(LengthUnit.Meter, _fromLocation!, _toLocation!) / 1000;

      // Use the new multi-tier calculator
      final options = FareCalculator.calculateFareOptions(
        distanceInKm: distanceInKm,
        serviceType: _selectedSubCategory ?? widget.selectedCategory,
      );

      setState(() {
        _fareOptions = options;
        _courierFare = options[_selectedTier]!;
      });
      
      print("💰 Fare Options: $options");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. From-To Section
            SizedBox(height: screenWidth * 0.06),
            SimpleFromToSection(
              fromText: _fromAddress,
              toText: _toAddress,
              onFromChanged: (newFrom, lat, lng) {
                setState(() {
                  _fromAddress = newFrom;
                  _fromLocation = LatLng(lat, lng);
                });
                _calculateFare();
              },
              onToChanged: (newTo, lat, lng) {
                setState(() {
                  _toAddress = newTo;
                  _toLocation = LatLng(lat, lng);
                });
                _calculateFare();
              },
              onAddMore: () {
                _addMoreDestinations();
              },
            ),
            SizedBox(height: screenWidth * 0.1),

            // 2. Map Container
            MapWidget(
              onMapTap: () {
                _openFullMapScreen();
              },
              fromLocation: _fromLocation,
              toLocation: _toLocation,
              height: 300,
            ),
            const SizedBox(height: 20),

            // 3. Sub-category Options
            widget.selectedCategory == 'mechanic'
                ? _buildMechanicOptions(context)
                : _buildCourierOptions(context),

            // 4. Action Buttons (shown when sub-category is selected)
            if (_selectedSubCategory != null)
              _buildVerticalActionButtons(context),

            SizedBox(height: screenWidth * 0.1),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  // Mechanic Options - WITH CATEGORY STYLING
  Widget _buildMechanicOptions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with padding like CategorySection
        Padding(
          padding: EdgeInsets.only(bottom: screenWidth * 0.04),
          child: Text(
            'Select Service Type',
            style: TextStyle(
              fontSize: screenWidth * 0.038,
              fontWeight: FontWeight.bold,
              color: HColors.primary,
            ),
          ),
        ),
        SizedBox(height: screenWidth * 0.03),

        Row(
          children: [
            // Car Recovery - WITH CATEGORY STYLING
            Expanded(
              child: _buildCategoryStyleOptionCard(
                title: 'Car Recovery',
                iconAsset: HImages.truckIcon,
                isSelected: _selectedSubCategory == 'recovery',
                onTap: () {
                  setState(() {
                    _selectedSubCategory = 'recovery';
                  });
                  _calculateFare();
                },
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            // Mechanic - WITH CATEGORY STYLING
            Expanded(
              child: _buildCategoryStyleOptionCard(
                title: 'Mechanic',
                iconAsset: HImages.mechanicIcon,
                isSelected: _selectedSubCategory == 'mechanic',
                onTap: () {
                  setState(() {
                    _selectedSubCategory = 'mechanic';
                  });
                  _calculateFare();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Courier Options - WITH CATEGORY STYLING
  Widget _buildCourierOptions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with padding like CategorySection
        Padding(
          padding: EdgeInsets.only(bottom: screenWidth * 0.04),
          child: Text(
            'Select Vehicle Type',
            style: TextStyle(
              fontSize: screenWidth * 0.038,
              fontWeight: FontWeight.bold,
              color: HColors.primary,
            ),
          ),
        ),
        SizedBox(height: screenWidth * 0.03),

        Row(
          children: [
            // Bike - WITH CATEGORY STYLING
            Expanded(
              child: _buildCategoryStyleOptionCard(
                title: 'Bike',
                iconAsset: HImages.bikeIcon,
                isSelected: _selectedSubCategory == 'bike',
                onTap: () {
                  setState(() {
                    _selectedSubCategory = 'bike';
                  });
                  _calculateFare();
                },
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            // Cab - WITH CATEGORY STYLING
            Expanded(
              child: _buildCategoryStyleOptionCard(
                title: 'Cab',
                iconAsset: HImages.cabIcon,
                isSelected: _selectedSubCategory == 'cab',
                onTap: () {
                  setState(() {
                    _selectedSubCategory = 'cab';
                  });
                  _calculateFare();
                },
              ),
            ),
          ],
        ),

        // Fare Tier Suggestions
        if (_fareOptions != null) ...[
          SizedBox(height: screenWidth * 0.05),
          _buildFareTierSuggestions(screenWidth),
        ],

        // Fare Adjustment
        if (_selectedSubCategory != null) ...[
          SizedBox(height: screenWidth * 0.05),
          _buildSimpleFareAdjustment(context),
        ],
      ],
    );
  }

  Widget _buildFareTierSuggestions(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Fares',
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: screenWidth * 0.03),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _fareOptions!.entries.map((entry) {
            bool isSelected = _selectedTier == entry.key;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTier = entry.key;
                    _courierFare = entry.value;
                  });
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: isSelected ? HColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? HColors.primary : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: HColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ] : [],
                  ),
                  child: Column(
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: screenWidth * 0.028,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs ${entry.value}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : HColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Category Style Option Card (EXACT SAME AS CategorySection)
  Widget _buildCategoryStyleOptionCard({
    required String title,
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
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Custom Image Asset
            Image.asset(
              iconAsset,
              width: screenWidth * 0.15,
              height: screenWidth * 0.15,
            ),
            SizedBox(height: screenWidth * 0.02),

            // Title - Primary color when selected
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w600,
                color: isSelected ? HColors.primary : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Fare Adjustment
  Widget _buildSimpleFareAdjustment(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        SizedBox(height: screenWidth * 0.03),

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
            Container(
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
                onPressed: () {
                  // GET MINIMUM ALLOWED FARE (Budget)
                  int minAllowed = _fareOptions?['Budget'] ?? 100;
                  
                  if (_courierFare > minAllowed) {
                    setState(() {
                      _courierFare -= 50;
                      // Ensure it doesn't dip below minimum even after subtraction
                      if (_courierFare < minAllowed) _courierFare = minAllowed;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cannot go below minimum fare of Rs $minAllowed'),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                icon: Icon(
                  Icons.remove,
                  color: HColors.primary,
                  size: screenWidth * 0.05,
                ),
                padding: EdgeInsets.zero,
              ),
            ),

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
                'Rs $_courierFare',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            SizedBox(width: screenWidth * 0.04),

            // Plus Button
            Container(
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
                onPressed: () {
                  setState(() {
                    _courierFare += 50;
                  });
                },
                icon: Icon(
                  Icons.add,
                  color: HColors.primary,
                  size: screenWidth * 0.05,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),

        SizedBox(height: screenWidth * 0.02),

        // Optional Text
        Text(
          'Adjust fare to attract more captains (Optional)',
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



  // Action Buttons
  Widget _buildVerticalActionButtons(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        SizedBox(height: screenWidth * 0.05),

        // Select Captain Button
        SizedBox(
          width: screenWidth * 0.7,
          child: ElevatedButton(
            onPressed: () {
              _navigateToFindRideScreen(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HColors.primary,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenWidth * 0.035,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.5),
              ),
              elevation: 5,
              shadowColor: HColors.primary.withOpacity(0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search,
                  color: Colors.white,
                  size: screenWidth * 0.055,
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  'Select Captain',
                  style: TextStyle(
                    fontSize: screenWidth * 0.036,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: screenWidth * 0.03),

        // Schedule Ride Button
        SizedBox(
          width: screenWidth * 0.7,
          child: ElevatedButton(
            onPressed: () {
              _scheduleRide();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: HColors.primary, width: 2),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenWidth * 0.035,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.5),
              ),
              elevation: 5,
              shadowColor: Colors.grey.withOpacity(0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: HColors.primary,
                  size: screenWidth * 0.055,
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  'Schedule Ride',
                  style: TextStyle(
                    fontSize: screenWidth * 0.036,
                    fontWeight: FontWeight.w600,
                    color: HColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Navigation to FindRideScreen
  void _navigateToFindRideScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FindRideScreen(
              selectedCategory: widget.selectedCategory,
              selectedSubCategory: _selectedSubCategory ?? '',
              initialFare:
                  widget.selectedCategory == 'courier' ? _courierFare : 0,
              fromLocation: _fromAddress,
              toLocation: _toAddress,
              // Pass the coordinates - Use local state variables first, fallback to widget params
              fromCoordinates: _fromLocation ?? widget.fromCoordinates,
              toCoordinates: _toLocation ?? widget.toCoordinates,
            ),
      ),
    );
  }

  void _scheduleRide() async {
    // Step 1: Pick a date
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: HColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate == null || !mounted) return;

    // Step 2: Pick a time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: HColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime == null || !mounted) return;

    final scheduledDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Validate the time is in the future
    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a future time'), backgroundColor: Colors.red),
      );
      return;
    }

    // Format the date/time nicely
    final formattedDate = '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
    final formattedTime = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';

    // Confirm with user
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: HColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: HColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Text(formattedTime, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We will find a ${widget.selectedCategory} driver for you at this time.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: HColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ride scheduled for $formattedDate at $formattedTime'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate to FindRideScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FindRideScreen(
            selectedCategory: widget.selectedCategory,
            selectedSubCategory: _selectedSubCategory ?? '',
            initialFare: widget.selectedCategory == 'courier' ? _courierFare : 0,
            fromLocation: _fromAddress,
            toLocation: _toAddress,
            fromCoordinates: _fromLocation ?? widget.fromCoordinates,
            toCoordinates: _toLocation ?? widget.toCoordinates,
          ),
        ),
      );
    }
  }

  // Helper Methods
  void _addMoreDestinations() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add More Stops'),
            content: const Text('Add multiple stops along your route.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _openFullMapScreen() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Full Map'),
            content: const Text('Full map screen will open here.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}

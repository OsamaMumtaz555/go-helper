import 'package:flutter/material.dart';
import 'package:go_helper/screens/rides/serviceselection_screen.dart';
import 'package:go_helper/shared/widgets/AppDrawer.dart';
import 'package:go_helper/shared/widgets/ultra_minimal_from_to.dart';
import 'package:go_helper/shared/widgets/map_container.dart';
import 'package:go_helper/shared/widgets/category_section.dart';
import 'package:go_helper/shared/layouts/bottom_nav_bar.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_helper/screens/rides/ride_history_screen.dart';
import 'package:go_helper/screens/profile/profile_screen.dart';
import 'package:go_helper/screens/home/alerts_screen.dart';
import 'package:go_helper/screens/home/services_tab.dart';

// This is the Main Home page that the user sees first
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final String _selectedCategory = 'mechanic';
  String _fromAddress = 'Current Location';
  String _toAddress = 'Enter Destination';

  // ADD THESE FOR MAP INTEGRATION
  LatLng? _fromLocation;
  LatLng? _toLocation;

  // ADD THESE STATE VARIABLES FOR CATEGORY SECTION
  String? _selectedMainCategory;
  String? _selectedSubCategory;


  @override
  void initState() {
    super.initState();
    // Initialize with default Karachi coordinates
    _fromLocation = const LatLng(24.8607, 67.0011);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      drawer: const AppDrawer(),
      body: _buildBody(),

      // 4. Bottom Navigation
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

  // This decides which "Tab" to show based on the Bottom Bar selection
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent(); // Shows the Map and Services
      case 1:
        return const ServicesTab(); // Shows Services List
      case 2:
        return const AlertsScreen(); // Shows Notifications
      case 3:
        return const ProfileScreen(); // Shows User Profile
      case 4:
        return const RideHistoryScreen(); // Shows Past Rides
      default:
        return _buildHomeContent();
    }
  }

  // This builds the main screen content (Map + Category Icons)
  Widget _buildHomeContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(height: screenWidth * 0.06),
          SimpleFromToSection(
            fromText: _fromAddress,
            toText: _toAddress,
            onFromChanged: (newFrom, lat, lng) {
              setState(() {
                _fromAddress = newFrom;
                _fromLocation = LatLng(lat, lng);
              });
            },
            onToChanged: (newTo, lat, lng) {
              setState(() {
                _toAddress = newTo;
                _toLocation = LatLng(lat, lng);
              });
            },
            onAddMore: _addMoreDestinations,
          ),
          SizedBox(height: screenWidth * 0.1),
          MapWidget(
            onMapTap: _openFullMapScreen,
            fromLocation: _fromLocation,
            toLocation: _toLocation,
            onFromLocationSelected: (location) {
              setState(() {
                _fromLocation = location;
                _fromAddress = "Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}";
              });
            },
            onToLocationSelected: (location) {
              setState(() {
                _toLocation = location;
                _toAddress = "Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}";
              });
            },
            height: 350,
          ),
          const SizedBox(height: 20),
          CategorySection(
            onCategorySelected: (category) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceSelectionScreen(
                    selectedCategory: category,
                    fromLocation: _fromAddress,
                    toLocation: _toAddress,
                    fromCoordinates: _fromLocation,
                    toCoordinates: _toLocation,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: screenWidth * 0.1),
        ],
      ),
    );
  }

  void _pickFromLocation() {
    print('Pick FROM location');
  }

  void _pickToLocation() {
    print('Pick TO location');
  }

  void _addMoreDestinations() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add More Stops'),
        content: const Text('This feature will allow you to add multiple stops along your route.'),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: MapWidget(
            onMapTap: () {
              Navigator.pop(context);
            },
            fromLocation: _fromLocation,
            toLocation: _toLocation,
            onFromLocationSelected: (location) {
              setState(() {
                _fromLocation = location;
                _fromAddress = "Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}";
              });
              Navigator.pop(context);
            },
            onToLocationSelected: (location) {
              setState(() {
                _toLocation = location;
                _toAddress = "Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}";
              });
              Navigator.pop(context);
            },
            isFullMap: true,
            height: MediaQuery.of(context).size.height * 0.9,
          ),
        );
      },
    );
  }
}

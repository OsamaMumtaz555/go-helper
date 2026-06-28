import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:go_helper/model/driver_request_model.dart';
import 'package:go_helper/screens/rides/ride_started/ride_started_screen.dart';
import 'package:go_helper/shared/widgets/ultra_minimal_from_to.dart';
import 'package:go_helper/shared/widgets/map_container.dart';
import 'package:go_helper/shared/widgets/driver_request_card.dart';
import 'package:go_helper/shared/widgets/drivers_viewing_section.dart';
import 'package:go_helper/shared/widgets/blue_dotted_divider.dart';
import 'package:go_helper/shared/widgets/fare_adjustment_section.dart';
import 'package:go_helper/shared/layouts/bottom_nav_bar.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:go_helper/utils/constants/image_strings.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_helper/utils/fare_calculator.dart';

class FindRideScreen extends StatefulWidget {
  final String selectedCategory;
  final String selectedSubCategory;
  final int initialFare;
  final String fromLocation;
  final String toLocation;
  final LatLng? fromCoordinates;
  final LatLng? toCoordinates;

  const FindRideScreen({
    super.key,
    required this.selectedCategory,
    required this.selectedSubCategory,
    required this.initialFare,
    required this.fromLocation,
    required this.toLocation,
    this.fromCoordinates,
    this.toCoordinates,
  });

  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {
  int _currentIndex = 0;
  int _currentFare = 250;
  final List<DriverRequest> _driverRequests = [];
  bool _isLoading = true;
  bool _showSearching = true;
  StreamSubscription? _driverSubscription;
  StreamSubscription? _fareSubscription;
  String? _broadcastRideId; // The single broadcast ride document ID
  final Map<String, int> _driverFares = {}; // Real-time counter-offers from drivers

  @override
  void dispose() {
    _driverSubscription?.cancel();
    _fareSubscription?.cancel();
    super.dispose();
  }

  // Custom driver images
  List<String> driverImages = [
    HImages.driver1,
    HImages.driver2,
    HImages.driver3,
    HImages.driver4,
  ];

  // Add state variables to track coordinates
  LatLng? _fromLocation;
  LatLng? _toLocation;

  @override
  void initState() {
    super.initState();
    _currentFare = widget.initialFare;

    // Initialize coordinates from widget
    _fromLocation = widget.fromCoordinates;
    _toLocation = widget.toCoordinates;

    _initializeRideSearch();
  }

  void _initializeRideSearch() {
    print("📍 FindRideScreen Initial Coordinates:");
    print("📍 From: $_fromLocation");
    print("📍 To: $_toLocation");

    // 🟢 BROADCAST: Create a single ride document IMMEDIATELY so drivers see it instantly!
    _createBroadcastRide();
    _startRealDriverListener();
    _listenForDriverOffers(); // 🟢 NEW: Listen for counter offers

    // If coordinates are missing, fallback asynchronously without blocking
    if (_fromLocation == null) {
      _fetchFallbackLocation();
    } else if (_fromLocation != null && _toLocation != null) {
      _calculateAndSetFare();
    } else {
      _currentFare = widget.initialFare;
    }
  }

  void _fetchFallbackLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 4));
      
      if (mounted) {
        setState(() {
          _fromLocation = LatLng(pos!.latitude, pos.longitude);
        });
        _calculateAndSetFare();
        
        // Update the broadcast ride with the newly found coordinates!
        if (_broadcastRideId != null) {
           await FirebaseFirestore.instance.collection('rides').doc(_broadcastRideId).update({
              'fromCoordinates': {'lat': pos.latitude, 'lng': pos.longitude}
           });
        }
      }
    } catch (e) {
      print("Failed to get customer fallback location: $e");
    }
  }

  /// Creates a single broadcast ride document with driverId='all'
  /// so every online driver of the matching service type sees this request.
  void _createBroadcastRide() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Generate a unique broadcast ride ID
      _broadcastRideId = 'RIDE_BROADCAST_${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}';

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final customerName = userDoc.data()?['fullName'] ?? 'Customer';

      await FirebaseFirestore.instance.collection('rides').doc(_broadcastRideId).set({
        'rideId': _broadcastRideId,
        'customerId': currentUser.uid,
        'customerName': customerName,
        'driverId': 'all', // 🔑 THIS IS THE KEY: 'all' means every driver sees it
        'driverName': '',
        'serviceType': widget.selectedCategory,
        'fare': _currentFare,
        'fromLocation': widget.fromLocation,
        'toLocation': widget.toLocation,
        'fromCoordinates': _fromLocation != null ? {'lat': _fromLocation!.latitude, 'lng': _fromLocation!.longitude} : null,
        'toCoordinates': _toLocation != null ? {'lat': _toLocation!.latitude, 'lng': _toLocation!.longitude} : null,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("📡 BROADCAST RIDE CREATED: $_broadcastRideId (visible to ALL ${widget.selectedCategory} drivers)");
 
      // 🟢 SYNC FIX: Also listen for individual driver offers
      _listenForDriverOffers();

      // Listen for when any driver accepts this broadcast ride
      _listenForRideAcceptance(_broadcastRideId!);
    } catch (e) {
      print("❌ Broadcast Ride Error: $e");
    }
  }

  void _listenForDriverOffers() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    _fareSubscription = FirebaseFirestore.instance
        .collection('rides')
        .where('customerId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      bool changed = false;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final driverId = data['driverId'];
        if (driverId != null && driverId != 'all') {
           final fare = data['fare'];
           if (fare != null && _driverFares[driverId] != fare) {
             _driverFares[driverId] = fare;
             changed = true;
           }
        }
      }
      if (changed && mounted) {        setState(() {}); // Rebuild UI to show new driver offers
      }
    });
  }

  // This connects to the real database to find actual Partners (Drivers) nearby
  void _startRealDriverListener() {
    setState(() {
      _isLoading = true;
      _showSearching = true;
    });

    // We listen to the "users" folder for anyone who is a Driver and is Online
    _driverSubscription = FirebaseFirestore.instance
        .collection('users')
        .where('userType', isEqualTo: 'driver')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      
      print("🟢 Driver Listener Update: ${snapshot.docs.length} drivers found online.");

      final List<DriverRequest> realDrivers = [];
      const Distance distanceCalc = Distance();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // 1. Get the driver's current position
        if (data['currentLocation'] != null && _fromLocation != null) {
          double driverLat = data['currentLocation']['lat'];
          double driverLng = data['currentLocation']['lng'];
          LatLng driverPos = LatLng(driverLat, driverLng);

          // 2. Calculate how far they are from the Customer
          double distMeters = distanceCalc.as(LengthUnit.Meter, _fromLocation!, driverPos);
          double distKm = distMeters / 1000;

          // 3. Only show drivers within 20km range
          if (distKm >=0.0 && distKm <= 20.0) {
            
            // 🕒 NEW: Heartbeat Check (Recent update within 5 mins)
            bool isRecent = false;
            final lastUpdated = data['lastUpdated'] as Timestamp?;
            if (lastUpdated != null) {
              final diff = DateTime.now().difference(lastUpdated.toDate());
              if (diff.inMinutes <= 5) isRecent = true;
            }

            if (isRecent) {
              realDrivers.add(
                DriverRequest(
                  id: doc.id,
                  name: data['fullName'] ?? 'Driver',
                  cnic: data['licensePlate'] ?? 'Verified',
                  eta: '${(distKm * 2 + 2).toInt()} mins',
                  rating: (data['rating'] ?? 5.0).toDouble(),
                  totalRides: data['totalRides'] ?? 0,
                  carModel: data['vehicleModel'] ?? 'Vehicle',
                  licensePlate: data['licensePlate'] ?? '...',
                  distance: '${distKm.toStringAsFixed(1)} km',
                  fare: _driverFares[doc.id] ?? _currentFare, 
                  imagePath: HImages.driver1, 
                  isNew: true,
                ),
              );
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _driverRequests.clear();
          _driverRequests.addAll(realDrivers);
          _isLoading = false;
          _showSearching = realDrivers.isEmpty; // Keep searching if nobody found
        });

        // 🟢 AUTO-REQUEST LOGIC: 
        for (var driver in realDrivers) {
          _sendSilentRequestToDriver(driver);
        }
      }
    });
  }

  // This creates a Firestore entry so the driver gets the popup automatically
  void _sendSilentRequestToDriver(DriverRequest driver) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Check if request already exists for this ride/driver combo to avoid duplicates
      String rideId = 'RIDE_${currentUser.uid}_${driver.id}';
      
      final rideDoc = await FirebaseFirestore.instance.collection('rides').doc(rideId).get();
      if (rideDoc.exists) return; // Already sent

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final customerName = userDoc.data()?['fullName'] ?? 'Customer';

      await FirebaseFirestore.instance.collection('rides').doc(rideId).set({
        'rideId': rideId,
        'customerId': currentUser.uid,
        'customerName': customerName,
        'driverId': driver.id,
        'driverName': driver.name,
        'serviceType': widget.selectedCategory,
        'fare': _currentFare,
        'fromLocation': widget.fromLocation,
        'toLocation': widget.toLocation,
        'fromCoordinates': _fromLocation != null ? {'lat': _fromLocation!.latitude, 'lng': _fromLocation!.longitude} : null,
        'toCoordinates': _toLocation != null ? {'lat': _toLocation!.latitude, 'lng': _toLocation!.longitude} : null,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'carModel': driver.carModel,
        'licensePlate': driver.licensePlate,
      }, SetOptions(merge: true));

      _listenForRideAcceptance(rideId);
    } catch (e) {
      print("❌ Silent Request Error: $e");
    }
  }

  // This handles the fare logic
  void _calculateAndSetFare() {
    // We only calculate if we have both coordinates
    if (_fromLocation != null && _toLocation != null) {
      const Distance distance = Distance();
      
      // 1. Calculate the distance (meters to KM)
      double distanceInKm =
          distance.as(LengthUnit.Meter, _fromLocation!, _toLocation!) / 1000;

      // 2. Use our realistic calculator that includes:
      // - Base Fare
      // - Distance Rate
      // - Time Rate
      // - Service Type Multiplier (Bike/Cab/Recovery)
      int calculatedFare = FareCalculator.calculateFare(
        distanceInKm: distanceInKm,
        serviceType: widget.selectedSubCategory,
      );

      // 3. Update the UI
      setState(() {
        _currentFare = calculatedFare;
      });
      
      print(
        " Fare Calculated: Distance=${distanceInKm.toStringAsFixed(2)}km, Fare=Rs$_currentFare",
      );
    }
  }


  void _showNewDriverNotification(String driverName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.directions_car, color: Colors.white),
            const SizedBox(width: 10),
            Text('$driverName is available!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
            Opacity(
              opacity: 0.7,
              child: SimpleFromToSection(
                fromText: widget.fromLocation,
                toText: widget.toLocation,
                onFromChanged: (newFrom, lat, lng) {
                  // Handle from location change with coordinates
                  print(" FindRide FROM Selected: $newFrom, ($lat, $lng)");
                  setState(() {
                    _fromLocation = LatLng(lat, lng);
                  });
                  _calculateAndSetFare();
                },
                onToChanged: (newTo, lat, lng) {
                  // Handle to location change with coordinates
                  print(" FindRide TO Selected: $newTo, ($lat, $lng)");
                  setState(() {
                    _toLocation = LatLng(lat, lng);
                  });
                  _calculateAndSetFare();
                },
                onAddMore: () {
                  _addMoreDestinations();
                },
              ),
            ),
            SizedBox(height: screenWidth * 0.1),

            // 2. Map Container - FIX: PASS COORDINATES HERE
            Stack(
              children: [
                MapWidget(
                  onMapTap: _openFullMapScreen,
                  fromLocation: _fromLocation, // Pass coordinates
                  toLocation: _toLocation, // Pass coordinates
                  height: 300,
                ),
                // Searching Overlay
                if (_showSearching)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.4),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Searching for drivers...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Please wait',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: screenWidth * 0.05),

            // 3. Drivers Viewing Section
            DriversViewingSection(driverImages: driverImages),

            // 4. Driver Requests Header
            SizedBox(height: screenWidth * 0.04),
            _buildDriverRequestsHeader(screenWidth),

            // 5. Searching Animation (Only when no drivers yet)
            if (_isLoading && _driverRequests.isEmpty)
              _buildSearchingAnimation(screenWidth),

            // 6. Driver Request Cards
            if (_driverRequests.isNotEmpty)
              ..._driverRequests.map((driver) {
                // Instantly sync UI if driver countered
                driver.fare = _driverFares[driver.id] ?? _currentFare;
                return Padding(
                  padding: EdgeInsets.only(bottom: screenWidth * 0.04),
                  child: DriverRequestCard(
                    driver: driver,
                    onAccept: () => _acceptDriverRequest(driver),
                    onReject: () => _declineDriverRequest(driver.id),
                  ),
                );
              }),

            // 7. No Drivers Found Message
            if (!_isLoading && _driverRequests.isEmpty)
              _buildNoDriversFound(screenWidth),

            // 8. Dotted Divider
            if (_driverRequests.isNotEmpty) const BlueDottedDivider(screenWidth: 0.1),

            // 9. Fare Adjustment Section
            FareAdjustmentSection(
              initialFare: _currentFare,
              onFareChanged: (newFare) {
                setState(() {
                  _currentFare = newFare;
                  for (var driver in _driverRequests) {
                    driver.fare = newFare;
                  }
                });
              },
            ),

            // 10. Action Buttons
            _buildActionButtons(screenWidth),

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

  Widget _buildDriverRequestsHeader(double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _driverRequests.isEmpty
              ? (_isLoading ? 'Finding drivers...' : 'No drivers found')
              : 'Driver Requests (${_driverRequests.length})',
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
            color: HColors.primary,
          ),
        ),
        if (_driverRequests.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenWidth * 0.01,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  '${_driverRequests.length} Available',
                  style: TextStyle(
                    fontSize: screenWidth * 0.025,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSearchingAnimation(double screenWidth) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: screenWidth * 0.05),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: HColors.primary,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: screenWidth * 0.03),
          Text(
            'Searching for available drivers...',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          Text(
            'This may take a few seconds',
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenWidth * 0.02),
          LinearProgressIndicator(
            color: HColors.primary,
            backgroundColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildNoDriversFound(double screenWidth) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: screenWidth * 0.05),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.car_repair, size: 50, color: Colors.orange.shade400),
          SizedBox(height: screenWidth * 0.03),
          Text(
            'No drivers available',
            style: TextStyle(
              fontSize: screenWidth * 0.038,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade800,
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          Text(
            'Try raising your fare or check back later',
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: Colors.orange.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(top: screenWidth * 0.05),
      child: Column(
        children: [
          /* Removed manual broadcast button - it's now automatic! */
          
          // Raise Fare Button
          SizedBox(
            width: screenWidth * 0.8,
            child: ElevatedButton(
              onPressed: _raiseFare,
              style: ElevatedButton.styleFrom(
                backgroundColor: HColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenWidth * 0.04,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_upward, color: Colors.white),
                  SizedBox(width: screenWidth * 0.03),
                  const Text('Raise Fare'),
                ],
              ),
            ),
          ),

          SizedBox(height: screenWidth * 0.03),

          // Cancel Ride Button
          SizedBox(
            width: screenWidth * 0.8,
            child: ElevatedButton(
              onPressed: _cancelRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.red, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.close, color: Colors.red),
                  SizedBox(width: screenWidth * 0.03),
                  const Text('Cancel Ride', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  void _raiseFare() {
    setState(() {
      _currentFare += 100;
      for (var driver in _driverRequests) {
        // Only update drivers who haven't counter-offered
        if (!_driverFares.containsKey(driver.id)) {
           driver.fare = _currentFare;
        }
      }
    });
    
    // 🟢 FIX: Send raised fare to Firestore so ALL drivers see it instantly!
    if (_broadcastRideId != null) {
      FirebaseFirestore.instance.collection('rides').doc(_broadcastRideId).update({'fare': _currentFare}).catchError((e) => print("Update Error: $e"));
    }
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Also update any silent requests previously generated to sync the new fare across all
      for (var driver in _driverRequests) {
         if (!_driverFares.containsKey(driver.id)) {
           FirebaseFirestore.instance.collection('rides').doc('RIDE_${currentUser.uid}_${driver.id}').update({'fare': _currentFare}).catchError((e) => {});
         }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.payments, color: Colors.white), // Changed from attach_money to avoid $
            const SizedBox(width: 10),
            Text('Fare raised to Rs $_currentFare'),
          ],
        ),
        backgroundColor: HColors.primary,
      ),
    );
  }

  void _cancelRide() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 10),
                Text('Cancel Ride'),
              ],
            ),
            content: const Text('Are you sure you want to cancel this ride?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  // CLOSE UI INSTANTLY FOR PERFECT UX
                  Navigator.of(context, rootNavigator: true).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close FindRideScreen
                  
                  // FIRE AND FORGET DELETION (Do not await in UI flow)
                  _deleteRideRequests();
                },
                child: const Text('Yes', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _deleteRideRequests() async {
    // 🟢 Clean up: Delete the broadcast ride document so drivers stop seeing it
    if (_broadcastRideId != null) {
      try {
        await FirebaseFirestore.instance.collection('rides').doc(_broadcastRideId).delete();
        print("🗑️ Broadcast ride $_broadcastRideId deleted on cancel.");
      } catch (e) {
        print("Failed deleting broadcast ride: $e");
      }
    }
    // Also clean up any individual driver ride docs
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final myRides = await FirebaseFirestore.instance
            .collection('rides')
            .where('customerId', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'pending')
            .get();
        for (var doc in myRides.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        print("Failed deleting individual rides: $e");
      }
    }
  }

  // Logic for broadcast and individual driver requests is now automated
  // within _startRealDriverListener and _sendSilentRequestToDriver.

  // Separated listener logic to handle both targeted and broadcast requests
  void _listenForRideAcceptance(String rideId) {
    FirebaseFirestore.instance
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data()!;
        final status = data['status'];
        
        if (status == 'accepted') {
          print("🟢 Ride $rideId FINALIZED and ACCEPTED!");

          // Clean up individual requests for this ride
          _deleteRideRequests();
        
          // Construct the DriverRequest object
          final acceptedDriver = DriverRequest(
            id: data['driverId'],
            name: data['driverName'],
            cnic: 'Verified',
            eta: 'Calculating...', 
            rating: (data['driverRating'] ?? 5.0).toDouble(),
            totalRides: data['totalRides'] ?? 0,
            carModel: data['carModel'] ?? 'Vehicle',
            licensePlate: data['licensePlate'] ?? '...',
            distance: '...',
            fare: data['fare'],
            imagePath: HImages.driver1,
            isNew: false,
          );

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RideStartedScreen(
                  driver: acceptedDriver,
                  fromLocation: widget.fromLocation,
                  toLocation: widget.toLocation,
                  fromCoordinates: _fromLocation ?? widget.fromCoordinates,
                  toCoordinates: _toLocation ?? widget.toCoordinates,
                  rideId: rideId,
                  fare: data['fare'],
                ),
              ),
            );
          }
        }
      }
    });
  }

  void _declineDriverRequest(String driverId) {
    setState(() {
      _driverRequests.removeWhere((driver) => driver.id == driverId);
    });

    // 🔄 RE-NEGOTIATION SYNC: Instead of deleting, mark as 'rejected'
    // so the driver can see the original request again and try a different price.
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String rideId = 'RIDE_${currentUser.uid}_$driverId';
      FirebaseFirestore.instance.collection('rides').doc(rideId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      }).catchError((e) => print("Error rejecting driver: $e"));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.thumb_down, color: Colors.white),
            SizedBox(width: 10),
            Text('Driver request declined'),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _acceptDriverRequest(DriverRequest driver) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.thumb_up, color: Colors.green),
                SizedBox(width: 10),
                Text('Accept Offer?'),
              ],
            ),
            content: Text(
              'Accept ${driver.name}\'s offer for Rs ${driver.fare}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    // Update the existing ride document to 'accepted'
                    String rideId = 'RIDE_${currentUser.uid}_${driver.id}';
                    
                    await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
                      'status': 'accepted',
                      'acceptedAt': FieldValue.serverTimestamp(),
                    });
                    
                    Navigator.pop(context); // Close dialog
                    
                    // The _listenForRideAcceptance (called via _listenForDriverOffers logic or direct) 
                    // will handle navigation to the RideStartedScreen
                    _listenForRideAcceptance(rideId);

                  } catch (e) {
                    print("❌ Error accepting driver: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Accept', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
            title: const Row(
              children: [
                Icon(Icons.map, color: HColors.primary),
                SizedBox(width: 10),
                Text('Full Map'),
              ],
            ),
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

  void _addMoreDestinations() {
    // Implementation for adding more destinations
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add More Stops'),
            content: const Text('This feature will allow you to add multiple stops.'),
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

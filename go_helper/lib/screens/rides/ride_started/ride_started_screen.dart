import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_helper/shared/widgets/AppDrawer.dart';
import 'package:go_helper/shared/widgets/ultra_minimal_from_to.dart';
import 'package:go_helper/shared/widgets/map_container.dart';
import 'package:go_helper/shared/layouts/bottom_nav_bar.dart';
import 'package:go_helper/model/driver_request_model.dart';
import 'package:go_helper/model/chat_message.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:latlong2/latlong.dart';

// Import widgets
import 'widgets/driver_info_section.dart';
import 'widgets/blue_dotted_divider.dart';
import 'widgets/chat_section.dart';
import 'widgets/payment_section.dart';
import 'widgets/trip_locations_section.dart';
import 'widgets/cancel_ride_button.dart';
import 'package:go_helper/screens/rides/cancel_ride_reason_screen.dart';

class RideStartedScreen extends StatefulWidget {
  final DriverRequest driver;
  final String fromLocation;
  final String toLocation;
  final LatLng? fromCoordinates;
  final LatLng? toCoordinates;
  final String rideId;
  final int fare;

  const RideStartedScreen({
    super.key,
    required this.driver,
    required this.fromLocation,
    required this.toLocation,
    required this.rideId,
    required this.fare,
    this.fromCoordinates,
    this.toCoordinates,
  });

  @override
  State<RideStartedScreen> createState() => _RideStartedScreenState();
}

class _RideStartedScreenState extends State<RideStartedScreen> {
  int _currentIndex = 0;
  String _etaMinutes = "Calculating...";
  final TextEditingController _messageController = TextEditingController();
  StreamSubscription<DocumentSnapshot>? _statusSubscription;
  String _rideStatus = 'accepted';
  LatLng? _driverCoords;

  @override
  void initState() {
    super.initState();
    _startETACountdown();
    _listenToRideStatus();
  }

  void _listenToRideStatus() {
    _statusSubscription = FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists && mounted) {
        // If doc is deleted, assume it was cancelled
        Navigator.popUntil(context, (route) => route.isFirst);
        _showSnackBar('Ride is no longer active', Colors.orange);
        return;
      }

      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>;
        final status = data['status'];

        setState(() {
          _rideStatus = status;
          if (data['driverCoordinates'] != null) {
            _driverCoords = LatLng(
                data['driverCoordinates']['lat'], 
                data['driverCoordinates']['lng']);
          }
        });

        if (status == 'cancelled') {
          Navigator.popUntil(context, (route) => route.isFirst);
          _showSnackBar('Ride has been cancelled', Colors.red);
        } else if (status == 'completed') {
          // If the driver completes it, the rider should know
          Navigator.popUntil(context, (route) => route.isFirst);
          _showSnackBar('Ride completed successfully!', Colors.green);
        }
      }
    });
  }

  void _startETACountdown() {
    int? eta = int.tryParse(_etaMinutes);
    if (eta == null) {
      // It's still 'Calculating...', try again later
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) _startETACountdown();
      });
      return;
    }
    
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted && eta! > 1) {
        setState(() {
          eta = eta! - 1;
          _etaMinutes = eta.toString();
        });
        _startETACountdown();
      }
    });
  }

  void _sendMessage(String text) async {
    final now = DateTime.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) return;

    // Check if user is driver or customer to set isDriver flag
    // For simplicity here, we assume if current user id == driver.id, then isDriver = true
    // (Actual logic would check userType from Firestore)
    
    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .collection('chats')
          .add({
        'text': text,
        'senderId': user.uid,
        'isDriver': false, // In this screen (Customer side), it's always false
        'time': time,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Colors.white,
      body: _buildBody(screenHeight, screenWidth),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBody(double screenHeight, double screenWidth) {
    return Stack(
      children: [
        _buildMainContent(screenHeight, screenWidth),
        _buildBottomOverlay(screenHeight, screenWidth),
      ],
    );
  }

  Column _buildMainContent(double screenHeight, double screenWidth) {
    return Column(
      children: [
        // Space at top
        SizedBox(height: screenHeight * 0.03),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: SimpleFromToSection(
            fromText: widget.fromLocation,
            toText: widget.toLocation,
            onFromChanged: (newFrom, lat, lng) {
              print("🟢 RideStarted FROM Selected: $newFrom, ($lat, $lng)");
            },
            onToChanged: (newTo, lat, lng) {
              print("🔴 RideStarted TO Selected: $newTo, ($lat, $lng)");
            },
            onAddMore: () {
              _addMoreDestinations();
            },
          ),
        ),
        SizedBox(
          height: screenHeight * 0.4,
          child: MapWidget(
            onMapTap: _openFullMapScreen,
            // PHASE 1: Heading to pickup
            fromLocation: (_rideStatus == 'accepted' || _rideStatus == 'arrived') 
                ? _driverCoords ?? widget.fromCoordinates 
                : widget.fromCoordinates, // PHASE 2: Heading to destination
            toLocation: (_rideStatus == 'accepted' || _rideStatus == 'arrived') 
                ? widget.fromCoordinates 
                : widget.toCoordinates,
            height: screenHeight * 0.4,
            onRouteCalculated: (durationSeconds) {
              if (mounted) {
                setState(() {
                  _etaMinutes = (durationSeconds / 60).ceil().toString();
                });
              }
            },
          ),
        ),
        Expanded(child: Container(color: Colors.transparent)),
      ],
    );
  }

  Positioned _buildBottomOverlay(double screenHeight, double screenWidth) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: screenHeight * 0.4,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(screenWidth * 0.06),
            topRight: Radius.circular(screenWidth * 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 5,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            children: [
              SizedBox(height: screenWidth * 0.02),

              DriverInfoSection(
                driver: widget.driver,
                etaMinutes: _etaMinutes,
                onContactDriver: _contactDriver,
                screenWidth: screenWidth,
              ),

              SizedBox(height: screenWidth * 0.04),
              BlueDottedDivider(screenWidth: screenWidth),
              SizedBox(height: screenWidth * 0.04),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('rides')
                    .doc(widget.rideId)
                    .collection('chats')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  List<ChatMessage> messages = [];
                  if (snapshot.hasData) {
                    messages = snapshot.data!.docs.map((doc) {
                      return ChatMessage.fromMap(doc.data() as Map<String, dynamic>);
                    }).toList();
                  }

                  return ChatSection(
                    messageController: _messageController,
                    chatMessages: messages.reversed.toList(),
                    onSendMessage: _sendMessage,
                    screenWidth: screenWidth,
                  );
                },
              ),

              SizedBox(height: screenWidth * 0.04),
              BlueDottedDivider(screenWidth: screenWidth),
              SizedBox(height: screenWidth * 0.04),

              PaymentSection(fare: widget.fare, screenWidth: screenWidth),

              SizedBox(height: screenWidth * 0.04),
              BlueDottedDivider(screenWidth: screenWidth),
              SizedBox(height: screenWidth * 0.04),

              TripLocationsSection(
                fromLocation: widget.fromLocation,
                toLocation: widget.toLocation,
                screenWidth: screenWidth,
              ),

              SizedBox(height: screenWidth * 0.04),
              BlueDottedDivider(screenWidth: screenWidth),
              SizedBox(height: screenWidth * 0.04),

              CancelRideButton(
                onPressed: _showCancelRideDialog,
                screenWidth: screenWidth,
              ),

              SizedBox(height: screenWidth * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return CustomBottomNavBar(
      currentIndex: _currentIndex,
      onTabSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }

  // Helper Methods
  void _addMoreDestinations() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add More Stops'),
            content: const Text(
              'This feature allows adding multiple stops to your trip.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: HColors.primary)),
              ),
            ],
          ),
    );
  }

  // Dialog Methods
  void _contactDriver() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Contact ${widget.driver.name}',
              style: const TextStyle(color: HColors.primary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.phone, color: HColors.primary),
                  title: const Text(
                    'Call Driver',
                    style: TextStyle(color: HColors.primary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar(
                      'Calling ${widget.driver.name}...',
                      HColors.primary,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.message, color: HColors.primary),
                  title: const Text(
                    'Send SMS',
                    style: TextStyle(color: HColors.primary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Opening SMS...', HColors.primary);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: HColors.primary)),
              ),
            ],
          ),
    );
  }

  void _showCancelRideDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Cancel Ride?',
              style: TextStyle(color: HColors.primary),
            ),
            content: const Text(
              'Are you sure you want to cancel this ongoing ride? A cancellation fee may apply.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No', style: TextStyle(color: HColors.primary)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CancelRideReasonScreen(
                        rideId: widget.rideId,
                        isDriver: false,
                      ),
                    ),
                  );
                },
                child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _cancelRide() async {
    try {
      //  Actually cancel the ride in Firestore
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .update({'status': 'cancelled'});

      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
        _showSnackBar('Ride cancelled successfully', Colors.red);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error cancelling ride: $e', Colors.red);
      }
    }
  }

  void _openFullMapScreen() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Full Map', style: TextStyle(color: HColors.primary)),
            content: const Text('Full map screen will open here.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: HColors.primary)),
              ),
            ],
          ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }
}

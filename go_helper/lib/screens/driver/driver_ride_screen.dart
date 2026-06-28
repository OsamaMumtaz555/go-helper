import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_helper/model/chat_message.dart';
import 'package:go_helper/shared/widgets/map_container.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_helper/screens/rides/cancel_ride_reason_screen.dart';
import 'package:geolocator/geolocator.dart';

class DriverRideScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> rideData;

  const DriverRideScreen({
    super.key,
    required this.rideId,
    required this.rideData,
  });

  @override
  State<DriverRideScreen> createState() => _DriverRideScreenState();
}

class _DriverRideScreenState extends State<DriverRideScreen> {
  final TextEditingController _messageController = TextEditingController();
  StreamSubscription<DocumentSnapshot>? _statusSubscription;
  LatLng? _fromCoords;
  LatLng? _toCoords;
  LatLng? _driverCoords;
  String _rideStatus = 'accepted';

  @override
  void initState() {
    super.initState();
    if (widget.rideData['fromCoordinates'] != null) {
      _fromCoords = LatLng(
        widget.rideData['fromCoordinates']['lat'],
        widget.rideData['fromCoordinates']['lng'],
      );
    }
    if (widget.rideData['toCoordinates'] != null) {
      _toCoords = LatLng(
        widget.rideData['toCoordinates']['lat'],
        widget.rideData['toCoordinates']['lng'],
      );
    }
    
    // Default ride status from data if available
    if (widget.rideData['status'] != null) {
      _rideStatus = widget.rideData['status'];
    }

    _listenToRideStatus();
    _fetchDriverLocation();
  }

  void _fetchDriverLocation() async {
    try {
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5));
          
      if (mounted) {
        setState(() {
          _driverCoords = LatLng(pos!.latitude, pos.longitude);
        });
        
        // Push coordinate to Firestore for customer map
        await FirebaseFirestore.instance.collection('rides').doc(widget.rideId).update({
          'driverCoordinates': {
            'lat': pos.latitude,
            'lng': pos.longitude,
          }
        }).catchError((e) => print("Coordinates update error: $e"));
      }
    } catch (e) {
      print("Error fetching driver loc: $e");
    }
  }

  void _listenToRideStatus() {
    _statusSubscription = FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists && mounted) {
        // If doc is deleted, assume it was cancelled
        Navigator.pop(context);
        _showSnackBar('Ride is no longer active', Colors.orange);
        return;
      }

      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>;
        final status = data['status'];

        setState(() {
           _rideStatus = status;
        });

        if (status == 'cancelled') {
          Navigator.pop(context);
          _showSnackBar('Customer has cancelled the ride', Colors.red);
        }
      }
    });
  }

  void _sendMessage(String text) async {
    final now = DateTime.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .collection('chats')
          .add({
        'text': text,
        'senderId': user.uid,
        'isDriver': true,
        'time': time,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  void _markArrived() async {
    setState(() => _rideStatus = 'arrived');
    try {
      await FirebaseFirestore.instance.collection('rides').doc(widget.rideId).update({
        'status': 'arrived',
      });
      _showSnackBar('Notified customer you have arrived.', Colors.blue);
    } catch (e) {
      print("Update error: $e");
    }
  }

  void _startTrip() async {
    setState(() => _rideStatus = 'in_progress');
    try {
      await FirebaseFirestore.instance.collection('rides').doc(widget.rideId).update({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
      });
      _showSnackBar('Trip Started! Heading to destination.', Colors.blue);
    } catch (e) {
      print("Update error: $e");
    }
  }

  void _completeRide() async {
    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      // 🔑 SYNC FIX: Update Driver's Profile stats (Total Rides & Earnings)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final fare = (widget.rideData['fare'] as num?)?.toInt() ?? 0;
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'totalRides': FieldValue.increment(1),
          'totalEarnings': FieldValue.increment(fare),
        }).catchError((e) => print("Stats update error: $e"));
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip Completed! Great job!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error completing ride: $e");
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ongoing Trip'),
        backgroundColor: Colors.white,
        foregroundColor: HColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Background Map
          Column(
            children: [
              Expanded(
                flex: 4,
                child: MapWidget(
                  onMapTap: () {},
                  // PHASE 1: Heading to pickup
                  fromLocation: (_rideStatus == 'accepted' || _rideStatus == 'arrived') 
                      ? _driverCoords ?? _fromCoords 
                      : _fromCoords, // PHASE 2: Heading to destination
                  toLocation: (_rideStatus == 'accepted' || _rideStatus == 'arrived') 
                      ? _fromCoords // Customer Pickup
                      : _toCoords,  // Final Destination
                  height: screenHeight * 0.4,
                ),
              ),
              const Expanded(flex: 5, child: SizedBox()),
            ],
          ),
          
          // Bottom Info Draggable-like Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: screenHeight * 0.55,
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomerHeader(screenWidth),
                    const Divider(height: 30),
                    _buildTripLocations(screenWidth),
                    const Divider(height: 30),
                    _buildChatSection(screenWidth),
                    const SizedBox(height: 30),
                    _buildActionButtons(screenWidth),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerHeader(double screenWidth) {
    return Row(
      children: [
        CircleAvatar(
          radius: screenWidth * 0.07,
          backgroundColor: Colors.green.withOpacity(0.1),
          child: const Icon(Icons.person, color: Colors.green),
        ),
        SizedBox(width: screenWidth * 0.04),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.rideData['customerName'] ?? 'Customer',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: HColors.primary,
                ),
              ),
              Text(
                'Customer is waiting for you',
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _callCustomer(),
          icon: const Icon(Icons.call, color: Colors.green),
          style: IconButton.styleFrom(
            backgroundColor: Colors.green.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  void _callCustomer() async {
    try {
      // Get customer phone from Firestore
      final customerId = widget.rideData['customerId'];
      if (customerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer ID not found')),
        );
        return;
      }

      final customerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();

      String phone = '03001234567'; // fallback
      if (customerDoc.exists) {
        final customerData = customerDoc.data() as Map<String, dynamic>;
        phone = customerData['phone'] ?? phone;
      }

      final url = Uri.parse("tel:$phone");
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer phone: $phone')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildTripLocations(double screenWidth) {
    return Column(
      children: [
        _buildLocationRow(
          Icons.my_location, 
          "Pickup", 
          widget.rideData['fromLocation'] ?? '...',
          Colors.blue
        ),
        const SizedBox(height: 15),
        _buildLocationRow(
          Icons.location_on, 
          "Dropoff", 
          widget.rideData['toLocation'] ?? '...',
          Colors.red
        ),
      ],
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                address, 
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chat with Customer',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rides')
              .doc(widget.rideId)
              .collection('chats')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            
            final messages = snapshot.data!.docs
                .map((doc) => ChatMessage.fromMap(doc.data() as Map<String, dynamic>))
                .toList();

            return Container(
              height: 120,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return Align(
                    alignment: msg.isDriver ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: msg.isDriver ? HColors.primary : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: msg.isDriver ? Colors.white : Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {
                if (_messageController.text.isNotEmpty) {
                  _sendMessage(_messageController.text);
                }
              },
              icon: const Icon(Icons.send, color: HColors.primary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(double screenWidth) {
    String mainButtonText = 'ARRIVED AT PICKUP';
    VoidCallback mainButtonAction = _markArrived;
    Color mainButtonColor = Colors.blue;

    if (_rideStatus == 'arrived') {
      mainButtonText = 'START TRIP';
      mainButtonAction = _startTrip;
      mainButtonColor = Colors.orange;
    } else if (_rideStatus == 'in_progress') {
      mainButtonText = 'COMPLETE TRIP';
      mainButtonAction = _completeRide;
      mainButtonColor = Colors.green;
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: mainButtonAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: mainButtonColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: Text(
              mainButtonText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CancelRideReasonScreen(
                    rideId: widget.rideId,
                    isDriver: true,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text(
              'CANCEL TRIP',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }
}

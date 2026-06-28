import 'package:flutter/material.dart';
import 'package:go_helper/services/auth_service.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:go_helper/shared/widgets/AppDrawer.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_helper/screens/driver/driver_ride_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isOnline = false;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<DocumentSnapshot>? _userStream;
  Map<String, dynamic>? _driverData;
  Timer? _refreshTimer;
  StreamSubscription<QuerySnapshot>? _rideSubscription;
  bool _isAccepting = false; // Prevent double-accept
  final Set<String> _declinedRides = {};

  @override
  void initState() {
    super.initState();
    _listenToDriverData();
    _listenForAcceptedRides();
    // 🟢 UI AUTO-REFRESH:
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() {});
    });
  }

  void _listenToDriverData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          setState(() {
            _driverData = snapshot.data();
          });
          
          final isApprovedField = _driverData?['isApproved'] == true;
          final driverStatus = _driverData?['status'] ?? 'pending';
          final isTrulyApproved = isApprovedField || driverStatus == 'approved';

          // Force them offline if admin revokes their approval
          if (_driverData != null && !isTrulyApproved && _isOnline) {
            _toggleOnline(false);
          }
          
          print(" Driver data updated: isTrulyApproved=$isTrulyApproved, fullName=${_driverData?['fullName']}");
        }
      });
    }
  }

  void _listenForAcceptedRides() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _rideSubscription = FirebaseFirestore.instance
        .collection('rides')
        .where('driverId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty && mounted) {
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final status = data['status'];
          final originalRideId = data['originalRideId'];

          if (status == 'accepted') {
            print("🎉 Ride ${doc.id} matched and accepted! Starting trip...");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DriverRideScreen(
                  rideId: doc.id,
                  rideData: data,
                ),
              ),
            );
            return; // Exit loop after navigating
          } else if (status == 'rejected' && originalRideId != null) {
            // 🔄 Re-negotiation logic: Remove from declined so it shows up again
            if (_declinedRides.contains(originalRideId)) {
              setState(() {
                _declinedRides.remove(originalRideId);
              });
              _showSnackBar('Your offer was rejected. You can try a different price!', Colors.orange);
              
              // Reset status back to pending so it doesn't keep triggering
              FirebaseFirestore.instance.collection('rides').doc(doc.id).update({'status': 'pending'});
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _positionStream?.cancel();
    _userStream?.cancel();
    _rideSubscription?.cancel();
    super.dispose();
  }

  // This starts tracking the driver's movements and saves them to the map
  Future<void> _toggleOnline(bool online) async {
    setState(() => _isOnline = online);

    // Save their online status in our system
    await AuthService().updateProfile({'isOnline': online});

    if (online) {
      // 1. Ask for permission to use GPS
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Fetch immediate location to eliminate delay before drivers show in searches
      try {
        Position currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'currentLocation': {
              'lat': currentPosition.latitude,
              'lng': currentPosition.longitude,
            },
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        print("Error getting initial location: $e");
      }

      // 2. Start following their location every few meters
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position position) {
        // 3. Save their current Lat/Lng to Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'currentLocation': {
              'lat': position.latitude,
              'lng': position.longitude,
            },
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are now Online! Customers can see you.'))
        );
      }
    } else {
      // Stop tracking if they go offline
      _positionStream?.cancel();
    }
  }

  // Accept a ride request
  void _acceptRideAtCustomerPrice(String rideId, Map<String, dynamic> rideData) async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Check if still pending
      final freshDoc = await FirebaseFirestore.instance.collection('rides').doc(rideId).get();
      if (!freshDoc.exists || freshDoc.data()?['status'] != 'pending') {
         _showSnackBar('Ride no longer available', Colors.orange);
         return;
      }

      // 2. Instead of starting trip, we send an OFFER at the customer's price
      int customerFare = rideData['fare'] ?? 0;
      
      // Send offer
      await _sendFareOffer(rideId, rideData, customerFare);

      _showSnackBar('Offer sent! Waiting for customer to accept...', Colors.blue);
      
    } catch (e) {
      print("Accept Offer Error: $e");
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  Future<void> _sendFareOffer(String rideId, Map<String, dynamic> data, int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Create/Update a specific ride doc for this driver-customer pair
    String customerId = data['customerId'];
    String specificRideId = 'RIDE_${customerId}_${user.uid}';

    await FirebaseFirestore.instance.collection('rides').doc(specificRideId).set({
      'rideId': specificRideId,
      'originalRideId': rideId, // 🔑 Store original ID for re-negotiation tracking
      'fare': amount,
      'customerId': customerId,
      'customerName': data['customerName'] ?? 'Customer',
      'driverId': user.uid,
      'driverName': _driverData?['fullName'] ?? 'Driver',
      'carModel': _driverData?['vehicleModel'] ?? 'Vehicle',
      'licensePlate': _driverData?['licensePlate'] ?? '...',
      'driverRating': _driverData?['rating'] ?? 5.0,
      'status': 'pending', // Waiting for customer to accept
      'serviceType': data['serviceType'],
      'fromLocation': data['fromLocation'],
      'toLocation': data['toLocation'],
      'fromCoordinates': data['fromCoordinates'],
      'toCoordinates': data['toCoordinates'],
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    // Also update current state to show waiting
    setState(() {
      _declinedRides.add(rideId); // Hide the broadcast one as we've made an offer
    });
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color)
      );
    }
  }

  // Decline a ride request (for direct requests only)
  void _declineRide(String rideId, Map<String, dynamic> rideData) async {
    setState(() {
      _declinedRides.add(rideId); // hide locally since broadcasts aren't easily "declined" globally
    });
    try {
      // For broadcast rides, don't change the status (other drivers should still see it)
      // For direct rides, mark as declined
      if (rideData['driverId'] != 'all') {
        await FirebaseFirestore.instance.collection('rides').doc(rideId).update({'status': 'declined'});
      }
      print("❌ Ride $rideId declined");
    } catch (e) {
      print("❌ Decline Ride Error: e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApprovedField = _driverData?['isApproved'] == true;
    final driverStatus = _driverData?['status'] ?? 'pending';
    final isTrulyApproved = isApprovedField || driverStatus == 'approved';

    if (_driverData != null && !isTrulyApproved) {
      return Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(title: const Text('Driver Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings, size: 80, color: Colors.orange.shade300),
              const SizedBox(height: 20),
              const Text(
                'Pending Admin Approval',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  'Your account is waiting for administrator approval. You will be able to receive rides once approved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          Switch(
            value: _isOnline,
            onChanged: (value) => _toggleOnline(value),
            activeThumbColor: Colors.green,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Center(
              child: Text(
                _isOnline ? "ONLINE" : "OFFLINE",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isOnline ? Colors.green : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Stats Card
            _buildStatsCard(screenWidth),
            const SizedBox(height: 30),

            // Pending Requests Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Incoming Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isOnline && _driverData != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Listening: ${_driverData!['serviceType'] ?? 'all'}',
                      style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Offline State
            if (!_isOnline)
              _buildEmptyState(
                icon: Icons.cloud_off,
                title: 'You are currently offline',
                subtitle: 'Go online to start receiving requests from customers.',
              )
            // Online: Show LIVE pending requests from Firestore using StreamBuilder
            else if (user != null)
              StreamBuilder<QuerySnapshot>(
                // ✅ FIX: Only filter by 'status' = 'pending' (single field query, no composite index needed)
                stream: FirebaseFirestore.instance
                    .collection('rides')
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    print(" StreamBuilder Error: ${snapshot.error}");
                    return _buildErrorState(
                      'Error loading requests',
                      'Error: ${snapshot.error}',
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.search,
                      title: 'Searching for requests...',
                      subtitle: 'We will notify you when a customer needs help.',
                    );
                  }

                  //  FIX: Filter in-memory by serviceType and driverId
                  // This avoids needing a Firestore composite index
                  final allRides = snapshot.data!.docs;
                  final matchingRides = allRides.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    // Check if driver just declined this
                    if (_declinedRides.contains(doc.id)) return false;

                    // 1. Skip rides I created (I'm the customer for these)
                    if (data['customerId'] == user.uid) return false;

                    // 2. Hide requests for other service types
                    final driverService = _driverData!['serviceType'];
                    if (data['serviceType'] != driverService) return false;

                    // 3. Only show broadcasts ('all') or rides targeted at me
                    // If driverId is missing, assume it's for everyone (fallback)
                    final driverId = data['driverId'] ?? 'all';
                    if (driverId != 'all' && driverId != user.uid) return false;

                    // 💡 NEW SYNC FIX: If this is a broadcast ride, but I have already 
                    // made a specific offer for this customer, hide the broadcast one!
                    if (driverId == 'all') {
                      final customerId = data['customerId'];
                      bool alreadyOffered = allRides.any((d) {
                        final rd = d.data() as Map<String, dynamic>;
                        return rd['driverId'] == user.uid && rd['customerId'] == customerId;
                      });
                      if (alreadyOffered) return false;
                    }

                    // 4. Hide requests older than 1 minute (60 seconds)
                    final timestamp = data['timestamp'] as Timestamp?;
                    if (timestamp != null) {
                      final diff = DateTime.now().difference(timestamp.toDate());
                      if (diff.inSeconds > 60) return false;
                    }

                    return true;
                  }).toList();

                  int totalPending = snapshot.data!.docs.length;

                  print(" Driver StreamBuilder: ${snapshot.data!.docs.length} total pending rides, ${matchingRides.length} matching rides found");

                  // Debug: Log ALL pending rides for troubleshooting
                  for (var doc in snapshot.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    print("    Ride ${doc.id}: serviceType=${d['serviceType']}, driverId=${d['driverId']}, customerId=${d['customerId']}, status=${d['status']}");
                  }

                  if (matchingRides.isEmpty) {
                    if (totalPending > 0) {
                      return _buildEmptyState(
                        icon: Icons.filter_alt,
                        title: 'Requests available!',
                        subtitle: 'There are $totalPending pending requests, but they are targeted at other drivers. Waiting for a broadcast or direct request...',
                      );
                    }
                    return _buildEmptyState(
                      icon: Icons.search,
                      title: 'Searching for requests...',
                      subtitle: 'No new requests yet. We\'ll show them as they come in.',
                    );
                  }

                  // Show the matching rides as cards
                  return Column(
                    children: matchingRides.map((doc) {
                      final rideData = doc.data() as Map<String, dynamic>;
                      final rideId = doc.id;
                      return _buildRideRequestCard(rideId, rideData, screenWidth);
                    }).toList(),
                  );
                },
              )
            else
              _buildEmptyState(
                icon: Icons.error_outline,
                title: 'Not signed in',
                subtitle: 'Please sign in to receive ride requests.',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideRequestCard(String rideId, Map<String, dynamic> data, double screenWidth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Customer name + Type badge
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.green.withOpacity(0.1),
                child: const Icon(Icons.person, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['customerName'] ?? 'Customer',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      data['serviceType'] ?? 'Service',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              // Broadcast badge
              if (data['driverId'] == 'all')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'BROADCAST',
                    style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'DIRECT',
                    style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const Divider(height: 20),

          // From / To
          Row(
            children: [
              const Icon(Icons.my_location, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data['fromLocation'] ?? '...',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data['toLocation'] ?? '...',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Fare
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Fare: Rs ${data['fare'] ?? 0}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _declineRide(rideId, data),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('DECLINE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _offerFare(rideId, data),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('OFFER FARE', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isAccepting ? null : () => _acceptRideAtCustomerPrice(rideId, data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isAccepting
                      ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('ACCEPT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _offerFare(String rideId, Map<String, dynamic> data) {
    int currentFare = data['fare'] ?? 0;
    int offerFare = currentFare;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Offer Fare', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Propose a new fare to the customer:'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: offerFare > currentFare 
                          ? () => setState(() => offerFare -= 50)
                          : null, // 🔒 Disabled if at or below customer price
                        icon: Icon(
                          Icons.remove_circle_outline, 
                          color: offerFare > currentFare ? Colors.blue : Colors.grey, 
                          size: 30
                        ),
                      ),
                      Text(
                        'Rs $offerFare',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => setState(() => offerFare += 50),
                        icon: const Icon(Icons.add_circle_outline, color: Colors.blue, size: 30),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      
                      // Safety Check: No less than customer's selected price
                      if (offerFare < currentFare) {
                        _showSnackBar('Offer cannot be less than customer\'s price', Colors.orange);
                        return;
                      }

                      await _sendFareOffer(rideId, data, offerFare);
                      
                      _showSnackBar('Offer sent: Rs $offerFare', Colors.blue);
                    } catch (e) {
                      print("Offer Error: $e");
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Send Offer', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildStatsCard(double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: HColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Earnings', 'Rs ${_driverData?['totalEarnings'] ?? 0}', Icons.account_balance_wallet),
          _buildStatItem('Rides', '${_driverData?['totalRides'] ?? 0}', Icons.directions_car),
          _buildStatItem('Rating', '${_driverData?['rating'] ?? 5.0}', Icons.star),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.red.shade400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

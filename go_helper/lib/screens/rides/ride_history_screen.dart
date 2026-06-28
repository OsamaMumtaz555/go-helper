import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:intl/intl.dart';

class RideHistoryScreen extends StatelessWidget {
  final bool isDriver;
  const RideHistoryScreen({super.key, this.isDriver = false});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isDriver ? 'Driver History' : 'Ride History', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Please login to view history'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rides')
                  .where(isDriver ? 'driverId' : 'customerId', isEqualTo: user.uid)
                  // .orderBy('timestamp', descending: true) // ❌ REMOVED: To avoid missing index errors and missing field exclusions
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: Colors.red),
                          const SizedBox(height: 10),
                          const Text('Error loading history', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 10),
                          Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 20),
                        Text(
                          isDriver ? 'No trips completed yet' : 'No rides found yet',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isDriver ? 'Your accepted trips will appear here' : 'Your completed trips will appear here',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                // 🟢 SYNC FIX: Filter and Sort in-memory
                final docs = snapshot.data!.docs;
                final sortedDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  // Filter out "all" broadcasts for drivers (they should only see accepted rides)
                  if (isDriver && data['driverId'] == 'all') return false;
                  return true;
                }).toList();

                // Sort by timestamp descending
                sortedDocs.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedDocs.length,
                  itemBuilder: (context, index) {
                    final ride = sortedDocs[index].data() as Map<String, dynamic>;
                    return _buildRideItem(context, ride, screenWidth);
                  },
                );
              },
            ),
    );
  }

  Widget _buildRideItem(BuildContext context, Map<String, dynamic> ride, double screenWidth) {
    final timestamp = ride['timestamp'] as Timestamp?;
    final dateStr = timestamp != null 
        ? DateFormat('EEE, d MMM yyyy - hh:mm a').format(timestamp.toDate())
        : 'Unknown Date';
    
    final fare = ride['fare'] ?? 0;
    final status = ride['status'] ?? 'completed';
    final otherPartyName = isDriver 
        ? (ride['customerName'] ?? 'Unknown Customer')
        : (ride['driverName'] ?? 'Unknown Driver');
    
    final fromLocation = ride['fromLocation'] ?? 'Unknown Location';
    final toLocation = ride['toLocation'] ?? 'Unknown Location';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'cancelled' ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: screenWidth * 0.025,
                    fontWeight: FontWeight.bold,
                    color: status == 'cancelled' ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(isDriver ? Icons.person : Icons.directions_car, size: 20, color: HColors.primary),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    isDriver ? 'Customer' : 'Driver',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  Text(
                    otherPartyName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Rs $fare',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: HColors.primary,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildLocationRow(Icons.my_location, Colors.green, fromLocation, screenWidth),
          const SizedBox(height: 12),
          _buildLocationRow(Icons.location_on, Colors.red, toLocation, screenWidth),
          if (status == 'cancelled' && ride['cancelReason'] != null) ...[
            const Divider(height: 24),
            Text(
              'Reason: ${ride['cancelReason']}',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String text, double screenWidth) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

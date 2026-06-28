import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Please login'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rides')
                  .where('customerId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // If there's an error (likely missing index), fall back to unordered query
                if (snapshot.hasError) {
                  return _buildFallbackNotifications(user.uid);
                }

                return _buildNotificationList(snapshot.data?.docs ?? []);
              },
            ),
    );
  }

  Widget _buildFallbackNotifications(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .where('customerId', isEqualTo: userId)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildNotificationList(snapshot.data?.docs ?? []);
      },
    );
  }

  Widget _buildNotificationList(List<QueryDocumentSnapshot> rides) {
    if (rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text('No notifications yet', style: TextStyle(color: Colors.grey, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Your ride updates will appear here', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final data = rides[index].data() as Map<String, dynamic>;
        final status = data['status'] ?? 'unknown';
        final from = data['fromLocation'] ?? '...';
        final to = data['toLocation'] ?? '...';
        final fare = data['fare'] ?? 0;
        final serviceType = data['serviceType'] ?? 'general';

        // Determine notification details based on status
        IconData icon;
        Color color;
        String title;
        String subtitle;

        switch (status) {
          case 'pending':
            icon = Icons.search;
            color = Colors.orange;
            title = 'Searching for driver';
            subtitle = 'Your $serviceType request is being broadcast to nearby drivers.';
            break;
          case 'accepted':
            icon = Icons.check_circle;
            color = Colors.green;
            title = 'Driver found!';
            subtitle = 'A driver has accepted your $serviceType request.';
            break;
          case 'completed':
            icon = Icons.done_all;
            color = Colors.blue;
            title = 'Ride completed';
            subtitle = 'Your $serviceType ride from $from to $to has been completed. Fare: Rs $fare';
            break;
          case 'cancelled':
            icon = Icons.cancel;
            color = Colors.red;
            title = 'Ride cancelled';
            subtitle = 'Your $serviceType ride from $from was cancelled.';
            break;
          default:
            icon = Icons.info;
            color = Colors.grey;
            title = 'Ride update';
            subtitle = '$serviceType ride - Status: $status';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ),
        );
      },
    );
  }
}

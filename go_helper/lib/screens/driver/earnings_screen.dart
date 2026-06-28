import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Earnings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Please login'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rides')
                  .where('driverId', isEqualTo: user.uid)
                  .where('status', isEqualTo: 'completed')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rides = snapshot.data?.docs ?? [];
                int totalEarnings = 0;
                for (var ride in rides) {
                  final data = ride.data() as Map<String, dynamic>;
                  totalEarnings += (data['fare'] as num?)?.toInt() ?? 0;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [HColors.primary, HColors.primary.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: HColors.primary.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(
                              'Rs $totalEarnings',
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem('Completed', '${rides.length}', Icons.check_circle),
                                _buildSummaryItem('Avg Fare', rides.isEmpty ? 'Rs 0' : 'Rs ${(totalEarnings / rides.length).round()}', Icons.trending_up),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Earnings History
                      Row(
                        children: [
                          const Text('Earnings History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('${rides.length} rides', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 15),

                      if (rides.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 15),
                              const Text('No earnings yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                              const SizedBox(height: 5),
                              Text('Complete rides to start earning!', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                            ],
                          ),
                        )
                      else
                        ...rides.map((ride) {
                          final data = ride.data() as Map<String, dynamic>;
                          final fare = data['fare'] ?? 0;
                          final from = data['fromLocation'] ?? '...';
                          final to = data['toLocation'] ?? '...';
                          final customerName = data['customerName'] ?? 'Customer';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 3),
                                      Text('$from → $to', style: TextStyle(color: Colors.grey.shade600, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                Text(
                                  '+Rs $fare',
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
    );
  }

  static Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

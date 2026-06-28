import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_helper/services/auth_service.dart';
import 'package:go_helper/utils/constants/colors.dart';

/// Shown when a driver has signed up but is pending admin approval, or was rejected.
class DriverPendingScreen extends StatelessWidget {
  /// Pass 'pending' or 'rejected'
  final String status;
  const DriverPendingScreen({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isRejected = status == 'rejected';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'GoHelper',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: HColors.primary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await AuthService().signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign Out'),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Main illustration area
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Status Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isRejected
                          ? Colors.red.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRejected ? Icons.cancel_outlined : Icons.pending_actions,
                      size: 55,
                      color: isRejected ? Colors.red : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Title
                  Text(
                    isRejected ? 'Application Rejected' : 'Application Submitted!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Subtitle
                  Text(
                    isRejected
                        ? 'Unfortunately, your driver application was not approved by our admin team. '
                            'Please contact support for more information.'
                        : 'Your application is under review by our admin team. '
                            'You will be notified once it\'s approved — usually within 24 hours.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isRejected
                          ? Colors.red.withOpacity(0.08)
                          : Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isRejected
                            ? Colors.red.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRejected ? Icons.close : Icons.hourglass_top,
                          size: 16,
                          color: isRejected ? Colors.red : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isRejected ? 'STATUS: REJECTED' : 'STATUS: PENDING REVIEW',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isRejected ? Colors.red : Colors.orange,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom steps / info (only for pending)
            if (!isRejected) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    _buildStep(
                      icon: Icons.how_to_reg,
                      title: 'Application Received',
                      done: true,
                    ),
                    _buildStep(
                      icon: Icons.manage_search,
                      title: 'Under Admin Review',
                      done: false,
                      current: true,
                    ),
                    _buildStep(
                      icon: Icons.check_circle,
                      title: 'Account Activated',
                      done: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Contact support button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Contact Support'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HColors.primary,
                    side: const BorderSide(color: HColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required bool done,
    bool current = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: done
                  ? Colors.green
                  : current
                      ? Colors.orange
                      : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check : icon,
              size: 18,
              color: done || current ? Colors.white : Colors.grey,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: current ? FontWeight.bold : FontWeight.normal,
              color: done
                  ? Colors.green
                  : current
                      ? Colors.orange
                      : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// This wrapper listens to Firestore in real-time and switches the driver
/// between the pending, rejected, or home screen automatically.
class DriverApprovalWrapper extends StatelessWidget {
  const DriverApprovalWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const DriverPendingScreen(status: 'pending');
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const DriverPendingScreen(status: 'pending');
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final isApprovedField = data['isApproved'] == true;
        final driverStatus = data['status'] ?? 'pending';

        if (isApprovedField || driverStatus == 'approved') {
          // Import lazily to avoid circular deps
          return _RedirectToDriverHome();
        }

        if (driverStatus == 'rejected') {
          return const DriverPendingScreen(status: 'rejected');
        }

        return const DriverPendingScreen(status: 'pending');
      },
    );
  }
}

class _RedirectToDriverHome extends StatefulWidget {
  @override
  State<_RedirectToDriverHome> createState() => _RedirectToDriverHomeState();
}

class _RedirectToDriverHomeState extends State<_RedirectToDriverHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/driver-home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

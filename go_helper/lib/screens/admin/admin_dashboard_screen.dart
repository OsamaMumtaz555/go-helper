import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_helper/services/auth_service.dart';
import 'package:go_helper/utils/constants/colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── APPROVE ──────────────────────────────────────────────────────────────
  Future<void> _approveDriver(String driverId, String name) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(driverId).update({
        'isApproved': true,
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showSnack('✅ $name has been approved!', Colors.green);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', Colors.red);
    }
  }

  // ─── REJECT ───────────────────────────────────────────────────────────────
  Future<void> _rejectDriver(String driverId, String name) async {
    final confirmed = await _showConfirmDialog(
      title: 'Reject Driver',
      message: 'Are you sure you want to reject $name\'s application?',
      confirmLabel: 'Reject',
      confirmColor: Colors.red,
    );
    if (!confirmed) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(driverId).update({
        'isApproved': false,
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showSnack('❌ $name has been rejected.', Colors.red);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', Colors.red);
    }
  }

  // ─── REVOKE APPROVAL (approved → pending) ─────────────────────────────────
  Future<void> _revokeApproval(String driverId, String name) async {
    final confirmed = await _showConfirmDialog(
      title: 'Revoke Approval',
      message: 'Revoke approval for $name? They will lose access until approved again.',
      confirmLabel: 'Revoke',
      confirmColor: Colors.orange,
    );
    if (!confirmed) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(driverId).update({
        'isApproved': false,
        'status': 'pending',
        'revokedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showSnack('⚠️ $name\'s approval revoked.', Colors.orange);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: HColors.primary,
        elevation: 0,
        title: const Text(
          'Admin Panel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: () async => await AuthService().signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions, size: 18), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle, size: 18), text: 'Approved'),
            Tab(icon: Icon(Icons.cancel, size: 18), text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DriverList(
            statusFilter: 'pending',
            onApprove: _approveDriver,
            onReject: _rejectDriver,
          ),
          _DriverList(
            statusFilter: 'approved',
            onRevoke: _revokeApproval,
            onReject: _rejectDriver,
          ),
          _DriverList(
            statusFilter: 'rejected',
            onApprove: _approveDriver,
          ),
        ],
      ),
    );
  }
}

// ─── Driver List Widget ────────────────────────────────────────────────────────

class _DriverList extends StatelessWidget {
  final String statusFilter;
  final Future<void> Function(String id, String name)? onApprove;
  final Future<void> Function(String id, String name)? onReject;
  final Future<void> Function(String id, String name)? onRevoke;

  const _DriverList({
    required this.statusFilter,
    this.onApprove,
    this.onReject,
    this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .where('status', isEqualTo: statusFilter)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Fallback: filter in-memory if index missing
          return _buildFallback(context);
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmpty();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _DriverCard(
              driverId: docs[i].id,
              data: data,
              statusFilter: statusFilter,
              onApprove: onApprove,
              onReject: onReject,
              onRevoke: onRevoke,
            );
          },
        );
      },
    );
  }

  // Fallback stream that fetches all drivers and filters in memory
  Widget _buildFallback(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final s = data['status'] ?? 'pending';
          return s == statusFilter;
        }).toList();

        if (docs.isEmpty) return _buildEmpty();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _DriverCard(
              driverId: docs[i].id,
              data: data,
              statusFilter: statusFilter,
              onApprove: onApprove,
              onReject: onReject,
              onRevoke: onRevoke,
            );
          },
        );
      },
    );
  }

  Widget _buildEmpty() {
    final Map<String, Map<String, dynamic>> config = {
      'pending': {
        'icon': Icons.inbox_outlined,
        'color': Colors.orange,
        'title': 'No Pending Applications',
        'sub': 'All driver applications have been reviewed.',
      },
      'approved': {
        'icon': Icons.verified_outlined,
        'color': Colors.green,
        'title': 'No Approved Drivers',
        'sub': 'Approve pending applications to see them here.',
      },
      'rejected': {
        'icon': Icons.block_outlined,
        'color': Colors.red,
        'title': 'No Rejected Applications',
        'sub': 'Rejected driver accounts will appear here.',
      },
    };

    final c = config[statusFilter]!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(c['icon'] as IconData, size: 80, color: (c['color'] as Color).withOpacity(0.4)),
            const SizedBox(height: 20),
            Text(
              c['title'] as String,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              c['sub'] as String,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Driver Card ──────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final String driverId;
  final Map<String, dynamic> data;
  final String statusFilter;
  final Future<void> Function(String id, String name)? onApprove;
  final Future<void> Function(String id, String name)? onReject;
  final Future<void> Function(String id, String name)? onRevoke;

  const _DriverCard({
    required this.driverId,
    required this.data,
    required this.statusFilter,
    this.onApprove,
    this.onReject,
    this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['fullName'] ?? 'Unknown Driver';
    final email = data['email'] ?? '';
    final phone = data['phone'] ?? 'No phone';
    final service = data['serviceType'] ?? 'Unknown';
    final vehicle = data['vehicleModel'] ?? 'N/A';
    final plate = data['licensePlate'] ?? 'N/A';

    // Status badge color
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (statusFilter) {
      case 'approved':
        statusColor = Colors.green;
        statusLabel = 'APPROVED';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'REJECTED';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'PENDING';
        statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: statusColor.withOpacity(0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _infoRow(Icons.phone, 'Phone', phone),
                const SizedBox(height: 6),
                _infoRow(Icons.build, 'Specialization', service.toUpperCase()),
                const SizedBox(height: 6),
                _infoRow(Icons.directions_car, 'Vehicle', vehicle),
                const SizedBox(height: 6),
                _infoRow(Icons.badge, 'License Plate', plate),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Approve button
                if (onApprove != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onApprove!(driverId, name),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (onApprove != null && (onReject != null || onRevoke != null))
                  const SizedBox(width: 10),

                // Reject button
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onReject!(driverId, name),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                // Revoke button (for approved drivers)
                if (onRevoke != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onRevoke!(driverId, name),
                      icon: const Icon(Icons.remove_circle_outline, size: 16),
                      label: const Text('Revoke'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

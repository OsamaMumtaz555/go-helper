import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';

class CancelRideReasonScreen extends StatefulWidget {
  final String rideId;
  final bool isDriver;

  const CancelRideReasonScreen({
    super.key,
    required this.rideId,
    required this.isDriver,
  });

  @override
  State<CancelRideReasonScreen> createState() => _CancelRideReasonScreenState();
}

class _CancelRideReasonScreenState extends State<CancelRideReasonScreen> {
  String? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();
  bool _isLoading = false;

  final List<String> _riderReasons = [
    'Driver is taking too long',
    'Driver asked me to cancel',
    'Changed my mind / No longer need it',
    'Safety concerns',
    'Driver is going in wrong direction',
    'Other (Please specify)',
  ];

  final List<String> _driverReasons = [
    'Rider not showing up',
    'Too many passengers / Luggage',
    'Vehicle issue / Emergency',
    'Unable to contact rider',
    'Rider asked me to cancel',
    'Other (Please specify)',
  ];

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  void _submitCancellation() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    String finalReason = _selectedReason!;
    if (_selectedReason == 'Other (Please specify)' && _otherReasonController.text.isNotEmpty) {
      finalReason = _otherReasonController.text;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('rides').doc(widget.rideId).update({
        'status': 'cancelled',
        'cancelledBy': widget.isDriver ? 'driver' : 'rider',
        'cancelReason': finalReason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // Go back to the dashboard/home screen
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ride cancelled: $finalReason'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling ride: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reasons = widget.isDriver ? _driverReasons : _riderReasons;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Why cancel?'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: HColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please select the reason for cancelling this trip. Your feedback helps us improve.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),
            ...reasons.map((reason) {
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: _selectedReason == reason ? HColors.primary.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedReason == reason ? HColors.primary : Colors.grey.shade200,
                  ),
                ),
                child: RadioListTile<String>(
                  title: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _selectedReason == reason ? FontWeight.bold : FontWeight.normal,
                      color: _selectedReason == reason ? HColors.primary : Colors.black87,
                    ),
                  ),
                  value: reason,
                  groupValue: _selectedReason,
                  activeColor: HColors.primary,
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value;
                    });
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
              );
            }),
            if (_selectedReason == 'Other (Please specify)') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _otherReasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe the reason...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: HColors.primary),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitCancellation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'SUBMIT CANCELLATION',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go back', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

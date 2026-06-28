import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';

class VehicleInfoScreen extends StatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleModelController = TextEditingController();
  final _licensePlateController = TextEditingController();
  String _selectedServiceType = 'mechanic';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  @override
  void dispose() {
    _vehicleModelController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && mounted) {
      final data = doc.data()!;
      setState(() {
        _vehicleModelController.text = data['vehicleModel'] ?? '';
        _licensePlateController.text = data['licensePlate'] ?? '';
        _selectedServiceType = data['serviceType'] ?? 'mechanic';
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveVehicleData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'vehicleModel': _vehicleModelController.text.trim(),
        'licensePlate': _licensePlateController.text.trim(),
        'serviceType': _selectedServiceType,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle info updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Vehicle Info', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: HColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_car, size: 60, color: HColors.primary),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Vehicle Model
                    const Text('Vehicle Model', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _vehicleModelController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Honda City 2020',
                        prefixIcon: const Icon(Icons.directions_car_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter vehicle model' : null,
                    ),
                    const SizedBox(height: 20),

                    // License Plate
                    const Text('License Plate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _licensePlateController,
                      decoration: InputDecoration(
                        hintText: 'e.g. ABC-1234',
                        prefixIcon: const Icon(Icons.credit_card),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter license plate' : null,
                    ),
                    const SizedBox(height: 20),

                    // Service Type
                    const Text('Service Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedServiceType,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'mechanic', child: Text('Mechanic')),
                            DropdownMenuItem(value: 'courier', child: Text('Courier')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedServiceType = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveVehicleData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

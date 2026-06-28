import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool _isEditing = false;
  bool _isSaving = false;

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _userData = doc.data() ?? {};
        _fullNameController.text = _userData['fullName'] ?? user!.displayName ?? '';
        _phoneController.text = _userData['phone'] ?? '';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      // Also update Firebase Auth display name
      await user!.updateDisplayName(_fullNameController.text.trim());

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
          _userData['fullName'] = _fullNameController.text.trim();
          _userData['phone'] = _phoneController.text.trim();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final fullName = _userData['fullName'] ?? user?.displayName ?? 'User';
    final email = _userData['email'] ?? user?.email ?? '';
    final phone = _userData['phone'] ?? 'Add Phone Number';
    final userType = _userData['userType'] ?? 'customer';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: HColors.primary),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: screenWidth * 0.15,
                    backgroundColor: HColors.primary.withOpacity(0.1),
                    child: Icon(Icons.person, size: screenWidth * 0.15, color: HColors.primary),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: HColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Editable Fields
            if (_isEditing) ...[
              _buildEditField('Full Name', _fullNameController, Icons.person),
              _buildEditField('Phone', _phoneController, Icons.phone),
              _buildProfileItem(Icons.email, 'Email', email, screenWidth),
              _buildProfileItem(Icons.work, 'Account Type', userType.toUpperCase(), screenWidth),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSaving
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildProfileItem(Icons.person, 'Full Name', fullName, screenWidth),
              _buildProfileItem(Icons.email, 'Email', email, screenWidth),
              _buildProfileItem(Icons.phone, 'Phone', phone, screenWidth),
              _buildProfileItem(Icons.work, 'Account Type', userType.toUpperCase(), screenWidth),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _isEditing = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Edit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: HColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: HColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value, double screenWidth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: HColors.primary, size: 24),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}

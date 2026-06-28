import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Settings
            const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildSettingToggle(
              icon: Icons.notifications_active_outlined,
              title: 'Push Notifications',
              subtitle: 'Receive ride request notifications',
              value: _notificationsEnabled,
              onChanged: (val) => setState(() => _notificationsEnabled = val),
            ),
            _buildSettingToggle(
              icon: Icons.volume_up_outlined,
              title: 'Sound',
              subtitle: 'Play sound for new notifications',
              value: _soundEnabled,
              onChanged: (val) => setState(() => _soundEnabled = val),
            ),
            const SizedBox(height: 25),

            // Privacy Settings
            const Text('Privacy & Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildSettingToggle(
              icon: Icons.location_on_outlined,
              title: 'Location Services',
              subtitle: 'Allow app to access your location',
              value: _locationEnabled,
              onChanged: (val) => setState(() => _locationEnabled = val),
            ),
            const SizedBox(height: 25),

            // Account Settings
            const Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildSettingAction(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: () => _changePassword(context),
            ),
            _buildSettingAction(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'English',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Only English is available at this time.')),
                );
              },
            ),
            const SizedBox(height: 25),

            // About
            const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildSettingAction(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: '1.0.0',
              onTap: () {},
            ),
            _buildSettingAction(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Terms of Service')),
                );
              },
            ),
            _buildSettingAction(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy Policy')),
                );
              },
            ),
            const SizedBox(height: 30),

            // Delete Account Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showDeleteAccountDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingToggle({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: HColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: HColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingAction({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: HColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to ${user.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // Delete user data from Firestore
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                  // Delete the Firebase Auth account
                  await user.delete();
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting account: $e. Please log in again and retry.'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

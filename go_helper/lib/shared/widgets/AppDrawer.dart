import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:go_helper/screens/profile/profile_screen.dart';
import 'package:go_helper/screens/rides/ride_history_screen.dart';
import 'package:go_helper/screens/driver/earnings_screen.dart';
import 'package:go_helper/screens/driver/vehicle_info_screen.dart';
import 'package:go_helper/screens/promos/promos_screen.dart';
import 'package:go_helper/screens/support/help_support_screen.dart';
import 'package:go_helper/screens/settings/settings_screen.dart';

// This is the Side Menu (Drawer) that pops out when you swipe from the left
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // We get the user's current login information
    final screenWidth = MediaQuery.of(context).size.width;
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      width: screenWidth * 0.8,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: user == null
            ? const Center(child: Text('Please login'))
            : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get(),
                builder: (context, snapshot) {
                    // We fetch the user's Name and Role (Customer/Driver) from the database
                    String userType = 'customer';
                    String fullName = user.displayName ?? 'User';

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      userType = data['userType'] ?? 'customer';
                      fullName = data['fullName'] ?? fullName;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // -- SECTION 1: User Profile (Photo, Name, Email) --
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: screenWidth * 0.07,
                              backgroundColor: HColors.primary.withOpacity(0.1),
                              child: const Icon(Icons.person,
                                  color: HColors.primary),
                            ),
                            SizedBox(width: screenWidth * 0.04),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: HColors.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    user.email ?? '',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.032,
                                      color: HColors.primary.withOpacity(0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Divider(color: HColors.primary.withOpacity(0.3)),

                        // -- SECTION 2: Menu List (Profile, History, Settings) --
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              // ... (Menu items follow here)
                            _buildMenuItem(
                              context: context,
                              icon: Icons.person_outline,
                              title: 'My Profile',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                                );
                              },
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.history,
                              title: 'Ride History',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => RideHistoryScreen(isDriver: userType == 'driver')),
                                );
                              },
                            ),
                            if (userType == 'driver') ...[
                              _buildMenuItem(
                                context: context,
                                icon: Icons.account_balance_wallet,
                                title: 'Earnings',
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen()));
                                },
                              ),
                              _buildMenuItem(
                                context: context,
                                icon: Icons.directions_car,
                                title: 'Vehicle Info',
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleInfoScreen()));
                                },
                              ),
                            ] else ...[
                              _buildMenuItem(
                                context: context,
                                icon: Icons.local_offer,
                                title: 'Promos',
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PromosScreen()));
                                },
                              ),
                            ],
                            _buildMenuItem(
                              context: context,
                              icon: Icons.help_outline,
                              title: 'Help & Support',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                              },
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.settings_outlined,
                              title: 'Settings',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                              },
                            ),
                          ],
                        ),
                      ),

                        // -- SECTION 3: Bottom Buttons (Switch Mode and Logout) --
                        Padding(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          child: Column(
                            children: [
                              // Logic to switch between Customer and Driver modes
                              if (userType == 'customer')
                                // (Button to become a Driver)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .update({'userType': 'driver'});
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/driver-home',
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: HColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.drive_eta,
                                          color: Colors.white, size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Switch to Driver Mode',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .update({'userType': 'customer'});
                                    Navigator.pushReplacementNamed(
                                        context, '/home');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.person,
                                          color: Colors.white, size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Switch to Customer Mode',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 10),

                            // Logout Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _simpleLogoutFix(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.logout,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Logout',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.035,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ListTile(
      leading: Icon(icon, color: HColors.primary, size: screenWidth * 0.06),
      title: Text(
        title,
        style: TextStyle(
          color: HColors.primary,
          fontSize: screenWidth * 0.038,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: HColors.primary,
        size: screenWidth * 0.05,
      ),
      onTap: onTap,
    );
  }

  void _simpleLogoutFix(BuildContext context) async {
    try {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      await Future.delayed(const Duration(milliseconds: 300));
      await FirebaseAuth.instance.signOut();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final nav = Navigator.of(context, rootNavigator: true);
          ScaffoldMessenger.of(nav.context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: Colors.green,
            ),
          );
          nav.pushNamedAndRemoveUntil('/login', (route) => false);
        } catch (e) {
          print('Logout Nav Error: $e');
        }
      });
    } catch (e) {
      print('Logout Error: $e');
    }
  }

  void _showComingSoon(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coming Soon!'),
          backgroundColor: HColors.primary,
        ),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {'q': 'How do I book a ride?', 'a': 'Select a service category from the home screen, choose your pickup and drop-off locations, select a vehicle type, and tap "Select Captain" to find available drivers.'},
      {'q': 'How do I become a driver?', 'a': 'You can switch to Driver mode from the side menu, or sign up as a driver during registration by providing your vehicle details.'},
      {'q': 'How is the fare calculated?', 'a': 'The fare is calculated based on the distance between pickup and drop-off locations, the type of vehicle selected, and a base fare. You can adjust the fare before booking.'},
      {'q': 'Can I cancel a ride?', 'a': 'Yes, you can cancel a ride before a driver accepts it by tapping the "Cancel Ride" button on the ride search screen.'},
      {'q': 'How do I track my ride?', 'a': 'Once a driver accepts your ride, you will be taken to the trip screen where you can see the driver\'s location on the map and communicate via chat.'},
      {'q': 'How do I contact my driver?', 'a': 'On the trip screen, you can use the built-in chat feature or tap the phone icon to call your driver directly.'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Cards
            const Text('Contact Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildContactCard(context, Icons.call, 'Call Us', '0300-1234567', Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildContactCard(context, Icons.email, 'Email', 'support@gohelper.pk', Colors.blue)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildContactCard(context, Icons.chat, 'WhatsApp', '+92 300 1234567', Colors.teal),
            ),
            const SizedBox(height: 30),

            // FAQs
            const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ...faqs.map((faq) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.help_outline, color: HColors.primary, size: 22),
                  title: Text(
                    faq['q']!,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  children: [
                    Text(
                      faq['a']!,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title: $subtitle'),
            backgroundColor: color,
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

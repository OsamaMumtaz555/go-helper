import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';

class PromosScreen extends StatelessWidget {
  const PromosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final promos = [
      {'code': 'WELCOME50', 'discount': '50% OFF', 'description': 'First ride discount! Up to Rs 200 off.', 'color': Colors.green},
      {'code': 'GOHELPER25', 'discount': '25% OFF', 'description': 'Get 25% off on your next 3 rides.', 'color': Colors.blue},
      {'code': 'NIGHT20', 'discount': 'Rs 100 OFF', 'description': 'Flat Rs 100 off on rides between 10PM - 6AM.', 'color': Colors.deepPurple},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Promos & Offers', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Apply promo code
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HColors.primary),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter promo code',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Promo code applied!'), backgroundColor: Colors.green),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text('Available Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            ...promos.map((promo) {
              final color = promo['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.local_offer, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promo['discount'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              promo['description'] as String,
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Code: ${promo['code']}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

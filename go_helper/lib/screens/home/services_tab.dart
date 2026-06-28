import 'package:flutter/material.dart';
import 'package:go_helper/shared/widgets/category_section.dart';
import 'package:go_helper/screens/rides/serviceselection_screen.dart';

class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Services'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select a service to proceed",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: CategorySection(
                onCategorySelected: (category) {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceSelectionScreen(
                        selectedCategory: category,
                        fromLocation: "Current Location", // Default
                        toLocation: "",
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

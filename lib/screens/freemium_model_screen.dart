import 'package:flutter/material.dart';

class FreemiumModelScreen extends StatefulWidget {
  const FreemiumModelScreen({Key? key}) : super(key: key);

  @override
  State<FreemiumModelScreen> createState() => _FreemiumModelScreenState();
}

class _FreemiumModelScreenState extends State<FreemiumModelScreen> {
  String selectedPlan = 'Yearly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEF70A9), Color(0xFF9D2CF3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
            child: Column(
              children: const [
                Text(
                  "Choose Your Plan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '"Speak Aloud"',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Plan Options
          _buildPlanOption(
            title: 'Yearly',
            price: '\$60',
            originalPrice: '\$120',
            description: 'Save 50%\nGet 7 Days Free Trial',
            isSelected: selectedPlan == 'Yearly',
            tag: 'BEST VALUE',
            onTap: () => setState(() => selectedPlan = 'Yearly'),
            borderColor: const Color(0xFFF8C56A),
          ),
          _buildPlanOption(
            title: '3 Months',
            price: '\$24',
            originalPrice: '\$30',
            description: 'Save 20%\nGet 3 Days Free Trial',
            isSelected: selectedPlan == '3 Months',
            tag: 'Most Popular',
            onTap: () => setState(() => selectedPlan = '3 Months'),
            borderColor: const Color(0xFFFFB1C1),
          ),
          _buildPlanOption(
            title: '1 Months',
            price: '\$8.4',
            originalPrice: '\$10',
            description: 'Save 16%',
            isSelected: selectedPlan == '1 Months',
            onTap: () => setState(() => selectedPlan = '1 Months'),
          ),
          const SizedBox(height: 20),

          // Disclaimer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'If you choose to purchase a subscription, payment will be charged to your account and it will be within 24 hours. You can cancel the auto renewal at any time.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          // Continue Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () {},
              child: const Text(
                "Continue to Purchase",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption({
    required String title,
    required String price,
    required String originalPrice,
    required String description,
    required bool isSelected,
    String? tag,
    required VoidCallback onTap,
    Color borderColor = Colors.grey,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.pink.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? borderColor : Colors.transparent,
            width: 3,
          ),
        ),
        child: Row(
          children: [
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFF8C56A)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (tag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(description, style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  originalPrice,
                  style: const TextStyle(
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


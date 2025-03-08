/*import 'package:flutter/material.dart';
import 'package:flutter_sslcommerz/model/SSLCSdkType.dart';
import 'package:flutter_sslcommerz/model/SSLCommerzInitialization.dart';
import 'package:flutter_sslcommerz/model/SSLCurrencyType.dart';
import 'package:flutter_sslcommerz/model/SslcommerzPaymentStatus.dart';
import 'package:flutter_sslcommerz/sslcommerz.dart';



class PaymentConfirmationScreen extends StatefulWidget {
  final String planName;
  final String price;
  final String description;

  const PaymentConfirmationScreen({
    super.key,
    required this.planName,
    required this.price,
    required this.description,
  });

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context,
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
              children: [
                Text(
                  "Confirm Payment",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"Complete your subscription"',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Plan Details
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.planName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.description,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 10),
                Text(
                  'Price: ${widget.price}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Phone Number Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'bKash Phone Number',
                hintText: '01XXXXXXXXX',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(height: 20),

          // Confirm Button
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
              onPressed: _processPayment,
              child: const Text(
                "Confirm Payment",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty ||
        !phoneNumber.startsWith('01') ||
        phoneNumber.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid bKash phone number')),
      );
      return;
    }

    _initiateSSLCommerzPayment();
  }

  Future<void> _initiateSSLCommerzPayment() async {
    final sslcommerz = Sslcommerz(
      initializer: SSLCommerzInitialization(

        storeId: 'navcr67b89d01ccb31',
        storePassword: 'navcr67b89d01ccb31@ssl',
        totalAmount: _getPlanAmount(widget.planName),

        currency: SSLCurrencyType.BDT,
        tranId: 'TRAN${DateTime.now().millisecondsSinceEpoch}',
        productCategory: 'Subscription',
        successUrl: 'https://yourdomain.com/success',
        failUrl: 'https://yourdomain.com/fail',
        cancelUrl: 'https://yourdomain.com/cancel',
        ipnUrl: 'https://yourdomain.com/ipn',
        multiCardName: 'bkash',
        customerPhone: _phoneController.text,
        customerEmail: 'customer@example.com',
        shippingMethod: 'NO',
        productName: '${widget.planName} Plan',
        productProfile: 'general',
      ),
      sdkType: SSLCSdkType.TESTBOX,

    );

    try {
      final result = await sslcommerz.payNow();
      if (result.status == SslcommerzPaymentStatus.SUCCESS) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  double _getPlanAmount(String plan) {
    switch (plan) {
      case 'Yearly':
        return 600.0;
      case '3 Months':
        return 220.0;
      case '1 Month':
        return 80.0;
      default:
        return 0.0;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
*/
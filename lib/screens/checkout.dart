/*import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_sslcommerz/model/SSLCSdkType.dart';
import 'package:flutter_sslcommerz/model/SSLCommerzInitialization.dart';
import 'package:flutter_sslcommerz/model/SSLCurrencyType.dart';
import 'package:flutter_sslcommerz/sslcommerz.dart';

class Checkout extends StatefulWidget {
  final String planName;
  final String price;
  final String description;

  const Checkout({
    super.key,
    required this.planName,
    required this.price,
    required this.description,
  });

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
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
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Text(
                  "Confirm Payment",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"Complete your subscription"',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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
        multi_card_name: "visa,master,bkash",
        currency: SSLCurrencyType.BDT,
        product_category: "Digital Product",
        sdkType: SSLCSdkType.TESTBOX,
        store_id: "navcr67b89d01ccb31",
        store_passwd: "navcr67b89d01ccb31@ssl",
        total_amount: _getPlanAmount(widget.planName),
        tran_id: "TestTRX001",
      ),
    );

    try {
      final response = await sslcommerz.payNow();

      if (response.status == 'VALID') {
        print(jsonEncode(response));
        print('Payment completed, TRX ID: ${response.tranId}');
        print(response.tranDate);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful!')),
        );
        Navigator.pop(context);
      } else if (response.status == 'Closed') {
        print('Payment closed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment closed. Please try again.')),
        );
      } else if (response.status == 'FAILED') {
        print('Payment failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed. Please try again.')),
        );
      }
    } catch (e) {
      print('Error: ${e.toString()}');
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_sslcommerz/model/SSLCSdkType.dart';
import 'package:flutter_sslcommerz/model/SSLCommerzInitialization.dart';
import 'package:flutter_sslcommerz/model/SSLCurrencyType.dart';
import 'package:flutter_sslcommerz/sslcommerz.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class Checkout extends StatefulWidget {
  final String planName;
  final String price;
  final String description;

  const Checkout({
    super.key,
    required this.planName,
    required this.price,
    required this.description,
  });

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final _phoneController = TextEditingController();
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _spokenText = '';

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initializeTts();
    _startVoiceNavigation();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  void _startVoiceNavigation() async {
    await _flutterTts.speak("For checkout, enter your bKash number.");
    _startListening();
  }

  void _startListening() async {
    bool available = await _speechToText.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speechToText.listen(
        onResult: (result) => _handleVoiceCommand(result.recognizedWords),
      );
    }
  }

  void _handleVoiceCommand(String command) {
    setState(() {
      _spokenText = command;
      _phoneController.text =
          command; // Update the text field with the spoken number
    });

    if (_spokenText.isNotEmpty) {
      _askForConfirmation();
    }
  }

  void _askForConfirmation() async {
    await _flutterTts.speak(
        "You said $_spokenText. Do you want to proceed? Say yes to proceed or no to cancel.");
    _startListeningForConfirmation();
  }

  void _startListeningForConfirmation() async {
    bool available = await _speechToText.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speechToText.listen(
        onResult: (result) => _handleConfirmation(result.recognizedWords),
      );
    }
  }

  void _handleConfirmation(String command) {
    command = command.toLowerCase();
    if (command.contains('yes')) {
      _processPayment();
    } else if (command.contains('no')) {
      _flutterTts.speak("Payment canceled.");
      Navigator.pop(context); // Go back to the previous screen
    } else {
      _flutterTts.speak(
          "Command not recognized. Please say yes to proceed or no to cancel.");
      _startListeningForConfirmation();
    }
  }

  void _processPayment() {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty ||
        !phoneNumber.startsWith('01') ||
        phoneNumber.length != 11) {
      _flutterTts.speak("Please enter a valid bKash phone number.");
      return;
    }

    _initiateSSLCommerzPayment();
  }

  Future<void> _initiateSSLCommerzPayment() async {
    final sslcommerz = Sslcommerz(
      initializer: SSLCommerzInitialization(
        multi_card_name: "visa,master,bkash",
        currency: SSLCurrencyType.BDT,
        product_category: "Digital Product",
        sdkType: SSLCSdkType.TESTBOX,
        store_id: "navcr67b89d01ccb31",
        store_passwd: "navcr67b89d01ccb31@ssl",
        total_amount: _getPlanAmount(widget.planName),
        tran_id: "TestTRX001",
      ),
    );

    try {
      final response = await sslcommerz.payNow();

      if (response.status == 'VALID') {
        print(jsonEncode(response));
        print('Payment completed, TRX ID: ${response.tranId}');
        print(response.tranDate);

        _flutterTts.speak("Payment successful!");
        Navigator.pop(context);
      } else if (response.status == 'Closed') {
        print('Payment closed');
        _flutterTts.speak("Payment closed. Please try again.");
      } else if (response.status == 'FAILED') {
        print('Payment failed');
        _flutterTts.speak("Payment failed. Please try again.");
      }
    } catch (e) {
      print('Error: ${e.toString()}');
      _flutterTts.speak("Error: ${e.toString()}");
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
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }

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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEF70A9), Color(0xFF9D2CF3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Text(
                  "Confirm Payment",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
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
}

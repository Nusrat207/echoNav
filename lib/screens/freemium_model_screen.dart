/*import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'payment_confirmation_screen.dart';

class FreemiumModelScreen extends StatefulWidget {
  const FreemiumModelScreen({super.key});

  @override
  State<FreemiumModelScreen> createState() => _FreemiumModelScreenState();
}

class _FreemiumModelScreenState extends State<FreemiumModelScreen> {
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  String selectedPlan = 'Yearly';
  bool _isListening = false;

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
    await _flutterTts.speak(
        "Welcome to the freemium model. Let me explain our subscription plans.");
    await _flutterTts.speak(
        "Our Yearly plan offers faster object recognition, unlimited prompts, and priority support. Normally 900, now only 600 with 33% savings and 7 days free trial. This is our BEST VALUE plan.");
    await _flutterTts.speak(
        "Our 3 Months plan provides faster object recognition and unlimited prompts. Normally 300, now only 220 with 27% savings and 3 days free trial. This is our MOST POPULAR plan.");
    await _flutterTts.speak(
        "Our 1 Month plan includes faster object recognition and unlimited prompts. Normally 100, now only 80 with 20% savings.");
    await _flutterTts.speak(
        "Please say 'Yearly', '3 Months', or '1 Month' to select your preferred plan.");
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
    command = command.toLowerCase();
    if (command.contains('yearly')) {
      setState(() => selectedPlan = 'Yearly');
      _flutterTts.speak("Yearly plan selected");
    } else if (command.contains('3 months')) {
      setState(() => selectedPlan = '3 Months');
      _flutterTts.speak("3 Months plan selected");
    } else if (command.contains('1 month')) {
      setState(() => selectedPlan = '1 Month');
      _flutterTts.speak("1 Month plan selected");
    } else if (command.contains('continue')) {
      _handleContinue();
    } else {
      _flutterTts.speak("Command not recognized. Please try again.");
    }
  }

  void _handleContinue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentConfirmationScreen(
          planName: selectedPlan,
          price: _getPlanPrice(selectedPlan),
          description: _getPlanDescription(selectedPlan),
        ),
      ),
    );
  }

  String _getPlanPrice(String plan) {
    switch (plan) {
      case 'Yearly':
        return '৳600';
      case '3 Months':
        return '৳220';
      case '1 Month':
        return '৳80';
      default:
        return '';
    }
  }

  String _getPlanDescription(String plan) {
    switch (plan) {
      case 'Yearly':
        return 'Save 33%\nGet 7 Days Free Trial';
      case '3 Months':
        return 'Save 27%\nGet 3 Days Free Trial';
      case '1 Month':
        return 'Save 20%';
      default:
        return '';
    }
  }

  @override
  void dispose() {
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Choose Your Plan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"Speak Aloud"',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Plan Options
          _buildPlanOption(
            title: 'Yearly',
            price: '৳600',
            originalPrice: '৳900',
            description: 'Save 33%\nGet 7 Days Free Trial',
            features: '(Faster object recognition & unlimited prompts)',
            isSelected: selectedPlan == 'Yearly',
            tag: 'BEST VALUE',
            onTap: () => setState(() => selectedPlan = 'Yearly'),
            borderColor: const Color(0xFFF8C56A),
          ),
          _buildPlanOption(
            title: '3 Months',
            price: '৳220',
            originalPrice: '৳300',
            description: 'Save 27%\nGet 3 Days Free Trial',
            features: '(Faster object recognition & unlimited prompts)',
            isSelected: selectedPlan == '3 Months',
            tag: 'Most Popular',
            onTap: () => setState(() => selectedPlan = '3 Months'),
            borderColor: const Color(0xFFFFB1C1),
          ),
          _buildPlanOption(
            title: '1 Month',
            price: '৳80',
            originalPrice: '৳100',
            description: 'Save 20%',
            features: '(Faster object recognition & unlimited prompts)',
            isSelected: selectedPlan == '1 Month',
            onTap: () => setState(() => selectedPlan = '1 Month'),
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
              onPressed: () {
                _handleContinue();
              },
              child: const Text(
                "Continue to Purchase",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    _isListening ? "Listening..." : "Say a command",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
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
    String? features,
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
                  if (features != null)
                    Text(
                      features!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
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
*/

/*
//main file

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'checkout.dart';

class FreemiumModelScreen extends StatefulWidget {
  const FreemiumModelScreen({super.key});

  @override
  State<FreemiumModelScreen> createState() => _FreemiumModelScreenState();
}

class _FreemiumModelScreenState extends State<FreemiumModelScreen> {
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  String selectedPlan = 'Yearly';
  bool _isListening = false;

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
    await _flutterTts.speak(
        "Welcome to the freemium model. Let me explain our subscription plans. All our plans offer faster object recognition, unlimited prompts, and priority support. ");
    await _flutterTts.speak(
        "Our Yearly plan is normally 900, now only 600 with 33% savings and 7 days free trial. This is our BEST VALUE plan.");
    await _flutterTts.speak(
        "Our 3 Months plan is usually 300, now only 220 with 27% savings and 3 days free trial. This is our MOST POPULAR plan.");
    await _flutterTts
        .speak("Our 1 Month plan is 100, now only 80 with 20% savings.");
    await _flutterTts.speak(
        "Please say 'Yearly', '3 Months', or '1 Month' to select your preferred plan.");
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
    command = command.toLowerCase();
    if (command.contains('yearly')) {
      setState(() => selectedPlan = 'Yearly');
      _flutterTts.speak("Yearly plan selected");
    } else if (command.contains('3 months')) {
      setState(() => selectedPlan = '3 Months');
      _flutterTts.speak("3 Months plan selected");
    } else if (command.contains('1 month')) {
      setState(() => selectedPlan = '1 Month');
      _flutterTts.speak("1 Month plan selected");
    } else if (command.contains('continue')) {
      _handleContinue();
    } else {
      _flutterTts.speak("Command not recognized. Please try again.");
    }
  }

  void _handleContinue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Checkout(
          planName: selectedPlan,
          price: _getPlanPrice(selectedPlan),
          description: _getPlanDescription(selectedPlan),
        ),
      ),
    );
  }

  String _getPlanPrice(String plan) {
    switch (plan) {
      case 'Yearly':
        return '৳600';
      case '3 Months':
        return '৳220';
      case '1 Month':
        return '৳80';
      default:
        return '';
    }
  }

  String _getPlanDescription(String plan) {
    switch (plan) {
      case 'Yearly':
        return 'Save 33%\nGet 7 Days Free Trial';
      case '3 Months':
        return 'Save 27%\nGet 3 Days Free Trial';
      case '1 Month':
        return 'Save 20%';
      default:
        return '';
    }
  }

  @override
  void dispose() {
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Choose Your Plan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"Speak Aloud"',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Plan Options
          _buildPlanOption(
            title: 'Yearly',
            price: '৳600',
            originalPrice: '৳900',
            description: 'Save 33%\nGet 7 Days Free Trial',
            features: '(Faster object recognition & unlimited prompts)',
            isSelected: selectedPlan == 'Yearly',
            tag: 'BEST VALUE',
            onTap: () => setState(() => selectedPlan = 'Yearly'),
            borderColor: const Color(0xFFF8C56A),
          ),
          _buildPlanOption(
            title: '3 Months',
            price: '৳220',
            originalPrice: '৳300',
            description: 'Save 27%\nGet 3 Days Free Trial',
            features: '(Faster object recognition & unlimited prompts)',
            isSelected: selectedPlan == '3 Months',
            tag: 'Most Popular',
            onTap: () => setState(() => selectedPlan = '3 Months'),
            borderColor: const Color(0xFFFFB1C1),
          ),
          _buildPlanOption(
            title: '1 Month',
            price: '৳80',
            originalPrice: '৳100',
            description: 'Save 20%',
            features: '(Faster object recognition & unlimited prompts)',
            isSelected: selectedPlan == '1 Month',
            onTap: () => setState(() => selectedPlan = '1 Month'),
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
              onPressed: _handleContinue,
              child: const Text(
                "Continue to Purchase",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    _isListening ? "Listening..." : "Say a command",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
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
    String? features,
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
                  if (features != null)
                    Text(
                      features!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
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
*/
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'checkout.dart';

class FreemiumModelScreen extends StatefulWidget {
  const FreemiumModelScreen({super.key});

  @override
  State<FreemiumModelScreen> createState() => _FreemiumModelScreenState();
}

class _FreemiumModelScreenState extends State<FreemiumModelScreen> {
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  String selectedPlan = 'Yearly';
  bool _isListening = false;

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
    await _flutterTts.speak(
        "Welcome to the freemium model. Let me explain our subscription plans. All our plans offer faster object recognition, unlimited prompts, and priority support. ");
    await _flutterTts.speak(
        "Our Yearly plan is normally 900, now only 600 with 33% savings and 7 days free trial. This is our BEST VALUE plan.");
    await _flutterTts.speak(
        "Our 3 Months plan is usually 300, now only 220 with 27% savings and 3 days free trial. This is our MOST POPULAR plan.");
    await _flutterTts
        .speak("Our 1 Month plan is 100, now only 80 with 20% savings.");
    await _flutterTts.speak(
        "Please say 'Yearly', '3 Months', or '1 Month' to select your preferred plan.");
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
    command = command.toLowerCase();
    if (command.contains('yearly')) {
      setState(() => selectedPlan = 'Yearly');
      _flutterTts.speak("Yearly plan selected");
    } else if (command.contains('3 months')) {
      setState(() => selectedPlan = '3 Months');
      _flutterTts.speak("3 Months plan selected");
    } else if (command.contains('1 month')) {
      setState(() => selectedPlan = '1 Month');
      _flutterTts.speak("1 Month plan selected");
    } else if (command.contains('continue')) {
      _handleContinue(); // Call the method to navigate to Checkout
    } else {
      _flutterTts.speak("Command not recognized. Please try again.");
    }
  }

  // Insert the _handleContinue method here
  void _handleContinue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Checkout(
          planName: selectedPlan,
          price: _getPlanPrice(selectedPlan),
          description: _getPlanDescription(selectedPlan),
        ),
      ),
    );
  }

  String _getPlanPrice(String plan) {
    switch (plan) {
      case 'Yearly':
        return '৳600';
      case '3 Months':
        return '৳220';
      case '1 Month':
        return '৳80';
      default:
        return '';
    }
  }

  String _getPlanDescription(String plan) {
    switch (plan) {
      case 'Yearly':
        return 'Save 33%\nGet 7 Days Free Trial';
      case '3 Months':
        return 'Save 27%\nGet 3 Days Free Trial';
      case '1 Month':
        return 'Save 20%';
      default:
        return '';
    }
  }

  @override
  void dispose() {
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Choose Your Plan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"Speak Aloud"',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Plan Options
          _buildPlanOption(
            title: 'Yearly',
            price: '৳600',
            originalPrice: '৳900',
            description: 'Save 33%\nGet 7 Days Free Trial',
            features: '(Faster object recognition & unlimited prompts)',
            isSelected: selectedPlan == 'Yearly',
            tag: 'BEST VALUE',
            onTap: () => setState(() => selectedPlan = 'Yearly'),
            borderColor: const Color(0xFFF8C56A),
          ),
          _buildPlanOption(
            title: '3 Months',
            price: '৳220',
            originalPrice: '৳300',
            description: 'Save 27%\nGet 3 Days Free Trial',
            features: '(Faster object recognition & unlimited prompts)',
            isSelected: selectedPlan == '3 Months',
            tag: 'Most Popular',
            onTap: () => setState(() => selectedPlan = '3 Months'),
            borderColor: const Color(0xFFFFB1C1),
          ),
          _buildPlanOption(
            title: '1 Month',
            price: '৳80',
            originalPrice: '৳100',
            description: 'Save 20%',
            features: '(Faster object recognition & unlimited prompts)',
            isSelected: selectedPlan == '1 Month',
            onTap: () => setState(() => selectedPlan = '1 Month'),
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
              onPressed: _handleContinue, // Call _handleContinue here
              child: const Text(
                "Continue to Purchase",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    _isListening ? "Listening..." : "Say a command",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
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
    String? features,
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
                  if (features != null)
                    Text(
                      features!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
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

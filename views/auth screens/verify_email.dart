import 'package:ai_assistant/views/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyEmail extends StatefulWidget {
  const VerifyEmail({super.key});

  @override
  _VerifyEmailState createState() => _VerifyEmailState();
}

class _VerifyEmailState extends State<VerifyEmail> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  // Function to check if email is verified
  Future<void> _checkEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Listen to changes in the user's email verification status
      user.reload(); // Refresh user data
      final updatedUser = _auth.currentUser;
      if (updatedUser != null && updatedUser.emailVerified) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const BottomNavigation(), // Navigate to homepage
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Email Verification Required",
          style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 15,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "An email has been sent to you. \n"
                  "Please confirm your email address to proceed. \n",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _checkEmailVerification();
              },
              child: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }
}

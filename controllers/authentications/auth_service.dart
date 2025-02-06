import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user is logged in and email is verified
  Future<bool> isUserLoggedIn() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload(); // Reload user to get the latest verification status
      user = _auth.currentUser;
      return user!.emailVerified;
    }
    return false;
  }
}

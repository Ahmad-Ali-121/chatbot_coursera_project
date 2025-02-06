import 'package:ai_assistant/views/auth screens/verify_email.dart';
import 'package:ai_assistant/views/bottom_navigation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../views/auth screens/login_screen.dart';

class UserAuthentication {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserAuthentication();


  Future<String> login(
      BuildContext context, String email, String password) async {

    String msg = "An error occurred";
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? fcmToken = await messaging.getToken();

      if (user != null) {
        if (user.emailVerified) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Login successful')));
          });
          msg = "Login successful";
          checkEmailVerification();
        } else {
          msg = "Please verify your email before logging in.";
          checkEmailVerification();
        }

        await _firestore.collection('usersInfo').doc(user.uid).update({
          'token': fcmToken,
        });

      }
    } on FirebaseAuthException catch (e) {

      if (e.code == 'user-not-found') {
        msg = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        msg = 'Wrong password provided for that user.';
      } else if (e.message!.contains("auth credential is incorrect")) {
        msg = "Incorrect credentials";
      }else if (e.message!.contains("We have blocked all requests from this device")) {
        msg = "Account temporarily disabled due to failed login attempts. Try again later.";
      }else if (e.code == 'too-many-requests') {
        msg = 'Too many requests. Please try again later.';
      }else if (e.code == 'You can immediately restore it by resetting your password or you can try again later.') {
        msg = 'Account temporarily disabled due to failed login attempts. Reset password or try again later.';
      }else if (e.message!.contains('user account has been disabled by an administrator')) {
        msg = 'Your Account is disabled by an administrator. Please contact support.';
      }else if (e.code == 'network-request-failed') {
        msg = 'No or slow internet error!.';
      }

    } catch (e) {
      msg = "An error occurred";
    }

    return msg;
  }

  Future<String> signup(BuildContext context, String email, String password,
      String name, String phone) async {

    String msg = "An error occurred";

    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;


      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? fcmToken = await messaging.getToken();

      if (user != null && fcmToken != null) {
        await user.sendEmailVerification();
        // Store additional user details in Firestore
        await _firestore.collection('usersInfo').doc(user.uid).set({
          'name': name,
          'email': email,
          'uid': user.uid,
          'phoneNumber': phone,
          'emailVerified': false,
          'token': fcmToken,
        });


         msg = 'Signup successful';

        checkEmailVerification();
      }else{
        msg = "Something is null";
      }
    } on FirebaseAuthException catch (e) {
      msg = 'An unknown error occurred';
      if (e.code == 'weak-password') {
        msg = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        msg =  'The account already exists for that email.';
      }

    } catch (e) {
      msg = 'An unknown error occurred';
    }

    return msg;
  }

  void checkEmailVerification() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload(); // Reload user to get the latest verification status
      user = FirebaseAuth.instance.currentUser;

      if (user!.emailVerified) {
        await FirebaseFirestore.instance
            .collection('usersInfo')
            .doc(user.uid)
            .update({'emailVerified': true});
        Get.to(()=> const BottomNavigation());
      } else {
        Get.to(() => const VerifyEmail());
      }
    }
  }

  Future<void> sendPasswordResetEmail(
      BuildContext context, String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset email sent.')));
      });
    } on FirebaseAuthException catch (e) {
      // Handle errors here
      String errorMessage = 'An unknown error occurred';
      if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      });
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Redirect to login screen after sign out
      Get.offAll(() => const LoginScreen()); // Navigates to the login screen and removes all previous routes
    } catch (e) {
      // Optionally show an error message to the user
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }
}

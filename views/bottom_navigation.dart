import 'dart:convert';
import 'dart:developer';
import 'package:ai_assistant/controllers/notifications/local_services.dart';
import 'package:ai_assistant/views/bottom%20navigation%20screens/notification/notification.dart';
import 'package:ai_assistant/views/bottom%20navigation%20screens/tasks/task_management.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'bottom navigation screens/home/home_screen.dart';
import 'bottom navigation screens/user profile/edit_profile.dart';


class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 1;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    getToken();

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      log("App is terminated");

      if (message != null) {
        log("App opened from terminated state by notification");

        // Extract the payload from the notification data
        if (message.data.isNotEmpty) {
          String payload = message.data['payload'] ?? '';

          // Decode the JSON payload into a Map
          Map<String, dynamic> payloadData;
          try {
            payloadData = jsonDecode(payload);
          } catch (e) {
            log('Error decoding payload: $e');
            payloadData = {}; // Handle invalid payload
          }

          // Use Get.to to navigate to a specific page with the payload data
          Get.to(() => NotificationScreen(payloadData));
        }
      }
    });

    FirebaseMessaging.onMessage.listen((message) {
      log("App is in foreground when notification received");

      if (message.notification != null) {
        // Extract the original title and body from the notification
        String? originalTitle = message.notification!.title;
        String? originalBody = message.notification!.body;


        // Extract the payload from message data
        String modifiedPayload = message.data['payload'] ?? '';

        log("Title: $originalTitle");
        log("Body: $originalBody");
        log("Payload: $modifiedPayload");

        // Create a new object with the modified values and pass it to createNotification
        LocalNotificationServices.createNotification(
          originalTitle!,
          originalBody!,
          modifiedPayload,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      log("App is in background when notification received");

      if (message.notification != null) {
        log(message.notification!.title!);
        log(message.notification!.body!);

        if (message.data.isNotEmpty) {
          String payload = message.data['payload'] ?? '';

          // Decode the JSON payload into a Map
          Map<String, dynamic> payloadData;
          try {
            payloadData = jsonDecode(payload);
          } catch (e) {
            log('Error decoding payload: $e');
            payloadData = {}; // Handle invalid payload
          }

          // Use Get.to to navigate to a specific page with the payload data
          Get.to(() => NotificationScreen(payloadData));
        }
      }
    });

    super.initState();
  }


  Future<void> getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      log("FCM Token: $token");
    } else {
      log("Token not fetched");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = [
      const TaskManagement(),
      const HomeScreen(),
      const EditProfile(),
    ];

    return GestureDetector(
      onTap: () {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: CurvedNavigationBar(
          backgroundColor: Colors.white,
          color: Colors.blueAccent,
          animationDuration: const Duration(milliseconds: 300),
          index: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            Icon(
              Icons.assignment,
              semanticLabel: "Tasks",
              color: Colors.white,
            ),
            Icon(
              Icons.home,
              semanticLabel: "Home",
              color: Colors.white,
            ),
            Icon(
              CupertinoIcons.settings,
              semanticLabel: "Profile",
              color: Colors.white,
            ),
          ],
        ),
        body: widgetList[_selectedIndex],
      ),
    );
  }
}

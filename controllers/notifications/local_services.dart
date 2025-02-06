import 'dart:convert';
import 'dart:developer';

import 'package:ai_assistant/views/bottom%20navigation%20screens/notification/notification.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class LocalNotificationServices {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void initialize() {
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: AndroidInitializationSettings("@mipmap/ic_launcher"));

    notificationsPlugin.initialize(initializationSettings);

    notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  static void createNotification(
      String title, String body, String payload) async {
    try {
      // Use a valid ID that fits within the 32-bit integer range
      final id = DateTime.now().millisecondsSinceEpoch % 1000000;

      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          "high_importance_channel",
          "high_importance_channel",
          importance: Importance.max,
          priority: Priority.high,
        ),
      );

      // Show the notification with the modified title and body
      await notificationsPlugin.show(
        id,
        title, // Modified title
        body, // Modified body
        notificationDetails,
        payload: payload, // Custom payload
      );
      sendAcknowledgement(payload);
    } on Exception catch (e) {
      log("Error in create notification: $e");
    }
  }

  // New callback for handling notification taps
  static void onDidReceiveNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      log('Notification clicked with payload: ${response.payload}');

      // Decode the JSON payload into a Map
      Map<String, dynamic> payloadData;
      try {
        payloadData = jsonDecode(response.payload!);
      } catch (e) {
        log('Error decoding payload: $e');
        payloadData = {}; // Handle invalid payload
      }

      // Use Get.to to navigate to a specific page with the payload data
      Get.to(() => NotificationScreen(payloadData));
    }
  }

  static Future<void> sendAcknowledgement(String payload) async {
    const url = 'YOUR_CLOUD_FUNCTION_URL'; // Replace with your cloud function URL
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: '{"payload": "$payload"}',
    );

    if (response.statusCode == 200) {
      log("Acknowledgement sent successfully.");
    } else {
      log("Failed to send acknowledgement.");
    }
  }
}

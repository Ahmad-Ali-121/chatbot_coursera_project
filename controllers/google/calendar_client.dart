import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';
import 'google_auth_client.dart';

class CalendarClient {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  final FirebaseAuth auth = FirebaseAuth.instance;

  final _googleSignIn = GoogleSignIn(
    scopes: [cal.CalendarApi.calendarScope],
  );

  Future<cal.CalendarApi?> initializeCalendar(BuildContext context) async {
    final account = await signIn();
    if (account != null) {
      final calendarApi = await getCalendarApiClient();
      if (calendarApi != null) {
        return calendarApi;
      } else {
        return null;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign-in failed.')),
      );

      return null;
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e, stackTrace) {
      log('Error signing in: $e');
      log('Stack Trace: $stackTrace');
      return null;
    }
  }

  Future<cal.CalendarApi?> getCalendarApiClient() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser != null) {
      final authHeaders = await googleUser.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      return cal.CalendarApi(authenticateClient);
    } else {
      log("Google user is null");
    }
    return null;
  }

  Future<Map<String, dynamic>> createEventWithPhysicalLocation(
      BuildContext context,
      String summary,
      DateTime startDate,
      DateTime endDate,
      String lat,
      String lng,
      String name) async {
    cal.CalendarApi? calendarApi = await initializeCalendar(context);

    String calendarMessage = "saved successfully";
    String databaseMessage = "saved successfully";

    if (calendarApi != null) {
      try {
        String timeZone = await FlutterTimezone.getLocalTimezone();

        final event = cal.Event(
          summary: summary,
          start: cal.EventDateTime(
            dateTime: startDate,
            timeZone: timeZone,
          ),
          end: cal.EventDateTime(
            dateTime: endDate,
            timeZone: timeZone,
          ),
        );


        try {
          final createdEvent =
              await calendarApi.events.insert(event, "primary");
          String eventId = createdEvent.id!;

          calendarMessage = "Event is saved successfully.";

          User? user = auth.currentUser;
          if (user != null) {
            String uid = user.uid;
            databaseReference
                .child("pendingCalendarEvents")
                .child(uid)
                .child(eventId)
                .set({
              "calendarId": eventId,
              "details": summary,
              "startDate": startDate.toIso8601String().split('T')[0],
              "startTime": startDate.toIso8601String().split('T')[1],
              "endDate": endDate.toIso8601String().split('T')[0],
              "endTime": endDate.toIso8601String().split('T')[1],
              "status": "pending",
              "locationName": name,
              "latitude": lat,
              "longitude": lng,
              "hasSent": false,
              "timezone": timeZone
            }).then((_) {
              calendarMessage = "Event is saved successfully.";
            }).catchError((e) {
              calendarMessage =
                  "Event is saved successfully in your calendar but not in database.";
            });
          } else {
            calendarMessage =
                "Login is required so that we can access your calendar for saving events.";
          }
        } catch (e) {
          // Hide the loading indicator
          Navigator.of(context).pop();

          User? user = auth.currentUser;
          if (user != null) {
            Uuid uuid = const Uuid();
            String errorId = uuid.v4();

            String uid = user.uid;
            databaseReference
                .child("calendarErrors")
                .child(uid)
                .child(errorId)
                .set({
              "errorId": errorId,
              "error": e,
              "details": summary,
              "startDate": startDate.toLocal().toIso8601String().split('T')[0],
              "startTime": startDate.toLocal().toIso8601String().split('T')[1],
              "endDate": endDate.toLocal().toIso8601String().split('T')[0],
              "endTime": endDate.toLocal().toIso8601String().split('T')[1],
              "status": "error",
              "locationName": name,
              "latitude": lat,
              "longitude": lng,
              "hasSent": false,
              "timezone": "Error"
            }).then((_) {
              databaseMessage = "Saved to database successfully!";
            }).catchError((e) {
              databaseMessage = 'Error saving to calendar in database: $e';
            });
          } else {
            calendarMessage = 'User not logged in';
          }
          calendarMessage = "Error saving event in calendar. $e";
        }
      } catch (e) {
        calendarMessage = 'Timezone error: $e';
        databaseMessage = 'Error saving to calendar in database';
      }
    } else {
      calendarMessage = "Error while taking permission from calendar";
    }

    log("testing cal: $calendarMessage");
    log("testing cal: $databaseMessage");
    return {
      "calendarMessage": calendarMessage,
      "databaseMessage": databaseMessage,
    };
  }

  Future<Map<String, dynamic>> createEventWithVirtualLocation(
      BuildContext context,
      String summary,
      DateTime startDate,
      DateTime endDate,
      String location) async {
    cal.CalendarApi? calendarApi = await initializeCalendar(context);

    String calendarMessage = "saved successfully";
    String databaseMessage = "saved successfully";

    if (calendarApi != null) {
      try {
        String timeZone = await FlutterTimezone.getLocalTimezone();

        final event = cal.Event(
          summary: summary,
          start: cal.EventDateTime(
            dateTime: startDate,
            timeZone: timeZone,
          ),
          end: cal.EventDateTime(
            dateTime: endDate,
            timeZone: timeZone,
          ),
        );


        try {
          final createdEvent =
              await calendarApi.events.insert(event, "primary");
          String eventId = createdEvent.id!;

          calendarMessage = "Event is saved successfully.";

          User? user = auth.currentUser;
          if (user != null) {
            String uid = user.uid;
            databaseReference
                .child("pendingCalendarEvents")
                .child(uid)
                .child(eventId)
                .set({
              "calendarId": eventId,
              "details": summary,
              "startDate": startDate.toIso8601String().split('T')[0],
              "startTime": startDate.toIso8601String().split('T')[1],
              "endDate": endDate.toIso8601String().split('T')[0],
              "endTime": endDate.toIso8601String().split('T')[1],
              "status": "pending",
              "locationName": location,
              "latitude": "Not Applicable",
              "longitude": "Not Applicable",
              "hasSent": false,
              "timezone": timeZone,
            }).then((_) {
              calendarMessage = "Event is saved successfully.";
            }).catchError((e) {
              calendarMessage =
                  "Event is saved successfully in your calendar but not in database.";
            });
          } else {
            calendarMessage =
                "Login is required so that we can access your calendar for saving events.";
          }
        } catch (e) {
          // Hide the loading indicator
          Navigator.of(context).pop();

          User? user = auth.currentUser;
          if (user != null) {
            Uuid uuid = const Uuid();
            String errorId = uuid.v4();

            String uid = user.uid;
            databaseReference
                .child("calendarErrors")
                .child(uid)
                .child(errorId)
                .set({
              "errorId": errorId,
              "error": e,
              "details": summary,
              "startDate": startDate.toLocal().toIso8601String().split('T')[0],
              "startTime": startDate.toLocal().toIso8601String().split('T')[1],
              "endDate": endDate.toLocal().toIso8601String().split('T')[0],
              "endTime": endDate.toLocal().toIso8601String().split('T')[1],
              "status": "error",
              "locationName": location,
              "latitude": "Not Applicable",
              "longitude": "Not Applicable",
              "hasSent": false,
              "timezone": "Error",
            }).then((_) {
              databaseMessage = "Saved to database successfully!";
            }).catchError((e) {
              databaseMessage = 'Error saving to calendar in database: $e';
            });
          } else {
            calendarMessage = 'User not logged in';
          }
          calendarMessage = "Error saving event in calendar. $e";
        }
      } catch (e) {
        calendarMessage = 'Timezone error: $e';
        databaseMessage = 'Error saving to calendar in database';
      }
    } else {
      calendarMessage = "Error while taking permission from calendar";
    }

    log("testing cal: $calendarMessage");
    log("testing cal: $databaseMessage");
    return {
      "calendarMessage": calendarMessage,
      "databaseMessage": databaseMessage,
    };
  }
}

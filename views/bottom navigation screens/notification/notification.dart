import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../controllers/maps/maps_controller.dart';
import '../../../controllers/weather/weather_controller.dart';
import '../../bottom_navigation.dart';

class NotificationScreen extends StatefulWidget {
  final Map<String, dynamic> eventData; // Making eventData nullable
  const NotificationScreen(this.eventData, {super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String? _temperature = "N/A";
  String? _origin = "N/A";
  String? _destination = "N/A";
  String? _traffic = "N/A";
  String? _duration = "N/A";
  String? _details = "N/A";
  String? _distance = "N/A";
  String? _location;

  bool _isLoading = true;
  bool _isAvailable = true;

  String? formattedStartDate;
  String? formattedStartTime;

  String? formattedEndDate;
  String? formattedEndTime;

  String? formattedDate;
  String? formattedTime;

  String? _icon;

  String eventType = "";

  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    fetchNotificationDetails();
    tz.initializeTimeZones();
    super.initState();
  }

  // Function to convert date string
  String _formatDate(String dateStr) {
    final DateFormat inputFormat = DateFormat('yyyy-MM-dd');
    final DateFormat outputFormat = DateFormat('d MMM, yyyy');
    final DateTime date = inputFormat.parse(dateStr);
    return outputFormat.format(date);
  }

  // Function to convert time string
  String _formatTime(String timeStr) {
    final DateFormat inputFormat = DateFormat('HH:mm:ss.SSS');
    final DateFormat outputFormat = DateFormat('h:mm a'); // AM/PM format
    final DateTime time = inputFormat.parse(timeStr);
    return outputFormat.format(time);
  }

  // Function to convert DateTime to a formatted date string
  String _formatDateNew(DateTime dateTime) {
    final DateFormat dateFormat =
    DateFormat('d MMM, yyyy'); // Example: 10 Sep, 2024
    return dateFormat.format(dateTime);
  }

  // Function to convert DateTime to a formatted time string
  String _formatTimeNew(DateTime dateTime) {
    final DateFormat timeFormat = DateFormat('h:mm a'); // Example: 7:39 PM
    return timeFormat.format(dateTime);
  }

  Future<String> getLocationNameFromCoordinates(double latitude, double longitude) async {
    String address;
    try {
      // Get location details from latitude and longitude
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        address =
        '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
      } else {
        address = 'No address found';
      }
    } catch (e) {
      log('Error fetching location details: $e');
      address = 'Error fetching address';
    }

    return address;
  }

  Future<void> fetchNotificationDetails() async {
    String userId = widget.eventData['userId'];
    List<dynamic> calendarIds = widget.eventData['calendarIds'];

    try {
      // Reference to the database path where the data is stored
      final DatabaseReference ref = databaseReference
          .child("pendingCalendarEvents")
          .child(userId)
          .child(calendarIds[0]);

      // Fetch the data once
      final DataSnapshot snapshot = await ref.get();

      if (snapshot.exists) {
        // Get the data as a Map
        final data = snapshot.value as Map?;

        final DateTime now = DateTime.now();

        if (data != null) {
          // Access specific data if you know the structure
          final details = data['details'];
          final endDate = data['endDate'];
          final endTime = data['endTime'];
          final latitude = data['latitude'];
          String locationName = data['locationName'];
          final longitude = data['longitude'];
          final startDate = data['startDate'];
          final startTime = data['startTime'];

          formattedStartDate = _formatDate(startDate);
          formattedStartTime = _formatTime(startTime);

          formattedEndDate = _formatDate(endDate);
          formattedEndTime = _formatTime(endTime);

          // Format the date and time
          formattedDate = _formatDateNew(now);
          formattedTime = _formatTimeNew(now);

          setState(() {
            _details = details;
          });

          if (latitude == "Not Applicable" || longitude == "Not Applicable") {

          } else {

            setState(() {
              eventType = "physical";
            });
            locationName = locationName.replaceAll(RegExp(r'[{}]'), '').trim();

            double lat = double.parse(latitude);
            double long = double.parse(longitude);

            String location = await getLocationNameFromCoordinates(lat, long);

            if (location == 'No address found') {
              setState(() {
                _destination = "Destination not found";
              });
            } else if (location == 'Error fetching address') {
              setState(() {
                _destination = "Error while fetching destination address";
              });
            } else {
              setState(() {
                _location = locationName;
                _destination = location;
              });

              Map<String, dynamic> weatherDetails =
              await WeatherApi.fetchWeatherData(location);
              setState(() {
                _temperature = weatherDetails['weather'];
                _icon = weatherDetails['icon'];
              });

              String userLocation =
              await GoogleMapsController.getUserLocation();

              setState(() {
                _origin = userLocation;
              });

              if (userLocation == "Permission not granted" ||
                  userLocation ==
                      "The location service on the device is disabled.") {
                setState(() {
                  _isLoading = false;
                  _isAvailable = false;
                });
                showAlertDialog(context);
              } else {
                Map<String, dynamic> destinationData =
                await GoogleMapsController
                    .getTrafficDistanceAndTimeOfTwoPoints(
                    userLocation, location);

                setState(() {
                  _duration = destinationData["duration"];
                  _distance = destinationData["distance"];
                  _traffic = destinationData["traffic condition"];
                  _isLoading = false;
                  _isAvailable = true;
                });

              }
            }
          }
        } else {
          log('No data found');
          setState(() {
            _isLoading = false;
            _isAvailable = false;
          });
        }
      } else {
        log('No data available at the reference');
        setState(() {
          _isLoading = false;
          _isAvailable = false;
        });
      }
    } catch (error) {
      log('Error fetching data: $error');
      setState(() {
        _isLoading = false;
        _isAvailable = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // Define responsive values
    final fiveWidth = screenWidth * 0.01215278;
    final fiveHeight = screenHeight * 0.0059121621621622;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.blue.shade300],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (_isLoading) const Center(child: CircularProgressIndicator()),
                if (!_isLoading)
                  if (_isAvailable)
                    if(eventType == "physical")
                      Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Details Card
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 8,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    "Details",
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  SizedBox(height: fiveHeight * 4),
                                  Text(
                                    _details ?? "No details available",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lora(
                                      fontSize: 18,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: fiveHeight * 5),

                          // Weather section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                "https:${_icon!}",
                                height: 100,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(width: fiveWidth * 4),
                              Column(
                                children: [
                                  Text(
                                    "Weather",
                                    style: GoogleFonts.lora(
                                      fontSize: 24,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    "$_temperature °C",
                                    style: GoogleFonts.lato(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.yellowAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          SizedBox(height: fiveHeight * 6),

                          // Origin and Destination
                          buildLocationCard("Origin", _origin, Colors.white),
                          SizedBox(height: fiveHeight * 5),
                          buildLocationCard("Destination", _location, Colors.white),

                          SizedBox(height: fiveHeight * 5),

                          // Duration & Distance
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              buildInfoTile("Duration", "$_duration", Colors.greenAccent),
                              buildInfoTile("Distance", "$_distance", Colors.pinkAccent),
                            ],
                          ),
                          SizedBox(height: fiveHeight * 5),

                          // Traffic condition
                          Text(
                            "Traffic: $_traffic",
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    )
                    else
                      Container()
                  else
                    const Center(
                      child: Text(
                        "No data to show.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLocationCard(String title, String? location, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 10,
      color: color.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$title:",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              location ?? "Unknown",
              style: GoogleFonts.lora(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.lora(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }



  void showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Alert!'),
          content: const Text(
              "To provide traffic and weather information, location access is required. Click 'Ok' to grant permission or 'Cancel' to go to 'Main Screen'."),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Get.to(() => const BottomNavigation());
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                fetchNotificationDetails();
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}

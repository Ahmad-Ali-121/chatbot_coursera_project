import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../../consts.dart';

class GoogleMapsController{

  // Method to request location permission and get location
  static Future<String> getUserLocation() async {

    String location = "Location error because user does not give access for fetching device location.";

    // Request location permission
    final status = await Permission.location.request();

    if (status == PermissionStatus.granted) {

      // Get the current location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Reverse geocode to get the address
      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks[0];

      // Format the address
      location =
        "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";

      return location;

    }
    return location;
  }

  static Future<Map<String, dynamic>> getTrafficDistanceAndTimeFromUserLocationToDestination(String destination) async {

    final String origin = await getUserLocation();
    

    final String url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?units=metric'
        '&origins=$origin'
        '&destinations=$destination'
        '&departure_time=now'
        '&key=$GOOGLE_MAPS_API';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Extract values
      String distanceText = data['rows'][0]['elements'][0]['distance']['text'];
      String durationText = data['rows'][0]['elements'][0]['duration']['text'];
      String durationInTrafficText =
      data['rows'][0]['elements'][0]['duration_in_traffic']['text'];

      // Convert duration in traffic to minutes
      int durationInMinutes = _convertDurationToMinutes(durationText);
      int durationInTrafficMinutes =
      _convertDurationToMinutes(durationInTrafficText);

      // Determine traffic difficulty
      String trafficDifficulty =
      _getTrafficDifficulty(durationInMinutes, durationInTrafficMinutes);

      return{
        "distance" : distanceText,
        "duration" : durationText,
        "traffic condition": trafficDifficulty,
        "message" : "Successfully retrieved Map's data",
        "responseCode" : response.statusCode,
      };



    } else {
      return {
        "distance" : "Error",
        "duration" : "Error",
        "traffic condition": "Error",
        "message" : "Failed to retrieved Map's data. Error is in google maps api. The response code is returned by google maps api.",
        "responseCode" : response.statusCode,
      };
    }
  }

  static Future<Map<String, dynamic>> getTrafficDistanceAndTimeOfTwoPoints(String origin, String destination) async {

    Map<String, dynamic> googleMapsData = {};

    final String url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?units=metric'
        '&origins=$origin'
        '&destinations=$destination'
        '&departure_time=now'
        '&key=$GOOGLE_MAPS_API';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);


      // Extract values
      String distanceText = data['rows'][0]['elements'][0]['distance']['text'];
      String durationText = data['rows'][0]['elements'][0]['duration']['text'];
      String durationInTrafficText =
      data['rows'][0]['elements'][0]['duration_in_traffic']['text'];

      // Convert duration in traffic to minutes
      int durationInMinutes = _convertDurationToMinutes(durationText);
      int durationInTrafficMinutes =
      _convertDurationToMinutes(durationInTrafficText);

      // Determine traffic difficulty
      String trafficDifficulty =
      _getTrafficDifficulty(durationInMinutes, durationInTrafficMinutes);

      googleMapsData = {
        "distance" : distanceText,
        "duration" : durationText,
        "traffic condition": trafficDifficulty,
        "message" : "Successfully retrieved Map's data. Api request successful.",
        "responseCode" : response.statusCode,
      };

    } else {
      googleMapsData = {
        "distance" : "error",
        "duration" : "error",
        "traffic condition": "error",
        "message" : "Failed to retrieved Map's data. Error is in google maps api. The response code is returned by google maps api.",
        "responseCode" : response.statusCode,
      };
    }

    return googleMapsData;
  }

  static int _convertDurationToMinutes(String durationText) {
    final regex = RegExp(r'(\d+) mins');
    final match = regex.firstMatch(durationText);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  static String _getTrafficDifficulty(int durationInMinutes, int durationInTrafficMinutes) {
    if ((durationInTrafficMinutes - durationInMinutes) <= 5) {
      return 'None';
    } else if ((durationInTrafficMinutes - durationInMinutes) <= 15) {
      return 'Low';
    } else if ((durationInTrafficMinutes - durationInMinutes) <= 30) {
      return 'Medium';
    } else {
      return 'High';
    }
  }

  // Function to fetch exact location from Google Maps Places API
  static Future<Map<String, dynamic>> getExactLocation(String locationQuery) async {
    const String apiKey = GOOGLE_MAPS_API; // Replace with your API key
    final String requestUrl =
        'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$locationQuery&radius=5000&key=$apiKey';


    try {
      final response = await http.get(Uri.parse(requestUrl));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List results = json['results'];

        // Limit results to 5
        final limitedResults = results.take(5).toList();

        if (limitedResults.isEmpty) {
          return {
            "location": "No location found. Ask user to give correct location.",
          };
        } else if (limitedResults.length == 1) {
          final locationData = limitedResults[0];
          final formattedAddress = locationData['formatted_address'] ?? 'Address not available';
          final name = locationData['name'] ?? 'Name not available';
          final openNow = locationData['opening_hours']?['open_now'] ?? false;

          return {
            "location": "name: $name, location: $formattedAddress, currentlyOpen: $openNow",
          };

        } else {
          return {
            "locations": limitedResults.map((result) {
              final formattedAddress = result['formatted_address'] ?? 'Address not available';
              final name = result['name'] ?? 'Name not available';
              final openNow = result['opening_hours']?['open_now'] ?? false;

              return {
                "location": "name: $name, location: $formattedAddress, currentlyOpen: $openNow"
              };
            }).toList()
          };
        }
      } else {
        return {
          "location": 'Failed to load data. Status code: ${response.statusCode} received from google maps api',
        };
      }
    } catch (e) {
      return {
        "location": 'Error fetching exact location: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getExactLocationCoordinates(String locationQuery) async {
    const String apiKey = GOOGLE_MAPS_API; // Replace with your API key
    final String requestUrl =
        'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$locationQuery&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(requestUrl));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List results = json['results'];

        // Extract only name and coordinates
        final locations = results.map((result) {
          final name = result['name'] ?? 'Name not available';
          final geometry = result['geometry'] ?? {};
          final location = geometry['location'] ?? {};
          final lat = location['lat'] ?? 'Latitude not available';
          final lng = location['lng'] ?? 'Longitude not available';

          return {
            "name": name,
            "coordinates": {
              "lat": lat,
              "lng": lng,
            },
            "location": "Location found successfully.",
            "details": "Success.",
          };
        }).toList();

        if (locations.isEmpty) {
          return {
            "location": "No location found",
            "details": "Error! restricted to proceed. No location found. Tell user that no location found.",
          };
        } else if (locations.length == 1) {
          final locationData = locations[0];
          return {
            "location": "name: ${locationData['name']}, coordinates: ${locationData['coordinates']}",
            "details": "Exact one location found ready to proceed.",
          };
        } else {
          return {
            "locations": "Multiple locations",
            "details": "Multiples locations found, not ready to proceed. Ask user to give single or exact location.",
          };
        }
      } else {
        return {
          "location": 'Failed to load data. Status code: ${response.statusCode} received from google maps api.',
          "details": "Error! restricted to proceed.",
        };
      }
    } catch (e) {
      return {
        "location": 'Error fetching exact location: $e',
        "details": "Error! restricted to proceed.",
      };
    }
  }

}
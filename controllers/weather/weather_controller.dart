import 'dart:convert';

import 'package:ai_assistant/consts.dart';
import 'package:ai_assistant/models/weather_model.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class WeatherApi {
  final baseUrl = "http://api.weatherapi.com/v1/current.json";

  static Future<Map<String, dynamic>> fetchWeatherDataOfUser() async {
    String location = "Lahore, Pakistan";

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

      String apiUrl =
          "http://api.weatherapi.com/v1/current.json?key=$WEATHER_API_KEY&q=$location";
      String weatherData = "Weather data not fetched";
      String weatherMsg = "";

      try {
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final ApiResponse weatherResponse =
              ApiResponse.fromJson(jsonDecode(response.body));

          weatherData = "${weatherResponse.current?.tempC?.toString() ?? "N/A"} °C";
          weatherMsg = "Weather data fetched successfully";
        } else {
          weatherMsg = "Response not get from weather api. Api response code is ${response.statusCode}";
        }
      } catch (e) {
        weatherMsg = "Error fetching weather data: $e";
      }

      return {
        "weather": weatherData,
        "weather message": weatherMsg,
        "user location": location,
      };
    } else {
      return {
        "weather": "weather error",
        "weather message": "Failed to load weather due to user's location not fetched because user did not grant user permission.",
        "user location": "Failed to get user location. Tell user to give location permissions.",
      };
    }
  }

  static Future<Map<String, dynamic>> fetchWeatherData(String location) async {
    String apiUrl =
        "http://api.weatherapi.com/v1/current.json?key=$WEATHER_API_KEY&q=$location";
    String weatherData = "Weather data not fetched";
    String weatherMsg = "";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final ApiResponse weatherResponse =
            ApiResponse.fromJson(jsonDecode(response.body));

        weatherData =
            "${weatherResponse.current?.tempC?.toString() ?? "N/A"} °C";
        weatherMsg = "Weather data fetched successfully";
      } else {
        weatherMsg = "Response not get from weather api. Api response code is ${response.statusCode}";
      }
    } catch (e) {
      weatherMsg = "Error fetching weather data: $e";
    }

    return {
      "weather": weatherData,
      "weather message": weatherMsg,
    };
  }
}



import 'dart:developer';

class DateController {


  static Map<String, String> getCurrentDateTime() {
    Map<String, String> dateString = {};

    DateTime now = DateTime.now();

    // Fetch current date
    String date = "${now.day}-${now.month}-${now.year}";

    // Fetch current day
    List<String> weekdays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];


    String day = weekdays[now.weekday - 1];

    // Fetch current time
    String time = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    dateString = {
      "Date": date,
      "Day": day,
      "Time": time,
    };


    return dateString;
  }

  static Map<String, String> getCurrentDateTimeDetailed() {
    Map<String, String> dateString = {};

    DateTime now = DateTime.now();


    // Fetch current day
    List<String> weekdays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];


    String day = weekdays[now.weekday - 1];

    // Fetch current time
    String time = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    dateString = {
      "Day": day,
      "Time": time,
      "Month": now.month.toString(),
      "Date": now.day.toString(),
      "Year": now.year.toString(),
    };

    DateTime utcNow = now.toUtc();

    // Fetch current time with padding for both hours and minutes
    String utcTime = "${utcNow.hour.toString().padLeft(2, '0')}:${utcNow.minute
        .toString().padLeft(2, '0')}";

    // Fetch time zone details
    String localTimeZone = now.timeZoneName;
    int localTimeOffset = now.timeZoneOffset.inHours;

    // Fetch current date
    String date = "${now.day}-${now.month}-${now.year}";


    log("Date: $date");
    log("Day: $day");
    log("Local Time: $time");
    log("UTC Time: $utcTime");
    log("Time Zone: $localTimeZone");
    log("Time Zone Offset (in hours): $localTimeOffset");


    return dateString;
  }
}


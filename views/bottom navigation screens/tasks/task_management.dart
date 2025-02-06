import 'dart:async';
import 'package:ai_assistant/views/bottom%20navigation%20screens/tasks/task_history.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TaskManagement extends StatefulWidget {
  const TaskManagement({super.key});

  @override
  State<TaskManagement> createState() => _TaskManagementState();
}

class _TaskManagementState extends State<TaskManagement> {
  StreamSubscription? eventSubscription;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

  List<String> dailyStartTimeList = [];
  List<String> dailyEndTimeList = [];
  List<String> dailyTaskList = [];
  List<String> dailyDateList = [];
  List<String> dailyStatusList = [];
  List<String> dailyCalendarIdList = [];

  List<String> upcomingStartTimeList = [];
  List<String> upcomingEndTimeList = [];
  List<String> upcomingTaskList = [];
  List<String> upcomingDateList = [];
  List<String> upcomingStatusList = [];
  List<String> upcomingCalendarIdList = [];

  bool isLoading = true;

  int dailyPendingTask = 0;
  int upcomingPendingTask = 0;

  String _name = 'Loading...';
  bool _hasError = false;

  @override
  void initState() {
    _startListeningForTodayEventsFromFirebase();
    _startListeningForUpcomingEventsFromFirebase();
    _fetchName();
    super.initState();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning!';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon!';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening!';
    } else {
      return 'Good Night!';
    }
  }

  void _fetchName() async {
    User? user = auth.currentUser;
    if (user != null) {
      String uid = user.uid;

      try {
        DocumentSnapshot document = await FirebaseFirestore.instance
            .collection('usersInfo')
            .doc(uid) // Replace with your document ID
            .get();

        if (document.exists) {
          // Safely cast to Map<String, dynamic> and check for null
          Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;

          setState(() {
            // Access the 'name' field with a default value
            _name = data?['name'] ?? 'No name available';
          });
        } else {
          setState(() {
            _name = 'No data found';
          });
        }
      } catch (e) {
        setState(() {
          _name = 'Error: ${e.toString()}';
          _hasError = true;
        });
      }
    }
  }

  void _startListeningForTodayEventsFromFirebase() {
    User? user = auth.currentUser;
    if (user != null) {
      String uid = user.uid;
      DatabaseReference eventsRef =
          databaseReference.child("pendingCalendarEvents").child(uid);

      DateTime today = DateTime.now();
      // String todayDate = today.toLocal().toIso8601String().split('T')[0];
      String todayDate = DateFormat('yyyy-MM-dd').format(today);

      eventSubscription = eventsRef.onValue.listen((event) {
        final dataSnapshot = event.snapshot;

        if (dataSnapshot.exists) {
            dailyPendingTask = 0;
            Map<dynamic, dynamic> events =
              dataSnapshot.value as Map<dynamic, dynamic>;

            if (mounted) {
              setState(() {
                dailyStartTimeList.clear();
                dailyEndTimeList.clear();
                dailyTaskList.clear();
                dailyDateList.clear();
                dailyStatusList.clear();
                dailyCalendarIdList.clear();
              });
            }

            events.forEach((key, value) {
              if (value['startDate'] == todayDate) {
                String formattedStartTime = DateFormat('HH:mm')
                    .format(DateTime.parse("1970-01-01 ${value['startTime']}"));
                String formattedEndTime = DateFormat('HH:mm')
                    .format(DateTime.parse("1970-01-01 ${value['endTime']}"));

                if (mounted) {
                  setState(() {
                    dailyTaskList.add(value['details']);
                  });
                }
                dailyStartTimeList.add(formattedStartTime);
                dailyEndTimeList.add(formattedEndTime);


                dailyCalendarIdList.add(value['calendarId']);
                DateTime parsedDate = DateTime.parse(value['startDate']);
                String formattedDate =
                    DateFormat('E, d MMMM yyyy').format(parsedDate);
                dailyDateList.add(formattedDate);
                dailyStatusList.add(value['status']);
                if (value['status'] == 'pending') {
                  dailyPendingTask++;
                }
              }
            });
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }

        } else {
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        }
      });
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _startListeningForUpcomingEventsFromFirebase() {
    User? user = auth.currentUser;
    if (user != null) {
      String uid = user.uid;
      DatabaseReference eventsRef =
          databaseReference.child("pendingCalendarEvents").child(uid);

      DateTime today = DateTime.now();
      String todayDate = today.toLocal().toIso8601String().split('T')[0];

      eventSubscription = eventsRef.onValue.listen((event) {
        final dataSnapshot = event.snapshot;

        if (dataSnapshot.exists) {


          setState(() {
            upcomingPendingTask = 0;
          });
          Map<dynamic, dynamic> events =
              dataSnapshot.value as Map<dynamic, dynamic>;

          setState(() {
            upcomingStartTimeList.clear();
            upcomingEndTimeList.clear();
            upcomingTaskList.clear();
            upcomingDateList.clear();
            upcomingStatusList.clear();
            upcomingCalendarIdList.clear();

            events.forEach((key, value) {
              if (value['startDate'].compareTo(todayDate) > 0) {
                String formattedStartTime = DateFormat('HH:mm')
                    .format(DateTime.parse("1970-01-01 ${value['startTime']}"));
                String formattedEndTime = DateFormat('HH:mm')
                    .format(DateTime.parse("1970-01-01 ${value['endTime']}"));

                upcomingStartTimeList.add(formattedStartTime);
                upcomingEndTimeList.add(formattedEndTime);
                upcomingTaskList.add(value['details']);
                upcomingCalendarIdList.add(value['calendarId']);
                DateTime parsedDate = DateTime.parse(value['startDate']);
                String formattedDate =
                    DateFormat('E, d MMMM yyyy').format(parsedDate);
                upcomingDateList.add(formattedDate);
                upcomingStatusList.add(value['status']);
                if (value['status'] == 'pending') {
                  upcomingPendingTask++;
                }
              }
            });
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _changeStatusToday(String calendarId, String newStatus) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid;

        // Reference to the specific node
        DatabaseReference ref = FirebaseDatabase.instance
            .ref()
            .child('pendingCalendarEvents')
            .child(uid)
            .child(calendarId)
            .child('status');

        // Update the status field
        await ref.set(newStatus);
        // print('Status updated successfully');

      }
    } catch (e) {
      // print('Error updating status: $e');
    }
  }

  void _changeStatusUpcoming(String calendarId, String newStatus) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid;

        // Reference to the specific node
        DatabaseReference ref = FirebaseDatabase.instance
            .ref()
            .child('pendingCalendarEvents')
            .child(uid)
            .child(calendarId)
            .child('status');

        // Update the status field
        await ref.set(newStatus);
        // print('Status updated successfully');

      }
    } catch (e) {
      // print('Error updating status: $e');
    }
  }

  @override
  void dispose() {
    eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    final screenWidth = MediaQuery.of(context).size.width;
    // Define responsive values
    final fiveSize = screenWidth * 0.01215278;

    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
        ),
        padding: EdgeInsets.fromLTRB(fiveSize * 4, fiveSize * 8, fiveSize * 4, fiveSize * 7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, fiveSize * 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 0, fiveSize * 2, 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(fiveSize * 4.5),
                          color: const Color(0xFFD9D9D9),
                          image: const DecorationImage(
                            fit: BoxFit.cover,
                            image: AssetImage(
                              'assets/images/ellipse_2.jpeg',
                            ),
                          ),
                        ),
                        child: SizedBox(
                          width: fiveSize * 9,
                          height: fiveSize * 9,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.fromLTRB(fiveSize * 0.18, fiveSize * 0.4, fiveSize * 4, 0),
                            child: Text(
                              _getGreeting(),
                              style: GoogleFonts.getFont(
                                'Work Sans',
                                fontWeight: FontWeight.w400,
                                fontSize: fiveSize * 2.4,
                                letterSpacing: -0.1,
                                color: const Color(0xFF7B7B7B),
                              ),
                            ),
                          ),
                          Text(
                            _hasError ? "Error" : _name,
                            style: GoogleFonts.getFont(
                              'Work Sans',
                              fontWeight: FontWeight.w600,
                              fontSize: fiveSize * 3.4,
                              letterSpacing: -0.1,
                              color: const Color(0xFF000B23),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                      onPressed: () {
                        Get.to(() => const TaskHistory());
                      },
                      icon: Icon(
                        Icons.history,
                        size: fiveSize * 5,
                        color: Colors.blueAccent,
                        weight: fiveSize * 2,
                      )),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(1.3, 0, 4, 31),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                    child: Text(
                      'My Daily Tasks',
                      style: GoogleFonts.getFont(
                        'Work Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        letterSpacing: -0.1,
                        color: const Color(0xFF000B23),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(0.4, 0, 0.4, 0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        '$dailyPendingTask Tasks are Pending Today',
                        style: GoogleFonts.getFont(
                          'Work Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          letterSpacing: -0.1,
                          color: const Color(0xFF7B7B7B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              if (dailyTaskList.isNotEmpty)
                LayoutBuilder(
                  // Number of items in the list
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Wrap(
                        spacing: fiveSize * 2, // Adjust the spacing between items
                        runSpacing: fiveSize * 2,
                        children: List.generate(dailyTaskList.length, (index) {
                          // Adjust the spacing between rows
                          return Container(
                            margin: EdgeInsets.fromLTRB(0, 0, 0, fiveSize * 8.4),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFFFF),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: SizedBox(
                                      width: fiveSize * 43,
                                      child: Container(
                                        padding: EdgeInsets.fromLTRB(
                                            fiveSize * 3.4, fiveSize * 3.8, fiveSize * 3.4, fiveSize * 4.5),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                       dailyStatusList[index],
                                                        style:
                                                        GoogleFonts.getFont(
                                                          'Poppins',
                                                          fontWeight:
                                                          FontWeight.w400,
                                                          fontSize: fiveSize * 2.5,
                                                          letterSpacing: 1,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ),

                                                    GestureDetector(
                                                      onTap: (){
                                                        if(dailyStatusList[index] == "pending"){
                                                          _changeStatusToday(dailyCalendarIdList[index], "completed");
                                                        }else{
                                                          _changeStatusToday(dailyCalendarIdList[index], "pending");
                                                        }

                                                      },
                                                      child: AnimatedContainer(
                                                        duration: const Duration(milliseconds: 200),
                                                        height: fiveSize * 3.5,
                                                        width: fiveSize * 8,
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(fiveSize * 5),
                                                          color: dailyStatusList[index] == "completed" ? Colors.green : Colors.red,
                                                        ),
                                                        child: Stack(
                                                          children: <Widget>[
                                                            AnimatedPositioned(
                                                              duration: const Duration(milliseconds: 200),
                                                              curve: Curves.easeIn,
                                                              left: dailyStatusList[index] == "completed" ? (fiveSize * 8 - fiveSize * 3.5) : 0.0,
                                                              child: Container(
                                                                height: fiveSize * 3.5,
                                                                width: fiveSize * 3.5,
                                                                decoration: const BoxDecoration(
                                                                  shape: BoxShape.circle,
                                                                  color: Colors.white,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: fiveSize * 5,),
                                                Container(
                                                  margin:
                                                      EdgeInsets.fromLTRB(
                                                          0, 0, 0, fiveSize * 4),
                                                  child: Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: Text(
                                                      dailyTaskList[index],
                                                      style:
                                                          GoogleFonts.getFont(
                                                        'Work Sans',
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: fiveSize * 3.5,
                                                        letterSpacing: -0.1,
                                                        color: const Color(
                                                            0xFF000B23),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .center,
                                                  children: [
                                                    Container(
                                                      margin: EdgeInsets
                                                          .fromLTRB(
                                                          0, 0, 0, fiveSize),
                                                      decoration:
                                                      BoxDecoration(
                                                        color: const Color(
                                                            0x1A8E61E9),
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(fiveSize * 6),
                                                      ),
                                                      padding:
                                                      EdgeInsets
                                                          .fromLTRB(
                                                          fiveSize * 2.72, fiveSize * 1.2, fiveSize * 2.4, fiveSize * 1.2),
                                                      child: Text(
                                                        dailyStartTimeList[
                                                        index],
                                                        style: GoogleFonts
                                                            .getFont(
                                                          'Work Sans',
                                                          fontWeight:
                                                          FontWeight.w500,
                                                          fontSize: fiveSize * 2.4,
                                                          letterSpacing: -0.1,
                                                          color: Colors
                                                              .blueAccent,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      margin: EdgeInsets
                                                          .fromLTRB(
                                                          0, 0, 0, fiveSize),
                                                      padding:
                                                      EdgeInsets
                                                          .fromLTRB(
                                                          0, fiveSize * 1.2, 0, fiveSize * 1.2),
                                                      child: Text(
                                                        "to",
                                                        style: GoogleFonts
                                                            .getFont(
                                                          'Work Sans',
                                                          fontWeight:
                                                          FontWeight.w500,
                                                          fontSize: fiveSize * 3,
                                                          letterSpacing: -0.1,
                                                          color: const Color(
                                                              0xFF000B23),
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      margin: EdgeInsets
                                                          .fromLTRB(
                                                          0, 0, 0, fiveSize),
                                                      child: Container(
                                                        decoration:
                                                        BoxDecoration(
                                                          color: const Color(
                                                              0x1A8E61E9),
                                                          borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                              fiveSize * 6),
                                                        ),
                                                        padding:
                                                        EdgeInsets
                                                            .fromLTRB(
                                                            fiveSize * 2.72,
                                                            fiveSize * 1.2,
                                                            fiveSize * 2.4,
                                                            fiveSize * 1.2),
                                                        child: Text(
                                                          dailyEndTimeList[
                                                          index],
                                                          style: GoogleFonts
                                                              .getFont(
                                                            'Work Sans',
                                                            fontWeight:
                                                            FontWeight
                                                                .w500,
                                                            fontSize: fiveSize * 2.4,
                                                            letterSpacing:
                                                            -0.1,
                                                            color: Colors
                                                                .blueAccent,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: fiveSize * 3,),
                                                Row(
                                                  children: [
                                                    Container(
                                                      margin: EdgeInsets
                                                          .fromLTRB(
                                                          0, 0, fiveSize * 1.66, 0),
                                                      width: fiveSize * 4.8,
                                                      height: fiveSize * 4.8,
                                                      child: SizedBox(
                                                        width: fiveSize * 3.4,
                                                        height: fiveSize * 3.7,
                                                        child: SvgPicture.asset(
                                                          'assets/vectors/shape_6_x2.svg',
                                                        ),
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: Container(
                                                        margin: EdgeInsets
                                                            .fromLTRB(
                                                            0, fiveSize * 0.5, 0, fiveSize * 0.4),
                                                        child: Text(
                                                          dailyDateList[index],
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .visible,
                                                          style: GoogleFonts
                                                              .getFont(
                                                            'Work Sans',
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontSize: fiveSize * 2.4,
                                                            letterSpacing: -0.1,
                                                            color: const Color(
                                                                0xFF7B7B7B),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                )
              else
                Center(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 0, fiveSize * 1.6),
                    child: Text(
                      'No Task is pending for today!',
                      style: GoogleFonts.getFont(
                        'Work Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: fiveSize * 3.6,
                        letterSpacing: -0.1,
                        color: const Color(0xFF000B23),
                      ),
                    ),
                  ),
                ),
            ],
            Container(
              margin: EdgeInsets.fromLTRB(fiveSize * 0.3, fiveSize * 4, fiveSize * 0.8, fiveSize * 6.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 0, 0, fiveSize * 1.5),
                        child: Text(
                          'Upcoming Tasks',
                          style: GoogleFonts.getFont(
                            'Work Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: fiveSize * 3.6,
                            letterSpacing: -0.1,
                            color: const Color(0xFF000B23),
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(fiveSize * 0.04, 0, fiveSize * 0.04, 0),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            '$upcomingPendingTask Tasks Pending',
                            style: GoogleFonts.getFont(
                              'Work Sans',
                              fontWeight: FontWeight.w400,
                              fontSize: fiveSize * 2.4,
                              letterSpacing: -0.1,
                              color: const Color(0xFF7B7B7B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isLoading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: fiveSize * 6),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              if (upcomingTaskList.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                      upcomingTaskList.length, // Number of items in the list
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 0, fiveSize * 4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(fiveSize * 4),
                        ),
                        child: Container(
                          padding: EdgeInsets.fromLTRB(fiveSize * 4.6, fiveSize * 4.6, fiveSize * 4.6, fiveSize * 4.6),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.fromLTRB(
                                          fiveSize * 0.12, 0, fiveSize * 1.84, fiveSize * 3.8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding:
                                                      EdgeInsets.fromLTRB(
                                                          0, 0, fiveSize * 2, 0),
                                                  margin:
                                                      EdgeInsets.fromLTRB(
                                                          0, 0, 0, fiveSize * 2),
                                                  child: Text(
                                                    upcomingTaskList[index],
                                                    maxLines: null,
                                                    overflow:
                                                        TextOverflow.visible,
                                                    style: GoogleFonts.getFont(
                                                      'Work Sans',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: fiveSize * 3.6,
                                                      decoration:
                                                          upcomingStatusList[
                                                                      index] ==
                                                                  'completed'
                                                              ? TextDecoration
                                                                  .lineThrough
                                                              : TextDecoration
                                                                  .none,
                                                      letterSpacing: -0.1,
                                                      height: 1.3,
                                                      color: const Color(
                                                          0xFF000B23),
                                                      decorationColor:
                                                          const Color(
                                                              0xFF000B23),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  margin:
                                                      const EdgeInsets.fromLTRB(
                                                          0, 0, 0, 0),
                                                  child: Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: Text(
                                                      upcomingStatusList[index],
                                                      style:
                                                          GoogleFonts.getFont(
                                                        'Work Sans',
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontSize: fiveSize * 2.4,
                                                        letterSpacing: -0.1,
                                                        color: const Color(
                                                            0xFF7B7B7B),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.fromLTRB(
                                                0, fiveSize * 0.6, 0, fiveSize * 0.64),
                                            child: Container(
                                              width: fiveSize * 7.36,
                                              height: fiveSize * 7.36,
                                              decoration: BoxDecoration(
                                                color: upcomingStatusList[
                                                            index] ==
                                                        'completed'
                                                    ? const Color(0xFF577CFF)
                                                    : Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(fiveSize * 3.68),
                                              ),
                                              child: Center(
                                                child: SizedBox(
                                                  width: fiveSize * 4.4,
                                                  height: fiveSize * 4.4,
                                                  child: upcomingStatusList[
                                                              index] ==
                                                          'completed'
                                                      ? SvgPicture.asset(
                                                          'assets/vectors/shape_2_x2.svg')
                                                      : const Icon(
                                                          Icons.hourglass_empty,
                                                          color: Colors.white,
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.fromLTRB(
                                          0, 0, 0, fiveSize * 3),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFDFDFDF),
                                        ),
                                        child: SizedBox(
                                          width: fiveSize * 62.8,
                                          height: 0,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: (){
                                            if(upcomingStatusList[index] == "pending"){
                                              _changeStatusUpcoming(upcomingCalendarIdList[index], "completed");
                                            }else{
                                              _changeStatusUpcoming(upcomingCalendarIdList[index], "pending");
                                            }

                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            height: fiveSize * 3.5,
                                            width: fiveSize * 8,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(fiveSize * 5),
                                              color: upcomingStatusList[index] == "completed" ? Colors.green : Colors.red,
                                            ),
                                            child: Stack(
                                              children: <Widget>[
                                                AnimatedPositioned(
                                                  duration: const Duration(milliseconds: 200),
                                                  curve: Curves.easeIn,
                                                  left: upcomingStatusList[index] == "completed" ? (fiveSize * 8 - fiveSize * 3.5) : 0.0,
                                                  child: Container(
                                                    height: fiveSize * 3.5,
                                                    width: fiveSize * 3.5,
                                                    decoration: const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: fiveSize * 2,),
                                    Container(
                                      height: 1.0, // Line thickness
                                      color: Colors.black, // Line color
                                      width: fiveSize * 70,
                                      margin: EdgeInsets.symmetric(
                                          vertical: fiveSize *
                                              2), // Space above and below the line
                                    ),
                                    SizedBox(height: fiveSize * 2,),
                                    Container(
                                      margin: EdgeInsets.fromLTRB(
                                          fiveSize * 0.7, 0, fiveSize * 0.7, 0),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: SizedBox(
                                          width: fiveSize * 53.46,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                margin:
                                                    EdgeInsets.fromLTRB(
                                                        0, fiveSize * 0.9, 0, fiveSize * 1.16),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: EdgeInsets
                                                          .fromLTRB(
                                                          0, 0, fiveSize * 2, 0),
                                                      width: fiveSize * 5,
                                                      height: fiveSize * 5,
                                                      child: SizedBox(
                                                        width: fiveSize * 3.4,
                                                        height: fiveSize * 3.7,
                                                        child: SvgPicture.asset(
                                                          'assets/vectors/shape_8_x2.svg',
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      margin: EdgeInsets
                                                          .fromLTRB(
                                                          0, fiveSize * 0.5, 0, fiveSize * 0.4),
                                                      child: Text(
                                                        upcomingDateList[index],
                                                        style:
                                                            GoogleFonts.getFont(
                                                          'Work Sans',
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: fiveSize * 2.4,
                                                          letterSpacing: -0.1,
                                                          color: const Color(
                                                              0xFF7B7B7B),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              else
                Center(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    padding: EdgeInsets.fromLTRB(0, fiveSize * 16, 0, fiveSize * 18),
                    child: Text(
                      'No Upcoming Tasks to show!',
                      style: GoogleFonts.getFont(
                        'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: fiveSize * 3,
                        letterSpacing: -0.1,
                        color: const Color(0xFF000B23),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

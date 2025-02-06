import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TaskHistory extends StatefulWidget {
  const TaskHistory({super.key});

  @override
  State<TaskHistory> createState() => _TaskHistoryState();
}

class _TaskHistoryState extends State<TaskHistory> {
  StreamSubscription? eventSubscription;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();


  List<String> upcomingStartTimeList = [];
  List<String> upcomingEndTimeList = [];
  List<String> upcomingTaskList = [];
  List<String> upcomingDateList = [];
  List<String> upcomingStatusList = [];

  bool isLoading = true;

  int upcomingPendingTask = 0;

  String _name = 'Loading...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startListeningForPreviousEventsFromFirebase();
    _fetchName();
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


  void _startListeningForPreviousEventsFromFirebase() {
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
          Map<dynamic, dynamic> events =
          dataSnapshot.value as Map<dynamic, dynamic>;

          setState(() {
            upcomingStartTimeList.clear();
            upcomingEndTimeList.clear();
            upcomingTaskList.clear();
            upcomingDateList.clear();
            upcomingStatusList.clear();

            events.forEach((key, value) {
              if (value['startDate'].compareTo(todayDate) < 0 && value['endDate'].compareTo(todayDate) < 0) {
                String formattedStartTime = DateFormat('HH:mm')
                    .format(DateTime.parse("1970-01-01 ${value['startTime']}"));
                String formattedEndTime = DateFormat('HH:mm')
                    .format(DateTime.parse("1970-01-01 ${value['endTime']}"));

                upcomingStartTimeList.add(formattedStartTime);
                upcomingEndTimeList.add(formattedEndTime);
                upcomingTaskList.add(value['details']);
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
        }else{
          setState(() {
            isLoading = false;
          });
        }
      });
    }else{
      setState(() {
        isLoading = false;
      });
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Previous Tasks',
          style: GoogleFonts.getFont(
            'Bricolage Grotesque',
            fontWeight: FontWeight.bold,
            fontSize: fiveSize * 4,
            height: 1.2,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
          ),
          padding: const EdgeInsets.fromLTRB(20, 34, 20, 35),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(0, 0, 11, 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22.5),
                            color: const Color(0xFFF5F5F5),
                            image: const DecorationImage(
                              fit: BoxFit.cover,
                              image: AssetImage(
                                'assets/images/ellipse_2.jpeg',
                              ),
                            ),
                          ),
                          child: const SizedBox(
                            width: 45,
                            height: 45,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.fromLTRB(0.9, 2, 19, 0),
                              child: Text(
                                _getGreeting(),
                                style: GoogleFonts.getFont(
                                  'Work Sans',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  letterSpacing: -0.1,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Text(
                              _hasError ? "Error" : _name,
                              style: GoogleFonts.getFont(
                                'Work Sans',
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                letterSpacing: -0.1,
                                color: const Color(0xFF000B23),
                              ),
                            ),
                          ],
                        ),

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
                        'My Previous Tasks',
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
                          '$upcomingPendingTask Tasks are Pending Previously',
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
                if (upcomingTaskList.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                    upcomingTaskList.length, // Number of items in the list
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(23, 23, 22, 22.2),
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
                                        margin: const EdgeInsets.fromLTRB(
                                            0.6, 0, 9.2, 19),
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
                                                    const EdgeInsets.fromLTRB(
                                                        0, 0, 10, 0),
                                                    margin:
                                                    const EdgeInsets.fromLTRB(
                                                        0, 0, 0, 10),
                                                    child: Text(
                                                      upcomingTaskList[index],
                                                      maxLines: null,
                                                      overflow:
                                                      TextOverflow.visible,
                                                      style: GoogleFonts.getFont(
                                                        'Work Sans',
                                                        fontWeight:
                                                        FontWeight.w600,
                                                        fontSize: 18,
                                                        decoration:
                                                        upcomingStatusList[
                                                        index] ==
                                                            'Done'
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
                                                          fontSize: 12,
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
                                              margin: const EdgeInsets.fromLTRB(
                                                  0, 3, 0, 3.2),
                                              child: Container(
                                                width: 36.8,
                                                height: 36.8,
                                                decoration: BoxDecoration(
                                                  color: upcomingStatusList[
                                                  index] ==
                                                      'completed'
                                                      ? Colors.blueAccent
                                                      : Colors.red,
                                                  borderRadius:
                                                  BorderRadius.circular(18.4),
                                                ),
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 22,
                                                    height: 22,
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
                                        margin: const EdgeInsets.fromLTRB(
                                            0, 0, 0, 15),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFDFDFDF),
                                          ),
                                          child: const SizedBox(
                                            width: 314,
                                            height: 0,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 1.0, // Line thickness
                                        color: Colors.black, // Line color
                                        width: fiveSize * 70,
                                        margin: EdgeInsets.symmetric(
                                            vertical: fiveSize *
                                                2), // Space above and below the line
                                      ),
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(
                                            3.5, 0, 3.5, 0),
                                        child: Align(
                                          alignment: Alignment.topLeft,
                                          child: SizedBox(
                                            width: 267.3,
                                            child: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin:
                                                  const EdgeInsets.fromLTRB(
                                                      0, 4.5, 0, 5.8),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        margin: const EdgeInsets
                                                            .fromLTRB(
                                                            0, 0, 9.8, 0),
                                                        width: 24,
                                                        height: 24,
                                                        child: SizedBox(
                                                          width: 17,
                                                          height: 18.5,
                                                          child: SvgPicture.asset(
                                                            'assets/vectors/shape_8_x2.svg',
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        margin: const EdgeInsets
                                                            .fromLTRB(
                                                            0, 2.5, 0, 2),
                                                        child: Text(
                                                          upcomingDateList[index],
                                                          style:
                                                          GoogleFonts.getFont(
                                                            'Work Sans',
                                                            fontWeight:
                                                            FontWeight.w400,
                                                            fontSize: 12,
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
                      padding: const EdgeInsets.fromLTRB(0, 80, 0, 90),
                      child: Text(
                        'No Previous Tasks to show!',
                        style: GoogleFonts.getFont(
                          'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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
      ),
    );
  }

}

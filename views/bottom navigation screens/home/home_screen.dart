import 'dart:developer';
import 'dart:ui';

import 'package:ai_assistant/views/bottom%20navigation%20screens/home/existing_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> questions = [];
  List<String> answers = [];
  List<String> time = [];
  List<String> threadIdsNew = [];


  bool _isLoading = true;

  @override
  void initState() {
    fetchThreadIds();
    super.initState();
  }

  String dataText = 'No history to show';

  Future<void> fetchThreadIds() async {
    final databaseReference = FirebaseDatabase.instance.ref();
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;
        DatabaseEvent event = await _fetchUserThreads(databaseReference, uid);
        DataSnapshot snapshot = event.snapshot;

        if (snapshot.exists) {
          List<String> threadIds = _extractThreadIds(snapshot);
          fetchFirstMessages(threadIds, uid);
        } else {
          _setLoadingState("No History found!");
          log('No threads found for this user.');
        }
      } else {
        _setLoadingState("Error! Please login again to continue.");
      }
    } catch (e) {
      _setLoadingState("Error! Could not load history.");
      log('Error fetching thread IDs: $e');
    }
  }

  Future<DatabaseEvent> _fetchUserThreads(DatabaseReference dbRef, String uid) async {
    return await dbRef.child("threads").child(uid).once();
  }

  List<String> _extractThreadIds(DataSnapshot snapshot) {
    Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;
    return data?.keys.map((key) => key.toString()).toList() ?? [];
  }

  void _setLoadingState(String message) {
    setState(() {
      _isLoading = false;
      dataText = message;
    });
  }

  Future<void> fetchFirstMessages(List<String> threadIds, String uid) async {
    final databaseReference = FirebaseDatabase.instance.ref();
    _clearPreviousData();

    try {
      List<Map<String, dynamic>> messagesData = [];
      for (var threadId in threadIds) {
        DatabaseEvent event = await _fetchThreadMessages(databaseReference, uid, threadId);
        DataSnapshot snapshot = event.snapshot;

        if (snapshot.exists) {
          var messages = _extractMessages(snapshot);
          if (messages != null) {
            var firstMessages = _getFirstUserAndAssistantMessages(messages);
            var formattedData = _formatMessageData(firstMessages, threadId);
            messagesData.add(formattedData);
          }
        }
      }
      _updateMessageLists(messagesData);
    } catch (e) {
      log('Error fetching first messages: $e');
      _setLoadingState("");
    }
  }

  void _clearPreviousData() {
    setState(() {
      questions.clear();
      answers.clear();
      time.clear();
      threadIdsNew.clear();
    });
  }

  Future<DatabaseEvent> _fetchThreadMessages(DatabaseReference dbRef, String uid, String threadId) async {
    return await dbRef.child("threads").child(uid).child(threadId).once();
  }

  List<Map<dynamic, dynamic>>? _extractMessages(DataSnapshot snapshot) {
    Map<dynamic, dynamic>? messagesMap = snapshot.value as Map<dynamic, dynamic>?;
    return messagesMap?.values.map((value) {
      return value is Map<dynamic, dynamic> ? value : {};
    }).toList();
  }

  Map<String, dynamic> _getFirstUserAndAssistantMessages(List<Map<dynamic, dynamic>> messages) {
    messages.sort((a, b) => (a['createdAt'] ?? 0).compareTo(b['createdAt'] ?? 0));

    Map<dynamic, dynamic>? firstUserMessage;
    Map<dynamic, dynamic>? firstAssistantMessage;

    for (var message in messages) {
      if (firstUserMessage == null && message['savedBy'] == 'user' && message['createdAt'] != null) {
        firstUserMessage = message;
      }
      if (firstAssistantMessage == null && message['savedBy'] == 'AI-Assistant' && message['createdAt'] != null) {
        firstAssistantMessage = message;
      }
      if (firstUserMessage != null && firstAssistantMessage != null) break;
    }

    return {
      'userMessage': firstUserMessage,
      'assistantMessage': firstAssistantMessage,
    };
  }

  Map<String, dynamic> _formatMessageData(Map<String, dynamic> messages, String threadId) {
    var userMessage = messages['userMessage'];
    var assistantMessage = messages['assistantMessage'];

    if (userMessage != null && userMessage['createdAt'] != null) {
      int timestamp = userMessage['createdAt'];
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

      return {
        'question': userMessage['message'] ?? "User query does not send to Ai Assistant",
        'answer': assistantMessage?['message'] ?? "No response to show from Ai Assistant",
        'time': dateTime,
        'threadId': threadId
      };
    } else {
      return {
        'question': "User query does not send to Ai Assistant",
        'answer': "No response to show from Ai Assistant",
        'time': "No Date to show",
        'threadId': threadId
      };
    }
  }

  void _updateMessageLists(List<Map<String, dynamic>> messagesData) {
    messagesData.sort((a, b) {
      if (a['time'] is DateTime && b['time'] is DateTime) {
        return (b['time'] as DateTime).compareTo(a['time'] as DateTime);
      } else if (a['time'] == "No Date to show") {
        return 1;
      } else if (b['time'] == "No Date to show") {
        return -1;
      } else {
        return 0;
      }
    });

    setState(() {
      for (var message in messagesData) {
        questions.add(message['question']);
        answers.add(message['answer']);
        time.add(message['time'] is DateTime
            ? DateFormat('EEEE, MMMM d, y').format(message['time'])
            : message['time']);
        threadIdsNew.add(message['threadId']);
      }
      _isLoading = false;
    });
  }



  @override
  Widget build(BuildContext context) {

    // Get the screen width and height
    final screenWidth = MediaQuery.of(context).size.width;
    // Define responsive values
    final fiveSize = screenWidth * 0.01215278;

    int count = questions.length;
    const int itemsPerRow = 2;
    const double ratio = 0.65;
    const double horizontalPadding = 0;
    final double calcHeight =
        ((screenWidth / itemsPerRow) - (horizontalPadding)) *
            (count / itemsPerRow).ceil() *
            (1 / ratio);

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          color: const Color(0xFFFFFFFF),
          padding: EdgeInsets.fromLTRB(fiveSize, fiveSize * 10, fiveSize, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(
                    fiveSize * 4.5, 0, fiveSize * 5, fiveSize * 0),
                padding: EdgeInsets.fromLTRB(0, fiveSize * 7, 0, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(1.6, 0, 1.6, 4),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Start a new chat',
                          style: GoogleFonts.getFont(
                            'Bricolage Grotesque',
                            fontWeight: FontWeight.w600,
                            fontSize: fiveSize * 8,
                            height: 1.2,
                            letterSpacing: -1.6,
                            color: const Color(0xFF000000),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 0, fiveSize * 0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              margin:
                                  EdgeInsets.fromLTRB(0, 0, fiveSize * 2, 0),
                              child: Text(
                                'With',
                                style: GoogleFonts.getFont(
                                  'Bricolage Grotesque',
                                  fontWeight: FontWeight.w600,
                                  fontSize: fiveSize * 8,
                                  height: 1.2,
                                  letterSpacing: -1.6,
                                  color: const Color(0xFF000000),
                                ),
                              ),
                            ),
                            Container(
                              margin:
                                  EdgeInsets.fromLTRB(0, fiveSize * 0.6, 0, 0),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(36),
                                  image: const DecorationImage(
                                    fit: BoxFit.cover,
                                    image: AssetImage(
                                      'assets/images/logo.png',
                                    ),
                                  ),
                                ),
                                child: SizedBox(
                                  width: fiveSize * 8.4,
                                  height: fiveSize * 8.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(
                          0, 0, fiveSize * 5.4, fiveSize * 2),
                      child: Text(
                        'Chatbot AI',
                        style: GoogleFonts.getFont(
                          'Bricolage Grotesque',
                          fontWeight: FontWeight.w600,
                          fontSize: fiveSize * 8,
                          height: 1.2,
                          letterSpacing: -1.6,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                    Container(
                      width: fiveSize * 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDF9ECD),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(36),
                          topRight: Radius.circular(36),
                          bottomRight: Radius.circular(8),
                          bottomLeft: Radius.circular(36),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          // In the first screen
                          Get.to(() => const ChatScreen())?.then((result) {
                            if (result == true) {
                              // fetchThreadIds();
                            }
                          });

                        },
                        child: Container(
                          padding: EdgeInsets.fromLTRB(
                              0, fiveSize * 3.2, 0, fiveSize * 3.2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.fromLTRB(
                                    0, 0, fiveSize * 1.6, 0),
                                child: SizedBox(
                                  width: fiveSize * 4.8,
                                  height: fiveSize * 4.8,
                                  child: SvgPicture.asset(
                                    'assets/vectors/plus_41_x2.svg',
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.fromLTRB(
                                    0, fiveSize * 0.4, 0, fiveSize * 0.4),
                                child: Text(
                                  'New Topic',
                                  style: GoogleFonts.getFont(
                                    'Roboto Condensed',
                                    fontWeight: FontWeight.w600,
                                    fontSize: fiveSize * 3,
                                    height: 1.3,
                                    color: const Color(0xFFFFFFFF),
                                  ),
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
              Container(
                height: 1.0, // Line thickness
                color: Colors.black, // Line color
                width: fiveSize * 70,
                margin: EdgeInsets.symmetric(
                    vertical: fiveSize * 6), // Space above and below the line
              ),
              Container(
                margin: EdgeInsets.fromLTRB(fiveSize * 5, 0, fiveSize * 5, fiveSize * 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: fiveSize * 8,
                          height: fiveSize * 8,
                          child: Icon(
                            Icons.history,
                            semanticLabel: "History",
                            size: fiveSize * 7,
                          ),
                        ),
                        SizedBox(
                          height: fiveSize * 8,
                          child: Text(
                            'History',
                            style: GoogleFonts.getFont(
                              'Roboto Condensed',
                              fontWeight: FontWeight.w500,
                              fontSize: fiveSize * 5,
                              height: 1.3,
                              color: const Color(0xFF0A0A0A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: (){
                        setState(() {
                          dataText = "Reloading History, Please wait......";
                        });
                        fetchThreadIds();
                      },
                      icon: Icon(
                          Icons.refresh,
                        size: fiveSize * 7,
                      ),
                    ),
                  ],
                ),
              ),
              if(_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (questions.isNotEmpty)
                SizedBox(
                  width: screenWidth,
                  height: calcHeight,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent:
                          (screenWidth - 11) / 2, // Max width of the grid items
                      crossAxisSpacing: 1.0, // Horizontal spacing between items
                      mainAxisSpacing: 8.0, // Vertical spacing between items
                      childAspectRatio: 0.64,
                    ),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {

                          Get.to(() => ExistingChatScreen(threadIdsNew[index]))?.then((result) {
                            if (result == true) {
                              // fetchThreadIds();
                            }
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.fromLTRB(
                              fiveSize * 0.5, 0, fiveSize * 0.5, 0),
                          padding: EdgeInsets.fromLTRB(fiveSize * 3,
                              fiveSize * 7, fiveSize * 3, fiveSize * 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0x527A808C)),
                            borderRadius: BorderRadius.circular(36),
                          ),
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 15,
                                sigmaY: 15,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    questions[index],
                                    style: GoogleFonts.getFont(
                                      'Montserrat',
                                      fontWeight: FontWeight.w600,
                                      fontSize: fiveSize * 3,
                                      height: 1.3,
                                      color: const Color(0xFFDF9ECD),
                                    ),
                                    maxLines: 3, // Limit to 3 lines
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: fiveSize * 4),
                                  Text(
                                    answers[index],
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.getFont(
                                      'Lato',
                                      fontWeight: FontWeight.w400,
                                      fontSize: fiveSize * 2.7,
                                      height: 1.5,
                                      color: const Color(0xFF7A808C),
                                    ),
                                    maxLines: 4, // Limit to 5 lines
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(
                                      height: fiveSize *
                                          4), // Space between question and answer
                                  Text(
                                    time[index],
                                    style: GoogleFonts.getFont(
                                      'Poppins',
                                      fontWeight: FontWeight.w400,
                                      fontSize: fiveSize * 2.3,
                                      height: 1.3,
                                      color: const Color(0xFF000000),
                                    ),
                                    maxLines: 2, // Limit to 2 lines
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Center(child: Text(dataText))
            ],
          ),
        ),
      ),
    );
  }
}

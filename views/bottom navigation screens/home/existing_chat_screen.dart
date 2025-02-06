import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:ai_assistant/consts.dart';
import 'package:ai_assistant/controllers/maps/maps_controller.dart';
import 'package:ai_assistant/controllers/weather/weather_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../../../controllers/date/date.dart';
import '../../../controllers/google/calendar_client.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class ExistingChatScreen extends StatefulWidget {
  const ExistingChatScreen(this.threadId, {super.key});

  final String threadId;

  @override
  State<ExistingChatScreen> createState() => _ExistingChatScreenState();
}

class _ExistingChatScreenState extends State<ExistingChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isFieldEnabled = false;

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;

  final List<types.Message> _messages = [];

  bool _isAssistantTyping = false;

  final _user = const types.User(
    id: '82091008-a484-4a89-ae75-a22bf8d6f3ac',
    firstName: 'user',
    imageUrl: 'assets/images/nrd_zmm_anliy_1_d_4_unsplash_1.png',
  );

  final _receiver = const types.User(
    id: 'receiver-user-id', // ID of the receiver user
    firstName: 'AI-Assistant',
    imageUrl: 'assets/images/logo.png',
  );

  // Customizable options
  final double _inputPadding = 15.0;

  String? _threadId;


  final databaseReference = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    super.initState();
    _threadId = widget.threadId;
    if(_threadId != null){
      setState(() {
        _isFieldEnabled = !_isFieldEnabled; // Toggle enable/disable state
      });
    }
    _initializeSpeechToText();
    fetchAllMessages(widget.threadId);
  }


  Future<void> fetchAllMessages(String threadId) async {
    try {
      var user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid;

        final databaseReference = FirebaseDatabase.instance.ref();

        // Fetch all messages under the specified uid and threadId
        DatabaseEvent event = await databaseReference.child("threads").child(uid).child(threadId).once();
        DataSnapshot snapshot = event.snapshot;

        if (snapshot.exists) {
          // Convert the snapshot value to a Map of unique IDs with their respective message data
          Map<dynamic, dynamic>? messagesMap = snapshot.value as Map<dynamic, dynamic>?;
          if (messagesMap != null) {
            List<Map<String, dynamic>> messages = [];

            // Iterate over each entry in the map
            messagesMap.forEach((key, value) {
              if (value is Map<dynamic, dynamic>) {
                // Convert each entry to Map<String, dynamic>
                Map<String, dynamic> messageData = {};
                value.forEach((k, v) {
                  messageData[k.toString()] = v;
                });
                messageData['uniqueId'] = key.toString(); // Store the unique ID as a string
                messages.add(messageData);
              }
            });

            // Sort messages by createdAt timestamp
            messages.sort((a, b) {
              int createdAtA = a['createdAt'] ?? 0;
              int createdAtB = b['createdAt'] ?? 0;
              return createdAtA.compareTo(createdAtB);
            });

            // Print all messages with their details
            for (var message in messages) {

              if(message['savedBy'] == "AI-Assistant"){

                final replyMessage = types.TextMessage(
                  author: _receiver,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  id: const Uuid().v4(),
                  text: message['message'],
                );
                _addMessage(replyMessage);

              }else if(message['savedBy'] == "user"){

                final replyMessage = types.TextMessage(
                  author: _user,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  id: const Uuid().v4(),
                  text: message['message'],
                );
                _addMessage(replyMessage);

              }

            }
          } else {
            log('No messages found.');
          }
        } else {
          log('No messages found in this thread.');
        }
      }
    } catch (e) {
      log('Error fetching messages: $e');
    }
  }

  void saveMessagesInFirebase(String threadId, String message, String savedBy) async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      var uuid = const Uuid();
      String uniqueId = uuid.v4();

      if (user != null) {
        String uid = user.uid;

        await databaseReference
            .child("threads")
            .child(uid)
            .child(threadId)
            .child(uniqueId)
            .set({
          'message': message,
          'savedBy': savedBy,
          'createdAt': ServerValue.timestamp,
          'userId': uid,
        });
      } else {
        log("Error: No user is signed in.");
      }

      log('Message saved in database successfully');
    } catch (e) {
      log('Error saving message query in database: $e');
    }
  }

  void _initializeSpeechToText() async {
    log("Initializing Speech to Text...");
    try {
      bool available = await _speechToText.initialize(
        onError: (val) {
          log("Error initializing Speech to Text: $val");
          setState(() {
            _isListening = false;
          });
        },
        debugLogging: true, // Enable debug logging for detailed output
      );

      if (available) {
        log("Speech recognition is available.");
      } else {
        log("Speech recognition not available on this device.");
        _showSpeechNotAvailableDialog(); // Show a dialog if unavailable
      }
    } catch (e) {
      log("Exception during Speech to Text initialization: $e");
    }
  }

  void _showSpeechNotAvailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Speech Recognition"),
        content:
        const Text("Speech recognition is not supported on this device."),
        actions: <Widget>[
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _startListening() async {
    if (_isListening) {
      log("Stopping speech recognition...");
      _stopListening();
    } else {
      log("Initializing speech recognition for listening...");
      bool available = await _speechToText.initialize(
        onError: (val) {
          log("Error during initialization: $val");
          setState(() {
            _isListening = false;
          });
        },
      );

      if (available) {
        log("Speech recognition initialized successfully. Starting to listen...");

        // Create SpeechListenOptions with desired settings
        final listenOptions = stt.SpeechListenOptions(
          partialResults: true, // Enable real-time updates
        );

        await _speechToText.listen(
          onResult: (result) {
            log("Result received: ${result.recognizedWords}");
            if (result.finalResult) {
              log("Final result received. Stopping speech recognition automatically.");
              _stopListening(); // Stop listening when final result is received
            }
            setState(() {
              _messageController.text = result.recognizedWords;
            });
          },
          listenFor: const Duration(seconds: 30), // Adjust duration as needed
          pauseFor: const Duration(seconds: 20),
          listenOptions: listenOptions, // Pass the SpeechListenOptions
          localeId: 'en_US', // Adjust locale as needed
          onSoundLevelChange: (level) {
            log("Sound level: $level");
          },
        );

        setState(() {
          _isListening = true;
        });
        log("Speech recognition is listening for input.");
      } else {
        log("Speech recognition not available.");
      }
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false; // Update the state when listening stops
    });
    log("Speech recognition stopped manually.");
  }

  void linkMessageAndThreadWithOutput(String msg) async {
    final url = Uri.parse("https://api.openai.com/v1/threads/$_threadId/messages");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $OPEN_AI_API',
        'OpenAI-Beta': 'assistants=v2',
      },
      body: json.encode({"role": "user", "content": msg}),
    );


    if (response.statusCode == 200) {
      runAssistant(_threadId!);
    } else {
      log('Request failed of linking thread and message with status with output: ${response.statusCode}.');
      log('Thread Code: ${response.body}');
      setState(() {
        _isAssistantTyping = false;
      });

      final replyMessage = types.TextMessage(
        author: _receiver,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: "Please try again later or start a new chat.",
      );
      saveMessagesInFirebase(_threadId!, "Please try again later or start a new chat.", "AI-Assistant");
      _addMessage(replyMessage);


    }
  }

  void runAssistant(String thread) async {
    final url = Uri.parse("https://api.openai.com/v1/threads/$thread/runs");

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $OPEN_AI_API',
        'Content-Type': 'application/json',
        'OpenAI-Beta': 'assistants=v2',
      },
      body: json.encode({"assistant_id": OPEN_AI_ASSISTANT_API}),
    );

    if (response.statusCode == 200) {
      final linkResponse = json.decode(response.body);
      final Map<String, dynamic> responseData = linkResponse;
      String runId = responseData["id"];

      if (runId.isNotEmpty) {
        checkAssistantStatus(thread, runId);
      } else {
        log("Run Id Error: Run Id is null");
      }
    } else {
      log('Request failed with status: ${response.statusCode}');
    }
  }

  void checkAssistantStatus(String thread, String run) async {
    setState(() {
      _isAssistantTyping = true;
    });

    final url =
    Uri.parse("https://api.openai.com/v1/threads/$thread/runs/$run");

    while (true) {
      await Future.delayed(const Duration(seconds: 5)); // Poll every 5 seconds

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $OPEN_AI_API',
          'OpenAI-Beta': 'assistants=v2',
        },
      );

      if (response.statusCode == 200) {
        final linkResponse = json.decode(response.body);
        final Map<String, dynamic> responseData = linkResponse;
        String runStatus = responseData["status"];

        log("Current Status: $runStatus");

        if (runStatus == "completed") {
          setState(() {
            _isAssistantTyping = false;
          });
          assistantResponse(thread);
          break;
        } else if (runStatus == "failed") {
          log("Run failed");
          final replyMessage = types.TextMessage(
            author: _receiver,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            id: const Uuid().v4(),
            text: "Network error. Please try again later",
          );
          saveMessagesInFirebase(_threadId!,
              "Network error. Please try again later", "AI-Assistant");
          _addMessage(replyMessage);

          setState(() {
            _isAssistantTyping = false;
          });
          break;
        } else if (runStatus == "requires_action") {
          functionCalled(response.body);
          break;
        }
      } else {
        log('Request failed with status: ${response.statusCode}');
        log('Response body: ${response.body}');
        break;
      }
    }
  }

  void assistantResponse(String thread) async {
    final url = Uri.parse("https://api.openai.com/v1/threads/$thread/messages");

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $OPEN_AI_API',
        'OpenAI-Beta': 'assistants=v2',
      },
    );

    String assistantMessage = '';

    if (response.statusCode == 200) {
      final linkResponse = json.decode(response.body);
      final Map<String, dynamic> responseData = linkResponse;

      final data = responseData['data'];

      if (data is List && data.isNotEmpty) {
        final messages = data[0];

        final role = messages['role'];
        final contentList = messages['content']; // content is a list of items

        if (contentList is List && contentList.isNotEmpty) {
          final contentItem = contentList[0];
          if (contentItem is Map) {
            final text = contentItem['text'];
            if (text is Map) {
              final content = text['value'];

              if (role == 'user') {
              } else if (role == 'assistant') {
                assistantMessage = content;
              }
            } else {
              log('Text is not a map');
              assistantMessage = "Please try again!";
              setState(() {
                _isAssistantTyping = false;
              });
            }
          } else {
            log('Content item is not a map');
            assistantMessage = "Please try again!";
            setState(() {
              _isAssistantTyping = false;
            });
          }
        } else {
          log('Content is not a list or is empty');
          assistantMessage = "Please try again!";
          setState(() {
            _isAssistantTyping = false;
          });
        }
      } else {
        log('Data is not a list or is empty');
        assistantMessage = "Please try again!";
        setState(() {
          _isAssistantTyping = false;
        });
      }
    } else {
      // Request failed
      log('Request failed with status: ${response.statusCode}');
      log('Response body: ${response.body}');
      assistantMessage = "Please try again!";
      setState(() {
        _isAssistantTyping = false;
      });
    }

    final replyMessage = types.TextMessage(
      author: _receiver,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: assistantMessage,
    );
    saveMessagesInFirebase(_threadId!, assistantMessage, "AI-Assistant");
    _addMessage(replyMessage);

    setState(() {
      _isAssistantTyping = false;
    });
  }

  // Main function that processes the incoming JSON body
  void functionCalled(String jsonBody) async {
    final Map<String, dynamic> linkResponse = json.decode(jsonBody);
    final response = jsonDecode(jsonBody);

    response.remove("instructions");
    response.remove("tools");

    final runId = linkResponse['id'];
    final status = linkResponse['status'];
    final requiredAction = linkResponse['required_action'];
    final Map<String, Map<String, dynamic>> toolCallId =
    getToolCallIdWithFunctionNameAndArguments(linkResponse);

    if (status == "requires_action" && requiredAction != null) {
      final type = requiredAction['type'];
      if (type == "submit_tool_outputs") {
        toolCallId.forEach((toolId, toolInfo) {
          // Extract function name and arguments for each tool
          String functionName = toolInfo['function_name'];
          Map<String, dynamic> arguments = toolInfo['arguments'];

          // Print the tool ID, function name, and arguments
          log('Tool ID: $toolId');
          log('Function Name: $functionName');

          // Loop through all arguments
          arguments.forEach((key, value) {
            log('Argument: $key = $value');
          });

          log('-------------------------'); // For readability between tools
        });

        if (toolCallId.isNotEmpty) {
          await handleFunctionCall(runId, toolCallId);
        } else {
          log("Error: Tool call id, function name and arguments are null");
        }
      } else {
        log("Error: Incorrect required action type");
      }
    } else {
      log("Error: Status is not 'requires_action' or requiredAction is null");
    }
  }

  Map<String, Map<String, dynamic>> getToolCallIdWithFunctionNameAndArguments(Map<String, dynamic> linkResponse) {
    try {
      final toolCalls = linkResponse['required_action']?['submit_tool_outputs']
      ?['tool_calls'];

      if (toolCalls != null) {
        // Create a map to store id, function name, and arguments
        Map<String, Map<String, dynamic>> toolCallMap = {};

        for (var item in toolCalls) {
          final toolId = item['id'] as String?;
          final functionName = item['function']?['name'] as String?;
          final dynamic arguments = item['function']?['arguments'];

          // Check if arguments are in the right format
          if (toolId != null && functionName != null) {
            if (arguments is Map<String, dynamic>) {
              // If arguments are a Map, add them to the map
              toolCallMap[toolId] = {
                'function_name': functionName,
                'arguments': arguments,
              };
            } else {
              // Handle cases where arguments are not a Map
              toolCallMap[toolId] = {
                'function_name': functionName,
                'arguments': {
                  'value': arguments
                }, // Add as string or other type
              };
            }
          }
        }

        log("---------------------------------------");

        return toolCallMap;
      } else {
        return {}; // Return an empty map if toolCalls is null
      }
    } catch (e) {
      log('Error extracting tool call ID, function name, and arguments: $e');
      return {}; // Return an empty map in case of an error
    }
  }

  Future<void> handleFunctionCall(String runId, Map<String, Map<String, dynamic>> toolCallData) async {
    List<Map<String, dynamic>> toolOutputs = [];

    for (var entry in toolCallData.entries) {
      final toolId = entry.key.toString();
      final toolInfo = entry.value;
      final functionName = toolInfo['function_name'];
      final argument = toolInfo['arguments']['value'];
      Map<String, dynamic> arguments =
      jsonDecode(argument) as Map<String, dynamic>;

      try {
        Map<String, dynamic> processedData;

        log("Function named Data: $functionName");

        switch (functionName) {
          case "get_weather_by_city":
            final location = arguments['location']!;
            processedData = await processWeatherData(location);
            break;

          case "get_weather_of_user_location":
            processedData = await processWeatherDataWithUserLocation();
            break;

          case "get_traffic_distance_and_time_two_points":
            final source = arguments['origin']!;
            final destination = arguments['destination']!;
            log("Source: $source");
            log("Destination: $destination");
            processedData = await processGoogleMapsDataPointsBetweenTwoPoints(
                source, destination);
            break;

          case "get_traffic_distance_and_time_from_user_location":
            final destination = arguments['destination']!;
            log("Destination: $destination");
            processedData =
            await processGoogleMapsDataPointsBetweenUserLocationAndDestination(
                destination);
            break;

          case "get_location_of_user":
            final userLocation = await GoogleMapsController.getUserLocation();
            log("user location: $userLocation");
            processedData = {"user location": userLocation};
            break;

          case "get_current_users_date_day_and_time":
            final dateData = DateController.getCurrentDateTime();
            log("Date: ${dateData["Date"]}");
            log("Day: ${dateData["Day"]}");
            log("Time: ${dateData["Time"]}");

            processedData = {
              "current time": dateData["Time"],
              "current day": dateData["Day"],
              "current date": dateData["Date"],
            };
            break;

          case "create_calendar_event_with_physical_location":
            String startDateTimeString = arguments['startDateAndTime']!
                .split("+")[0]; // Remove the time zone part
            String endDateTimeString = arguments['endDateAndTime']!
                .split("+")[0]; // Remove the time zone part

            final startDate = DateTime.parse(startDateTimeString);
            final endDate = DateTime.parse(endDateTimeString);

            final summary = arguments['summary']!;
            final destination = arguments['destination']!;

            log("Event Start Date: $startDate");
            log("Event End Date: $endDate");
            log("Event Summary: $summary");
            log("Destination: $destination");

            Map<String, String> message =
            await processCalendarDataWithPhysicalLocation(
                summary, startDate, endDate, destination);

            processedData = {
              "calendar status": message['calendarStatus'] ?? "N/A",
              "database status": message['databaseStatus'] ?? "N/A",
              "location status": message['locationStatus'] ?? "N/A",
              "details status": message['detailsStatus'] ?? "N/A",
            };

            log("calendar status: ${message['calendarStatus']}");
            log("database status: ${message['databaseStatus']}");
            log("location status: ${message['locationStatus']}");
            log("details status: ${message['detailsStatus']}");
            break;

          case "get_location_details_from_query":
            final locationQuery = arguments['locationQuery']!;
            final message =
            await GoogleMapsController.getExactLocation(locationQuery);
            log("responseFromGoogleMapsApi: ${message}");
            processedData = message;
            break;

          case "create_calendar_event_with_online_or_virtual_location_or_meeting":
            String startDateTimeString = arguments['startDateAndTime']!
                .split("+")[0]; // Remove the time zone part
            String endDateTimeString = arguments['endDateAndTime']!
                .split("+")[0]; // Remove the time zone part

            final startDate = DateTime.parse(startDateTimeString);
            final endDate = DateTime.parse(endDateTimeString);

            final summary = arguments['summary']!;
            final destination = arguments['destination']!;

            log("Event Start Date: $startDate");
            log("Event End Date: $endDate");
            log("Event Summary: $summary");
            log("Destination: $destination");

            Map<String, String> message =
            await processCalendarDataWithVirtualLocation(
                summary, startDate, endDate, destination);

            processedData = {
              "calendar status":
              message['calendarStatus'] ?? "Error while adding to calendar",
              "database status":
              message['databaseStatus'] ?? "Error while saving to database",
            };
            log("calendar status: ${message['calendarStatus']}");
            log("database status: ${message['databaseStatus']}");

            break;

          default:
            log("Error: Unknown function name");
            continue; // Skip unknown function names
        }

        toolOutputs.add({
          "tool_call_id": toolId,
          "output": jsonEncode(processedData),
        });

        log("------------------------------------------------");
      } catch (e) {
        log("Failed to handle function call: $e");
      }
    }

    await sendProcessedFunctionBackDataToOpenAI(runId, toolOutputs);
  }

  // Send processed data to OpenAI
  Future<void> sendProcessedFunctionBackDataToOpenAI(String runId, List<Map<String, dynamic>> toolIdsAndData) async {
    final url = Uri.parse(
        "https://api.openai.com/v1/threads/$_threadId/runs/$runId/submit_tool_outputs");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $OPEN_AI_API',
          'OpenAI-Beta': 'assistants=v2',
        },
        body: jsonEncode({
          "tool_outputs": toolIdsAndData,
        }),
      );

      if (response.statusCode == 200) {
        // Extract tool IDs from the toolIdsAndData
        List<String?> toolIds = toolIdsAndData
            .map((toolData) => toolData['tool_call_id'] as String?)
            .toList();

        checkProcessedDataToOpenAI(runId, toolIds);
      } else {
        log("Error in sendProcessedFunctionBackDataToOpenAI: ${response.statusCode}");
        log("Error in sendProcessedFunctionBackDataToOpenAI: ${response.body}");
      }
    } catch (e) {
      log("Failed to send processed data in sendProcessedFunctionBackDataToOpenAI: $e");
    }
  }

  Future<void> checkProcessedDataToOpenAI(String runId, List<String?> toolId) async {
    log("Thread Id: ${_threadId!}");
    log("   Run Id: $runId");
    log("  Tool Id: $toolId");

    final url = Uri.parse(
        "https://api.openai.com/v1/threads/$_threadId/runs/$runId/steps");

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $OPEN_AI_API',
          'OpenAI-Beta': 'assistants=v2',
        },
      );

      if (response.statusCode == 200) {
        try {
          // Parse the response body into a Dart map
          final Map<String, dynamic> responseJson = jsonDecode(response.body);

          // Extract the 'data' field
          final List<dynamic> data = responseJson['data'];

          List<String> stepIds = [];

          for (var item in data) {
            if (item is Map<String, dynamic> && item.containsKey('id')) {
              stepIds.add(item['id']); // Add the 'id' to the list
            } else {
              log("Error item is not Map<String, dynamic> and does contain key Step ID.");
            }
          }

          // Print the extracted ids
          for (var id in stepIds) {
            log("Extracted Step ID: $id");
          }

          await checkRunStatus(runId);
        } catch (e) {
          log("Error parsing response in checkProcessedDataToOpenAI: $e");
        }
      } else {
        log("Error in checkProcessedDataToOpenAI: ${response.statusCode}");
        log("Error in checkProcessedDataToOpenAI: ${response.body}");
      }
    } catch (e) {
      log("Failed to send processed data: $e");
    }
  }

  // Check the status of the run
  Future<void> checkRunStatus(String runId) async {
    final url =
    Uri.parse("https://api.openai.com/v1/threads/$_threadId/runs/$runId");



    while (true) {

      try {
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $OPEN_AI_API',
            'OpenAI-Beta': 'assistants=v2',
          },
        );

        if (response.statusCode == 200) {

          final Map<String, dynamic> responseData = json.decode(response.body);

          final requiredAction = responseData['required_action'];
          final status = responseData["status"];
          final Map<String, Map<String, dynamic>> toolCallId =
          getToolCallIdWithFunctionNameAndArguments(responseData);

          if (status == "in_progress") {
            log("Please wait open ai is processing data.");
          } else {
            if (status == "completed") {
              assistantResponse(_threadId!);
              break;
            } else if (status == "failed") {
              log("Failed to get response.");
              final replyMessage = types.TextMessage(
                author: _receiver,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                id: const Uuid().v4(),
                text: "Network error. Please try again later",
              );
              saveMessagesInFirebase(_threadId!,
                  "Network error. Please try again later", "AI-Assistant");
              _addMessage(replyMessage);

              setState(() {
                _isAssistantTyping = false;
              });
              break;
            } else if (status == "requires_action" && requiredAction != null) {
              final type = requiredAction['type'];
              if (type == "submit_tool_outputs") {
                if (toolCallId.isNotEmpty) {
                  await handleFunctionCall(runId, toolCallId);
                  break;
                } else {
                  log("Error: Tool call id, function name and arguments are null");
                }
              } else {
                log("Error: Incorrect required action type");
              }
            } else {
              log("Error: Status is not 'requires_action' or requiredAction is null");
            }
          }
        } else {
          log("Error in last step with code: ${response.statusCode}");
          log("Error in last step with body: ${response.body}");
        }
      } catch (e) {
        log("Failed to check run status: $e");
      }

    }
  }

  // Process calendar data
  Future<Map<String, String>> processCalendarDataWithPhysicalLocation(String summary, DateTime startDate, DateTime endDate, String location) async {
    // Call the getExactLocationCoordinates method
    final Map<String, dynamic> result =
    await GoogleMapsController.getExactLocationCoordinates(location);

    // Check the result
    if (result.containsKey("location")) {
      final String locationStatus = result["location"];
      final String details = result["details"];

      log("Location Status: $locationStatus");
      log("Location Details: $details");

      if (locationStatus == "No location found") {
        return {
          "calendarStatus": "event will only save when exact location is found",
          "databaseStatus":
          "database will not save anything if location is not found",
          "locationStatus": locationStatus,
          "detailsStatus": details,
        };
      } else if (locationStatus.contains("name:")) {
        // Extract location details for the single location found
        final locationData =
        result['location']; // This should be a string with location details
        log("Coordinates: $locationData");
        // final coordinatesMatch = RegExp(r"coordinates: \{lat: ([\d.]+), lng: ([\d.]+)\}").firstMatch(locationData);
        final coordinatesMatch = RegExp(
            r"coordinates:\s*\{lat:\s*([\d.-]+),\s*lng:\s*([\d.-]+)\}",
            caseSensitive: false)
            .firstMatch(locationData);

        if (coordinatesMatch != null) {
          final lat = coordinatesMatch.group(1);
          final lng = coordinatesMatch.group(2);

          final name = {locationData.split(',')[0].replaceFirst('name: ', '')};
          // Use the extracted coordinates and name
          log("Extracted Name: $name");
          log("Extracted Latitude: $lat");
          log("Extracted Longitude: $lng");

          final calendarClient = CalendarClient();
          final calendarData =
          await calendarClient.createEventWithPhysicalLocation(
              context,
              summary,
              startDate,
              endDate,
              lat.toString(),
              lng.toString(),
              name.toString());

          return {
            "calendarStatus": calendarData['calendarMessage'] ?? "N/A",
            "databaseStatus": calendarData['databaseMessage'] ?? "N/A",
            "locationStatus": locationStatus,
            "detailsStatus": details,
          };
        } else {
          return {
            "calendarStatus":
            "event will only save when there is no error in location",
            "databaseStatus":
            "database will not save anything if there is error in location",
            "locationStatus":
            "location found but there is error in coordinates",
            "detailsStatus":
            "location is found successfully but there is error while fetching coordinates. "
                "The regex does not match with location coordinates. Only tell this error to user if user is a developer.",
          };
        }
      } else if (locationStatus == "Multiple locations") {
        return {
          "calendarStatus":
          "event will only save when there is only exact one location is found.",
          "databaseStatus":
          "database will not save anything if locations is multiple.",
          "locationStatus": locationStatus,
          "detailsStatus": details,
        };
      } else {
        return {
          "calendarStatus":
          "event will only save when there is no error in location",
          "databaseStatus":
          "database will not save anything if there is error in location",
          "locationStatus": locationStatus,
          "detailsStatus": details,
        };
      }
    } else {
      return {
        "calendarStatus":
        "Problem in location class. Don't show this to user $result. Tell user to try again later or contact developer.",
        "databaseStatus":
        "Problem in location class. Don't show this to user $result. Tell user to try again later or contact developer.",
        "locationStatus":
        "Problem in location class. Don't show this to user $result. Tell user to try again later or contact developer.",
        "detailsStatus":
        "Problem in location class. Don't show this to user $result. Tell user to try again later or contact developer.",
      };
    }
  }

  // Process calendar data
  Future<Map<String, String>> processCalendarDataWithVirtualLocation(String summary, DateTime startDate, DateTime endDate, String location) async {
    final calendarClient = CalendarClient();
    final calendarData = await calendarClient.createEventWithVirtualLocation(
        context, summary, startDate, endDate, location);

    return {
      "calendarStatus": calendarData['calendarMessage'],
      "databaseStatus": calendarData['databaseMessage'],
    };
  }

// Process weather data
  Future<Map<String, String>> processWeatherData(String location) async {
    final weatherData = await WeatherApi.fetchWeatherData(location);

    log("Temperature : ${weatherData['weather']}");
    log("Weather Message for Developer: ${weatherData['weather message']}");

    return {
      'temperature': weatherData['weather'] ?? "N/A",
      'weather message': weatherData['weather message'] ?? "N/A"
    };
  }

// Process weather data with user location
  Future<Map<String, String>> processWeatherDataWithUserLocation() async {
    final weatherData = await WeatherApi.fetchWeatherDataOfUser();

    log("Temperature : ${weatherData['weather']}");
    log("Weather Message for Developer: ${weatherData['weather message']}");
    log("User's Location : ${weatherData['user location']}");

    return {
      'temperature': weatherData['weather'] ?? "N/A",
      'weather message': weatherData['weather message'] ?? "N/A",
      'user location': weatherData['user location'] ?? "N/A",
    };
  }

// Process Google Maps data between two points
  Future<Map<String, String>> processGoogleMapsDataPointsBetweenTwoPoints(String source, String destination) async {
    final googleMapData =
    await GoogleMapsController.getTrafficDistanceAndTimeOfTwoPoints(
        source, destination);

    log("Distance : ${googleMapData['distance']}");
    log("Duration : ${googleMapData['duration']}");
    log("Traffic Condition : ${googleMapData['traffic condition']}");
    log("Message for Developer : ${googleMapData['message']}");
    log("Api Response Code : ${googleMapData['responseCode']}");

    return {
      'distance': googleMapData['distance'],
      'duration': googleMapData['duration'],
      'traffic condition between origin and destination':
      googleMapData['traffic condition'],
      'message': googleMapData['message'],
      'responseCode': googleMapData['responseCode'],
    };
  }

  // Process Google Maps data between user location and destination
  Future<Map<String, String>> processGoogleMapsDataPointsBetweenUserLocationAndDestination(String destination) async {
    final googleMapData = await GoogleMapsController
        .getTrafficDistanceAndTimeFromUserLocationToDestination(destination);

    log("Distance : ${googleMapData['distance']}");
    log("Duration : ${googleMapData['duration']}");
    log("Traffic Condition : ${googleMapData['traffic condition']}");
    log("Message for Developer : ${googleMapData['message']}");
    log("Api Response Code : ${googleMapData['responseCode']}");

    return {
      'distance': googleMapData['distance'],
      'duration': googleMapData['duration'],
      'traffic condition between origin and destination':
      googleMapData['traffic condition'],
      'message': googleMapData['message'],
      'responseCode': googleMapData['responseCode'],
    };
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // Define responsive values
    final fiveSize = screenWidth * 0.01215278;
    final fiveSizeHeight = screenHeight * 0.0059121621621622;


    return GestureDetector(
      onTap: () {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      },
      child: SafeArea(
        child: Scaffold(
          appBar: _buildAppBar(fiveSize, fiveSizeHeight),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Chat(
                  messages: _messages,
                  onMessageLongPress: _handleMessageLongTap,
                  onMessageTap: _handleMessageTap,
                  onPreviewDataFetched: _handlePreviewDataFetched,
                  onSendPressed: _handleSendPressed,
                  showUserAvatars: true,
                  showUserNames: true,
                  user: _user,
                  bubbleBuilder: _customBubbleBuilder, // Custom bubble
                  customBottomWidget: _buildCustomInput(),
                  emptyState: const Center(child: CircularProgressIndicator(),),
                  listBottomWidget: _buildTypingIndicator(fiveSize),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(double fiveSize) {
    if (_isAssistantTyping) {
      return Padding(
        padding: EdgeInsets.all(fiveSize * 1.6),
        child: Row(
          children: [
            const CircularProgressIndicator(), // Or any custom widget for typing indicator
            SizedBox(width: fiveSize * 1.6),
            const Text("Assistant is typing..."),
          ],
        ),
      );
    }
    return const SizedBox.shrink(); // Return an empty widget if not typing
  }

  AppBar _buildAppBar(double fiveSize, double fiveSizeHeight) {
    return AppBar(
      iconTheme: IconThemeData(
        color: Colors.white,
        size: fiveSize * 7,
      ),
      backgroundColor: Colors.blueAccent,
      toolbarHeight: fiveSizeHeight * 16,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Return to the previous screen with a result
          Get.back(result: true);
        },
      ),
      flexibleSpace: Padding(
        padding: EdgeInsets.only(top: fiveSize * 2, left: fiveSize * 13),
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(right: fiveSize * 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                image: const DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage('assets/images/logo.png'),
                ),
              ),
              child: SizedBox(
                width: fiveSize * 9,
                height: fiveSize * 9,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: GoogleFonts.getFont(
                    'Bricolage Grotesque',
                    fontWeight: FontWeight.bold,
                    fontSize: fiveSize * 4,
                    height: 1.2,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.bottomRight,
                    end: Alignment.topLeft,
                    colors: [
                      Color(0xFFDF9EDB),
                      Color(0xFFDF9EDB),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    "Premium Account",
                    style: GoogleFonts.getFont(
                      'Bricolage Grotesque',
                      fontWeight: FontWeight.w600,
                      fontSize: fiveSize * 2.8,
                      height: 1.2,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      centerTitle: true,
      elevation: 0,
    );
  }

  Widget _buildCustomInput() {
    return Container(
      color: Colors.blueAccent,
      padding: EdgeInsets.all(_inputPadding),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              enabled: _isFieldEnabled,
              controller: _messageController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Type your message',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: null, // Allows the text field to grow vertically
              minLines: 1, // Minimum number of lines
              keyboardType: TextInputType.multiline,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _handleSendPressed(types.PartialText(text: value));
                  _messageController.clear();
                }
              },
            ),
          ),
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_off,
              color: _isListening ? Colors.green : Colors.red,
            ),
            onPressed: () async {

              PermissionStatus status = await Permission.microphone.status;

              if (status.isGranted) {
                log("Microphone permission granted.");
                _startListening();
              } else if (status.isDenied) {
                log("Microphone permission denied. Requesting permission...");
                PermissionStatus newStatus = await Permission.microphone.request();

                if (newStatus.isGranted) {
                  log("Permission granted after request.");
                } else if (newStatus.isPermanentlyDenied) {
                  log("Permission permanently denied. Open app settings to enable.");
                  _showPermissionDialog();
                } else {
                  log("Microphone Permission denied.");
                }
              }


            },
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                _handleSendPressed(
                    types.PartialText(text: _messageController.text));
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Microphone Permission Needed"),
        content: const Text("This app requires microphone access to use speech recognition. Please enable it in the app settings."),
        actions: <Widget>[
          TextButton(
            child: const Text("Open Settings"),
            onPressed: () {
              openAppSettings(); // Open device settings to grant permissions
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _customBubbleBuilder(Widget child, {required types.Message message, required bool nextMessageInGroup,}) {
    // Define colors based on the message type
    final bool isSentByUser = message.author.id == _user.id;
    final Color bubbleColor =
    isSentByUser ? Colors.blueAccent : Colors.grey[300]!;
    final Color textColor = isSentByUser ? Colors.white : Colors.black;
    final screenWidth = MediaQuery.of(context).size.width;
    // Define responsive values
    final fiveSize = screenWidth * 0.01215278;

    return Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: MarkdownBody(
          data: (message as types.TextMessage).text,
          styleSheet: MarkdownStyleSheet(
            p: GoogleFonts.getFont(
              'Open Sans',
              fontWeight: FontWeight.w400,
              fontSize: fiveSize * 2.8,
              height: 1.3,
              letterSpacing: 1,
              color: textColor,
            ),
            strong: TextStyle(
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
            // You can add more custom styles for other Markdown elements if needed
          ),
        )



    );
  }

  void _handleSendPressed(PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);
    setState(() {
      _isAssistantTyping = true;
    });

    if(_threadId != null){
      saveMessagesInFirebase(_threadId!, textMessage.text, "user");
      linkMessageAndThreadWithOutput(textMessage.text);
    }else{

    }


  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index =
              _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (_messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final index =
              _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (_messages[index] as types.FileMessage).copyWith(
            isLoading: null,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handleMessageLongTap(BuildContext _, types.Message message) async {
    if (message is types.TextMessage) {
      // Copy the message text to the clipboard
      await Clipboard.setData(ClipboardData(text: message.text));

      // Show a message to notify the user that the text has been copied
      ScaffoldMessenger.of(_).showSnackBar(
        const SnackBar(content: Text('Message copied to clipboard')),
      );
    }
  }

  void _handlePreviewDataFetched(types.TextMessage message, types.PreviewData previewData,) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

}

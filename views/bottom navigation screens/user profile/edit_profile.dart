import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_picker/country_picker.dart';

import '../../../controllers/authentications/user_authentication.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _countryController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _dateOfBirthFocusNode = FocusNode();
  final _countryFocusNode = FocusNode();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? fetchedName;
  String? fetchedEmail;
  String? fetchedDob;
  String? fetchedCountry;

  Future<void> inflateFields() async {
    try {
      // Fetch the current user's UID
      User? user = _auth.currentUser;
      if (user == null) {
        log('No user is currently signed in.');
        return;
      }
      String uid = user.uid;

      // Fetch user data from Firestore
      DocumentSnapshot doc =
          await _firestore.collection('usersInfo').doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic>? userData = doc.data() as Map<String, dynamic>?;

        if (userData != null) {
          fetchedName = userData['name'] as String?;
          fetchedEmail = userData['email'] as String?;
          fetchedDob = userData['dob'] as String?;
          fetchedCountry = userData['country'] as String?;

          if (fetchedName != null) {
            _nameController.clear();
            _nameController.text = fetchedName!;
          }
          if (fetchedEmail != null) {
            _emailController.clear();
            _emailController.text = fetchedEmail!;
          }
          if (fetchedDob != null) {
            _dateOfBirthController.clear();
            _dateOfBirthController.text = fetchedDob!;
          }
          if (fetchedCountry != null) {
            _countryController.clear();
            _countryController.text = fetchedCountry!;
          }

          log('Name: $fetchedName');
          log('Email: $fetchedEmail');
          log('Date of Birth: $fetchedDob');
          log('Country: $fetchedCountry');
        } else {
          log('User data is null.');
        }
      } else {
        log('No user found with UID: $uid');
      }
    } catch (e) {
      log('Error fetching user data: $e');
    }
  }

  void saveDataInFirebase() async {
    try {
      // Fetch the current user's UID
      User? user = _auth.currentUser;
      if (user == null) {
        log('No user is currently signed in.');
        return;
      }
      String uid = user.uid;

      // Create a Map with user data
      Map<String, dynamic> userData = {
        'name': _nameController.text.toString().trim(),
        'email': _emailController.text.toString().trim(),
        'dob': _dateOfBirthController.text
            .toString()
            .trim(), // Optional, may be null
        'country':
            _countryController.text.toString().trim(), // Optional, may be null
      };

      // Save data to Firestore
      await _firestore
          .collection('usersInfo')
          .doc(uid)
          .set(userData, SetOptions(merge: true));
      log('User data saved successfully!');
    } catch (e) {
      log('Error saving user data: $e');
    }
  }

  @override
  void initState() {
    inflateFields();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    // Get the screen width and height
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // Define responsive values
    final fiveSize = screenWidth * 0.01215278;
    final fiveSizeHeight = screenHeight * 0.0059121621621622;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        title: Text(
          "Edit Profile",
          style: GoogleFonts.getFont(
            'Inter',
            fontWeight: FontWeight.w700,
            fontSize: fiveSize * 3.2,
            height: 0.9,
            color: Colors.white,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        },
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  padding: EdgeInsets.fromLTRB(fiveSize * 5, fiveSizeHeight * 4, fiveSize * 4, 45),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: fiveSize * 35,
                        height: fiveSize * 35,
                        margin: EdgeInsets.fromLTRB(0, 0, fiveSize * 1, 25),
                        child: SizedBox(
                          child: Stack(
                            children: [
                              // The SVG frame
                              Center(
                                child: SvgPicture.asset(
                                  'assets/vectors/group_21_x2.svg',
                                  fit: BoxFit.cover,
                                  height: fiveSizeHeight * 26,
                                  width: fiveSize * 23.2,
                                ),
                              ),
                              // The icon inside the frame
                              Center(
                                child: Icon(
                                  Icons
                                      .camera_alt, // Replace with your desired icon
                                  size: fiveSize * 12, // Adjust size as needed
                                  color: Colors.black, // Adjust color as needed
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 0, fiveSize * 1, 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Name',
                                  style: GoogleFonts.getFont(
                                    'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: fiveSize * 3.2,
                                    height: 0.9,
                                    color: const Color(0xFF000000),
                                  ),
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              onChanged: (value) {},
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter name";
                                } else {
                                  return null;
                                }
                              },
                              onFieldSubmitted: (value) {
                                FocusScope.of(context)
                                    .requestFocus(_emailFocusNode);
                              },
                              decoration: InputDecoration(
                                suffixIcon: const Icon(
                                  Icons.drive_file_rename_outline,
                                  color: Colors.blueAccent,
                                ),
                                hintText: "Enter Name Here",
                                hintStyle: GoogleFonts.getFont(
                                  'Inter',
                                  fontWeight: FontWeight.w400,
                                  fontSize: fiveSize * 2.5,
                                  color: Colors.blueAccent,
                                ),
                                fillColor: const Color(0xFFF0EFFF),
                                filled: true,
                                contentPadding: EdgeInsets.fromLTRB(
                                    fiveSize * 4,
                                    fiveSize * 3,
                                    fiveSize * 4,
                                    fiveSize * 3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                      color: Colors.blueAccent, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                      color: Colors.blueAccent, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                      color: Colors.blueAccent, width: 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 0, fiveSize, 18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.fromLTRB(0, 0, 0, 11),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Email',
                                  style: GoogleFonts.getFont(
                                    'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: fiveSize * 3.2,
                                    height: 0.9,
                                    color: const Color(0xFF000000),
                                  ),
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              enabled: false,
                              onChanged: (value) {},
                              validator: (value) {
                                // Define the regex pattern for validating email
                                final emailRegex =
                                    RegExp(r'^[^@]+@[^@]+\.[^@]+$');

                                if (value == null || value.isEmpty) {
                                  return "Please enter Email Address";
                                } else if (!emailRegex.hasMatch(value)) {
                                  return "Please enter a valid email address";
                                } else {
                                  return null;
                                }
                              },
                              onFieldSubmitted: (value) {
                                FocusScope.of(context)
                                    .requestFocus(_dateOfBirthFocusNode);
                              },
                              decoration: InputDecoration(
                                suffixIcon: const Icon(
                                  Icons.email,
                                  color: Colors.blueAccent,
                                ),
                                hintText: "Fetching email...",
                                hintStyle: GoogleFonts.getFont(
                                  'Inter',
                                  fontWeight: FontWeight.w400,
                                  fontSize: fiveSize * 2.5,
                                  color: Colors.blueAccent,
                                ),
                                fillColor: const Color(0xFFF0EFFF),
                                filled: true,
                                contentPadding: EdgeInsets.fromLTRB(
                                    fiveSize * 4,
                                    15,
                                    fiveSize * 4,
                                    15),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                      color: Colors.blueAccent, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                      color: Colors.blueAccent, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                      color: Colors.blueAccent, width: 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 0, 5, 18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.fromLTRB(0, 0, 0, 11),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Date of Birth',
                                  style: GoogleFonts.getFont(
                                    'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: fiveSize *
                                        3.2, // Adjusted as per your original styling
                                    height: 0.9,
                                    color: const Color(0xFF000000),
                                  ),
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _dateOfBirthController,
                              focusNode: _dateOfBirthFocusNode,
                              onTap: () async {
                                DateTime? selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );

                                if (selectedDate != null) {
                                  _dateOfBirthController.text =
                                      "${selectedDate.toLocal()}".split(' ')[0];
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your date of birth";
                                } else {
                                  return null;
                                }
                              },
                              onFieldSubmitted: (value) {
                                FocusScope.of(context)
                                    .requestFocus(_countryFocusNode);
                              },
                              decoration: InputDecoration(
                                suffixIcon: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.blueAccent,
                                ),
                                hintText: "Select Date of Birth",
                                hintStyle: GoogleFonts.getFont(
                                  'Inter',
                                  fontWeight: FontWeight.w400,
                                  fontSize: fiveSize * 2.5,
                                  color: Colors.blueAccent,
                                ),
                                fillColor: const Color(0xFFF0EFFF),
                                filled: true,
                                contentPadding: EdgeInsets.fromLTRB(
                                    fiveSize * 4,
                                    fiveSize * 3,
                                    fiveSize * 4,
                                    fiveSize * 3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                      color: Colors.blueAccent, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                      color: Colors.blueAccent, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                      color: Colors.blueAccent, width: 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 0, 5, 18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.fromLTRB(0, 0, 0, 11),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Country',
                                  style: GoogleFonts.getFont(
                                    'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: fiveSize *
                                        3.2, // Adjusted as per your original styling
                                    height: 0.9,
                                    color: const Color(0xFF000000),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                showCountryPicker(
                                  context: context,
                                  countryListTheme: CountryListThemeData(
                                    borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        topLeft: Radius.circular(8)),
                                    backgroundColor: const Color(0xFFF0EFFF),
                                    textStyle: GoogleFonts.getFont(
                                      'Inter',
                                      fontWeight: FontWeight.w700,
                                      fontSize: fiveSize *
                                          3.2, // Adjusted as per your original styling
                                      height: 0.9,
                                      color: const Color(0xFF000000),
                                    ),
                                    bottomSheetHeight:
                                    fiveSizeHeight * 100, // Set the height of the bottom sheet
                                  ),
                                  onSelect: (Country country) {
                                    setState(() {
                                      _countryController.text = country.name;
                                    });
                                  },
                                );
                              },
                              child: AbsorbPointer(
                                child: TextFormField(
                                  validator: (value) {
                                    if (value == null || value.isEmpty || value == "Select Country") {
                                      return "Please select your country";
                                    } else {
                                      return null;
                                    }
                                  },
                                  controller: _countryController,
                                  decoration: InputDecoration(
                                    fillColor: const Color(0xFFF0EFFF),
                                    filled: true,
                                    labelText: 'Select Country',
                                    labelStyle: GoogleFonts.getFont(
                                      'Inter',
                                      fontWeight: FontWeight.w400,
                                      fontSize: fiveSize * 2.5,
                                      color: Colors.blueAccent,
                                    ),
                                    contentPadding: EdgeInsets.fromLTRB(
                                        fiveSize * 4,
                                        fiveSize * 3,
                                        fiveSize * 4,
                                        fiveSize * 3),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: const BorderSide(
                                          color: Colors.blueAccent, width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: const BorderSide(
                                          color: Colors.blueAccent, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: const BorderSide(
                                          color: Colors.blueAccent, width: 1),
                                    ),
                                    suffixIcon:
                                        const Icon(Icons.arrow_drop_down),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: fiveSize * 5,
                      ),
                      InkWell(
                        onTap: () {
                          if (formKey.currentState?.validate() ?? false) {
                            log("Button pressed");
                            saveDataInFirebase();
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 0, fiveSize * 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            color: Colors.blueAccent,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.blueAccent,
                                offset: Offset(0, 4),
                                blurRadius: 30.5,
                              ),
                            ],
                          ),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(fiveSize * 11,
                                fiveSize * 2.5, fiveSize * 11, fiveSize * 2.5),
                            child: Text(
                              'Save Changes',
                              style: GoogleFonts.getFont(
                                'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: fiveSize * 3,
                                color: const Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          UserAuthentication userAuthentication =
                              UserAuthentication();
                          userAuthentication.signOut();
                        },
                        child: Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 0, fiveSize * 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            color: Colors.blueAccent,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.blueAccent,
                                offset: Offset(0, 4),
                                blurRadius: 30.5,
                              ),
                            ],
                          ),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(fiveSize * 16,
                                fiveSize * 2.5, fiveSize * 16, fiveSize * 2.5),
                            child: Text(
                              'Logout',
                              style: GoogleFonts.getFont(
                                'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: fiveSize * 3,
                                color: const Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

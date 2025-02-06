import 'package:ai_assistant/views/auth%20screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:ai_assistant/controllers/authentications/user_authentication.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';


class ForgotPassword extends StatelessWidget {

  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _emailController = TextEditingController();

  final UserAuthentication userAuthentication = UserAuthentication();

  ForgotPassword({super.key});

  void sendPasswordResetLink (BuildContext context){
    if (_formKey.currentState?.validate() ?? false) {
      userAuthentication.sendPasswordResetEmail(
          context, _emailController.text.toString().trim());
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("A reset link has been sent to your registered Email.")));
      Get.to(()=> const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    // Define responsive values
    final fiveSize = screenWidth * 0.01215278;

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
              ),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    fiveSize * 5, fiveSize * 4, fiveSize * 5, fiveSize * 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 0, fiveSize * 8),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Logo Here',
                          style: GoogleFonts.getFont(
                            'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: fiveSize * 3.6,
                            color: const Color(0xFF000000),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: screenWidth * 0.2433,
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 0, fiveSize * 8),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              margin: EdgeInsets.fromLTRB(
                                  0, 0, fiveSize * 5, fiveSize * 5),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin:
                                    EdgeInsets.fromLTRB(0, 0, 0, fiveSize),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        'Reset Password',
                                        style: GoogleFonts.getFont(
                                          'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: fiveSize * 5,
                                          color: const Color(0xFF000000),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'AI Assistant Application',
                                    style: GoogleFonts.getFont(
                                      'Poppins',
                                      fontWeight: FontWeight.w500,
                                      fontSize: fiveSize * 4,
                                      color: const Color(0xFF000000),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextFormField(
                          autofillHints: const [AutofillHints.email],
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          onChanged: (value) {},
                          validator: (value) {
                            // Define the regex pattern for validating email
                            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

                            if (value == null || value.isEmpty) {
                              return "Please enter Email Address";
                            } else if (!emailRegex.hasMatch(value)) {
                              return "Please enter a valid email address";
                            } else {
                              return null;
                            }
                          },
                          onFieldSubmitted: (value) {
                            if (_formKey.currentState?.validate() ?? false) {
                              // Trigger the login button action
                              sendPasswordResetLink(context);
                            }
                          },
                          decoration: InputDecoration(
                            suffixIcon: const Icon(
                                Icons.email,
                                color: Colors.blueAccent,
                              ),
                            hintText: "Enter Email Here",
                            hintStyle: GoogleFonts.getFont(
                              'Poppins',
                              fontWeight: FontWeight.w400,
                              fontSize: fiveSize * 3,
                              color: Colors.blueAccent,
                            ),
                            fillColor: const Color(0xFFF0EFFF),
                            filled: true,
                            contentPadding: EdgeInsets.fromLTRB(fiveSize * 4.54,
                                fiveSize * 4, fiveSize * 4.54, fiveSize * 4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(
                                  color: Colors.white, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(
                                  color: Colors.white, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(
                                  color: Colors.blueAccent, width: 1),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: fiveSize * 3,
                        ),
                        InkWell(
                          onTap: (){
                            sendPasswordResetLink(context);
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
                              padding: EdgeInsets.fromLTRB(
                                  fiveSize * 10,
                                  fiveSize * 2.4,
                                  fiveSize * 10,
                                  fiveSize * 2.4),
                              child: Text(
                                'Send Link',
                                style: GoogleFonts.getFont(
                                  'Poppins',
                                  fontWeight: FontWeight.w500,
                                  fontSize: fiveSize * 3.2,
                                  color: const Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

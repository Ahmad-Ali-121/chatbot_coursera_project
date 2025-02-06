import 'package:ai_assistant/controllers/authentications/user_authentication.dart';
import 'package:ai_assistant/views/auth screens/forgot_password.dart';
import 'package:ai_assistant/views/auth screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../bottom_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscureText = true;

  bool _isloading = false;

  final _formKey = GlobalKey<FormState>();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final UserAuthentication userAuthentication = UserAuthentication();

  void loginMethod(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      String msg = await userAuthentication.login(context, _emailController.text.toString().trim(),
          _passwordController.text.toString().trim());

      if ( msg == "Login successful" ){
        ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        setState(() {
          _isloading = false;
        });
        Get.off(()=> const BottomNavigation());
      }else{
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        setState(() {
          _isloading = false;
        });
      }
    }else{
      setState(() {
        _isloading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    final screenWidth = MediaQuery.of(context).size.width;
    // Define responsive values
    final fiveSize = screenWidth * 0.01215278;

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // Hide system UI
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
                                        'Sign in to ',
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
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                child: Text(
                                  "Don't have an account?",
                                  style: GoogleFonts.getFont(
                                    'Poppins',
                                    fontWeight: FontWeight.w500,
                                    fontSize: fiveSize * 3,
                                    color: const Color(0xFFB0B0B0),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Register ',
                                  style: GoogleFonts.getFont(
                                    'Poppins',
                                    fontWeight: FontWeight.w500,
                                    fontSize: fiveSize * 3,
                                    color: const Color(0xFFB0B0B0),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Get.to(
                                      () => const RegisterScreen(),
                                      transition: Transition
                                          .fadeIn, // Example of fade-in transition
                                      duration:
                                          const Duration(milliseconds: 500),
                                    );
                                  },
                                  child: Text(
                                    'Here!',
                                    style: GoogleFonts.getFont(
                                      'Poppins',
                                      fontWeight: FontWeight.w500,
                                      fontSize: fiveSize * 3.3,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    AutofillGroup(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextFormField(
                            autofillHints: const [AutofillHints.email],
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            textInputAction: TextInputAction.next,
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
                                  .requestFocus(_passwordFocusNode);
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
                              contentPadding: EdgeInsets.fromLTRB(
                                  fiveSize * 4.54,
                                  fiveSize * 4,
                                  fiveSize * 4.54,
                                  fiveSize * 4),
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
                          TextFormField(
                            autofillHints: const [AutofillHints.password],
                            keyboardType: TextInputType.visiblePassword,
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            obscureText: obscureText,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter Password";
                              } else {
                                return null;
                              }
                            },
                            onFieldSubmitted: (value) {
                              if (_formKey.currentState?.validate() ?? false) {
                                // Trigger the login button action
                                loginMethod(context);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: "Enter Password Here",
                              hintStyle: GoogleFonts.getFont(
                                'Poppins',
                                fontWeight: FontWeight.w400,
                                fontSize: fiveSize * 3,
                                color: Colors.blueAccent,
                              ),
                              fillColor: const Color(0xFFF0EFFF),
                              filled: true,
                              contentPadding: EdgeInsets.fromLTRB(
                                  22.7, fiveSize * 4, 22.7, fiveSize * 4),
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
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscureText = !obscureText;
                                  });
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                            height: fiveSize * 3,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () {
                                  Get.to(() => ForgotPassword());
                                },
                                child: Container(
                                  margin: EdgeInsets.fromLTRB(
                                      fiveSize, 0, fiveSize, 0),
                                  child: Text(
                                    'Forgot password ?',
                                    style: GoogleFonts.getFont(
                                      'Poppins',
                                      fontWeight: FontWeight.w400,
                                      fontSize: fiveSize * 2.6,
                                      color: const Color(0xFFB0B0B0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: fiveSize * 6,
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isloading = true;
                              });
                              loginMethod(context);
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
                                child: _isloading ? const CircularProgressIndicator(color: Colors.white,) : Text(
                                  'Login',
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

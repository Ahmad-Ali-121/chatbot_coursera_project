import 'package:ai_assistant/controllers/authentications/user_authentication.dart';
import 'package:ai_assistant/views/auth screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool obscureText = true;
  bool obscureConfirmText = true;

  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();

  final _emailFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _contactNumberFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final UserAuthentication userAuthentication = UserAuthentication();

  void signUpMethod(BuildContext context) async {

    if (_formKey.currentState?.validate() ?? false) {
      String message = await userAuthentication.signup(
        context,
        _emailController.text.toString().trim(),
        _passwordController.text.toString().trim(),
        _nameController.text.toString().trim(),
        _contactNumberController.text.toString().trim(),
      );

      if (message == "Signup successful"){
        setState(() {
          isLoading = false;
        });
      }else{
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        setState(() {
          isLoading = false;
        });
      }
    }else{
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _nameFocusNode.dispose();
    _contactNumberFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    _emailController.dispose();
    _nameController.dispose();
    _contactNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

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
                    fiveSize * 5, fiveSize * 4, fiveSize * 5, fiveSize * 16),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.fromLTRB(0, 0, 0, 32),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin:
                                          const EdgeInsets.fromLTRB(0, 0, 0, 5),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          'Sign Up',
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
                            ),
                            Container(
                              margin: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin:
                                        const EdgeInsets.fromLTRB(0, 0, 0, 6),
                                    child: Text(
                                      'Already have an Account?',
                                      style: GoogleFonts.getFont(
                                        'Poppins',
                                        fontWeight: FontWeight.w400,
                                        fontSize: fiveSize * 3,
                                        color: const Color(0xFF000000),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Get.offAll(
                                        () => const LoginScreen(),
                                        transition: Transition
                                            .fadeIn, // Example of fade-in transition
                                        duration:
                                            const Duration(milliseconds: 500),
                                      );
                                    },
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: RichText(
                                        text: TextSpan(
                                          text: 'Login here !',
                                          style: GoogleFonts.getFont(
                                            'Poppins',
                                            fontWeight: FontWeight.w600,
                                            fontSize: fiveSize * 3.3,
                                            height: 1.3,
                                            color: Colors.blueAccent,
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
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AutofillGroup(
                          child: TextFormField(
                            autofillHints: const [AutofillHints.email],
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.emailAddress,
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
                              FocusScope.of(context).requestFocus(_nameFocusNode);
                            },
                            decoration: InputDecoration(
                              suffixIcon: const Icon(
                                  Icons.email,
                                  color: Colors.blueAccent,
                                ),
                          
                              hintText: "Enter Your Email Here",
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
                        ),
                        SizedBox(
                          height: fiveSize * 3,
                        ),
                        AutofillGroup(
                          child: TextFormField(
                            autofillHints: const [AutofillHints.name],
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.name,
                            onChanged: (value) {},
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your name";
                              } else {
                                return null;
                              }
                            },
                            onFieldSubmitted: (value) {
                              FocusScope.of(context)
                                  .requestFocus(_contactNumberFocusNode);
                            },
                            decoration: InputDecoration(
                              suffixIcon: const Icon(
                                  Icons.drive_file_rename_outline,
                                  color: Colors.blueAccent,
                                ),
                              hintText: "Enter Your Name Here",
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
                        ),
                        SizedBox(
                          height: fiveSize * 3,
                        ),
                        AutofillGroup(
                          child: TextFormField(
                            autofillHints: const [AutofillHints.telephoneNumber],
                            controller: _contactNumberController,
                            focusNode: _contactNumberFocusNode,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.phone,
                            onChanged: (value) {},
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your Phone Number";
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
                                  Icons.phone,
                                  color: Colors.blueAccent,
                                ),
                          
                          
                              hintText: "Enter Phone Number Here",
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
                        ),
                        SizedBox(
                          height: fiveSize * 3,
                        ),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: obscureText,
                          onChanged: (value) {},
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter Password";
                            } else {
                              return null;
                            }
                          },
                          onFieldSubmitted: (value) {
                            FocusScope.of(context)
                                .requestFocus(_confirmPasswordFocusNode);
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
                        TextFormField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocusNode,
                          obscureText: obscureConfirmText,
                          onChanged: (value) {},
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please Re-enter your Password";
                            } else if (_passwordController.text.toString() !=
                                value) {
                              return "Passwords dont match!";
                            } else {
                              return null;
                            }
                          },
                          onFieldSubmitted: (value) {
                            if (_formKey.currentState?.validate() ?? false) {
                              FocusScope.of(context).unfocus(); // Hides the keyboard
                              setState(() {
                                isLoading = true;
                              });
                              signUpMethod(context);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: "Enter Confirm Password Here",
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
                                obscureConfirmText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.blueAccent,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureConfirmText = !obscureConfirmText;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          height: fiveSize * 6,
                        ),
                        InkWell(
                          onTap: () {
                            signUpMethod(context);
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
                              child: isLoading ? const CircularProgressIndicator(color: Colors.white,) : Text(
                                'Sign Up',
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

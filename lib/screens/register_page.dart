import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/business/Spotify_Logic/constants.dart';
import 'package:spotify_project/business/business_logic.dart';
import 'package:spotify_project/screens/login_page.dart';
import 'package:spotify_project/screens/steppers.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

FirebaseAuth auth = FirebaseAuth.instance;

User? currentUser = FirebaseAuth.instance.currentUser;

class _RegisterPageState extends State<RegisterPage> {
  BusinessLogic businessLogic = BusinessLogic();
  final formKey = GlobalKey<FormState>();
  final FirestoreDatabaseService _firestoreDatabaseService =
      FirestoreDatabaseService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool isVisible = false;
  bool isLoading = false;
  bool isTermsAccepted = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      // Validate inputs
      if (emailController.text.isEmpty ||
          passwordController.text.isEmpty ||
          nameController.text.isEmpty) {
        throw 'Please fill in all required fields';
      }

      // Create user with Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      currentUser = userCredential.user;
      if (userCredential.user == null) {
        throw 'Failed to create user account';
      }

      // Get FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken() ?? '';

      // Create initial user data
      final userData = {
        'userId': userCredential.user!.uid,
        'email': emailController.text.trim(),
        'name': nameController.text.trim(),
        'biography': '',
        'phoneNumber': '',
        'fcmToken': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'profilePhotos': [
          'https://c4.wallpaperflare.com/wallpaper/436/55/826/abstract-black-wallpaper-preview.jpg'
        ],
      };

      // Save user data to Firestore
      await _firestoreDatabaseService.saveUser(
        biography: userData['biography'] as String,
        name: userData['name'] as String,
        phoneNumber: userData['phoneNumber'] as String,
        uid: userData['userId'] as String,
        fcmToken: userData['fcmToken'] as String,
      );

      await businessLogic.connectToSpotifyRemote();

      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const OnboardingSlider()));
    } catch (e) {
      // Handle specific Firebase Auth errors
      String errorMessage = 'An error occurred during registration';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'This email is already registered';
            break;
          case 'weak-password':
            errorMessage = 'The password provided is too weak';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is invalid';
            break;
          default:
            errorMessage = e.message ?? errorMessage;
        }
      }

      // Show error to user
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 60.h),
                    Text(
                      "Create Account",
                      style: GoogleFonts.poppins(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Sign up to get started!",
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        color: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 48.h),
                    _buildTextField("Name", nameController, Icons.person),
                    SizedBox(height: 24.h),
                    _buildTextField("Email", emailController, Icons.email),
                    SizedBox(height: 24.h),
                    _buildTextField("Password", passwordController, Icons.lock,
                        isPassword: true),
                    SizedBox(height: 48.h),
                    _buildSignUpButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.blueAccent,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[400],
                ),
                onPressed: () => setState(() => isVisible = !isVisible),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return '$label is required';
        }
        if (label == "Email" && !isValidEmail(value)) {
          return 'Enter a valid email';
        }
        if (label == "Password" && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildSignUpButton() {
    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: isTermsAccepted,
              onChanged: (value) {
                setState(() {
                  isTermsAccepted = value!;
                });
              },
            ),
            GestureDetector(
              onTap: () => _showTermsAndConditions(),
              child: Text(
                "I accept the terms and conditions",
                style: TextStyle(
                  color: Colors.grey[400],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: isTermsAccepted
              ? () {
                  if (formKey.currentState!.validate()) {
                    signUp().whenComplete(() {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) {
                        return const OnboardingSlider();
                      }));
                    });
                  }
                }
              : null,
          child: Text(
            "Sign Up",
            style: GoogleFonts.poppins(
                fontSize: 18.sp, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(vertical: 16.h),
            minimumSize: Size(double.infinity, 50.h),
          ),
        ),
        SizedBox(height: 16.h),
        TextButton(
          onPressed: () => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => LoginPage())),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 26.sp,
              ),
              children: const [
                TextSpan(text: "Have already an account? "),
                TextSpan(
                  text: "Sign in",
                  style: TextStyle(color: Colors.blueAccent),
                ),
                TextSpan(text: "."),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTermsAndConditions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Terms and Conditions",
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '''End User License Agreement (EULA) for Musee


This End User License Agreement ("Agreement") is a legal agreement between you ("User") and Musee ("Company") regarding the use of the Musee dating app ("App"). By downloading, accessing, or using the App, you agree to be bound by the terms of this Agreement. If you do not agree, do not download, access, or use the App.

1. License Grant

The Company grants you a limited, non-exclusive, non-transferable, and revocable license to use the App for personal, non-commercial purposes in accordance with this Agreement.

2. Eligibility

The App is intended for individuals aged 18 years or older. By using the App, you confirm that you meet this age requirement.

3. Usage Restrictions

You agree not to:

Post, share, or transmit explicit, offensive, or racist content.

Harass, abuse, or harm other users.

Use the App for any illegal purposes.

Reverse-engineer, decompile, or modify the App.

The Company reserves the right to suspend or terminate your account for violations of these terms.

4. User-Generated Content

You retain ownership of the content you upload to the App. By uploading content, you grant the Company a non-exclusive, royalty-free license to use, display, and distribute such content solely for operating the App.

The Company reserves the right to monitor and remove inappropriate content at its discretion.

5. In-App Purchases and Subscriptions

The App offers a free version and optional in-app purchases. By making a purchase, you agree to the pricing, payment, and subscription terms presented at the time of purchase.

Refunds will only be provided if the Company fails to deliver promised features due to its fault.

6. Privacy and Data Collection

The Company collects and processes personal data as outlined in its Privacy Policy. By using the App, you consent to the collection, processing, and sharing of your data in accordance with this policy.

7. Disclaimer of Liability

The App is provided "as is" and "as available" without warranties of any kind. The Company is not liable for any damages arising from:

Misuse of the App.

Matches or interactions between users.

Service interruptions or errors.

8. Termination

The Company reserves the right to terminate your access to the App at any time for violations of this Agreement. Users may terminate their account by uninstalling the App.

9. Updates and Changes

The Company may update this Agreement from time to time. Continued use of the App after such updates constitutes acceptance of the new terms.''',
                    style: GoogleFonts.poppins(fontSize: 16.sp),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool isValidEmail(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+$")
        .hasMatch(email);
  }

  void callSnackbar(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: color ?? Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(20),
    ));
  }
}

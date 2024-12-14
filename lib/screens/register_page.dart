import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/screens/login_page.dart';
import 'package:spotify_project/screens/steppers.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

FirebaseAuth auth = FirebaseAuth.instance;

User? currentUser = FirebaseAuth.instance.currentUser;

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<FormState>();
  final FirestoreDatabaseService _firestoreDatabaseService =
      FirestoreDatabaseService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool isVisible = false;
  bool isLoading = false;

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
        'majorInfo': '',
        'clinicLocation': '',
        'clinicName': '',
        'phoneNumber': '',
        'clinicOwner': false,
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
        majorInfo: userData['majorInfo'] as String,
        clinicLocation: userData['clinicLocation'] as String,
        clinicName: userData['clinicName'] as String,
        phoneNumber: userData['phoneNumber'] as String,
        clinicOwner: userData['clinicOwner'] as bool,
        uid: userData['userId'] as String,
        fcmToken: userData['fcmToken'] as String,
      );

      // Navigate to next screen or show success message
      // Add your navigation logic here
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
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              signUp().whenComplete(() {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OnboardingSlider()));
              });
            }
          },
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

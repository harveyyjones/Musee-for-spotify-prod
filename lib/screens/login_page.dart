import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spotify_project/Helpers/helpers.dart';
import 'package:spotify_project/main.dart';
import 'package:spotify_project/screens/register_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isVisible = false;
  late FirebaseAuth auth;
  bool isLoading = false;

  @override
  void initState() {
    auth = FirebaseAuth.instance;
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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
                      "Welcome Back",
                      style: GoogleFonts.poppins(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Sign in to continue!",
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        color: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 48.h),
                    _buildTextField("Email", emailController, Icons.email),
                    SizedBox(height: 24.h),
                    _buildTextField("Password", passwordController, Icons.lock,
                        isPassword: true),
                    SizedBox(height: 48.h),
                    _buildSignInButton(),
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
        return null;
      },
    );
  }

  bool isValidEmail(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  callSnackbar(String error, [Color? color, VoidCallback? onVisible]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
      //padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      backgroundColor: color ?? Colors.red,
      duration: const Duration(milliseconds: 500),
      onVisible: onVisible,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Text(error, style: const TextStyle(color: Colors.white)),
        ),
      ),
    ));
  }

  Widget _buildSignInButton() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              setState(() => isLoading = true);
              try {
                var userCredential = await auth.signInWithEmailAndPassword(
                    email: emailController.text,
                    password: passwordController.text);
               
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => Home()),
                      (route) => false);
                  firestoreDatabaseService.saveUserFCMToken();
                
              } on FirebaseAuthException catch (e) {
                switch (e.code) {
                  case "wrong-password":
                    callSnackbar("Wrong password.");
                    break;
                  case "user-not-found":
                    callSnackbar("Wrong E Mail");
                    break;
                  case "too-many-requests":
                    callSnackbar("Please try a few seconds later");
                    break;
                  default:
                    callSnackbar("An error occurred");
                }
              } finally {
                setState(() => isLoading = false);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(vertical: 16.h),
            minimumSize: Size(double.infinity, 50.h),
          ),
          child: Text(
            "Sign In",
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegisterPage()),
          ),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 16.sp,
              ),
              children: const [
                TextSpan(text: "Don't have an account? "),
                TextSpan(
                  text: "Sign up",
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
}

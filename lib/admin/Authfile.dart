// ignore_for_file: file_names, deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafe/admin/adminscreen.dart';


class Authfile extends StatefulWidget {
  const Authfile({super.key});

  @override
  State<Authfile> createState() => _AuthfileState();
}

class _AuthfileState extends State<Authfile> {
  bool isPasswordVisible = false;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> loginWithSupabase() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Platform.isIOS
                      ? const CupertinoActivityIndicator(radius: 12)
                      : CircularProgressIndicator(color: Colors.blue.shade700),
                  SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      "Verifying User...",
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      await Future.delayed(Duration(seconds: 5));

      Navigator.pop(context); // Close dialog

      if (res.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );

        // used as sharedpreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAdminLoggedIn', true);
        Navigator.pushReplacementNamed(context, '/admindash');



        // ignore: avoid_print
        print("Login successful");
      } else {
        _showError("Invalid credentials.");
      }
    } catch (e) {
      Navigator.pop(context); // Close dialog
      _showError("Login Failed: ${e.toString()}");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double responsiveFont(double size) => screenWidth * (size / 375);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: screenHeight * 0.08),

            /// Logo
            Center(
              child: Image.asset(
                'assets/logo.png',
                width: screenWidth * 0.35,
                height: screenWidth * 0.35,
              ),
            ),

            SizedBox(height: screenHeight * 0.01),
            Column(
              children: [
                Text(
                  "Secure Access",
                  style: GoogleFonts.inter(
                    fontSize: responsiveFont(20),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Login to manage incident reports",
                  style: GoogleFonts.inter(
                    fontSize: responsiveFont(13),
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.05),

            /// Form Container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  /// Email Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Email Address",
                          style: GoogleFonts.inter(
                            fontSize: responsiveFont(14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextField(
                        controller: emailController,
                        cursorColor: Colors.blue.shade700,
                        decoration: InputDecoration(
                          fillColor: Colors.grey[100],
                          filled: true,
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: "Enter Email",
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: responsiveFont(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.black12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.blue.shade700,
                              width: 2,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  /// Password Field with Hide/Show
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Password",
                          style: GoogleFonts.inter(
                            fontSize: responsiveFont(14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        cursorColor: Colors.blue.shade700,
                        decoration: InputDecoration(
                          fillColor: Colors.grey[100],
                          filled: true,
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                          hintText: "Enter Password",
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: responsiveFont(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.black12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.blue.shade700,
                              width: 2,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.050),
                  SizedBox(
                    width: screenWidth * 0.7,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: loginWithSupabase,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, color: Colors.white),
                          SizedBox(width: screenHeight * 0.010),
                          Text(
                            "Sign In",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentAuth extends StatefulWidget {
  const StudentAuth({super.key});

  @override
  State<StudentAuth> createState() => _StudentAuthState();
}

class _StudentAuthState extends State<StudentAuth> {
  bool isLogin = true; // Toggle between Login and Registration
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameController = TextEditingController();
  final studentIdController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    studentIdController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ================= SUPABASE AUTH =================

  Future<void> handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    // Loading Popup Dialog
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
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    isLogin ? "Verifying Student..." : "Creating Account...",
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final supabase = Supabase.instance.client;

      if (isLogin) {
        // Sign In
        final res = await supabase.auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        Navigator.pop(context); // Close loading dialog

        if (res.user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isStudentLoggedIn', true);
          await prefs.setBool('isAdminLoggedIn', false);

          _showSuccess("Login Successful");

          Navigator.pushReplacementNamed(context, '/student');
        } else {
          _showError("Invalid credentials.");
        }
      } else {
        // Registration
        final res = await supabase.auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          data: {
            'name': nameController.text.trim(),
            'student_id': studentIdController.text.trim(),
            'role': 'student',
          },
        );

        Navigator.pop(context); // Close loading dialog

        if (res.user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isStudentLoggedIn', true);
          await prefs.setBool('isAdminLoggedIn', false);

          _showSuccess("Registration Successful");

          Navigator.pushReplacementNamed(context, '/student');
        } else {
          _showError("Registration failed. Please try again.");
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double responsiveFont(double size) => screenWidth * (size / 375);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// Logo
                  Center(
                    child: Image.asset(
                      'assets/logo.png',
                      width: screenWidth * 0.28,
                      height: screenWidth * 0.28,
                    ),
                  ),
                  const SizedBox(height: 10),

                  /// Header Title
                  Text(
                    isLogin ? "Welcome Back" : "Create Student Account",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: responsiveFont(22),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isLogin
                        ? "Log in to secure university incident reporting"
                        : "Register to submit incident reports safely",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: responsiveFont(12),
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 25),

                  /// Registration fields only
                  if (!isLogin) ...[
                    /// Name Field
                    Text(
                      "Full Name",
                      style: GoogleFonts.inter(
                        fontSize: responsiveFont(13),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameController,
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? "Please enter your name" : null,
                      decoration: _buildInputDecoration(
                        hintText: "Enter Full Name",
                        prefixIcon: Icons.person_outline,
                        responsiveFont: responsiveFont,
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Student ID Field
                    Text(
                      "Student ID",
                      style: GoogleFonts.inter(
                        fontSize: responsiveFont(13),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: studentIdController,
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? "Please enter Student ID" : null,
                      decoration: _buildInputDecoration(
                        hintText: "Enter Student ID",
                        prefixIcon: Icons.badge_outlined,
                        responsiveFont: responsiveFont,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  /// Email Field
                  Text(
                    "Email Address",
                    style: GoogleFonts.inter(
                      fontSize: responsiveFont(13),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter your email";
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return "Please enter a valid email address";
                      }
                      return null;
                    },
                    decoration: _buildInputDecoration(
                      hintText: "Enter Email Address",
                      prefixIcon: Icons.email_outlined,
                      responsiveFont: responsiveFont,
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Password Field
                  Text(
                    "Password",
                    style: GoogleFonts.inter(
                      fontSize: responsiveFont(13),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your password";
                      }
                      if (value.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                    decoration: _buildInputDecoration(
                      hintText: "Enter Password",
                      prefixIcon: Icons.lock_outline,
                      responsiveFont: responsiveFont,
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Confirm Password Field (Registration Only)
                  if (!isLogin) ...[
                    Text(
                      "Confirm Password",
                      style: GoogleFonts.inter(
                        fontSize: responsiveFont(13),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: !isConfirmPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please confirm your password";
                        }
                        if (value != passwordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                      decoration: _buildInputDecoration(
                        hintText: "Re-enter Password",
                        prefixIcon: Icons.lock_outline,
                        responsiveFont: responsiveFont,
                        suffixIcon: IconButton(
                          icon: Icon(
                            isConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              isConfirmPasswordVisible = !isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 15),

                  /// Submit Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      onPressed: isLoading ? null : handleAuth,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isLogin ? Icons.login_rounded : Icons.person_add_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            isLogin ? "Sign In" : "Sign Up",
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
                  const SizedBox(height: 20),

                  /// Toggle Switch
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isLogin = !isLogin;
                        _formKey.currentState?.reset();
                      });
                    },
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: responsiveFont(12.5),
                          color: Colors.grey[700],
                        ),
                        children: [
                          TextSpan(
                            text: isLogin
                                ? "Don't have a student account? "
                                : "Already have a student account? ",
                          ),
                          TextSpan(
                            text: isLogin ? "Register Here" : "Login Here",
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required double Function(double) responsiveFont,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      fillColor: Colors.grey[50],
      filled: true,
      prefixIcon: Icon(prefixIcon, color: Colors.grey[600], size: 22),
      suffixIcon: suffixIcon,
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: responsiveFont(12.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.blue.shade700,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
    );
  }
}

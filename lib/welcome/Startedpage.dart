// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Startedpage extends StatelessWidget {
  const Startedpage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double responsiveFont(double size) => screenWidth * (size / 375); // base 375

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

                /// App Title
                Column(
                  children: [
                    Text(
                      "UniSafe",
                      style: GoogleFonts.inter(
                        fontSize: responsiveFont(20),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "University Incident Reporting",
                      style: GoogleFonts.inter(
                        fontSize: responsiveFont(13),
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.05),

                /// Student Button
                buildRoleCard(
                  context: context,
                  screenWidth: screenWidth,
                  title: "Continue as Student",
                  subtitle: "Report incidents anonymously",
                  icon: Icons.person_outlined,
                  onTap: () {
                    Navigator.pushNamed(context, '/student');
                  },
                ),

                /// Admin Button
                buildRoleCard(
                  context: context,
                  screenWidth: screenWidth,
                  title: "Admin Login",
                  subtitle: "Manage and review reports",
                  icon: Icons.security_outlined,
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final isAdminLoggedIn =
                        prefs.getBool('isAdminLoggedIn') ?? false;

                    if (isAdminLoggedIn) {
                      Navigator.pushReplacementNamed(context, '/admindash');
                    } else {
                      Navigator.pushNamed(context, '/adminauth');
                    }
                  },
                ),

                SizedBox(height: screenHeight * 0.25),

                /// Footer
                Text(
                  "Secure • Anonymous • Confidential",
                  style: GoogleFonts.inter(
                    fontSize: responsiveFont(12),
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Custom Role Card Widget with responsive fonts/icons
  Widget buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required double screenWidth,
    required VoidCallback onTap,
  }) {
    double iconSize = screenWidth * 0.08; // e.g., 30 on 375 width
    double titleSize = screenWidth * 0.035;
    double subtitleSize = screenWidth * 0.030;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon inside circle
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withOpacity(0.1),
                ),
                child: Icon(icon, size: iconSize, color: Colors.blue.shade700),
              ),
              SizedBox(width: 16),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(Icons.arrow_forward_ios,
                  size: iconSize * 0.6, color: Colors.blue.shade700),
            ],
          ),
        ),
      ),
    );
  }

  /// Custom SnackBar Function
  void showCustomSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

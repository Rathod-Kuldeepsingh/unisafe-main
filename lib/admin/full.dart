import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IncidentDetailPage extends StatelessWidget {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String location;
  final String timeAgo;

  const IncidentDetailPage({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
     final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double responsiveFont(double size) => screenWidth * (size / 375);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Incident Detail",
          style: GoogleFonts.inter(
            fontSize: responsiveFont(20),
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
             SizedBox(height: screenHeight*0.020),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: responsiveFont(20),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight*0.010),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                SizedBox(width: screenWidth*0.010),
                Flexible(
                  child: Text(
                    location,
                    style: GoogleFonts.inter(color: Colors.grey.shade700),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight*0.010),
            Text(
              "Reported $timeAgo",
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
            Divider(height: screenHeight*0.040),
            Text(
              description,
              style: GoogleFonts.inter(fontSize: responsiveFont(15), height: 1.5,color: Colors.black,fontWeight: FontWeight.w600),
            ),
            SizedBox(height: screenHeight*0.010),
            Text(
              "Incident ID: $id",
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

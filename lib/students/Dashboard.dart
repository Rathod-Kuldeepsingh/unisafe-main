// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  File? _imageFile;
  String? _uploadedImageUrl;
  bool isUploading = false;
  bool isLoading = false;

  final picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          isUploading = true;
        });
        await _uploadToSupabase(_imageFile!);
      }
    } catch (e) {
      print("❌ Error picking image: $e");
    }
  }

  Future<void> _uploadToSupabase(File file) async {
    try {
      final fileName =
          "incident_${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}";

      final storage = Supabase.instance.client.storage.from('incident-reports');

      await storage.upload(fileName, file);
      final publicUrl = storage.getPublicUrl(fileName);

      setState(() {
        _uploadedImageUrl = publicUrl;
        isUploading = false;
      });
    } catch (e) {
      setState(() => isUploading = false);
      print(e.toString());
    }
  }

  Future<void> _submitReport({
    required String imageUrl,
    required String description,
    required String location,
    required String title,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.from('incident_reports').insert({
        'title': title,
        'image_url': imageUrl,
        'description': description,
        'location': location,
        // 'created_at' will auto-fill from Supabase
      });

      if (response == null) {
        print("✅ Report submitted successfully.");
        setState(() {
          _imageFile = null;
          _uploadedImageUrl = null;
          titleController.clear();
          descriptionController.clear();
          locationController.clear();
        });

        // ✅ Show popup after success
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 30,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Report Submitted!",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Your incident report has been successfully uploaded. Thank you for your contribution.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(
                        "Okay",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (error) {
      print("error submitting report: $error");
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoading = true;
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled.');
        return;
      }

      // Check location permission
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions are permanently denied.');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convert lat/long to human-readable address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks[0];
      String address =
          "${place.name}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}";

      setState(() {
        locationController.text = address;
      });
    } catch (e) {
      _showError("Error fetching location: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double responsiveFont(double size) => screenWidth * (size / 375);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue.shade700,
        title: Text(
          "Report",
          style: GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: responsiveFont(24),
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.01),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 10),
                  child: Text(
                    'Add Incident Photo',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: responsiveFont(14),
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(2),
              child: Container(
                color: Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _imageFile != null
                            ? Image.file(
                                _imageFile!,
                                height: 200,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      SizedBox(height: screenHeight * 0.030),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                              label: Text(
                                "Camera",
                                style: GoogleFonts.inter(
                                  textStyle: TextStyle(
                                    fontSize: responsiveFont(14),
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.030),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(
                                Icons.photo_library,
                                color: Colors.white,
                              ),
                              label: Text(
                                "Gallery",
                                style: GoogleFonts.inter(
                                  textStyle: TextStyle(
                                    fontSize: responsiveFont(14),
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isUploading) ...[
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(color: Colors.teal),
                      ],
                      if (_uploadedImageUrl != null) ...[
                        const SizedBox(height: 20),
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Uploaded Successfully",
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: responsiveFont(14),
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.030),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 10),
                  child: Text(
                    'Report Title',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: responsiveFont(14),
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    height: screenWidth * 0.18,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: TextField(
                        cursorColor: Colors.blue.shade700,
                        controller: titleController,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter the Report Title",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        'Incident Description',
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: responsiveFont(14),
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        height:
                            screenHeight *
                            0.15, // ⬅️ Makes the box visually large
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: TextField(
                            cursorColor: Colors.blue.shade700,
                            controller: descriptionController,
                            maxLines: null, // allows unlimited lines
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            style: GoogleFonts.inter(
                              fontSize: responsiveFont(13),
                            ),
                            decoration: InputDecoration(
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              hintText: "Describe the Incident Details....",
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10, top: 10),
                      child: Text(
                        'Location',
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: responsiveFont(14),
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10, bottom: 4),
                      child: ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          "Use My Location",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    isLoading
                        ? Platform.isIOS
                              ? const CupertinoActivityIndicator(radius: 12)
                              :  CircularProgressIndicator(
                                  color: Colors.blue.shade700,
                                  strokeWidth: 3,
                                )
                        : locationController.text.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              top: 8,
                              right: 12,
                            ),
                            child: Text(
                              locationController.text,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          )
                        : SizedBox.shrink(),
                  ],
                ),

                SizedBox(height: screenHeight * 0.03),
                ElevatedButton(
                  onPressed: () {
                    if (_uploadedImageUrl != null &&
                        descriptionController.text.isNotEmpty &&
                        locationController.text.isNotEmpty) {
                      _submitReport(
                        title: titleController.text,
                        imageUrl: _uploadedImageUrl!,
                        description: descriptionController.text,
                        location: locationController.text,
                      );
                    } else {
                      _showError("Please Feild all Details");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Submit Report",
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

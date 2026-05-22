// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
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

  // GPS coordinates
  double? latitude;
  double? longitude;

  final picker = ImagePicker();

  // ================= SUCCESS MESSAGE =================

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ================= ERROR MESSAGE =================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ================= PICK IMAGE =================

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          isUploading = true;
        });

        await _uploadToSupabase(_imageFile!);
      }
    } catch (e) {
      print("❌ Error picking image: $e");
      _showError("Failed to pick image");
    }
  }

  // ================= UPLOAD IMAGE =================

  Future<void> _uploadToSupabase(File file) async {
  try {
    setState(() {
      isUploading = true;
    });

    final supabase = Supabase.instance.client;

    // EXACT bucket name
    const bucketName = 'incident-reports';

    // Unique image name
    final fileName =
        "incident_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}";

    print("Uploading file: $fileName");

    // Upload image to Supabase Storage
    await supabase.storage
        .from(bucketName)
        .upload(
          fileName,
          file,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ),
        );

    // Generate public image URL
    final imageUrl = supabase.storage
        .from(bucketName)
        .getPublicUrl(fileName);

    print("IMAGE URL:");
    print(imageUrl);

    // Save URL
    setState(() {
      _uploadedImageUrl = imageUrl;
      isUploading = false;
    });

    _showSuccess(
      "Image uploaded successfully",
    );
  } on StorageException catch (e) {
    setState(() {
      isUploading = false;
    });

    print("STORAGE ERROR:");
    print(e.message);

    _showError(
      e.message,
    );
  } catch (e) {
    setState(() {
      isUploading = false;
    });

    print("UPLOAD ERROR:");
    print(e);

    _showError(
      "Failed to upload image",
    );
  }
}

  // ================= GET LOCATION =================

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Check GPS enabled
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showError("Please enable location services");

        await Geolocator.openLocationSettings();

        setState(() {
          isLoading = false;
        });

        return;
      }

      // Check permission
      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showError("Location permission denied");

        setState(() {
          isLoading = false;
        });

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showError(
          "Permission permanently denied. Enable from settings.",
        );

        await Geolocator.openAppSettings();

        setState(() {
          isLoading = false;
        });

        return;
      }

      // Get GPS coordinates
      Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Save coordinates
      latitude = position.latitude;
      longitude = position.longitude;

      print("Latitude: $latitude");
      print("Longitude: $longitude");

      // Convert to address
      List<Placemark> placemarks =
          await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;

      String address =
          "${place.street}, "
          "${place.locality}, "
          "${place.administrativeArea}, "
          "${place.postalCode}";

      setState(() {
        locationController.text = address;
        isLoading = false;
      });

      _showSuccess("Location fetched successfully");
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      print("Location Error: $e");

      _showError("Failed to get location");
    }
  }

  // ================= SUBMIT REPORT =================

  Future<void> _submitReport({
    required String imageUrl,
    required String description,
    required String location,
    required String title,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      print("Lat: $latitude");
      print("Lng: $longitude");

      await supabase.from('incident_reports').insert({
        'title': title,
        'image_url': imageUrl,
        'description': description,
        'location': location,

        // GPS coordinates
        'latitude': latitude,
        'longitude': longitude,
      });

      print("✅ Report submitted successfully.");

      setState(() {
        _imageFile = null;
        _uploadedImageUrl = null;

        titleController.clear();
        descriptionController.clear();
        locationController.clear();

        latitude = null;
        longitude = null;
      });

      // SUCCESS POPUP

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
                  "Your incident report has been successfully uploaded.",
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
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
    } catch (error) {
      print("error submitting report: $error");

      _showError("Failed to submit report");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight =
        MediaQuery.of(context).size.height;

    final screenWidth =
        MediaQuery.of(context).size.width;

    double responsiveFont(double size) =>
        screenWidth * (size / 375);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Logout',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'Are you sure you want to log out?',
                    style: GoogleFonts.inter(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(color: Colors.black87),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await Supabase.instance.client.auth.signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isStudentLoggedIn', false);
                Navigator.pushNamedAndRemoveUntil(context, '/start', (route) => false);
              }
            },
          ),
        ],
      ),

      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildWelcomeBanner(responsiveFont),
            SizedBox(height: screenHeight * 0.01),

            // ================= IMAGE TITLE =================

            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    top: 10,
                  ),
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

            // ================= IMAGE SECTION =================

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
                        borderRadius:
                            BorderRadius.circular(12),
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

                      SizedBox(
                        height: screenHeight * 0.030,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _pickImage(
                                ImageSource.camera,
                              ),
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                              label: Text(
                                "Camera",
                                style: GoogleFonts.inter(
                                  textStyle: TextStyle(
                                    fontSize:
                                        responsiveFont(14),
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.blue.shade700,
                              ),
                            ),
                          ),

                          SizedBox(
                            width: screenWidth * 0.030,
                          ),

                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _pickImage(
                                ImageSource.gallery,
                              ),
                              icon: const Icon(
                                Icons.photo_library,
                                color: Colors.white,
                              ),
                              label: Text(
                                "Gallery",
                                style: GoogleFonts.inter(
                                  textStyle: TextStyle(
                                    fontSize:
                                        responsiveFont(14),
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (isUploading) ...[
                        const SizedBox(height: 20),

                        const CircularProgressIndicator(
                          color: Colors.teal,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ================= TITLE =================

            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: "Report Title",
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // ================= DESCRIPTION =================

            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Incident Description",
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // ================= LOCATION =================

            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(
                Icons.my_location,
                color: Colors.white,
              ),
              label: Text(
                "Use My Location",
                style: GoogleFonts.inter(
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
              ),
            ),

            const SizedBox(height: 10),

            if (isLoading)
              Platform.isIOS
                  ? const CupertinoActivityIndicator(
                      radius: 12,
                    )
                  : CircularProgressIndicator(
                      color: Colors.blue.shade700,
                    ),

            if (locationController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  locationController.text,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                  ),
                ),
              ),

            // ================= LAT LNG VIEW =================

            if (latitude != null && longitude != null)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      "Latitude: $latitude",
                      style: GoogleFonts.inter(),
                    ),
                    Text(
                      "Longitude: $longitude",
                      style: GoogleFonts.inter(),
                    ),
                  ],
                ),
              ),

            SizedBox(height: screenHeight * 0.03),

            // ================= SUBMIT =================

            ElevatedButton(
              onPressed: () {
                if (_uploadedImageUrl != null &&
                    titleController.text.isNotEmpty &&
                    descriptionController
                        .text
                        .isNotEmpty &&
                    locationController
                        .text
                        .isNotEmpty) {
                  _submitReport(
                    title: titleController.text,
                    imageUrl: _uploadedImageUrl!,
                    description:
                        descriptionController.text,
                    location: locationController.text,
                  );
                } else {
                  _showError(
                    "Please fill all details",
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
              ),
              child: Text(
                "Submit Report",
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(double Function(double) responsiveFont) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final name = user?.userMetadata?['name'] ?? 'Student';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome, $name!",
            style: GoogleFonts.inter(
              fontSize: responsiveFont(18),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: GoogleFonts.inter(
              fontSize: responsiveFont(12),
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'dart:ui';

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
  bool isSubmitting = false;
  String? studentNameFromPrefs;

  // GPS coordinates
  double? latitude;
  double? longitude;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkRoleAndLoad();
  }

  Future<void> _checkRoleAndLoad() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.user.userMetadata?['role'] != 'student') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isStudentLoggedIn', false);
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/start', (route) => false);
      }
      return;
    }
    await _loadStudentName();
  }

  Future<void> _loadStudentName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        studentNameFromPrefs = prefs.getString('studentName');
      });
    } catch (e) {
      print("Error loading student name: $e");
    }
  }

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

    setState(() {
      isSubmitting = true;
    });

    try {
      print("Lat: $latitude");
      print("Lng: $longitude");

      final currentUser = supabase.auth.currentUser;
      final inserted = await supabase.from('incident_reports').insert({
        'title': title,
        'image_url': imageUrl,
        'description': description,
        'location': location,

        // GPS coordinates
        'latitude': latitude,
        'longitude': longitude,
        'status': 'Pending',
        'admin_remark': '',
        'student_email': currentUser?.email ?? '',
      }).select();

      print("✅ Report submitted successfully.");

      // Save report ID in SharedPreferences
      if (inserted.isNotEmpty) {
        final newReportId = inserted.first['id'].toString();
        final user = supabase.auth.currentUser;
        if (user != null && user.email != null) {
          final prefs = await SharedPreferences.getInstance();
          final key = 'student_reports_${user.email}';
          List<String> reportIds = prefs.getStringList(key) ?? [];
          reportIds.add(newReportId);
          await prefs.setStringList(key, reportIds);
          print("Saved report ID $newReportId to SharedPreferences under $key");
        }
      }

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
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

   String _resolveStudentName(User? user) {
    if (studentNameFromPrefs != null && studentNameFromPrefs!.trim().isNotEmpty) {
      return studentNameFromPrefs!.trim();
    }
    final metaName = user?.userMetadata?['name'];
    if (metaName != null && metaName.toString().trim().isNotEmpty) {
      return metaName.toString().trim();
    }
    final metaFullName = user?.userMetadata?['full_name'];
    if (metaFullName != null && metaFullName.toString().trim().isNotEmpty) {
      return metaFullName.toString().trim();
    }
    final email = user?.email;
    if (email != null && email.contains('@')) {
      final part = email.split('@').first;
      final words = part.split(RegExp(r'[._-]'));
      final capitalized = words.map((w) {
        if (w.isEmpty) return '';
        return w[0].toUpperCase() + w.substring(1);
      }).join(' ');
      if (capitalized.trim().isNotEmpty) {
        return capitalized.trim();
      }
    }
    return 'Student';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double responsiveFont(double size) => screenWidth * (size / 375);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.indigo.shade800,
        elevation: 0,
        title: Text(
          "UniSafe Report",
          style: GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: responsiveFont(20),
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildWelcomeBanner(responsiveFont),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  // ================= IMAGE PICKER CARD =================
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Incident Photo',
                            style: GoogleFonts.inter(
                              fontSize: responsiveFont(14),
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          if (_imageFile != null)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    _imageFile!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _imageFile = null;
                                        _uploadedImageUrl = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            CustomPaint(
                              painter: DashedBorderPainter(
                                color: Colors.grey.shade300,
                                borderRadius: 16,
                              ),
                              child: Container(
                                height: 160,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 40,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "No image selected",
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Take a picture or select from gallery",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.camera),
                                  icon: Icon(Icons.camera_alt_outlined, size: 18, color: Colors.indigo.shade800),
                                  label: Text(
                                    "Camera",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.indigo.shade800,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(color: Colors.indigo.shade100),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.gallery),
                                  icon: Icon(Icons.photo_library_outlined, size: 18, color: Colors.indigo.shade800),
                                  label: Text(
                                    "Gallery",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.indigo.shade800,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(color: Colors.indigo.shade100),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          if (isUploading) ...[
                            const SizedBox(height: 16),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Uploading image...",
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ================= DETAILS CARD =================
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.assignment_outlined, color: Colors.indigo.shade800, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Incident Details',
                                style: GoogleFonts.inter(
                                  fontSize: responsiveFont(14),
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: titleController,
                            style: GoogleFonts.inter(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: "Incident Title",
                              hintText: "Enter a brief title",
                              prefixIcon: Icon(Icons.edit_note_rounded, color: Colors.indigo.shade800),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.indigo.shade800, width: 1.5),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: descriptionController,
                            maxLines: 4,
                            style: GoogleFonts.inter(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: "Incident Description",
                              hintText: "Provide details of the incident...",
                              prefixIcon: Icon(Icons.description_outlined, color: Colors.indigo.shade800),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              alignLabelWithHint: true,
                              labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.indigo.shade800, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ================= LOCATION CARD =================
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: Colors.indigo.shade800, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Location Details',
                                style: GoogleFonts.inter(
                                  fontSize: responsiveFont(14),
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                              label: Text(
                                "Use My Location",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade800,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          
                          if (isLoading) ...[
                            const SizedBox(height: 16),
                            Center(
                              child: Platform.isIOS
                                  ? const CupertinoActivityIndicator(radius: 12)
                                  : CircularProgressIndicator(color: Colors.indigo.shade800),
                            ),
                          ],
                          
                          if (locationController.text.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.place_rounded, color: Colors.indigo.shade800, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      locationController.text,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          if (latitude != null && longitude != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.indigo.shade100),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.gps_fixed_rounded, size: 14, color: Colors.indigo.shade800),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            "Lat: ${latitude!.toStringAsFixed(5)}",
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.indigo.shade900,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.indigo.shade100),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.gps_fixed_rounded, size: 14, color: Colors.indigo.shade800),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            "Lng: ${longitude!.toStringAsFixed(5)}",
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.indigo.shade900,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // ================= SUBMIT GRADIENT BUTTON =================
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade800, Colors.blue.shade700],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.shade800.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: isSubmitting
                            ? null
                            : () {
                                if (_uploadedImageUrl != null &&
                                    titleController.text.isNotEmpty &&
                                    descriptionController.text.isNotEmpty &&
                                    locationController.text.isNotEmpty) {
                                  _submitReport(
                                    title: titleController.text,
                                    imageUrl: _uploadedImageUrl!,
                                    description: descriptionController.text,
                                    location: locationController.text,
                                  );
                                } else {
                                  _showError(
                                    "Please fill all details and upload an image",
                                  );
                                }
                              },
                        child: Center(
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Submit Incident Report",
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(double Function(double) responsiveFont) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final name = _resolveStudentName(user);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade800, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade800.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, color: Colors.amberAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "Verified Student",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Welcome, $name!",
                  style: GoogleFonts.inter(
                    fontSize: responsiveFont(20),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: responsiveFont(12),
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/studentprofile');
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(
                  Icons.person_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double borderRadius;

  DashedBorderPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.5,
    this.gap = 4.0,
    this.dash = 6.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);

    final dashPath = _buildDashPath(path, dash, gap);
    canvas.drawPath(dashPath, paint);
  }

  Path _buildDashPath(Path source, double dashWidth, double gapWidth) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashWidth : gapWidth;
        if (distance + len >= metric.length) {
          if (draw) {
            dest.addPath(
              metric.extractPath(distance, metric.length),
              Offset.zero,
            );
          }
          break;
        }
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafe/admin/Admindashboardscreen.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, dynamic>> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('incident_reports')
        .select('*')
        .order('created_at', ascending: false);

    setState(() {
      reports = response.map<Map<String, dynamic>>((report) {
        return {
          "id": report["id"] ?? "",
          "title": report["title"] ?? "Untitled Report",
          "description": report["description"] ?? "",
          "imageUrl": report["image_url"] ?? "",
          "location": report["location"] ?? "",
          "created_at": report["created_at"] ?? "",
          "isNew": report["isNew"] ?? false,
        };
      }).toList();

      isLoading = false;
    });
  }

  Future<void> deleteReport(int index) async {
    final supabase = Supabase.instance.client;
    final report = reports[index];
    final id = report["id"];

    try {
      await supabase.from('incident_reports').delete().eq('id', id);

      setState(() {
        reports.removeAt(index);
      });
      _showError("succesfully delete Report");
    } catch (e) {
      _showError("Failed to delete Report");
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double responsiveFont(double size) => screenWidth * (size / 375);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text("Exit App"),
              content: const Text("Are you sure you want to exit the app?"),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.inter(
                      fontSize: responsiveFont(14),
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => exit(0),

                  child: Text(
                    "Exit",
                    style: GoogleFonts.inter(
                      fontSize: responsiveFont(14),
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.blue.shade700,
          elevation: 1,
          title: Text(
            'Admin Dashboard',
            style: GoogleFonts.inter(
              fontSize: responsiveFont(20),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 25,
                  ),
                  onPressed: () {},
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, "/admin");
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage("assets/admin1.png"),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: isLoading
            ? Center(
                child: Platform.isIOS
                    ? const CupertinoActivityIndicator(radius: 12)
                    : const CircularProgressIndicator(color: Colors.blue),
              )
            : RefreshIndicator(
                backgroundColor: Colors.white,
                color: Colors.blue.shade700,
                onRefresh: fetchReports,
                child: reports.isEmpty
                    ? ListView(
                        children: const [
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text("No reports found."),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          return IncidentCard(
                            id: report["id"],
                            title: report["title"],
                            description: report["description"],
                            imageUrl: report["imageUrl"],
                            location: report["location"],
                            isNew: report["isNew"],
                            timeAgo: report["created_at"],
                            onDelete: () {
                              deleteReport(index);
                            },
                          );
                        },
                      ),
              ),
      ),
    );
  }
}

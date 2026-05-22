// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafe/admin/Admindashboardscreen.dart';
import 'dialog_helper.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() =>
      _AdminDashboardState();
}

class _AdminDashboardState
    extends State<AdminDashboard> {
  List<Map<String, dynamic>> reports = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRoleAndLoad();
  }

  Future<void> _checkRoleAndLoad() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.user.userMetadata?['role'] == 'student') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAdminLoggedIn', false);
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/start', (route) => false);
      }
      return;
    }
    fetchReports();
  }

  // ================= FETCH REPORTS =================

  Future<void> fetchReports() async {
    try {
      final supabase =
          Supabase.instance.client;

      final response = await supabase
          .from('incident_reports')
          .select('*')
          .or('verified.eq.false,verified.is.null')
          .order(
            'created_at',
            ascending: false,
          );

      setState(() {
        reports = response
            .map<Map<String, dynamic>>(
              (report) {
                return {
                  "id":
                      report["id"] ?? 0,

                  "title":
                      report["title"] ??
                          "Untitled",

                  "description":
                      report[
                              "description"] ??
                          "",

                  "imageUrl":
                      report["image_url"] ??
                          "",

                  "location":
                      report["location"] ??
                          "",

                  "created_at":
                      report[
                              "created_at"] ??
                          "",

                  "latitude":
                      report["latitude"],

                  "longitude":
                      report["longitude"],

                  "isNew":
                      report["isNew"] ??
                          false,

                  "status":
                      report["status"] ??
                          "Pending",

                  "adminRemark":
                      report["admin_remark"] ??
                          "",
                };
              },
            )
            .toList();

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      _showSnackBar(
        "Failed to fetch reports",
        type: SnackBarType.error,
      );

      print(e);
    }
  }

  // ================= DELETE REPORT =================

  Future<void> deleteReport(
    int index,
  ) async {
    final supabase = Supabase.instance.client;
    final report = reports[index];
    final id = report["id"];

    try {
      final response = await supabase
          .from('incident_reports')
          .update({'verified': true})
          .eq('id', id)
          .select();

      print("Delete (verify) response: $response");
      if (response.isEmpty) {
        throw Exception("No rows were updated. Check Row Level Security policies.");
      }

      setState(() {
        reports.removeAt(index);
      });

      _showSnackBar(
        "Report deleted successfully",
        type: SnackBarType.success,
      );
    } catch (e) {
      _showSnackBar(
        "Failed to delete report: $e",
        type: SnackBarType.error,
      );
      print(e);
    }
  }

  // ================= SNACKBAR =================

  void _showSnackBar(String message, {SnackBarType type = SnackBarType.info}) {
    showCustomSnackBar(
      context,
      message: message,
      type: type,
    );
  }

  // ================= FORMAT DATE =================

  String formatDate(String rawDate) {
    try {
      final date =
          DateTime.parse(rawDate);

      return
          "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight =
        MediaQuery.of(context).size.height;

    final screenWidth =
        MediaQuery.of(context).size.width;

    double responsiveFont(
      double size,
    ) =>
        screenWidth * (size / 375);

    return PopScope(
      canPop: false,

      onPopInvoked: (didPop) async {
        if (!didPop) {
          showCustomConfirmDialog(
            context,
            title: "Exit App",
            content: "Are you sure you want to exit the app?",
            confirmLabel: "Exit",
            confirmColor: Colors.redAccent,
            icon: Icons.exit_to_app_rounded,
            onConfirm: () => exit(0),
          );
        }
      },

      child: Scaffold(
        backgroundColor:
            Colors.grey.shade100,

        // ================= APPBAR =================

        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 4,
          shadowColor: Colors.blue.shade900.withOpacity(0.15),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade800, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          title: Text(
            "Admin Dashboard",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: responsiveFont(20),
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    "/admin",
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundImage: AssetImage(
                      "assets/admin1.png",
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // ================= BODY =================

        body: isLoading
            ? Center(
                child: Platform.isIOS
                    ? const CupertinoActivityIndicator(
                        radius: 14,
                      )
                    : CircularProgressIndicator(
                        color: Colors
                            .blue.shade700,
                      ),
              )

            : RefreshIndicator(
                onRefresh: fetchReports,

                color:
                    Colors.blue.shade700,

                backgroundColor:
                    Colors.white,

                child: reports.isEmpty

                    // ================= EMPTY =================

                    ? ListView(
                        children: [
                          SizedBox(
                            height:
                                screenHeight *
                                    0.18,
                          ),

                          Icon(
                            Icons
                                .report_problem_outlined,
                            size: 90,
                            color:
                                Colors.grey
                                    .shade400,
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          Center(
                            child: Text(
                              "No Reports Found",

                              style:
                                  GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight
                                        .bold,

                                color: Colors
                                    .black87,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Center(
                            child: Text(
                              "All incident reports will appear here",

                              style:
                                  GoogleFonts.inter(
                                color: Colors
                                    .grey
                                    .shade600,
                              ),
                            ),
                          ),
                        ],
                      )

                    // ================= REPORTS =================

                    : Column(
                        children: [
                          // ================= STATS =================

                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                  color: Colors.indigo.shade800.withOpacity(0.3),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.insights_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${reports.length}",
                                        style: GoogleFonts.inter(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Total Incident Reports",
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withOpacity(0.85),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ================= LIST =================

                          Expanded(
                            child: ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),

                              padding:
                                  const EdgeInsets.only(
                                bottom: 20,
                              ),

                              itemCount:
                                  reports.length,

                              itemBuilder:
                                  (
                                context,
                                index,
                              ) {
                                final report =
                                    reports[index];

                                return IncidentCard(
                                  id:
                                      report["id"],

                                  title:
                                      report[
                                          "title"],

                                  description:
                                      report[
                                          "description"],

                                  imageUrl:
                                      report[
                                          "imageUrl"],

                                  location:
                                      report[
                                          "location"],

                                  timeAgo:
                                      formatDate(
                                    report[
                                        "created_at"],
                                  ),

                                  latitude:
                                      report[
                                          "latitude"],

                                  longitude:
                                      report[
                                          "longitude"],

                                  isNew:
                                      report[
                                          "isNew"],

                                  status:
                                      report[
                                          "status"],

                                  adminRemark:
                                      report[
                                          "adminRemark"],

                                  onDelete:
                                      () {
                                    deleteReport(
                                      index,
                                    );
                                  },

                                  onRefresh:
                                      fetchReports,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }
}
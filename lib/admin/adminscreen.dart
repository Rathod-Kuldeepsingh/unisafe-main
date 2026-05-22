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
      );

      print(e);
    }
  }

  // ================= DELETE REPORT =================

  Future<void> deleteReport(
    int index,
  ) async {
    final supabase =
        Supabase.instance.client;

    final report = reports[index];

    final id = report["id"];

    try {
      await supabase
          .from('incident_reports')
          .delete()
          .eq('id', id);

      setState(() {
        reports.removeAt(index);
      });

      _showSnackBar(
        "Report deleted successfully",
      );
    } catch (e) {
      _showSnackBar(
        "Failed to delete report",
      );

      print(e);
    }
  }

  // ================= SNACKBAR =================

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
            Colors.blue.shade700,

        behavior:
            SnackBarBehavior.floating,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),

        margin: const EdgeInsets.all(
          14,
        ),

        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight:
                FontWeight.w500,
          ),
        ),
      ),
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
          await showDialog(
            context: context,

            builder: (context) {
              return AlertDialog(
                backgroundColor:
                    Colors.white,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                title: Text(
                  "Exit App",
                  style:
                      GoogleFonts.inter(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                content: Text(
                  "Are you sure you want to exit the app?",
                  style:
                      GoogleFonts.inter(),
                ),

                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },

                    child: Text(
                      "Cancel",
                      style:
                          GoogleFonts.inter(
                        color:
                            Colors.black87,
                      ),
                    ),
                  ),

                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.red,
                    ),

                    onPressed: () {
                      exit(0);
                    },

                    child: Text(
                      "Exit",
                      style:
                          GoogleFonts.inter(
                        color:
                            Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      },

      child: Scaffold(
        backgroundColor:
            Colors.grey.shade100,

        // ================= APPBAR =================

        appBar: AppBar(
          automaticallyImplyLeading:
              false,

          elevation: 0,

          backgroundColor:
              Colors.blue.shade700,

          title: Text(
            "Admin Dashboard",

            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
              fontSize:
                  responsiveFont(20),
            ),
          ),

          actions: [
            IconButton(
              onPressed: fetchReports,

              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.only(
                right: 14,
              ),

              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    "/admin",
                  );
                },

                child: const CircleAvatar(
                  radius: 18,
                  backgroundImage:
                      AssetImage(
                    "assets/admin1.png",
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
                            margin:
                                const EdgeInsets.all(
                              14,
                            ),

                            padding:
                                const EdgeInsets.all(
                              18,
                            ),

                            decoration:
                                BoxDecoration(
                              gradient:
                                  LinearGradient(
                                colors: [
                                  Colors
                                      .blue
                                      .shade700,

                                  Colors
                                      .blue
                                      .shade500,
                                ],
                              ),

                              borderRadius:
                                  BorderRadius.circular(
                                22,
                              ),
                            ),

                            child: Row(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.all(
                                    16,
                                  ),

                                  decoration:
                                      BoxDecoration(
                                    color: Colors
                                        .white
                                        .withOpacity(
                                      0.2,
                                    ),

                                    shape:
                                        BoxShape.circle,
                                  ),

                                  child:
                                      const Icon(
                                    Icons
                                        .report_gmailerrorred_rounded,

                                    color:
                                        Colors.white,

                                    size:
                                        34,
                                  ),
                                ),

                                const SizedBox(
                                  width: 18,
                                ),

                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [
                                    Text(
                                      "${reports.length}",

                                      style:
                                          GoogleFonts.inter(
                                        fontSize:
                                            28,

                                        fontWeight:
                                            FontWeight.bold,

                                        color: Colors
                                            .white,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      "Total Incident Reports",

                                      style:
                                          GoogleFonts.inter(
                                        color: Colors
                                            .white
                                            .withOpacity(
                                          0.9,
                                        ),

                                        fontWeight:
                                            FontWeight.w500,
                                      ),
                                    ),
                                  ],
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

                                  onDelete:
                                      () {
                                    deleteReport(
                                      index,
                                    );
                                  },
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
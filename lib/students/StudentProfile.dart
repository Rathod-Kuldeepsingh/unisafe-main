import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  bool isLoading = true;
  String studentName = 'Student';
  String studentId = 'N/A';
  String studentEmail = '';
  int totalComplaints = 0;
  List<Map<String, dynamic>> incidentHistory = [];
  int pendingCount = 0;
  int acceptedCount = 0;
  int rejectedCount = 0;
int points = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileAndHistory();
  }

  Future<void> _loadProfileAndHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/start', (route) => false);
        }
        return;
      }

      // Load Profile Data from metadata and SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('studentName');
      
      setState(() {
        studentEmail = user.email ?? '';
        studentName = savedName ?? 
                      user.userMetadata?['name'] ?? 
                      user.userMetadata?['full_name'] ?? 
                      'Student';
        studentId = user.userMetadata?['student_id'] ?? 'N/A';
      });

      // Load Complaint History
      final key = 'student_reports_$studentEmail';
      final reportIds = prefs.getStringList(key) ?? [];
      
      if (reportIds.isEmpty) {
        // Still fetch reward points from DB even if no complaints
        int dbPoints = 0;
        if (studentEmail.isNotEmpty) {
          final ptRows = await supabase
              .from('incident_reports')
              .select('student_points')
              .eq('student_email', studentEmail)
              .not('student_points', 'is', null)
              .order('student_points', ascending: false)
              .limit(1);
          if (ptRows.isNotEmpty) {
            dbPoints = (ptRows.first['student_points'] ?? 0) as int;
          }
        }
        setState(() {
          totalComplaints = 0;
          incidentHistory = [];
          pendingCount = 0;
          acceptedCount = 0;
          rejectedCount = 0;
          points = dbPoints;
          isLoading = false;
        });
        return;
      }

      // Fetch reports matching the IDs from Supabase
      final response = await supabase
          .from('incident_reports')
          .select('*')
          .inFilter('id', reportIds.map((id) => int.parse(id)).toList())
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> reports = List<Map<String, dynamic>>.from(response);

      int pending = 0;
      int accepted = 0;
      int rejected = 0;

      for (var report in reports) {
        final status = (report['status'] ?? 'Pending').toString().toLowerCase();
        if (status == 'approved' || status == 'accepted') {
          accepted++;
        } else if (status == 'rejected') {
          rejected++;
        } else {
          pending++;
        }
      }

      setState(() {
        totalComplaints = reports.length;
        incidentHistory = reports;
        pendingCount = pending;
        acceptedCount = accepted;
        rejectedCount = rejected;
        isLoading = false;
      });

      // Fetch reward points from incident_reports column
      if (studentEmail.isNotEmpty) {
        final ptRows = await supabase
            .from('incident_reports')
            .select('student_points')
            .eq('student_email', studentEmail)
            .not('student_points', 'is', null)
            .order('student_points', ascending: false)
            .limit(1);
        if (mounted) {
          setState(() {
            points = ptRows.isNotEmpty
                ? (ptRows.first['student_points'] ?? 0) as int
                : 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading student profile/history: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Unknown date';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (_) {
      return dateStr;
    }
  }

  String _getInitials(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return 'S';
    final parts = cleanName.split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Logout',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.inter(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isStudentLoggedIn', false);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/start', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double responsiveFont(double size) => screenWidth * (size / 375);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.indigo.shade800,
        elevation: 0,
        title: Text(
          "Student Profile",
          style: GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: responsiveFont(18),
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: Platform.isIOS
                  ? const CupertinoActivityIndicator(radius: 15)
                  : CircularProgressIndicator(color: Colors.indigo.shade800),
            )
          : RefreshIndicator(
              color: Colors.indigo.shade800,
              onRefresh: _loadProfileAndHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Profile Header Banner
                    _buildHeaderBanner(responsiveFont),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Details Card
                          _buildDetailsCard(responsiveFont),
                          const SizedBox(height: 16),

                          // Status Highlight Card
                          _buildStatusHighlightCard(responsiveFont),
                          const SizedBox(height: 16),
_buildPointsCard(responsiveFont),
const SizedBox(height: 16),

                          // History Title & Counter
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Complaint History",
                                style: GoogleFonts.inter(
                                  fontSize: responsiveFont(16),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.indigo.shade100),
                                ),
                                child: Text(
                                  "$totalComplaints Raised",
                                  style: GoogleFonts.inter(
                                    fontSize: responsiveFont(12),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // History List
                          if (incidentHistory.isEmpty)
                            _buildEmptyState(responsiveFont)
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: incidentHistory.length,
                              itemBuilder: (context, index) {
                                final report = incidentHistory[index];
                                return _buildComplaintCard(report, responsiveFont);
                              },
                            ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderBanner(double Function(double) responsiveFont) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade800, Colors.blue.shade600],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 24, top: 10),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white.withAlpha((0.2 * 255).toInt()),
            child: Text(
              _getInitials(studentName),
              style: GoogleFonts.inter(
                fontSize: responsiveFont(28),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            studentName,
            style: GoogleFonts.inter(
              fontSize: responsiveFont(20),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.15 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Verified Student Account",
              style: GoogleFonts.inter(
                fontSize: responsiveFont(11),
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(double Function(double) responsiveFont) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Account Details",
              style: GoogleFonts.inter(
                fontSize: responsiveFont(14),
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.person_outline_rounded,
              label: "Full Name",
              value: studentName,
              responsiveFont: responsiveFont,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.badge_outlined,
              label: "Student ID (SID)",
              value: studentId,
              responsiveFont: responsiveFont,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.email_outlined,
              label: "Email Address",
              value: studentEmail,
              responsiveFont: responsiveFont,
            ),
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                  side: BorderSide(color: Colors.red.shade100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(
                  "Log Out",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: responsiveFont(13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required double Function(double) responsiveFont,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.indigo.shade700, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: responsiveFont(11),
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: responsiveFont(13.5),
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(double Function(double) responsiveFont) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "No Complaints Raised Yet",
            style: GoogleFonts.inter(
              fontSize: responsiveFont(15),
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Any incident reports you submit will appear here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: responsiveFont(12.5),
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> report, double Function(double) responsiveFont) {
    final title = report['title'] ?? 'Untitled';
    final description = report['description'] ?? 'No description provided.';
    final location = report['location'] ?? 'No location details';
    final dateStr = _formatDateTime(report['created_at']);
    final imageUrl = report['image_url'];
    final rawStatus = report['status'] ?? 'Pending';
    final statusStr = rawStatus.toString();
    final adminRemark = report['admin_remark'] ?? '';

    Color statusColor;
    Color statusBgColor;
    final displayStatus = (statusStr.toLowerCase() == 'approved' || statusStr.toLowerCase() == 'accepted')
        ? 'Accepted'
        : statusStr;
    if (statusStr.toLowerCase() == 'approved' || statusStr.toLowerCase() == 'accepted') {
      statusColor = Colors.green.shade700;
      statusBgColor = Colors.green.shade50;
    } else if (statusStr.toLowerCase() == 'rejected') {
      statusColor = Colors.red.shade700;
      statusBgColor = Colors.red.shade50;
    } else {
      statusColor = Colors.amber.shade800;
      statusBgColor = Colors.amber.shade50;
    }

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incident Image Thumbnail
            if (imageUrl != null && imageUrl.toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade100,
                    child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400),
                  ),
                ),
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.image_not_supported_outlined, color: Colors.indigo.shade300, size: 28),
              ),
            const SizedBox(width: 12),

            // Complaint Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: responsiveFont(14),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withAlpha((0.2 * 255).toInt())),
                        ),
                        child: Text(
                          displayStatus,
                          style: GoogleFonts.inter(
                            fontSize: responsiveFont(10),
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: responsiveFont(12),
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: responsiveFont(11),
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 11, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: GoogleFonts.inter(
                          fontSize: responsiveFont(11),
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  if (adminRemark.toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.rate_review_outlined, size: 14, color: Colors.indigo.shade800),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Admin Remark: ",
                                    style: GoogleFonts.inter(
                                      fontSize: responsiveFont(11),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade900,
                                    ),
                                  ),
                                  TextSpan(
                                    text: adminRemark.toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: responsiveFont(11),
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHighlightCard(double Function(double) responsiveFont) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatusItem(
              icon: Icons.check_circle_rounded,
              color: Colors.green.shade600,
              bgColor: Colors.green.shade50,
              label: "Accepted",
              count: acceptedCount,
              responsiveFont: responsiveFont,
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.grey.shade200,
            ),
            _buildStatusItem(
              icon: Icons.pending_rounded,
              color: Colors.amber.shade700,
              bgColor: Colors.amber.shade50,
              label: "Pending",
              count: pendingCount,
              responsiveFont: responsiveFont,
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.grey.shade200,
            ),
            _buildStatusItem(
              icon: Icons.cancel_rounded,
              color: Colors.red.shade600,
              bgColor: Colors.red.shade50,
              label: "Rejected",
              count: rejectedCount,
              responsiveFont: responsiveFont,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard(double Function(double) responsiveFont) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade600, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade400.withAlpha(100),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reward Points',
                  style: GoogleFonts.inter(
                    fontSize: responsiveFont(13),
                    color: Colors.white.withAlpha(220),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$points pts',
                  style: GoogleFonts.inter(
                    fontSize: responsiveFont(26),
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+20 per approval',
            style: GoogleFonts.inter(
              fontSize: responsiveFont(11),
              color: Colors.white.withAlpha(200),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

Widget _buildStatusItem({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String label,
    required int count,
    required double Function(double) responsiveFont,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            "$count",
            style: GoogleFonts.inter(
              fontSize: responsiveFont(16),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: responsiveFont(11),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

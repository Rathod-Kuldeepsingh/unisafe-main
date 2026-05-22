import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dialog_helper.dart';

class IncidentDetailPage extends StatefulWidget {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String location;
  final String timeAgo;
  final String status;
  final String adminRemark;

  const IncidentDetailPage({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.timeAgo,
    this.status = 'Pending',
    this.adminRemark = '',
  });

  @override
  State<IncidentDetailPage> createState() => _IncidentDetailPageState();
}

class _IncidentDetailPageState extends State<IncidentDetailPage> {
  late String currentStatus;
  late TextEditingController remarkController;
  bool isSaving = false;
  bool hasChanges = false;

  bool _isStatusSame() {
    final s1 = currentStatus.toLowerCase();
    final s2 = widget.status.toLowerCase();
    if ((s1 == 'approved' || s1 == 'accepted') && (s2 == 'approved' || s2 == 'accepted')) {
      return true;
    }
    return s1 == s2;
  }

  @override
  void initState() {
    super.initState();
    final s = widget.status.toLowerCase();
    currentStatus = (s == 'approved' || s == 'accepted') ? 'Accepted' : widget.status;
    remarkController = TextEditingController(text: widget.adminRemark);
    remarkController.addListener(() {
      setState(() {
        hasChanges = remarkController.text != widget.adminRemark;
      });
    });
  }

  @override
  void dispose() {
    remarkController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      isSaving = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final statusToSend = (currentStatus == 'Accepted') ? 'Approved' : currentStatus;
      
      print("=== DB UPDATE ATTEMPT ===");
      print("User: ${user?.email}");
      print("User metadata: ${user?.userMetadata}");
      print("Incident ID: ${widget.id}");
      print("Status to send: $statusToSend");
      print("Remark to send: ${remarkController.text.trim()}");

      final response = await supabase.from('incident_reports').update({
        'status': statusToSend,
        'admin_remark': remarkController.text.trim(),
      }).eq('id', widget.id).select();

      print("DB Update Response: $response");

      if (response.isEmpty) {
        throw Exception("No rows were updated. Please check Row Level Security (RLS) policies on 'incident_reports' table.");
      }

      // Credit 20 reward points when complaint is approved
      if (statusToSend == 'Approved') {
        final reportData = response.first;
        final studentEmail = reportData['student_email']?.toString() ?? '';
        if (studentEmail.isNotEmpty) {
          // Count how many approved complaints this student has
          final approvedReports = await supabase
              .from('incident_reports')
              .select('id')
              .eq('student_email', studentEmail)
              .or('status.eq.Approved,status.eq.Accepted');

          final totalApproved = approvedReports.length;
          final totalPoints = totalApproved * 20;

          // Update student_points on ALL this student's approved reports
          await supabase
              .from('incident_reports')
              .update({'student_points': totalPoints})
              .eq('student_email', studentEmail);
        }
      }

      if (!mounted) return;

      showCustomSnackBar(
        context,
        message: "Incident updated successfully",
        type: SnackBarType.success,
      );
      
      Navigator.pop(context, true); // Pop and return true to indicate we modified data
    } catch (e) {
      print("Error updating incident: $e");
      if (!mounted) return;
      showCustomSnackBar(
        context,
        message: "Failed to update incident: $e",
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double responsiveFont(double size) => screenWidth * (size / 375);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          "Incident Detail",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
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
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Details Card
            Card(
              color: Colors.white,
              margin: const EdgeInsets.all(16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.grey.shade100, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.imageUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FadeInImage.assetNetwork(
                          placeholder: "assets/loading.gif",
                          image: widget.imageUrl,
                          height: screenHeight * 0.24,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) => Container(
                            height: screenHeight * 0.24,
                            width: double.infinity,
                            color: Colors.grey.shade100,
                            child: Icon(Icons.broken_image_rounded, size: 50, color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      widget.title.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: responsiveFont(16),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C5364).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2C5364).withOpacity(0.1)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF2C5364)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.location,
                              style: GoogleFonts.inter(
                                color: Colors.black87,
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_filled_rounded, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          "Reported ${widget.timeAgo}",
                          style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Text(
                      "Description",
                      style: GoogleFonts.inter(
                        fontSize: responsiveFont(13),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      style: GoogleFonts.inter(
                        fontSize: responsiveFont(13.5),
                        height: 1.5,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Incident ID: #${widget.id}",
                      style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // Review & Status Panel
            Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.grey.shade100, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Review Status & Feedback",
                      style: GoogleFonts.inter(
                        fontSize: responsiveFont(14),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Divider(height: 24),
                    Text(
                      "Action Status",
                      style: GoogleFonts.inter(
                        fontSize: responsiveFont(12),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatusButton(
                          status: "Accepted",
                          color: Colors.green.shade700,
                          bgColor: Colors.green.shade50,
                          icon: Icons.check_circle_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusButton(
                          status: "Pending",
                          color: Colors.amber.shade800,
                          bgColor: Colors.amber.shade50,
                          icon: Icons.pending_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusButton(
                          status: "Rejected",
                          color: Colors.red.shade700,
                          bgColor: Colors.red.shade50,
                          icon: Icons.cancel_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Admin Remarks / Notes",
                      style: GoogleFonts.inter(
                        fontSize: responsiveFont(12),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: remarkController,
                      maxLines: 3,
                      style: GoogleFonts.inter(fontSize: 13.5, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: "Enter action details, updates or instructions...",
                        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF203A43), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo.shade800, Colors.blue.shade600],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            disabledBackgroundColor: Colors.grey.shade200,
                            disabledForegroundColor: Colors.grey.shade400,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: isSaving || (!hasChanges && _isStatusSame())
                              ? null
                              : _saveChanges,
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                          label: Text(
                            isSaving ? "Saving..." : "Save Changes",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
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
    );
  }

  Widget _buildStatusButton({
    required String status,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    final bool isSelected = currentStatus.toLowerCase() == status.toLowerCase();
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            currentStatus = status;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 1.8 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey.shade400,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

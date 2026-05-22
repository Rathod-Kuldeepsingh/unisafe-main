import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisafe/admin/full.dart';
import 'dialog_helper.dart';

class IncidentCard extends StatelessWidget {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String location;
  final String timeAgo;

  final double? latitude;
  final double? longitude;

  final bool isNew;
  final String status;
  final String adminRemark;
  final VoidCallback onDelete;
  final VoidCallback? onRefresh;

  const IncidentCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.timeAgo,
    required this.latitude,
    required this.longitude,
    this.isNew = false,
    this.status = 'Pending',
    this.adminRemark = '',
    required this.onDelete,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final screenWidth = MediaQuery.of(context).size.width;

    double responsiveFont(double size) => screenWidth * (size / 375);

    Color statusColor;
    Color statusBgColor;
    final displayStatus = (status.toLowerCase() == 'approved' || status.toLowerCase() == 'accepted')
        ? 'Accepted'
        : status;
    if (status.toLowerCase() == 'approved' || status.toLowerCase() == 'accepted') {
      statusColor = Colors.green.shade700;
      statusBgColor = Colors.green.shade50;
    } else if (status.toLowerCase() == 'rejected') {
      statusColor = Colors.red.shade700;
      statusBgColor = Colors.red.shade50;
    } else {
      statusColor = Colors.amber.shade800;
      statusBgColor = Colors.amber.shade50;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Dismissible(
        key: Key(id.toString()),

        direction: DismissDirection.endToStart,

        background: Container(
          padding: const EdgeInsets.only(right: 24),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xffef5350), Color(0xffe53935)],
            ),
          ),
          child: const Icon(
            Icons.delete_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),

        confirmDismiss: (direction) async {
          bool confirm = false;
          await showCustomConfirmDialog(
            context,
            title: "Delete Report?",
            content: "Are you sure you want to delete this incident report?",
            confirmLabel: "Delete",
            confirmColor: Colors.red,
            icon: Icons.delete_forever_rounded,
            onConfirm: () {
              confirm = true;
            },
          );
          return confirm;
        },

        onDismissed: (direction) {
          onDelete();
          showCustomSnackBar(
            context,
            message: "Report deleted successfully",
            type: SnackBarType.success,
          );
        },

        child: InkWell(
          borderRadius: BorderRadius.circular(22),

          onTap: () async {
            final refreshed = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IncidentDetailPage(
                  id: id,
                  title: title,
                  description: description,
                  imageUrl: imageUrl,
                  location: location,
                  timeAgo: timeAgo,
                  status: status,
                  adminRemark: adminRemark,
                ),
              ),
            );
            if (refreshed == true && onRefresh != null) {
              onRefresh!();
            }
          },

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(22),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ================= IMAGE =================
                // ================= IMAGE =================
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                      ),

                      child: imageUrl.isNotEmpty
                          ? FadeInImage.assetNetwork(
                              placeholder: "assets/loading.gif",

                              image: imageUrl,

                              height: screenHeight * 0.24,

                              width: double.infinity,

                              fit: BoxFit.cover,

                              imageErrorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: screenHeight * 0.24,

                                  width: double.infinity,

                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                  ),

                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,

                                    children: [
                                      Icon(
                                        Icons.broken_image_rounded,
                                        size: 55,
                                        color: Colors.grey.shade500,
                                      ),

                                      const SizedBox(height: 10),

                                      Text(
                                        "Image not available",

                                        style: GoogleFonts.inter(
                                          color: Colors.grey.shade600,

                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: screenHeight * 0.24,

                              width: double.infinity,

                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                              ),

                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,

                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    size: 55,
                                    color: Colors.grey.shade500,
                                  ),

                                  const SizedBox(height: 10),

                                  Text(
                                    "No Image Found",

                                    style: GoogleFonts.inter(
                                      color: Colors.grey.shade600,

                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    // ================= TOP GRADIENT =================
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,

                      child: Container(
                        height: 90,

                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(22),
                            topRight: Radius.circular(22),
                          ),

                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,

                            colors: [
                              Colors.black.withOpacity(0.45),

                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ================= NEW BADGE =================
                    if (isNew)
                      Positioned(
                        top: 14,
                        right: 14,

                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),

                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xffef5350), Color(0xffe53935)],
                            ),

                            borderRadius: BorderRadius.circular(30),
                          ),

                          child: Row(
                            children: [
                              const Icon(
                                Icons.fiber_new,
                                color: Colors.white,
                                size: 16,
                              ),

                              const SizedBox(width: 4),

                              Text(
                                "NEW",

                                style: GoogleFonts.inter(
                                  color: Colors.white,

                                  fontWeight: FontWeight.bold,

                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ================= STATUS BADGE =================
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: statusColor.withOpacity(0.25)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (status.toLowerCase() == 'approved' || status.toLowerCase() == 'accepted')
                                  ? Icons.check_circle_rounded
                                  : (status.toLowerCase() == 'rejected')
                                      ? Icons.cancel_rounded
                                      : Icons.pending_rounded,
                              color: statusColor,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              displayStatus.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ================= CONTENT =================
                Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // ================= TITLE =================
                      Text(
                        title.toUpperCase(),

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: GoogleFonts.inter(
                          fontSize: responsiveFont(15),

                          fontWeight: FontWeight.bold,

                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ================= DESCRIPTION =================
                      Text(
                        description,

                        maxLines: 3,

                        overflow: TextOverflow.ellipsis,

                        style: GoogleFonts.inter(
                          fontSize: responsiveFont(13),

                          height: 1.5,

                          color: Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ================= LOCATION =================
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C5364).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2C5364).withOpacity(0.1)),
                        ),

                        child: Column(
                          children: [
                            Row(
                              children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFF2C5364),
                                    size: 20,
                                  ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: Text(
                                    location,

                                    maxLines: 2,

                                    overflow: TextOverflow.ellipsis,

                                    style: GoogleFonts.inter(
                                      fontSize: responsiveFont(12),

                                      fontWeight: FontWeight.w600,

                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // ================= LAT LNG =================
                            if (latitude != null && longitude != null) ...[
                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),

                                      decoration: BoxDecoration(
                                        color: Colors.white,

                                        borderRadius: BorderRadius.circular(12),
                                      ),

                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,

                                        children: [
                                          Text(
                                            "Latitude",

                                            style: GoogleFonts.inter(
                                              fontSize: 11,

                                              color: Colors.grey,
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          Text(
                                            latitude!.toStringAsFixed(5),

                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,

                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),

                                      decoration: BoxDecoration(
                                        color: Colors.white,

                                        borderRadius: BorderRadius.circular(12),
                                      ),

                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,

                                        children: [
                                          Text(
                                            "Longitude",

                                            style: GoogleFonts.inter(
                                              fontSize: 11,

                                              color: Colors.grey,
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          Text(
                                            longitude!.toStringAsFixed(5),

                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,

                                              fontSize: 12,
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

                      const SizedBox(height: 18),

                      // ================= FOOTER =================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: Colors.grey.shade600,
                              ),

                              const SizedBox(width: 6),

                              Text(
                                timeAgo,

                                style: GoogleFonts.inter(
                                  fontSize: 12,

                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,

                              borderRadius: BorderRadius.circular(30),
                            ),

                            child: Text(
                              "ID #$id",

                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,

                                fontSize: 11,

                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

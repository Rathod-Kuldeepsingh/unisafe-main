import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisafe/admin/full.dart';


class IncidentCard extends StatelessWidget {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String location;
  final String timeAgo;
  final bool isNew;
  final VoidCallback onDelete;

final snackBar = SnackBar(
  elevation: 0,
  behavior: SnackBarBehavior.floating,
  duration: Duration(milliseconds: 700),
  backgroundColor: Colors.transparent,
  content: AwesomeSnackbarContent(
    color: Colors.blue.shade700,
    title: 'Hello!',
    message: 'This is an awesome snackbar using a package! 🎉',
    contentType: ContentType.success, // other options: failure, help, warning
  ),
);

   IncidentCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.timeAgo,
    this.isNew = false,
    required this.onDelete,
  });


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double responsiveFont(double size) => screenWidth * (size / 375);

    return Dismissible(
      key: Key(id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text("Confirm Deletion"),
            content: const Text("Are you sure you want to delete this report?"),
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
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(
                    fontSize: responsiveFont(14),
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              TextButton(
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
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  "Delete",
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
      },
      onDismissed: (direction) {
        onDelete(); // Call the deletion logic from parent
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Report deleted.")));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: InkWell(
          onTap: () {
             Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => IncidentDetailPage(
        id: id,
        title: title,
        description: description,
        imageUrl: imageUrl,
        location: location,
        timeAgo: timeAgo,
      ),
    ),
  );
          },
          child: Card(
            color: Colors.white,
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: responsiveFont(14),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:  Text(
                            "NEW",
                            style: TextStyle(color: Colors.white, fontSize: responsiveFont(12)),
                          ),
                        ),
                    ],
                  ),
                   SizedBox(height: screenHeight*0.020),

                  /// Image & Description
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: screenWidth*0.30,
                          height: screenHeight*0.10,
                          fit: BoxFit.cover,
                        ),
                      ),
                       SizedBox(width: screenWidth*0.020),
                      Expanded(
                        child: Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: responsiveFont(13),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight*0.020),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 20,
                            color: Colors.grey,
                          ),
                           SizedBox(width:screenWidth*0.020 ),
                          Flexible(
                            child: Text(
                              location.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: responsiveFont(11),
                                color: Colors.grey.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              softWrap: false,
                            ),
                          ),
                        ],
                      ),
                     SizedBox(height: screenHeight*0.010,),
                      Text("Time & Date :$timeAgo",
                        style: GoogleFonts.inter(
                          fontSize: responsiveFont(12.5),
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        "ID: $id",
                        style: GoogleFonts.inter(
                          fontSize: responsiveFont(12.4),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  
}


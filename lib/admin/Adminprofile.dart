import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dialog_helper.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  final _supabase = Supabase.instance.client;
  String _displayName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = _supabase.auth.currentUser;
    if (user != null && user.userMetadata != null) {
      setState(() {
        _displayName = user.userMetadata!['name'] ?? 'Admin';
      });
    }
  }

  Future<void> logoutAdmin(BuildContext context) async {
    final navigator = Navigator.of(context);
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print("Error signing out from Supabase: $e");
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isAdminLoggedIn'); // clear the login flag
    navigator.pushReplacementNamed('/start'); // back to Startedpage
  }

  Future<void> _showEditNameBottomSheet() async {
    final TextEditingController _nameController = TextEditingController(
      text: _displayName,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Edit Display Name",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                style: GoogleFonts.inter(fontSize: 14.5, color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  labelStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.person_outline_rounded, color: Colors.indigo.shade800),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.indigo.shade800, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;

                    try {
                      await _supabase.auth.updateUser(
                        UserAttributes(data: {'name': name}),
                      );
                      await _supabase.auth.refreshSession(); // Refresh session

                      setState(() {
                        _displayName = name;
                      });

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        _showError("Name updated successfully", isSuccess: true);
                      }
                    } catch (e) {
                      _showError("$e", isSuccess: false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Save Changes",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  void _confirmLogout(BuildContext context) {
    showCustomConfirmDialog(
      context,
      title: "Confirm Logout",
      content: "Are you sure you want to log out of the admin panel?",
      confirmLabel: "Log Out",
      confirmColor: const Color(0xFFC62828),
      icon: Icons.logout_rounded,
      onConfirm: () => logoutAdmin(context),
    );
  }

  void _showError(String message, {bool isSuccess = false}) {
    showCustomSnackBar(
      context,
      message: message,
      type: isSuccess ? SnackBarType.success : SnackBarType.error,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    final themeColor = iconColor ?? Colors.indigo.shade800;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: themeColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Admin Profile",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: _showEditNameBottomSheet,
            tooltip: "Edit Name",
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text("User not logged in"))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.indigo.shade800.withOpacity(0.2), width: 2),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.indigo.shade800, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundImage: const AssetImage("assets/admin1.png"),
                          backgroundColor: Colors.grey.shade100,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _displayName,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Administrator",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.indigo.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildInfoTile(
                    icon: Icons.email_outlined,
                    label: "EMAIL ADDRESS",
                    value: user.email ?? "",
                  ),
                  _buildInfoTile(
                    icon: Icons.shield_outlined,
                    label: "ADMINISTRATOR ID",
                    value: user.id,
                  ),
                  _buildInfoTile(
                    icon: Icons.verified_user_outlined,
                    label: "ACCOUNT LEVEL",
                    value: "Super Admin",
                    iconColor: Colors.green.shade700,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _confirmLogout(context);
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      label: Text(
                        "Log Out",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62828),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

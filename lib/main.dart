// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafe/admin/Adminprofile.dart';
import 'package:unisafe/admin/Authfile.dart';
import 'package:unisafe/admin/adminscreen.dart';
import 'package:unisafe/students/Dashboard.dart';
import 'package:unisafe/students/StudentAuth.dart';
import 'package:unisafe/welcome/Splashscreen.dart';
import 'package:unisafe/welcome/Startedpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://jwsibafhwkujlpgzqaph.supabase.co',
    anonKey: 'sb_publishable_Ann0sNjsSu8QeM9KVGo72Q_g1gz9pvv',
  );

  runApp(MyApp());
}

/// helo

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {
        "/admindash": (context) => AdminDashboard(),
        "/adminauth": (context) => Authfile(),
        "/student": (context) => Dashboard(),
        "/studentauth": (context) => const StudentAuth(),
        "/start": (context) => Startedpage(),
        "/admin": (context) => AdminProfile(),
      },
    );
  }
}
import 'package:bookapong_app/Splash%20Screen/splash_screen_page.dart';
import 'package:bookapong_app/User/Login%20and%20Register/login_register_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookapong_app/User/Home/home_page.dart';
import 'package:bookapong_app/Admin/Dashboard/admin_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BookaPong',
      theme: ThemeData(useMaterial3: true),
      // App Startup Splash
      home: SplashScreen(
        durationSeconds: 3,
        onComplete: () {
          runApp(
            const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: AuthWrapper(),
            ),
          );
        },
      ),
    );
  }
}

// Main Auth Handler
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFDF7E7),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF800020)),
            ),
          );
        }

        if (snapshot.hasData) {
          return const RoleBasedRedirect();
        }

        return const LoginPage();
      },
    );
  }
}

// Role Checker & Instant Redirect Handler
class RoleBasedRedirect extends StatefulWidget {
  const RoleBasedRedirect({super.key});

  @override
  State<RoleBasedRedirect> createState() => _RoleBasedRedirectState();
}

class _RoleBasedRedirectState extends State<RoleBasedRedirect> {
  String? _determinedRole;

  @override
  void initState() {
    super.initState();
    _redirectUser();
  }

  Future<void> _redirectUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        FirebaseAuth.instance.signOut();
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final role = (userDoc.data()?['role'] ?? 'user')
            .toString()
            .toLowerCase()
            .trim();
        if (mounted) setState(() => _determinedRole = role);
        return;
      }

      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();
      if (adminDoc.exists) {
        if (mounted) setState(() => _determinedRole = 'admin');
        return;
      }

      if (mounted) setState(() => _determinedRole = 'user');
    } catch (e) {
      debugPrint("⚠️ Redirect error: $e");
      if (mounted) setState(() => _determinedRole = 'user');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_determinedRole == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDF7E7),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF800020)),
        ),
      );
    }

    if (_determinedRole == 'admin') {
      return const AdminDashboardPage();
    }

    return const HomePage();
  }
}

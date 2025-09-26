import 'package:flutter/material.dart';
import 'package:manajemensekolah/screen/dashboard.dart';
import 'package:manajemensekolah/screen/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  runApp(SchoolManagementApp());
}

class SchoolManagementApp extends StatelessWidget {
  const SchoolManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manajemen Sekolah',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder(
        future: _checkAuthStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          } else {
            return LoginScreen();
          }
        },
      ),
      routes: {
        '/admin': (context) => Dashboard(role: 'admin'),
        '/guru': (context) => Dashboard(role: 'guru'),
        '/staff': (context) => Dashboard(role: 'staff'),
        '/wali': (context) => Dashboard(role: 'wali'),
      },
    );
  }

  Future<bool> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null;
  }
}
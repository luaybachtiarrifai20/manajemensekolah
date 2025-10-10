import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manajemensekolah/screen/dashboard.dart';
import 'package:manajemensekolah/screen/login_screen.dart';
import 'package:manajemensekolah/utils/language_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);
  
  // Initialize language provider and load saved language
  await languageProvider.loadSavedLanguage();
  
  runApp(SchoolManagementApp());
}

class SchoolManagementApp extends StatelessWidget {
  const SchoolManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LanguageProvider>(
      create: (context) => languageProvider,
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: languageProvider.getTranslatedText({
              'en': 'School Management',
              'id': 'Manajemen Sekolah',
            }),
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: FutureBuilder(
              future: _checkAuthStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            languageProvider.getTranslatedText({
                              'en': 'Loading...',
                              'id': 'Memuat...',
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  final isAuthenticated = snapshot.data ?? false;
                  if (isAuthenticated) {
                    // Redirect to appropriate dashboard based on user role
                    return _redirectToDashboard();
                  } else {
                    return LoginScreen();
                  }
                }
              },
            ),
            routes: {
              '/admin': (context) => Dashboard(role: 'admin'),
              '/guru': (context) => Dashboard(role: 'guru'),
              '/staff': (context) => Dashboard(role: 'staff'),
              '/wali': (context) => Dashboard(role: 'wali'),
              '/login': (context) => LoginScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  Future<bool> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userData = prefs.getString('user');
    
    // Check if both token and user data exist
    return token != null && userData != null && userData.isNotEmpty;
  }

  Widget _redirectToDashboard() {
    return FutureBuilder(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return Text(
                        languageProvider.getTranslatedText({
                          'en': 'Redirecting...',
                          'id': 'Mengalihkan...',
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        } else {
          final role = snapshot.data ?? 'guru'; // Default to guru if no role found
          return Dashboard(role: role);
        }
      },
    );
  }

  Future<String> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    
    if (userData != null && userData.isNotEmpty) {
      try {
        final userMap = json.decode(userData);
        return userMap['role'] ?? 'guru';
      } catch (e) {
        return 'guru';
      }
    }
    return 'guru';
  }
}
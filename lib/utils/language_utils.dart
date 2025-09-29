import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LanguageProvider with ChangeNotifier {
  static const String ENGLISH = 'en';
  static const String INDONESIAN = 'id';

  String _currentLanguage = INDONESIAN;

  String get currentLanguage => _currentLanguage;

  Future<void> setLanguage(String language) async {
    _currentLanguage = language;

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);

    notifyListeners(); // Notify all listeners about the change
  }

  // Load saved language
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language') ?? INDONESIAN;
    _currentLanguage = savedLanguage;
    notifyListeners();
  }

  String getTranslatedText(Map<String, String> translations) {
    return translations[_currentLanguage] ?? translations[INDONESIAN] ?? '';
  }
}

// Singleton instance
LanguageProvider languageProvider = LanguageProvider();

// Extension untuk memudahkan penggunaan
extension LocalizedString on Map<String, String> {
  String get tr {
    return languageProvider.getTranslatedText(this);
  }
}

class AppLocalizations {
  // Dashboard
  static Map<String, String> get appTitle => {
    'en': 'School Management',
    'id': 'Manajemen Sekolah',
  };

  static Map<String, String> get welcome => {
    'en': 'Welcome,',
    'id': 'Selamat datang,',
  };

  static Map<String, String> get activeAccount => {
    'en': 'Active account',
    'id': 'Akun aktif',
  };

  static Map<String, String> get searchHint => {
    'en': 'Search features, data, or menus...',
    'id': 'Cari fitur, data, atau menu...',
  };

  static Map<String, String> get logout => {'en': 'Logout', 'id': 'Keluar'};

  // Common
  static Map<String, String> get save => {'en': 'Save', 'id': 'Simpan'};

  static Map<String, String> get cancel => {'en': 'Cancel', 'id': 'Batal'};

  static Map<String, String> get edit => {'en': 'Edit', 'id': 'Edit'};

  static Map<String, String> get delete => {'en': 'Delete', 'id': 'Hapus'};

  static Map<String, String> get add => {'en': 'Add', 'id': 'Tambah'};

  static Map<String, String> get refresh => {
    'en': 'Refresh',
    'id': 'Muat Ulang',
  };

  static Map<String, String> get search => {'en': 'Search', 'id': 'Cari'};

  static Map<String, String> get loading => {
    'en': 'Loading...',
    'id': 'Memuat...',
  };

  static Map<String, String> get noData => {
    'en': 'No data',
    'id': 'Tidak ada data',
  };

  static Map<String, String> get noSearchResults => {
    'en': 'No search results found',
    'id': 'Tidak ditemukan hasil pencarian',
  };

  // Menu Items
  static Map<String, String> get manageStudents => {
    'en': 'Manage Students',
    'id': 'Kelola Siswa',
  };

  static Map<String, String> get manageTeachers => {
    'en': 'Manage Teachers',
    'id': 'Kelola Guru',
  };

  static Map<String, String> get manageClasses => {
    'en': 'Manage Classes',
    'id': 'Kelola Kelas',
  };

  static Map<String, String> get manageSubjects => {
    'en': 'Manage Subjects',
    'id': 'Kelola Mata Pelajaran',
  };

  static Map<String, String> get manageTeachingSchedule => {
    'en': 'Manage Teaching Schedule',
    'id': 'Kelola Jadwal Mengajar',
  };

  static Map<String, String> get reports => {'en': 'Reports', 'id': 'Laporan'};

  static Map<String, String> get finance => {'en': 'Finance', 'id': 'Keuangan'};

  static Map<String, String> get announcements => {
    'en': 'Announcements',
    'id': 'Pengumuman',
  };

  static Map<String, String> get studentAttendance => {
    'en': 'Student Attendance',
    'id': 'Absensi Siswa',
  };

  static Map<String, String> get inputGrades => {
    'en': 'Input Grades',
    'id': 'Input Nilai',
  };

  static Map<String, String> get teachingSchedule => {
    'en': 'Teaching Schedule',
    'id': 'Jadwal Mengajar',
  };

  static Map<String, String> get classActivities => {
    'en': 'Class Activities',
    'id': 'Kegiatan Kelas',
  };

  static Map<String, String> get learningMaterials => {
    'en': 'Learning Materials',
    'id': 'Materi Pembelajaran',
  };

  // Role Titles
  static Map<String, String> get adminRole => {'en': 'Admin', 'id': 'Admin'};

  static Map<String, String> get teacherRole => {'en': 'Teacher', 'id': 'Guru'};

  static Map<String, String> get staffRole => {'en': 'Staff', 'id': 'Staff'};

  static Map<String, String> get parentRole => {
    'en': 'Parent',
    'id': 'Wali Murid',
  };

  // Login Screen
  static Map<String, String> get login => {'en': 'Login', 'id': 'Masuk'};

  static Map<String, String> get email => {'en': 'Email', 'id': 'Email'};

  static Map<String, String> get password => {
    'en': 'Password',
    'id': 'Kata Sandi',
  };

  static Map<String, String> get forgotPassword => {
    'en': 'Forgot Password?',
    'id': 'Lupa Kata Sandi?',
  };

  static Map<String, String> get loginSuccess => {
    'en': 'Login Successful',
    'id': 'Login Berhasil',
  };

  static Map<String, String> get loginError => {
    'en': 'Login Failed',
    'id': 'Login Gagal',
  };

  // Add these to AppLocalizations class in language_utils.dart

  // Confirmation dialogs
  static Map<String, String> get confirmDelete => {
    'en': 'Confirm Delete',
    'id': 'Konfirmasi Hapus',
  };

  static Map<String, String> get areYouSure => {
    'en': 'Are you sure?',
    'id': 'Apakah Anda yakin?',
  };

  // Form fields
  static Map<String, String> get name => {'en': 'Name', 'id': 'Nama'};

  static Map<String, String> get class_ => {'en': 'Class', 'id': 'Kelas'};

  static Map<String, String> get subject => {
    'en': 'Subject',
    'id': 'Mata Pelajaran',
  };

  static Map<String, String> get teacher => {'en': 'Teacher', 'id': 'Guru'};

  static Map<String, String> get schedule => {'en': 'Schedule', 'id': 'Jadwal'};

  // Success messages
  static Map<String, String> get success => {'en': 'Success', 'id': 'Berhasil'};

  static Map<String, String> get error => {'en': 'Error', 'id': 'Error'};

  // Time related
  static Map<String, String> get startTime => {
    'en': 'Start Time',
    'id': 'Jam Mulai',
  };

  static Map<String, String> get endTime => {
    'en': 'End Time',
    'id': 'Jam Selesai',
  };

  static Map<String, String> get day => {'en': 'Day', 'id': 'Hari'};
}

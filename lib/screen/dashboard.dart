import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:manajemensekolah/screen/admin/teacher_admin.dart';
import 'package:manajemensekolah/screen/admin/teaching_schedule_management.dart';
import 'package:manajemensekolah/screen/admin/class_management.dart';
import 'package:manajemensekolah/screen/admin/subject_management.dart';
import 'package:manajemensekolah/screen/admin/student_management.dart';
import 'package:manajemensekolah/screen/admin/keuangan.dart';
import 'package:manajemensekolah/screen/admin/laporan.dart';
import 'package:manajemensekolah/screen/admin/pengumuman.dart';
import 'package:manajemensekolah/screen/guru/presence_teacher.dart';
import 'package:manajemensekolah/screen/guru/input_grade_teacher.dart';
import 'package:manajemensekolah/screen/guru/teaching_schedule.dart';

import 'package:manajemensekolah/screen/guru/materi_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatelessWidget {
  final String role;

  const Dashboard({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Navbar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(Icons.school, color: Colors.orange, size: 32),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Manajemen Sekolah',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.account_circle,
                      color: Colors.grey[700],
                      size: 28,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 28,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.orange.shade100,
                                      child: Icon(
                                        Icons.account_circle,
                                        color: Colors.orange,
                                        size: 32,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getRoleTitle(),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Akun aktif',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: Icon(
                                      Icons.logout,
                                      color: Colors.redAccent,
                                    ),
                                    label: Text(
                                      'Logout',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade50,
                                      foregroundColor: Colors.redAccent,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/',
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: 8),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none,
                      color: Colors.grey[700],
                      size: 26,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari fitur, data, atau menu...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (value) {
                    // Implementasi pencarian fitur jika diperlukan
                  },
                ),
              ),
            ),
            SizedBox(height: 18),
            // Hero Section ala Bank Jago
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.orange,
                      size: 36,
                    ),
                  ),
                  SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat datang,',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _getRoleTitle(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Aplikasi Manajemen Sekolah',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icon logout dihapus, hanya ada di bottom sheet akun
                ],
              ),
            ),
            SizedBox(height: 18),
            // Grid Menu ala Bank Jago
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  children: _getDashboardCards(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleTitle() {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'guru':
        return 'Guru';
      case 'staff':
        return 'Staff';
      case 'wali':
        return 'Wali Murid';
      default:
        return 'Pengguna';
    }
  }

  List<Widget> _getDashboardCards(BuildContext context) {
    // Add context parameter
    List<Map<String, dynamic>> allCards = [
      {
        'title': 'Kelola Siswa',
        'icon': Icons.people,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StudentManagementScreen()),
        ),
        'roles': ['admin'], // Hanya admin
      },
      {
        'title': 'Kelola Guru',
        'icon': Icons.person,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TeacherAdminScreen()),
        ),
        'roles': ['admin'], // Hanya admin
      },
      {
        'title': 'Kelola Kelas',
        'icon': Icons.class_,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ClassManagementScreen()),
        ),
        'roles': ['admin'], // Hanya admin
      },
      {
        'title': 'Kelola Mata Pelajaran',
        'icon': Icons.menu_book,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SubjectManagementScreen()),
        ),
        'roles': ['admin'], // Hanya admin
      },
      {
        'title': 'Laporan',
        'icon': Icons.assessment,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LaporanScreen()),
        ),
        'roles': ['admin'], // Hanya admin
      },
      {
        'title': 'Keuangan',
        'icon': Icons.attach_money,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => KeuanganScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': 'Pengumuman',
        'icon': Icons.announcement,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PengumumanScreen()),
        ),
        'roles': ['admin'], // Hanya admin
      },
      {
        'title': 'Absensi Siswa',
        'icon': Icons.how_to_reg,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PresencePage(guru: {'role': role}),
          ),
        ),
        'roles': ['admin', 'guru'], // Admin dan guru
      },
      {
        'title': 'Input Nilai',
        'icon': Icons.grade,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GradePage(guru: {'role': role}),
          ),
        ),
        'roles': ['admin', 'guru'], // Admin dan guru
      },
      {
        'title': 'Jadwal Mengajar',
        'icon': Icons.schedule,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TeachingScheduleScreen()),
        ),
        'roles': ['admin', 'guru'], // Guru
      },
      {
        'title': 'Kegiatan Kelas',
        'icon': Icons.event,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => KegiatanKelasScreen()),
        ),
        'roles': ['admin', 'guru'], // Admin dan guru
      },
      {
        'title': 'Materi Pembelajaran',
        'icon': Icons.book,
        'onTap': () async {
          final prefs = await SharedPreferences.getInstance();
          final userData = json.decode(prefs.getString('user') ?? '{}');

          final guruData = {
            'id': userData['id'] ?? '', // Pastikan ini ID dari users table
            'nama': userData['nama'] ?? 'Guru',
            'role': role,
          };

          if (guruData['id']!.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ID guru tidak ditemukan')),
              );
            }
            return;
          }
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MateriPage(guru: guruData)),
          );
        },
        'roles': ['admin', 'guru'],
      },
      // Di bagian _getDashboardCards, tambahkan:
      {
        'title': 'Kelola Jadwal Mengajar',
        'icon': Icons.schedule,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TeachingScheduleManagementScreen()),
        ),
        'roles': ['admin'],
      },
    ];

    // Filter cards berdasarkan role pengguna
    return allCards
        .where((card) => card['roles'].contains(role))
        .map(
          (card) =>
              _buildDashboardCard(card['title'], card['icon'], card['onTap']),
        )
        .toList();
  }

  Widget _buildDashboardCard(String title, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _getCardColor(role).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.all(16),
                child: Icon(icon, size: 36, color: _getCardColor(role)),
              ),
              SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCardColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.blue;
      case 'guru':
        return Colors.green;
      case 'staff':
        return Colors.orange;
      case 'wali':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

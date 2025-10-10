import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:manajemensekolah/screen/admin/admin_class_activity.dart';
import 'package:manajemensekolah/screen/admin/admin_teachers_screen.dart';
import 'package:manajemensekolah/screen/admin/class_management.dart';
import 'package:manajemensekolah/screen/admin/keuangan.dart';
import 'package:manajemensekolah/screen/admin/laporan.dart';
import 'package:manajemensekolah/screen/admin/pengumuman.dart';
import 'package:manajemensekolah/screen/admin/student_management.dart';
import 'package:manajemensekolah/screen/admin/subject_management.dart';
import 'package:manajemensekolah/screen/admin/teacher_admin.dart';
import 'package:manajemensekolah/screen/admin/teaching_schedule_management.dart';
import 'package:manajemensekolah/screen/guru/input_grade_teacher.dart';
import 'package:manajemensekolah/screen/guru/class_activity.dart';
import 'package:manajemensekolah/screen/guru/materi_screen.dart';
import 'package:manajemensekolah/screen/guru/presence_teacher.dart';
import 'package:manajemensekolah/screen/guru/teaching_schedule.dart';
import 'package:manajemensekolah/screen/guru/rpp_screen.dart'; // Tambahkan import RPP guru
import 'package:manajemensekolah/screen/walimurid/presence_parent.dart';
import 'package:manajemensekolah/services/api_student_services.dart';
import 'package:manajemensekolah/utils/language_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  final String role;

  const Dashboard({super.key, required this.role});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
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
                          AppLocalizations.appTitle.tr,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      // Language Selector
                      PopupMenuButton<String>(
                        icon: Icon(Icons.language, color: Colors.grey[700]),
                        onSelected: (String language) async {
                          await languageProvider.setLanguage(language);
                          // No need to restart - UI updates automatically
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'en',
                            child: Row(
                              children: [
                                Icon(Icons.language, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('English'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'id',
                            child: Row(
                              children: [
                                Icon(Icons.language, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Indonesia'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.account_circle,
                          color: Colors.grey[700],
                          size: 28,
                        ),
                        onPressed: () {
                          _showAccountBottomSheet(context);
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
                        hintText: AppLocalizations.searchHint.tr,
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (value) {
                        // Implement search functionality if needed
                      },
                    ),
                  ),
                ),
                SizedBox(height: 18),
                // Hero Section
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
                              AppLocalizations.welcome.tr,
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
                              AppLocalizations.appTitle.tr,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18),
                // Grid Menu
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      children: _getDashboardCards(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAccountBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            AppLocalizations.activeAccount.tr,
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
                      icon: Icon(Icons.logout, color: Colors.redAccent),
                      label: Text(
                        AppLocalizations.logout.tr,
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
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        }
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
    );
  }

  String _getRoleTitle() {
    switch (widget.role) {
      case 'admin':
        return AppLocalizations.adminRole.tr;
      case 'guru':
        return AppLocalizations.teacherRole.tr;
      case 'staff':
        return AppLocalizations.staffRole.tr;
      case 'wali':
        return AppLocalizations.parentRole.tr;
      default:
        return 'User';
    }
  }

  List<Widget> _getDashboardCards(BuildContext context) {
    List<Map<String, dynamic>> allCards = [
      {
        'title': AppLocalizations.manageStudents.tr,
        'icon': Icons.people,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StudentManagementScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': AppLocalizations.manageTeachers.tr,
        'icon': Icons.person,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TeacherAdminScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': AppLocalizations.manageClasses.tr,
        'icon': Icons.class_,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ClassManagementScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': AppLocalizations.manageSubjects.tr,
        'icon': Icons.menu_book,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SubjectManagementScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': AppLocalizations.reports.tr,
        'icon': Icons.assessment,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LaporanScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': AppLocalizations.finance.tr,
        'icon': Icons.attach_money,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => KeuanganScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': AppLocalizations.announcements.tr,
        'icon': Icons.announcement,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PengumumanScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': AppLocalizations.studentAttendance.tr,
        'icon': Icons.how_to_reg,
        'onTap': () async {
          final prefs = await SharedPreferences.getInstance();
          final userData = json.decode(prefs.getString('user') ?? '{}');

          print('👤 User data for attendance: $userData');

          final guruData = {
            'id': userData['id'] ?? '',
            'nama': userData['nama'] ?? 'Teacher',
            'email': userData['email'] ?? '',
            'role': widget.role,
          };

          if (guruData['id']!.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: Teacher ID not found')),
              );
            }
            return;
          }

          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PresencePage(guru: guruData),
            ),
          );
        },
        'roles': ['admin', 'guru'],
      },
      // Input Nilai
      {
        'title': AppLocalizations.inputGrades.tr,
        'icon': Icons.grade,
        'onTap': () async {
          final prefs = await SharedPreferences.getInstance();
          final userData = json.decode(prefs.getString('user') ?? '{}');

          print('👤 User data for grade input: $userData');

          final guruData = {
            'id': userData['id'] ?? '',
            'nama': userData['nama'] ?? 'Teacher',
            'email': userData['email'] ?? '',
            'role': widget.role,
          };

          if (guruData['id']!.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: Teacher ID not found')),
              );
            }
            return;
          }

          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GradePage(guru: guruData)),
          );
        },
        'roles': ['admin', 'guru'],
      },
      {
        'title': AppLocalizations.teachingSchedule.tr,
        'icon': Icons.schedule,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TeachingScheduleScreen()),
        ),
        'roles': ['admin', 'guru'],
      },
      {
        'title': AppLocalizations.classActivities.tr,
        'icon': Icons.event,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ClassActifityScreen()),
        ),
        'roles': ['guru'],
      },
      {
        'title': 'Kegiatan Kelas',
        'icon': Icons.event_available,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminClassActivityScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': AppLocalizations.learningMaterials.tr,
        'icon': Icons.book,
        'onTap': () async {
          final prefs = await SharedPreferences.getInstance();
          final userData = json.decode(prefs.getString('user') ?? '{}');

          final teacherData = {
            'id': userData['id'] ?? '',
            'name': userData['name'] ?? 'Teacher',
            'role': widget.role,
          };

          if (teacherData['id']!.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: Teacher ID not found')),
              );
            }
            return;
          }
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MateriPage(guru: teacherData),
            ),
          );
        },
        'roles': ['guru'],
      },
      {
        'title': AppLocalizations.manageTeachingSchedule.tr,
        'icon': Icons.schedule,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeachingScheduleManagementScreen(),
          ),
        ),
        'roles': ['admin'],
      },
      // TAMBAHKAN KARTU RPP UNTUK GURU
      {
        'title': AppLocalizations
            .myRpp
            .tr, // Bisa ditambahkan ke language_utils nanti
        'icon': Icons.description,
        'onTap': () async {
          final prefs = await SharedPreferences.getInstance();
          final userData = json.decode(prefs.getString('user') ?? '{}');

          print('👤 User data for RPP: $userData');

          final guruData = {
            'id': userData['id'] ?? '',
            'nama': userData['nama'] ?? 'Teacher',
            'email': userData['email'] ?? '',
            'role': widget.role,
          };

          if (guruData['id']!.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: Teacher ID not found')),
              );
            }
            return;
          }

          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RppScreen(
                guruId: guruData['id']!,
                guruName: guruData['nama']!,
              ),
            ),
          );
        },
        'roles': ['guru'],
      },
      // TAMBAHKAN KARTU KELOLA RPP UNTUK ADMIN
      {
        'title': AppLocalizations
            .manageRpp
            .tr, // Bisa ditambahkan ke language_utils nanti
        'icon': Icons.assignment,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminTeachersScreen()),
        ),
        'roles': ['admin'],
      },
      // Dalam _getDashboardCards, perbaiki bagian 'Absensi Anak':
      {
        'title': 'Absensi Anak',
        'icon': Icons.calendar_today,
        'onTap': () async {
          final prefs = await SharedPreferences.getInstance();
          final userData = json.decode(prefs.getString('user') ?? '{}');

          print('👤 Parent data: $userData');

          // Dapatkan data siswa/anak untuk parent ini
          final siswaData = await _getSiswaDataForParent(userData['id'] ?? '');

          if (siswaData.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Tidak ada data siswa/anak ditemukan untuk akun ini',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );

              // Tampilkan dialog informasi
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Informasi'),
                  content: Text(
                    'Tidak ada data siswa yang terhubung dengan akun wali murid ini. Silakan hubungi administrator.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            }
            return;
          }

          if (!context.mounted) return;

          // Jika hanya ada 1 anak, langsung buka halaman absensi
          if (siswaData.length == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PresenceParentPage(
                  parent: userData,
                  siswaId: siswaData[0]['id'],
                ),
              ),
            );
          } else {
            // Jika multiple anak, tampilkan dialog pilihan
            _showStudentSelectionDialog(context, userData, siswaData);
          }
        },
        'roles': ['wali'],
      },
    ];

    return allCards
        .where((card) => card['roles'].contains(widget.role))
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
                  color: _getCardColor(widget.role).withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.all(16),
                child: Icon(icon, size: 36, color: _getCardColor(widget.role)),
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

// Ganti fungsi _getSiswaDataForParent dengan ini:
Future<List<dynamic>> _getSiswaDataForParent(String parentId) async {
  try {
    // Dapatkan semua siswa
    final allStudents = await ApiStudentService.getStudent();

    // Dapatkan data user wali untuk mendapatkan siswa_id
    final prefs = await SharedPreferences.getInstance();
    final userData = json.decode(prefs.getString('user') ?? '{}');

    // Jika user wali memiliki siswa_id langsung (dari relasi one-to-one)
    if (userData['siswa_id'] != null && userData['siswa_id'].isNotEmpty) {
      final siswa = allStudents.firstWhere(
        (student) => student['id'] == userData['siswa_id'],
        orElse: () => null,
      );
      return siswa != null ? [siswa] : [];
    }

    // Alternatif: Filter siswa berdasarkan email wali (jika ada field email_wali di siswa)
    final siswaWithThisParent = allStudents.where((student) {
      return student['email_wali'] == userData['email'] ||
          student['nama_wali'] == userData['nama'];
    }).toList();

    if (siswaWithThisParent.isNotEmpty) {
      return siswaWithThisParent;
    }

    // Fallback: return semua siswa (untuk testing)
    print('⚠️  Using fallback - showing all students for parent');
    return allStudents;
  } catch (e) {
    print('Error getting student data for parent: $e');
    return [];
  }
}

// Tambahkan fungsi untuk mendapatkan siswa berdasarkan parent ID dari API
Future<List<dynamic>> _getSiswaByParentId(String parentId) async {
  try {
    // Anda perlu membuat endpoint API seperti: /api/siswa/by-parent/:parentId
    // Untuk sementara, kita gunakan pendekatan filter di frontend
    final allStudents = await ApiStudentService.getStudent();

    // Asumsi: ada field parent_id atau wali_id di tabel siswa
    return allStudents.where((student) {
      return student['parent_id'] == parentId ||
          student['wali_id'] == parentId ||
          student['wali_murid_id'] == parentId;
    }).toList();
  } catch (e) {
    print('Error getting siswa by parent ID: $e');
    return [];
  }
}

void _showStudentSelectionDialog(
  BuildContext context,
  Map<String, dynamic> parent,
  List<dynamic> siswaData,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Pilih Anak'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: siswaData.length,
          itemBuilder: (context, index) {
            final siswa = siswaData[index];
            return ListTile(
              leading: CircleAvatar(child: Text(siswa['nama'][0])),
              title: Text(siswa['nama']),
              subtitle: Text('Kelas: ${siswa['kelas_nama'] ?? '-'}'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PresenceParentPage(
                      parent: parent,
                      siswaId: siswa['id'],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal'),
        ),
      ],
    ),
  );
}

// parent_class_activity.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_class_activity_services.dart';
import 'package:manajemensekolah/services/api_student_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentClassActivityScreen extends StatefulWidget {
  const ParentClassActivityScreen({super.key});

  @override
  ParentClassActivityScreenState createState() =>
      ParentClassActivityScreenState();
}

class ParentClassActivityScreenState extends State<ParentClassActivityScreen> {
  List<dynamic> _activityList = [];
  List<dynamic> _studentList = [];
  String? _selectedStudentId;
  String _parentName = '';
  bool _isLoading = true;

  final Map<String, Color> _dayColorMap = {
    'Senin': Color(0xFF6366F1),
    'Selasa': Color(0xFF10B981),
    'Rabu': Color(0xFFF59E0B),
    'Kamis': Color(0xFFEF4444),
    'Jumat': Color(0xFF8B5CF6),
    'Sabtu': Color(0xFF06B6D4),
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = json.decode(prefs.getString('user') ?? '{}');

      setState(() {
        _parentName = userData['nama']?.toString() ?? 'Wali Murid';
      });

      await _loadStudentsForParent();
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error load user data: $e');
    }
  }

  Future<void> _loadStudentsForParent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = json.decode(prefs.getString('user') ?? '{}');
      final parentId = userData['id']?.toString() ?? '';

      // Dapatkan semua siswa dan filter berdasarkan parent
      final allStudents = await ApiStudentService.getStudent();

      // Filter siswa berdasarkan berbagai kemungkinan relasi
      final filteredStudents = allStudents.where((student) {
        // Cek berbagai kemungkinan field yang menghubungkan siswa dengan wali
        return student['email_wali'] == userData['email'] ||
            student['nama_wali'] == userData['nama'] ||
            student['parent_id'] == parentId ||
            student['wali_id'] == parentId ||
            (userData['siswa_id'] != null &&
                student['id'] == userData['siswa_id']);
      }).toList();

      setState(() {
        _studentList = filteredStudents;
      });

      // Jika hanya ada 1 siswa, langsung pilih dan load aktivitasnya
      if (_studentList.isNotEmpty) {
        if (_studentList.length == 1) {
          _selectedStudentId = _studentList[0]['id'];
          await _loadActivities();
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error load students for parent: $e');
    }
  }

  Future<void> _loadActivities() async {
    if (_selectedStudentId == null) return;

    try {
      setState(() => _isLoading = true);

      final selectedStudent = _studentList.firstWhere(
        (s) => s['id'] == _selectedStudentId,
        orElse: () => {},
      );

      if (selectedStudent.isNotEmpty && selectedStudent['kelas_id'] != null) {
        final activities = await ApiClassActivityService.getKegiatanByKelas(
          selectedStudent['kelas_id'],
          siswaId: _selectedStudentId,
        );

        setState(() {
          _activityList = activities;
          _isLoading = false;
        });
      } else {
        setState(() {
          _activityList = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error load activities: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat aktivitas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStudentSelector() {
    if (_studentList.isEmpty) {
      return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tidak ada data siswa/anak yang terhubung dengan akun ini',
                style: TextStyle(color: Colors.orange.shade800),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Pilih Anak:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<String>(
                value: _selectedStudentId,
                isExpanded: true,
                underline: SizedBox(), // Hapus garis bawah default
                items: _studentList.map((student) {
                  return DropdownMenuItem<String>(
                    value: student['id'],
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            student['nama'] ?? 'Nama tidak tersedia',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Kelas: ${student['kelas_nama'] ?? '-'} • NIS: ${student['nis'] ?? '-'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStudentId = value;
                  });
                  _loadActivities();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    if (_selectedStudentId == null) {
      return _buildEmptyState(
        'Pilih anak terlebih dahulu untuk melihat aktivitas',
      );
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_activityList.isEmpty) {
      return _buildEmptyState('Belum ada aktivitas untuk anak ini');
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _activityList.length,
      itemBuilder: (context, index) {
        final activity = _activityList[index];
        final day = activity['hari']?.toString() ?? 'Unknown';
        final cardColor = _getDayColor(day);
        final isAssignment = activity['jenis'] == 'tugas';
        final isSpecificTarget = activity['target'] == 'khusus';
        final isForThisStudent = activity['untuk_siswa_ini'] == true;

        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Activity Header
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isAssignment ? Icons.assignment : Icons.menu_book,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  activity['judul'] ?? 'Judul Kegiatan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      '${activity['mata_pelajaran_nama']} • ${activity['kelas_nama']}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${activity['hari']} • ${_formatDate(activity['tanggal'])}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAssignment
                            ? Colors.orange.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isAssignment ? Colors.orange : Colors.blue,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isAssignment ? 'TUGAS' : 'MATERI',
                        style: TextStyle(
                          color: isAssignment ? Colors.orange : Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isSpecificTarget && isForThisStudent)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.purple, width: 0.5),
                        ),
                        child: Text(
                          'KHUSUS',
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Activity Details
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (activity['deskripsi'] != null &&
                        activity['deskripsi'].isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          activity['deskripsi'],
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    if (activity['judul_bab'] != null)
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${activity['judul_bab']}${activity['judul_sub_bab'] != null ? ' • ${activity['judul_sub_bab']}' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSpecificTarget
                                ? Colors.purple.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSpecificTarget
                                  ? Colors.purple
                                  : Colors.green,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSpecificTarget ? Icons.person : Icons.group,
                                size: 12,
                                color: isSpecificTarget
                                    ? Colors.purple
                                    : Colors.green,
                              ),
                              SizedBox(width: 4),
                              Text(
                                isSpecificTarget
                                    ? 'Khusus Siswa'
                                    : 'Semua Siswa',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSpecificTarget
                                      ? Colors.purple
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        if (isAssignment && activity['batas_waktu'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.red.shade300,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              'Batas: ${_formatDate(activity['batas_waktu'])}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
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
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 80, color: Colors.grey.shade300),
            SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat aktivitas...',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    } catch (e) {
      return date;
    }
  }

  Color _getDayColor(String day) {
    return _dayColorMap[day] ?? Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Aktivitas Kelas Anak',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Color(0xFF8B5CF6), // Warna ungu untuk wali murid
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadActivities,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            height: 120,
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.family_restroom, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _parentName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Wali Murid',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Jumlah Anak: ${_studentList.length}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Student Selector
          _buildStudentSelector(),

          // Activities List
          Expanded(child: _buildActivityList()),
        ],
      ),
    );
  }
}

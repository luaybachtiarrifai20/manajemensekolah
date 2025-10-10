// admin_class_activity.dart
import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_class_activity_services.dart';
import 'package:manajemensekolah/services/api_teacher_services.dart';

class AdminClassActivityScreen extends StatefulWidget {
  const AdminClassActivityScreen({super.key});

  @override
  AdminClassActivityScreenState createState() => AdminClassActivityScreenState();
}

class AdminClassActivityScreenState extends State<AdminClassActivityScreen> {
  List<dynamic> _teacherList = [];
  List<dynamic> _activityList = [];
  final Map<String, List<dynamic>> _activitiesByTeacher = {};
  bool _isLoading = true;
  String? _selectedTeacherId;
  String? _selectedTeacherName;
  bool _showTeacherList = true;

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
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    try {
      setState(() => _isLoading = true);
      
      final apiTeacherService = ApiTeacherService();
      final teachers = await apiTeacherService.getTeacher();
      
      setState(() {
        _teacherList = teachers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Gagal memuat data guru: $e');
    }
  }

  Future<void> _loadActivitiesByTeacher(String teacherId, String teacherName) async {
    try {
      setState(() {
        _isLoading = true;
        _selectedTeacherId = teacherId;
        _selectedTeacherName = teacherName;
        _showTeacherList = false;
      });

      // Cek apakah sudah ada data aktivitas untuk guru ini
      if (_activitiesByTeacher.containsKey(teacherId)) {
        setState(() {
          _activityList = _activitiesByTeacher[teacherId]!;
          _isLoading = false;
        });
        return;
      }

      // Load data baru dari API
      final activities = await ApiClassActivityService.getKegiatanByGuru(teacherId);
      
      setState(() {
        _activityList = activities;
        _activitiesByTeacher[teacherId] = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Gagal memuat kegiatan: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _backToTeacherList() {
    setState(() {
      _showTeacherList = true;
      _selectedTeacherId = null;
      _selectedTeacherName = null;
    });
  }

  Widget _buildTeacherList() {
    if (_teacherList.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
            SizedBox(height: 16),
            Text(
              'Tidak ada data guru',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadTeachers,
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _teacherList.length,
      itemBuilder: (context, index) {
        final teacher = _teacherList[index];
        final teacherName = teacher['nama']?.toString() ?? 'Nama tidak tersedia';
        final teacherEmail = teacher['email']?.toString() ?? '';
        final teacherSubject = teacher['mata_pelajaran_nama']?.toString() ?? 'Mata Pelajaran';

        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                Icons.person,
                color: Color(0xFF4F46E5),
                size: 24,
              ),
            ),
            title: Text(
              teacherName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  teacherEmail,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  teacherSubject,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: () => _loadActivitiesByTeacher(
              teacher['id'].toString(),
              teacherName,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityList() {
    if (_activityList.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 80, color: Colors.grey.shade300),
            SizedBox(height: 16),
            Text(
              'Belum ada kegiatan',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Guru ${_selectedTeacherName} belum membuat kegiatan kelas',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Kelompokkan kegiatan berdasarkan target
    final umumActivities = _activityList.where((activity) => activity['target'] == 'umum').toList();
    final khususActivities = _activityList.where((activity) => activity['target'] == 'khusus').toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Color(0xFF4F46E5),
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Color(0xFF4F46E5),
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group, size: 18),
                      SizedBox(width: 6),
                      Text('Semua Siswa'),
                      SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          umumActivities.length.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, size: 18),
                      SizedBox(width: 6),
                      Text('Khusus Siswa'),
                      SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          khususActivities.length.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildActivityTabList(umumActivities, 'Semua Siswa'),
                _buildActivityTabList(khususActivities, 'Khusus Siswa'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTabList(List<dynamic> activities, String title) {
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey.shade300),
            SizedBox(height: 16),
            Text(
              'Tidak ada kegiatan $title.toLowerCase()',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        final day = activity['hari']?.toString() ?? 'Unknown';
        final cardColor = _getDayColor(day);
        final isAssignment = activity['jenis'] == 'tugas';
        final isSpecificTarget = activity['target'] == 'khusus';

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
                trailing: Container(
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

                    if (activity['bab_judul'] != null)
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
                                '${activity['bab_judul']}${activity['sub_bab_judul'] != null ? ' • ${activity['sub_bab_judul']}' : ''}',
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
                        if (isAssignment)
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
            _showTeacherList ? 'Memuat data guru...' : 'Memuat kegiatan...',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _showTeacherList ? 'Kegiatan Kelas - Semua Guru' : 'Kegiatan - $_selectedTeacherName',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _showTeacherList 
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: _backToTeacherList,
                tooltip: 'Kembali ke daftar guru',
              ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _showTeacherList ? _loadTeachers : () {
              if (_selectedTeacherId != null) {
                _loadActivitiesByTeacher(_selectedTeacherId!, _selectedTeacherName!);
              }
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : (
        _showTeacherList ? _buildTeacherList() : _buildActivityList()
      ),
    );
  }
}
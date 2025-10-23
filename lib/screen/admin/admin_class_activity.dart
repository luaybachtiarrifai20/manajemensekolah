// admin_class_activity.dart
import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_class_activity_services.dart';
import 'package:manajemensekolah/services/api_teacher_services.dart';
import 'package:manajemensekolah/components/enhanced_search_bar.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/components/error_screen.dart';
import 'package:manajemensekolah/services/excel_class_activity_service.dart';
import 'package:manajemensekolah/utils/color_utils.dart';
import 'package:manajemensekolah/utils/language_utils.dart';
import 'package:provider/provider.dart';

class AdminClassActivityScreen extends StatefulWidget {
  const AdminClassActivityScreen({super.key});

  @override
  AdminClassActivityScreenState createState() =>
      AdminClassActivityScreenState();
}

class AdminClassActivityScreenState extends State<AdminClassActivityScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _teacherList = [];
  List<dynamic> _activityList = [];
  final Map<String, List<dynamic>> _activitiesByTeacher = {};
  bool _isLoading = true;
  String? _selectedTeacherId;
  String? _selectedTeacherName;
  bool _showTeacherList = true;
  String? _errorMessage;

  // Search dan filter
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filterOptions = ['All', 'Assignment', 'Material'];
  String _selectedFilter = 'All';

  // Animations
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadTeachers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final apiTeacherService = ApiTeacherService();
      final teachers = await apiTeacherService.getTeacher();

      setState(() {
        _teacherList = teachers;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      _showErrorSnackBar('Gagal memuat data guru: $e');
    }
  }

  // Method untuk export data
  Future<void> exportActivities() async {
    if (_activityList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak ada data kegiatan untuk diexport'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ExcelClassActivityService.exportClassActivitiesToExcel(
        activities: _activityList,
        context: context,
      );
    } catch (e) {
      print('Error exporting activities: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadActivitiesByTeacher(
    String teacherId,
    String teacherName,
  ) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
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
        _animationController.forward();
        return;
      }

      // Load data baru dari API
      final activities = await ApiClassActivityService.getKegiatanByGuru(
        teacherId,
      );

      setState(() {
        _activityList = activities;
        _activitiesByTeacher[teacherId] = activities;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
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
      _searchController.clear();
      _selectedFilter = 'All';
    });
    _animationController.forward();
  }

  List<dynamic> _getFilteredTeachers() {
    final searchTerm = _searchController.text.toLowerCase();
    return _teacherList.where((teacher) {
      final teacherName = teacher['nama']?.toString().toLowerCase() ?? '';
      final teacherEmail = teacher['email']?.toString().toLowerCase() ?? '';
      final teacherSubject =
          teacher['mata_pelajaran_nama']?.toString().toLowerCase() ?? '';

      return searchTerm.isEmpty ||
          teacherName.contains(searchTerm) ||
          teacherEmail.contains(searchTerm) ||
          teacherSubject.contains(searchTerm);
    }).toList();
  }

  List<dynamic> _getFilteredActivities() {
    final searchTerm = _searchController.text.toLowerCase();
    return _activityList.where((activity) {
      final title = activity['judul']?.toString().toLowerCase() ?? '';
      final subject =
          activity['mata_pelajaran_nama']?.toString().toLowerCase() ?? '';
      final className = activity['kelas_nama']?.toString().toLowerCase() ?? '';
      final description = activity['deskripsi']?.toString().toLowerCase() ?? '';

      final matchesSearch =
          searchTerm.isEmpty ||
          title.contains(searchTerm) ||
          subject.contains(searchTerm) ||
          className.contains(searchTerm) ||
          description.contains(searchTerm);

      final isAssignment = activity['jenis'] == 'tugas';
      final matchesFilter =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'Assignment' && isAssignment) ||
          (_selectedFilter == 'Material' && !isAssignment);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher, int index) {
    final teacherName = teacher['nama']?.toString() ?? 'Nama tidak tersedia';
    final teacherEmail = teacher['email']?.toString() ?? '';
    final teacherSubject =
        teacher['mata_pelajaran_nama']?.toString() ?? 'Mata Pelajaran';

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = index * 0.1;
        final animation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, 1.0, curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () =>
            _loadActivitiesByTeacher(teacher['id'].toString(), teacherName),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _loadActivitiesByTeacher(
                teacher['id'].toString(),
                teacherName,
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Strip biru di pinggir kiri
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 6,
                        decoration: BoxDecoration(
                          color: _getPrimaryColor(),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    // Background pattern effect
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header dengan nama dan email
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      teacherName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      teacherEmail,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPrimaryColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getPrimaryColor().withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'Guru',
                                  style: TextStyle(
                                    color: _getPrimaryColor(),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Informasi mata pelajaran
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _getPrimaryColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.menu_book,
                                  color: _getPrimaryColor(),
                                  size: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mata Pelajaran',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 1),
                                    Text(
                                      teacherSubject,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Action button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildActionButton(
                                icon: Icons.visibility,
                                label: 'Lihat Kegiatan',
                                color: _getPrimaryColor(),
                                backgroundColor: Colors.white,
                                borderColor: _getPrimaryColor(),
                                onPressed: () => _loadActivitiesByTeacher(
                                  teacher['id'].toString(),
                                  teacherName,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, int index) {
    final isAssignment = activity['jenis'] == 'tugas';
    final isSpecificTarget = activity['target'] == 'khusus';

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = index * 0.1;
        final animation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, 1.0, curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showActivityDetail(activity),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 5,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Strip biru di pinggir kiri
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 6,
                      decoration: BoxDecoration(
                        color: _getPrimaryColor(),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  // Background pattern effect
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header dengan judul dan jenis
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity['judul'] ?? 'Judul Kegiatan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${activity['mata_pelajaran_nama']} • ${activity['kelas_nama']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getPrimaryColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getPrimaryColor().withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                isAssignment ? 'TUGAS' : 'MATERI',
                                style: TextStyle(
                                  color: _getPrimaryColor(),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // Informasi tanggal dan hari
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _getPrimaryColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.calendar_today,
                                color: _getPrimaryColor(),
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tanggal',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 1),
                                  Text(
                                    '${activity['hari']} • ${_formatDate(activity['tanggal'])}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Informasi guru
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _getPrimaryColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.person,
                                color: _getPrimaryColor(),
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Guru Pengajar',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 1),
                                  Text(
                                    activity['guru_nama'] ?? 'Tidak Diketahui',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Informasi deskripsi
                        if (activity['deskripsi'] != null &&
                            activity['deskripsi'].isNotEmpty) ...[
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _getPrimaryColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.description,
                                  color: _getPrimaryColor(),
                                  size: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Deskripsi',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 1),
                                    Text(
                                      activity['deskripsi'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],

                        SizedBox(height: 12),

                        // Status dan action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSpecificTarget
                                    ? Colors.purple.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSpecificTarget
                                      ? Colors.purple
                                      : Colors.green,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSpecificTarget
                                        ? Icons.person
                                        : Icons.group,
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
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildActionButton(
                              icon: Icons.visibility,
                              label: 'Detail',
                              color: _getPrimaryColor(),
                              backgroundColor: Colors.white,
                              borderColor: _getPrimaryColor(),
                              onPressed: () => _showActivityDetail(activity),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? backgroundColor,
    Color? borderColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor ?? Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivityDetail(Map<String, dynamic> activity) {
    final languageProvider = context.read<LanguageProvider>();
    final isAssignment = activity['jenis'] == 'tugas';
    final isSpecificTarget = activity['target'] == 'khusus';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan gradient
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: _getCardGradient(),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isAssignment ? Icons.assignment : Icons.menu_book,
                        size: 30,
                        color: _getPrimaryColor(),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      activity['judul'] ?? 'Judul Kegiatan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${activity['mata_pelajaran_nama']} • ${activity['kelas_nama']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      icon: Icons.person,
                      label: 'Guru Pengajar',
                      value: activity['guru_nama'] ?? 'Tidak Diketahui',
                    ),
                    _buildDetailItem(
                      icon: Icons.calendar_today,
                      label: 'Hari',
                      value: activity['hari'] ?? '-',
                    ),
                    _buildDetailItem(
                      icon: Icons.date_range,
                      label: 'Tanggal',
                      value: _formatDate(activity['tanggal']),
                    ),
                    if (isAssignment)
                      _buildDetailItem(
                        icon: Icons.access_time,
                        label: 'Batas Waktu',
                        value: _formatDate(activity['batas_waktu']),
                      ),
                    _buildDetailItem(
                      icon: Icons.category,
                      label: 'Jenis Kegiatan',
                      value: isAssignment ? 'Tugas' : 'Materi',
                    ),
                    _buildDetailItem(
                      icon: Icons.group,
                      label: 'Target Siswa',
                      value: isSpecificTarget ? 'Khusus Siswa' : 'Semua Siswa',
                    ),

                    if (activity['deskripsi'] != null &&
                        activity['deskripsi'].isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        'Deskripsi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          activity['deskripsi'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],

                    if (activity['judul_bab'] != null ||
                        activity['judul_sub_bab'] != null) ...[
                      SizedBox(height: 16),
                      Text(
                        'Informasi Bab',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (activity['judul_bab'] != null)
                        _buildDetailItem(
                          icon: Icons.menu_book,
                          label: 'Bab',
                          value: activity['judul_bab']!,
                        ),
                      if (activity['judul_sub_bab'] != null)
                        _buildDetailItem(
                          icon: Icons.bookmark,
                          label: 'Sub Bab',
                          value: activity['judul_sub_bab']!,
                        ),
                    ],

                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              languageProvider.getTranslatedText({
                                'en': 'Close',
                                'id': 'Tutup',
                              }),
                              style: TextStyle(color: Colors.grey.shade700),
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
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getPrimaryColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: _getPrimaryColor()),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPrimaryColor() {
    return Color(0xFF2563EB); // Blue untuk admin
  }

  LinearGradient _getCardGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_getPrimaryColor(), _getPrimaryColor().withOpacity(0.7)],
    );
  }

  Color _getDayColor(String day) {
    return _dayColorMap[day] ?? Color(0xFF6B7280);
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

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        if (_isLoading) {
          return LoadingScreen(
            message: _showTeacherList
                ? languageProvider.getTranslatedText({
                    'en': 'Loading teacher data...',
                    'id': 'Memuat data guru...',
                  })
                : languageProvider.getTranslatedText({
                    'en': 'Loading activities...',
                    'id': 'Memuat kegiatan...',
                  }),
          );
        }

        if (_errorMessage != null) {
          return ErrorScreen(
            errorMessage: _errorMessage!,
            onRetry: _showTeacherList
                ? _loadTeachers
                : () {
                    if (_selectedTeacherId != null) {
                      _loadActivitiesByTeacher(
                        _selectedTeacherId!,
                        _selectedTeacherName!,
                      );
                    }
                  },
          );
        }

        final filteredItems = _showTeacherList
            ? _getFilteredTeachers()
            : _getFilteredActivities();

        return Scaffold(
          backgroundColor: Color(0xFFF8F9FA),
          appBar: AppBar(
            title: Text(
              _showTeacherList
                  ? languageProvider.getTranslatedText({
                      'en': 'Class Activities - All Teachers',
                      'id': 'Kegiatan Kelas - Semua Guru',
                    })
                  : languageProvider.getTranslatedText({
                      'en': 'Activities - $_selectedTeacherName',
                      'id': 'Kegiatan - $_selectedTeacherName',
                    }),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: _getPrimaryColor(),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            leading: _showTeacherList
                ? null
                : IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _backToTeacherList,
                    tooltip: languageProvider.getTranslatedText({
                      'en': 'Back to teacher list',
                      'id': 'Kembali ke daftar guru',
                    }),
                  ),
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'export':
                      exportActivities();
                      break;
                    case 'refresh':
                      if (_showTeacherList) {
                        _loadTeachers();
                      } else {
                        if (_selectedTeacherId != null) {
                          _loadActivitiesByTeacher(
                            _selectedTeacherId!,
                            _selectedTeacherName!,
                          );
                        }
                      }
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.file_download, color: _getPrimaryColor()),
                        SizedBox(width: 8),
                        Text(
                          languageProvider.getTranslatedText({
                            'en': 'Export to Excel',
                            'id': 'Export ke Excel',
                          }),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: _getPrimaryColor()),
                        SizedBox(width: 8),
                        Text(
                          languageProvider.getTranslatedText({
                            'en': 'Refresh',
                            'id': 'Refresh',
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              EnhancedSearchBar(
                controller: _searchController,
                hintText: _showTeacherList
                    ? languageProvider.getTranslatedText({
                        'en': 'Search teachers...',
                        'id': 'Cari guru...',
                      })
                    : languageProvider.getTranslatedText({
                        'en': 'Search activities...',
                        'id': 'Cari kegiatan...',
                      }),
                onChanged: (value) => setState(() {}),
                filterOptions: _showTeacherList
                    ? ['All', 'With Activities', 'Without Activities']
                    : _filterOptions,
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                showFilter: !_showTeacherList,
              ),
              if (filteredItems.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${filteredItems.length} ${_showTeacherList ? languageProvider.getTranslatedText({'en': 'teachers found', 'id': 'guru ditemukan'}) : languageProvider.getTranslatedText({'en': 'activities found', 'id': 'kegiatan ditemukan'})}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 4),
              Expanded(
                child: filteredItems.isEmpty
                    ? EmptyState(
                        title: _showTeacherList
                            ? languageProvider.getTranslatedText({
                                'en': 'No teachers',
                                'id': 'Tidak ada guru',
                              })
                            : languageProvider.getTranslatedText({
                                'en': 'No activities',
                                'id': 'Tidak ada kegiatan',
                              }),
                        subtitle: _searchController.text.isEmpty
                            ? _showTeacherList
                                  ? languageProvider.getTranslatedText({
                                      'en': 'No teacher data available',
                                      'id': 'Data guru tidak tersedia',
                                    })
                                  : languageProvider.getTranslatedText({
                                      'en':
                                          'Teacher $_selectedTeacherName has not created class activities',
                                      'id':
                                          'Guru $_selectedTeacherName belum membuat kegiatan kelas',
                                    })
                            : languageProvider.getTranslatedText({
                                'en': 'No search results found',
                                'id': 'Tidak ditemukan hasil pencarian',
                              }),
                        icon: _showTeacherList
                            ? Icons.people_outline
                            : Icons.event_note,
                      )
                    : ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return _showTeacherList
                              ? _buildTeacherCard(item, index)
                              : _buildActivityCard(item, index);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// kegiatan_kelas.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manajemensekolah/components/enhanced_search_bar.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/services/api_subject_services.dart';
import 'package:manajemensekolah/services/api_class_activity_services.dart';
import 'package:manajemensekolah/services/api_schedule_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manajemensekolah/utils/language_utils.dart';
import 'package:manajemensekolah/utils/color_utils.dart';
import 'package:provider/provider.dart';

class ClassActifityScreen extends StatefulWidget {
  const ClassActifityScreen({super.key});

  @override
  ClassActifityScreenState createState() => ClassActifityScreenState();
}

class ClassActifityScreenState extends State<ClassActifityScreen>
    with TickerProviderStateMixin {
  List<dynamic> _scheduleList = [];
  List<dynamic> _subjectList = [];
  List<dynamic> _chapterList = [];
  List<dynamic> _subChapterList = [];
  List<dynamic> _activityList = [];
  List<dynamic> _studentList = [];

  bool _isLoading = true;
  String _teacherId = '';
  String _teacherName = '';
  String _selectedDay = 'Semua Hari';
  String _selectedClass = 'Semua Kelas';

  // Search dan Filter
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filterOptions = ['All', 'Today', 'This Week'];
  String _selectedFilter = 'All';

  late TabController _tabController;
  String _currentTarget = 'umum';

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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      _currentTarget = _tabController.index == 0 ? 'umum' : 'khusus';
    });
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = json.decode(prefs.getString('user') ?? '{}');

      setState(() {
        _teacherId = userData['id']?.toString() ?? '';
        _teacherName = userData['nama']?.toString() ?? 'Guru';
      });

      if (_teacherId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      await _loadSchedule();
      await _loadActivities();
    } catch (e) {
      setState(() => _isLoading = false);
      if (kDebugMode) {
        print('Error load user data: $e');
      }
    }
  }

  Future<void> _loadSchedule() async {
    try {
      final schedule = await ApiScheduleService.getScheduleByGuru(
        guruId: _teacherId,
        tahunAjaran: '2024/2025',
      );

      final uniqueSubjects = <String, dynamic>{};
      final uniqueClasses = <String, dynamic>{};

      for (var scheduleItem in schedule) {
        final subjectId = scheduleItem['mata_pelajaran_id']?.toString();
        final subjectName = scheduleItem['mata_pelajaran_nama']?.toString();
        final classId = scheduleItem['kelas_id']?.toString();
        final className = scheduleItem['kelas_nama']?.toString();

        if (subjectId != null && !uniqueSubjects.containsKey(subjectId)) {
          uniqueSubjects[subjectId] = {'id': subjectId, 'nama': subjectName};
        }

        if (classId != null && !uniqueClasses.containsKey(classId)) {
          uniqueClasses[classId] = {'id': classId, 'nama': className};
        }
      }

      setState(() {
        _scheduleList = schedule;
        _subjectList = uniqueSubjects.values.toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error load schedule: $e');
      }
    }
  }

  void _showAddActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => AddActivityDialog(
        teacherId: _teacherId,
        teacherName: _teacherName,
        scheduleList: _scheduleList,
        subjectList: _subjectList,
        chapterList: _chapterList,
        subChapterList: _subChapterList,
        onSubjectSelected: _loadMaterials,
        onChapterSelected: _loadSubChapterMaterials,
        onActivityAdded: _loadActivities,
        initialTarget: _currentTarget,
      ),
    );
  }

  List<dynamic> _getFilteredActivities() {
    final searchTerm = _searchController.text.toLowerCase();
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    return _activityList.where((activity) {
      final matchesTarget = activity['target'] == _currentTarget;

      final matchesSearch =
          searchTerm.isEmpty ||
          (activity['judul']?.toString().toLowerCase().contains(searchTerm) ??
              false) ||
          (activity['mata_pelajaran_nama']?.toString().toLowerCase().contains(
                searchTerm,
              ) ??
              false);

      final activityDate = activity['tanggal'] != null
          ? DateTime.tryParse(activity['tanggal'])
          : null;

      final matchesFilter =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'Today' &&
              activityDate != null &&
              _isSameDay(activityDate, now)) ||
          (_selectedFilter == 'This Week' &&
              activityDate != null &&
              activityDate.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
              activityDate.isBefore(endOfWeek.add(Duration(days: 1))));

      return matchesTarget && matchesSearch && matchesFilter;
    }).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // ========== HEADER BARU SEPERTI PENGUMUMAN ==========
  Widget _buildHeader(LanguageProvider languageProvider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: _getCardGradient(),
        boxShadow: [
          BoxShadow(
            color: _getPrimaryColor().withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageProvider.getTranslatedText({
                        'en': 'Class Activities',
                        'id': 'Kegiatan Kelas',
                      }),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      languageProvider.getTranslatedText({
                        'en': 'Manage class materials and assignments',
                        'id': 'Kelola materi dan tugas kelas',
                      }),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.event_note, color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========== TAB BAR BARU SEPERTI PRESENCE TEACHER ==========
  Widget _buildTabSwitcher(LanguageProvider languageProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              0,
              languageProvider.getTranslatedText({
                'en': 'All Students',
                'id': 'Semua Siswa',
              }),
              Icons.group,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              1,
              languageProvider.getTranslatedText({
                'en': 'Specific Student',
                'id': 'Khusus Siswa',
              }),
              Icons.person,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int tabIndex, String text, IconData icon) {
    final isSelected = _tabController.index == tabIndex;

    return Material(
      color: isSelected
          ? _getPrimaryColor().withOpacity(0.85)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _tabController.animateTo(tabIndex);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    final filteredActivities = _getFilteredActivities();

    if (filteredActivities.isEmpty) {
      return _buildEmptyStateForTab();
    }

    return Column(
      children: [
        // Search Bar dengan Filter
        Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            final translatedFilterOptions = [
              languageProvider.getTranslatedText({'en': 'All', 'id': 'Semua'}),
              languageProvider.getTranslatedText({
                'en': 'Today',
                'id': 'Hari Ini',
              }),
              languageProvider.getTranslatedText({
                'en': 'This Week',
                'id': 'Minggu Ini',
              }),
            ];

            return EnhancedSearchBar(
              controller: _searchController,
              hintText: languageProvider.getTranslatedText({
                'en': 'Search activities...',
                'id': 'Cari kegiatan...',
              }),
              onChanged: (value) {
                setState(() {});
              },
              filterOptions: translatedFilterOptions,
              selectedFilter:
                  translatedFilterOptions[_selectedFilter == 'All'
                      ? 0
                      : _selectedFilter == 'Today'
                      ? 1
                      : 2],
              onFilterChanged: (filter) {
                final index = translatedFilterOptions.indexOf(filter);
                setState(() {
                  _selectedFilter = index == 0
                      ? 'All'
                      : index == 1
                      ? 'Today'
                      : 'This Week';
                });
              },
              showFilter: true,
            );
          },
        ),

        if (filteredActivities.isNotEmpty)
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${filteredActivities.length} ${languageProvider.getTranslatedText({'en': 'activities found', 'id': 'kegiatan ditemukan'})}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
        SizedBox(height: 8),

        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: filteredActivities.length,
            itemBuilder: (context, index) {
              final activity = filteredActivities[index];
              return _buildActivityCard(activity, context);
            },
          ),
        ),
      ],
    );
  }

  // ========== CARD BARU SEPERTI PENGUMUMAN ==========
  Widget _buildActivityCard(dynamic activity, BuildContext context) {
    final day = activity['hari']?.toString() ?? 'Unknown';
    final cardColor = _getDayColor(day);
    final isAssignment = activity['jenis'] == 'tugas';
    final isSpecificTarget = activity['target'] == 'khusus';
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    return GestureDetector(
      onTap: () {
        // TODO: Add detail navigation if needed
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
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
                  // Strip berwarna di pinggir kiri
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 6,
                      decoration: BoxDecoration(
                        color: cardColor,
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

                  // Activity type badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAssignment ? Colors.orange : Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAssignment
                            ? languageProvider.getTranslatedText({
                                'en': 'ASSIGNMENT',
                                'id': 'TUGAS',
                              })
                            : languageProvider.getTranslatedText({
                                'en': 'MATERIAL',
                                'id': 'MATERI',
                              }),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header dengan judul kegiatan
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
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // Tanggal dan Hari
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: cardColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.calendar_today,
                                color: cardColor,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    languageProvider.getTranslatedText({
                                      'en': 'Schedule',
                                      'id': 'Jadwal',
                                    }),
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

                        SizedBox(height: 12),

                        // Deskripsi
                        if (activity['deskripsi'] != null &&
                            activity['deskripsi'].isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: cardColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.description,
                                      color: cardColor,
                                      size: 16,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          languageProvider.getTranslatedText({
                                            'en': 'Description',
                                            'id': 'Deskripsi',
                                          }),
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
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                            ],
                          ),

                        // Materi/Bab
                        if (activity['bab_judul'] != null)
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: cardColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.menu_book,
                                  color: cardColor,
                                  size: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      languageProvider.getTranslatedText({
                                        'en': 'Learning Material',
                                        'id': 'Materi Pembelajaran',
                                      }),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 1),
                                    Text(
                                      '${activity['bab_judul']}${activity['sub_bab_judul'] != null ? ' • ${activity['sub_bab_judul']}' : ''}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
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

                        SizedBox(height: 12),

                        // Target dan Deadline
                        Row(
                          children: [
                            // Target
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
                                        ? languageProvider.getTranslatedText({
                                            'en': 'Specific Student',
                                            'id': 'Khusus Siswa',
                                          })
                                        : languageProvider.getTranslatedText({
                                            'en': 'All Students',
                                            'id': 'Semua Siswa',
                                          }),
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

                            // Deadline untuk tugas
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: Colors.red.shade700,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '${languageProvider.getTranslatedText({'en': 'Deadline:', 'id': 'Batas:'})} ${_formatDate(activity['batas_waktu'])}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateForTab() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Column(
          children: [
            // Search Bar
            EnhancedSearchBar(
              controller: _searchController,
              hintText: languageProvider.getTranslatedText({
                'en': 'Search activities...',
                'id': 'Cari kegiatan...',
              }),
              onChanged: (value) {
                setState(() {});
              },
              filterOptions: [
                languageProvider.getTranslatedText({
                  'en': 'All',
                  'id': 'Semua',
                }),
                languageProvider.getTranslatedText({
                  'en': 'Today',
                  'id': 'Hari Ini',
                }),
                languageProvider.getTranslatedText({
                  'en': 'This Week',
                  'id': 'Minggu Ini',
                }),
              ],
              selectedFilter: languageProvider.getTranslatedText({
                'en': 'All',
                'id': 'Semua',
              }),
              onFilterChanged: (filter) {},
              showFilter: true,
            ),
            SizedBox(height: 20),

            Expanded(
              child: EmptyState(
                title: languageProvider.getTranslatedText({
                  'en': 'No Activities',
                  'id': 'Belum ada kegiatan',
                }),
                subtitle:
                    _searchController.text.isEmpty && _selectedFilter == 'All'
                    ? languageProvider.getTranslatedText({
                        'en': _currentTarget == 'umum'
                            ? 'No activities for all students available'
                            : 'No specific student activities available',
                        'id': _currentTarget == 'umum'
                            ? 'Tidak ada kegiatan untuk semua siswa tersedia'
                            : 'Tidak ada kegiatan khusus siswa tersedia',
                      })
                    : languageProvider.getTranslatedText({
                        'en': 'No search results found',
                        'id': 'Tidak ditemukan hasil pencarian',
                      }),
                icon: Icons.event_note,
              ),
            ),

            // Add Activity Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _showAddActivityDialog,
                  icon: Icon(Icons.add, size: 20),
                  label: Text(
                    languageProvider.getTranslatedText({
                      'en': 'Add Activity',
                      'id': 'Tambah Kegiatan',
                    }),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getPrimaryColor(),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),
          ],
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

  Future<void> _loadMaterials(String subjectId) async {
    try {
      final chapterMaterials = await ApiSubjectService.getBabMateri(
        mataPelajaranId: subjectId,
      );

      setState(() {
        _chapterList = chapterMaterials;
        _subChapterList = [];
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error load materials: $e');
      }
    }
  }

  Future<void> _loadSubChapterMaterials(String chapterId) async {
    try {
      final subChapterMaterials = await ApiSubjectService.getSubBabMateri(
        babId: chapterId,
      );

      setState(() {
        _subChapterList = subChapterMaterials;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error load sub chapter: $e');
      }
    }
  }

  Future<void> _loadActivities() async {
    try {
      final activities = await ApiClassActivityService.getKegiatanByGuru(
        _teacherId,
      );
      setState(() {
        _activityList = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (kDebugMode) {
        print('Error load activities: $e');
      }
    }
  }

  Color _getDayColor(String day) {
    return _dayColorMap[day] ?? Color(0xFF6B7280);
  }

  // ========== HELPER FUNCTIONS UNTUK STYLING ==========
  Color _getPrimaryColor() {
    return ColorUtils.getRoleColor('guru');
  }

  LinearGradient _getCardGradient() {
    final primaryColor = _getPrimaryColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, primaryColor.withOpacity(0.7)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: Color(0xFFF8F9FA),
          body: Column(
            children: [
              // Header baru seperti pengumuman
              _buildHeader(languageProvider),

              // Tab Switcher seperti presence teacher
              _buildTabSwitcher(languageProvider),

              // Content
              Expanded(
                child: _isLoading
                    ? LoadingScreen(
                        message: languageProvider.getTranslatedText({
                          'en': 'Loading activities...',
                          'id': 'Memuat kegiatan...',
                        }),
                      )
                    : Column(
                        children: [
                          // Action buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _showAddActivityDialog,
                                    icon: Icon(Icons.add, size: 20),
                                    label: Text(
                                      languageProvider.getTranslatedText({
                                        'en': 'Add Activity',
                                        'id': 'Tambah Kegiatan',
                                      }),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _getPrimaryColor(),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.refresh,
                                      color: _getPrimaryColor(),
                                    ),
                                    onPressed: _loadActivities,
                                    tooltip: languageProvider.getTranslatedText(
                                      {'en': 'Refresh', 'id': 'Muat Ulang'},
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),

                          // Activity List dengan TabBarView
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Tab 1: Untuk Semua Siswa
                                _buildActivityList(),

                                // Tab 2: Khusus Siswa
                                _buildActivityList(),
                              ],
                            ),
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
}

// AddActivityDialog class remains the same as in your original code...
// [Keep the existing AddActivityDialog class unchanged]

class AddActivityDialog extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final List<dynamic> scheduleList;
  final List<dynamic> subjectList;
  final List<dynamic> chapterList;
  final List<dynamic> subChapterList;
  final Function(String) onSubjectSelected;
  final Function(String) onChapterSelected;
  final VoidCallback onActivityAdded;
  final String initialTarget;

  const AddActivityDialog({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.scheduleList,
    required this.subjectList,
    required this.chapterList,
    required this.subChapterList,
    required this.onSubjectSelected,
    required this.onChapterSelected,
    required this.onActivityAdded,
    required this.initialTarget,
  });

  @override
  AddActivityDialogState createState() => AddActivityDialogState();
}

class AddActivityDialogState extends State<AddActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();

  String? _selectedSchedule;
  String? _selectedSubject;
  String? _selectedChapter;
  String? _selectedSubChapter;
  String _activityType = 'materi';

  List<String> _selectedStudents = [];
  List<dynamic> _studentList = [];

  // Dalam class AddActivityDialogState

  @override
  void initState() {
    super.initState();
    _checkTokenValidity();
    if (widget.initialTarget == 'khusus' && _selectedSchedule != null) {
      _loadStudentsForSelectedSchedule();
    }
  }

  Future<void> _checkTokenValidity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sesi telah berakhir. Silakan login kembali.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            }
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking token: $e');
      }
    }
  }

  Future<void> _loadStudentsForSelectedSchedule() async {
    if (_selectedSchedule == null) return;

    try {
      final selectedSchedule = widget.scheduleList.firstWhere(
        (j) => j['id'] == _selectedSchedule,
        orElse: () => {},
      );

      if (selectedSchedule.isNotEmpty) {
        final students = await ApiClassActivityService.getSiswaByKelas(
          selectedSchedule['kelas_id'],
        );
        setState(() {
          _studentList = students;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error load students: $e');
      }
    }
  }

  // Dalam class AddActivityDialogState di kegiatan_kelas.dart

  Future<void> _submitActivity() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_selectedSchedule == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pilih kelas terlebih dahulu'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final selectedSchedule = widget.scheduleList.firstWhere(
          (j) => j['id'] == _selectedSchedule,
          orElse: () => {},
        );

        if (selectedSchedule.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Data jadwal tidak valid'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Validasi token sebelum mengirim data
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        if (token == null || token.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sesi telah berakhir. Silakan login kembali.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Login',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                ),
              ),
            );
          }
          return;
        }

        final activityData = {
          'guru_id': widget.teacherId,
          'judul': _titleController.text,
          'deskripsi': _descriptionController.text,
          'jenis': _activityType,
          'target': widget.initialTarget,
          'mata_pelajaran_id': selectedSchedule['mata_pelajaran_id'],
          'kelas_id': selectedSchedule['kelas_id'],
          'bab_id': _selectedChapter,
          'sub_bab_id': _selectedSubChapter,
          'batas_waktu': _activityType == 'tugas'
              ? _deadlineController.text
              : null,
          'tanggal': DateTime.now().toIso8601String().split('T')[0],
          'hari': selectedSchedule['hari_nama'],
          'siswa_target': widget.initialTarget == 'khusus'
              ? _selectedStudents
              : null,
        };

        // Tampilkan loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );

        await ApiClassActivityService.tambahKegiatan(activityData);

        if (mounted) {
          Navigator.pop(context); // Tutup loading indicator
          Navigator.pop(context); // Tutup dialog
          widget.onActivityAdded();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_activityType == 'tugas' ? 'Tugas' : 'Materi'} berhasil ditambahkan',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Tutup loading indicator jika ada

          String errorMessage = 'Terjadi kesalahan saat menyimpan kegiatan';

          if (e.toString().contains('Token tidak tersedia')) {
            errorMessage = 'Sesi telah berakhir. Silakan login kembali.';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Login',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF4F46E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_task,
                        color: Color(0xFF4F46E5),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tambah Kegiatan ${widget.initialTarget == 'umum' ? 'Semua Siswa' : 'Khusus Siswa'}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Activity Type Selection
                Text(
                  'Jenis Kegiatan',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActivityTypeOption(
                          'materi',
                          'Materi',
                          Icons.menu_book,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade200,
                      ),
                      Expanded(
                        child: _buildActivityTypeOption(
                          'tugas',
                          'Tugas',
                          Icons.assignment,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Judul Kegiatan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF4F46E5)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Judul kegiatan harus diisi';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF4F46E5)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),

                // Schedule/Class Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSchedule,
                  decoration: InputDecoration(
                    labelText: 'Kelas dan Jadwal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF4F46E5)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  isExpanded: true,
                  items: widget.scheduleList.map((schedule) {
                    return DropdownMenuItem<String>(
                      value: schedule['id'],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${schedule['kelas_nama']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${schedule['mata_pelajaran_nama']} • ${schedule['hari_nama']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSchedule = value;
                      if (value != null) {
                        final selectedSchedule = widget.scheduleList.firstWhere(
                          (j) => j['id'] == value,
                          orElse: () => {},
                        );
                        if (selectedSchedule.isNotEmpty) {
                          _selectedSubject =
                              selectedSchedule['mata_pelajaran_id'];
                          widget.onSubjectSelected(_selectedSubject!);

                          if (widget.initialTarget == 'khusus') {
                            _loadStudentsForSelectedSchedule();
                          }
                        }
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih kelas terlebih dahulu';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Subject (auto-filled based on schedule)
                if (_selectedSubject != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.subject, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mata Pelajaran: ${_getSelectedSubjectName()}',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Chapter Material
                if (_selectedSubject != null) ...[
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedChapter,
                    decoration: InputDecoration(
                      labelText: 'Bab Materi (Opsional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF4F46E5)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: widget.chapterList.map((chapter) {
                      return DropdownMenuItem<String>(
                        value: chapter['id'],
                        child: Text(
                          '${chapter['urutan']}. ${chapter['judul_bab']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedChapter = value;
                        _selectedSubChapter = null;
                      });
                      if (value != null) {
                        widget.onChapterSelected(value);
                      }
                    },
                  ),
                ],

                // Sub Chapter Material
                if (_selectedChapter != null &&
                    widget.subChapterList.isNotEmpty) ...[
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSubChapter,
                    decoration: InputDecoration(
                      labelText: 'Sub Bab Materi (Opsional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF4F46E5)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: widget.subChapterList.map((subChapter) {
                      return DropdownMenuItem<String>(
                        value: subChapter['id'],
                        child: Text(
                          '${subChapter['urutan']}. ${subChapter['judul_sub_bab']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubChapter = value;
                      });
                    },
                  ),
                ],

                // Deadline for Assignments
                if (_activityType == 'tugas') ...[
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _deadlineController,
                    decoration: InputDecoration(
                      labelText: 'Batas Waktu (YYYY-MM-DD)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF4F46E5)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ],

                // Student Selection for Specific Target
                if (widget.initialTarget == 'khusus') ...[
                  SizedBox(height: 20),
                  Text(
                    'Pilih Siswa:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (_selectedSchedule == null)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Text(
                          'Pilih kelas terlebih dahulu untuk melihat daftar siswa',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _studentList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8),
                                  Text('Memuat daftar siswa...'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(8),
                              itemCount: _studentList.length,
                              itemBuilder: (context, index) {
                                final student = _studentList[index];
                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 2),
                                  child: CheckboxListTile(
                                    title: Text(
                                      student['nama'],
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    subtitle: student['nis'] != null
                                        ? Text(
                                            'NIS: ${student['nis']}',
                                            style: TextStyle(fontSize: 12),
                                          )
                                        : null,
                                    value: _selectedStudents.contains(
                                      student['id'],
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedStudents.add(student['id']);
                                        } else {
                                          _selectedStudents.remove(
                                            student['id'],
                                          );
                                        }
                                      });
                                    },
                                    dense: true,
                                  ),
                                );
                              },
                            ),
                    ),
                ],

                SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitActivity,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTypeOption(String value, String label, IconData icon) {
    final isSelected = _activityType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _activityType = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFF4F46E5).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: value == 'materi'
              ? BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                )
              : BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Color(0xFF4F46E5) : Colors.grey.shade600,
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Color(0xFF4F46E5) : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSelectedSubjectName() {
    if (_selectedSubject == null) return '';
    final subject = widget.subjectList.firstWhere(
      (s) => s['id'] == _selectedSubject,
      orElse: () => {'nama': ''},
    );
    return subject['nama'] ?? '';
  }
}

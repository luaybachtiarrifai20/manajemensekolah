// class_activity.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/components/new_enhanced_search_bar.dart';
import 'package:manajemensekolah/components/tab_switcher.dart';
import 'package:manajemensekolah/components/filter_sheet.dart';
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

  // Search dan Filter
  final TextEditingController _searchController = TextEditingController();
  String? _selectedDateFilter;
  List<String> _selectedSubjectIds = [];
  bool _hasActiveFilter = false;

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
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return _activityList.where((activity) {
      // Filter berdasarkan tab
      final matchesTarget = activity['target'] == _currentTarget;

      // Filter search
      final matchesSearch =
          searchTerm.isEmpty ||
          (activity['judul']?.toString().toLowerCase().contains(searchTerm) ??
              false) ||
          (activity['mata_pelajaran_nama']?.toString().toLowerCase().contains(
                searchTerm,
              ) ??
              false);

      // Filter tanggal
      final activityDate = activity['tanggal'] != null
          ? DateTime.tryParse(activity['tanggal'])
          : null;

      bool matchesDateFilter = true;
      if (_selectedDateFilter != null && activityDate != null) {
        if (_selectedDateFilter == 'today') {
          matchesDateFilter = _isSameDay(activityDate, now);
        } else if (_selectedDateFilter == 'week') {
          matchesDateFilter =
              activityDate.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
                  activityDate.isBefore(endOfWeek.add(Duration(days: 1)));
        } else if (_selectedDateFilter == 'month') {
          matchesDateFilter =
              activityDate.isAfter(startOfMonth.subtract(Duration(days: 1))) &&
                  activityDate.isBefore(endOfMonth.add(Duration(days: 1)));
        }
      }

      // Filter mata pelajaran
      final matchesSubject =
          _selectedSubjectIds.isEmpty ||
          _selectedSubjectIds.contains(activity['mata_pelajaran_id']?.toString());

      return matchesTarget && matchesSearch && matchesDateFilter && matchesSubject;
    }).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _checkActiveFilter() {
    setState(() {
      _hasActiveFilter =
          _selectedDateFilter != null || _selectedSubjectIds.isNotEmpty;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedDateFilter = null;
      _selectedSubjectIds.clear();
      _hasActiveFilter = false;
    });
  }

  // ========== HEADER SEPERTI PRESENCE TEACHER ==========
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
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'refresh':
                      _loadActivities();
                      break;
                  }
                },
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.more_vert, color: Colors.white, size: 20),
                ),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 20),
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
          SizedBox(height: 16),

          // Tab Switcher menggunakan komponen
          _buildTabSwitcher(languageProvider),
        ],
      ),
    );
  }

  // ========== TAB SWITCHER MENGGUNAKAN KOMPONEN ==========
  Widget _buildTabSwitcher(LanguageProvider languageProvider) {
    final tabs = [
      TabItem(
        label: languageProvider.getTranslatedText({
          'en': 'All Students',
          'id': 'Semua Siswa',
        }),
        icon: Icons.group,
      ),
      TabItem(
        label: languageProvider.getTranslatedText({
          'en': 'Specific Student',
          'id': 'Khusus Siswa',
        }),
        icon: Icons.person,
      ),
    ];

    return TabSwitcher(
      tabController: _tabController,
      tabs: tabs,
      primaryColor: _getPrimaryColor(),
    );
  }

  // ========== SEARCH AND FILTER MENGGUNAKAN KOMPONEN ==========
  Widget _buildSearchAndFilter(LanguageProvider languageProvider) {
    return NewEnhancedSearchBar(
      controller: _searchController,
      onChanged: (value) => setState(() {}),
      hintText: languageProvider.getTranslatedText({
        'en': 'Search activities...',
        'id': 'Cari kegiatan...',
      }),
      showFilter: true,
      hasActiveFilter: _hasActiveFilter,
      onFilterPressed: _showFilterSheet,
      primaryColor: _getPrimaryColor(),
    );
  }

  // ========== FILTER SHEET MENGGUNAKAN KOMPONEN ==========
  void _showFilterSheet() {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    // Siapkan konfigurasi filter
    final filterConfig = FilterConfig(
      sections: [
        FilterSection(
          key: 'date',
          title: languageProvider.getTranslatedText({
            'en': 'Date Range',
            'id': 'Rentang Tanggal',
          }),
          options: [
            FilterOption(
              label: languageProvider.getTranslatedText({
                'en': 'Today',
                'id': 'Hari Ini',
              }),
              value: 'today',
            ),
            FilterOption(
              label: languageProvider.getTranslatedText({
                'en': 'This Week',
                'id': 'Minggu Ini',
              }),
              value: 'week',
            ),
            FilterOption(
              label: languageProvider.getTranslatedText({
                'en': 'This Month',
                'id': 'Bulan Ini',
              }),
              value: 'month',
            ),
          ],
        ),
        FilterSection(
          key: 'subjects',
          title: languageProvider.getTranslatedText({
            'en': 'Subject',
            'id': 'Mata Pelajaran',
          }),
          options: _subjectList.map((subject) {
            return FilterOption(
              label: subject['nama'] ?? 'Subject',
              value: subject['id'].toString(),
            );
          }).toList(),
          multiSelect: true,
        ),
      ],
    );

    // Siapkan filter awal
    final initialFilters = <String, dynamic>{
      'date': _selectedDateFilter,
      'subjects': _selectedSubjectIds,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        config: filterConfig,
        initialFilters: initialFilters,
        onApplyFilters: (Map<String, dynamic> filters) {
          setState(() {
            _selectedDateFilter = filters['date'];
            _selectedSubjectIds = List<String>.from(filters['subjects'] ?? []);
            _checkActiveFilter();
          });
        },
      ),
    );
  }

  // ========== FILTER CHIPS SEPERTI PRESENCE TEACHER ==========
  List<Map<String, dynamic>> _buildFilterChips(
    LanguageProvider languageProvider,
  ) {
    List<Map<String, dynamic>> filterChips = [];

    if (_selectedDateFilter != null) {
      final label = _selectedDateFilter == 'today'
          ? languageProvider.getTranslatedText({
              'en': 'Today',
              'id': 'Hari Ini',
            })
          : _selectedDateFilter == 'week'
          ? languageProvider.getTranslatedText({
              'en': 'This Week',
              'id': 'Minggu Ini',
            })
          : languageProvider.getTranslatedText({
              'en': 'This Month',
              'id': 'Bulan Ini',
            });
      filterChips.add({
        'label':
            '${languageProvider.getTranslatedText({'en': 'Date', 'id': 'Tanggal'})}: $label',
        'onRemove': () {
          setState(() {
            _selectedDateFilter = null;
            _checkActiveFilter();
          });
        },
      });
    }

    if (_selectedSubjectIds.isNotEmpty) {
      filterChips.add({
        'label':
            '${languageProvider.getTranslatedText({'en': 'Subject', 'id': 'Mata Pelajaran'})}: ${_selectedSubjectIds.length}',
        'onRemove': () {
          setState(() {
            _selectedSubjectIds.clear();
            _checkActiveFilter();
          });
        },
      });
    }

    return filterChips;
  }

  Widget _buildActivityList() {
    final filteredActivities = _getFilteredActivities();

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        if (_isLoading) {
          return LoadingScreen(
            message: languageProvider.getTranslatedText({
              'en': 'Loading activities...',
              'id': 'Memuat kegiatan...',
            }),
          );
        }

        return Column(
          children: [
            // Search dan Filter Bar menggunakan komponen
            _buildSearchAndFilter(languageProvider),

            // Filter Chips
            if (_hasActiveFilter) ...[
              SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: Row(
                  children: [
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          ..._buildFilterChips(languageProvider).map((filter) {
                            return Container(
                              margin: EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text(
                                  filter['label'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                deleteIcon: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                onDeleted: filter['onRemove'],
                                backgroundColor: _getPrimaryColor().withOpacity(
                                  0.7,
                                ),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                labelPadding: EdgeInsets.only(left: 4),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: InkWell(
                        onTap: _clearAllFilters,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            languageProvider.getTranslatedText({
                              'en': 'Clear All',
                              'id': 'Hapus Semua',
                            }),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
            ],

            if (filteredActivities.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${filteredActivities.length} ${languageProvider.getTranslatedText({'en': 'activities found', 'id': 'kegiatan ditemukan'})}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 8),

            Expanded(
              child: filteredActivities.isEmpty
                  ? EmptyState(
                      title: languageProvider.getTranslatedText({
                        'en': 'No Activities',
                        'id': 'Belum ada kegiatan',
                      }),
                      subtitle:
                          _searchController.text.isEmpty && !_hasActiveFilter
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
                    )
                  : ListView.builder(
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
      },
    );
  }

  // ========== CARD SEPERTI PENGUMUMAN ==========
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
                                    color: Colors.red,
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      _formatDate(activity['batas_waktu']),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Column(
            children: [
              // Header dengan Tab
              _buildHeader(languageProvider),

              // Content Area
              Expanded(
                child: _buildActivityList(),
              ),
            ],
          ),

          // Floating Action Button untuk menambah kegiatan
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddActivityDialog,
            backgroundColor: _getPrimaryColor(),
            child: Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  // ========== HELPER METHODS ==========
  Color _getDayColor(String day) {
    return _dayColorMap[day] ?? Colors.grey;
  }

  Color _getPrimaryColor() {
    return ColorUtils.getRoleColor('guru');
  }

  LinearGradient _getCardGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _getPrimaryColor(),
        _getPrimaryColor().withOpacity(0.8),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // ========== API METHODS ==========
  Future<void> _loadMaterials(String subjectId) async {
    try {
      final materials = await ApiSubjectService.getMateri(
      );
      setState(() {
        _chapterList = materials;
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
      final subMaterials = await ApiSubjectService.getBabMateri(
        mataPelajaranId: chapterId,
      );
      setState(() {
        _subChapterList = subMaterials;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error load sub chapter materials: $e');
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
}

// TODO: Implement AddActivityDialog sesuai kebutuhan
class AddActivityDialog extends StatelessWidget {
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
    Key? key,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Activity'),
      content: Text('Implement add activity form here'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onActivityAdded();
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
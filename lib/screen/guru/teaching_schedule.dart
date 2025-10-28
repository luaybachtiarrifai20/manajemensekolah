import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/enhanced_search_bar.dart';
import 'package:manajemensekolah/components/filter_section.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/services/api_schedule_services.dart';
import 'package:manajemensekolah/utils/color_utils.dart';
import 'package:manajemensekolah/utils/language_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeachingScheduleScreen extends StatefulWidget {
  const TeachingScheduleScreen({super.key});

  @override
  TeachingScheduleScreenState createState() => TeachingScheduleScreenState();
}

class TeachingScheduleScreenState extends State<TeachingScheduleScreen> {
  List<dynamic> _jadwalList = [];
  List<dynamic> _semesterList = [];
  bool _isLoading = true;
  String _guruId = '';
  String _guruNama = '';
  String _selectedHari = 'Semua Hari';
  String _selectedSemester = '1';
  String _selectedAcademicYear = '2024/2025';
  final TextEditingController _searchController = TextEditingController();

  // Filter options untuk EnhancedSearchBar
  final List<String> _filterOptions = ['All', 'Today', 'This Week'];
  String _selectedFilter = 'All';

  // DITAMBAHKAN KEMBALI: Toggle antara card dan table view
  bool _isTableView = false;

  final List<String> _hariOptions = [
    'Semua Hari',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  final Map<String, String> _hariIdMap = {
    'Senin': '1',
    'Selasa': '2',
    'Rabu': '3',
    'Kamis': '4',
    'Jumat': '5',
    'Sabtu': '6',
  };

  final Map<String, Color> _hariColorMap = {
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = json.decode(prefs.getString('user') ?? '{}');

      setState(() {
        _guruId = userData['id']?.toString() ?? '';
        _guruNama = userData['nama']?.toString() ?? 'Guru';
      });

      if (_guruId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      await _loadSemesterData();
      _loadJadwal();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSemesterData() async {
    try {
      final semesterData = await ApiScheduleService.getSemester();
      setState(() {
        _semesterList = semesterData;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading semester data: $e');
      }
    }
  }

  Future<void> _loadJadwal() async {
    if (_guruId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      setState(() => _isLoading = true);

      final jadwal = await ApiScheduleService.getFilteredSchedule(
        guruId: _guruId,
        hari: _selectedHari != 'Semua Hari' ? _selectedHari : null,
        semester: _selectedSemester,
        tahunAjaran: _selectedAcademicYear,
      );

      setState(() {
        _jadwalList = jadwal;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error load jadwal: $e');
      }
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      _showErrorSnackBar('Failed to load schedule data: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().getTranslatedText({
              'en': message,
              'id': message.replaceAll(
                'Failed to load schedule data:',
                'Gagal memuat data jadwal:',
              ),
            }),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onHariChanged(String newHari) {
    setState(() {
      _selectedHari = newHari;
      _isLoading = true;
    });
    _loadJadwal();
  }

  void _onSemesterChanged(String semesterId) {
    setState(() {
      _selectedSemester = semesterId;
      _isLoading = true;
    });
    _loadJadwal();
  }

  void _onAcademicYearChanged(String academicYear) {
    setState(() {
      _selectedAcademicYear = academicYear;
      _isLoading = true;
    });
    _loadJadwal();
  }

  void _onFilterChanged(String filter) {
    final translatedFilterOptions = ['All', 'Today', 'This Week'];
    final index = _filterOptions.indexOf(filter);
    setState(() {
      _selectedFilter = index == 0
          ? 'All'
          : index == 1
          ? 'Today'
          : 'This Week';
    });
  }

  // DITAMBAHKAN KEMBALI: Method untuk toggle view
  void _toggleView() {
    setState(() {
      _isTableView = !_isTableView;
    });
  }

  Color _getPrimaryColor() {
    return ColorUtils.getRoleColor('guru');
  }

  LinearGradient _getCardGradient() {
    final primaryColor = _getPrimaryColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, primaryColor.withOpacity(0.8)],
    );
  }

  Color _getHariColor(String hari) {
    return _hariColorMap[hari] ?? Color(0xFF6B7280);
  }

  List<dynamic> _getFilteredSchedules() {
    final searchTerm = _searchController.text.toLowerCase();
    return _jadwalList.where((schedule) {
      final subjectName =
          schedule['mata_pelajaran_nama']?.toString().toLowerCase() ?? '';
      final className = schedule['kelas_nama']?.toString().toLowerCase() ?? '';
      final dayName = schedule['hari_nama']?.toString().toLowerCase() ?? '';

      final matchesSearch =
          searchTerm.isEmpty ||
          subjectName.contains(searchTerm) ||
          className.contains(searchTerm) ||
          dayName.contains(searchTerm);

      final today = _getTodayName();
      final matchesFilter =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'Today' && dayName == today.toLowerCase()) ||
          (_selectedFilter == 'This Week' && _isThisWeek(dayName));

      return matchesSearch && matchesFilter;
    }).toList();
  }

  String _getTodayName() {
    final now = DateTime.now();
    final days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    final index = (now.weekday + 6) % 7;
    return days[index];
  }

  bool _isThisWeek(String dayName) {
    final dayMap = {
      'senin': 1,
      'selasa': 2,
      'rabu': 3,
      'kamis': 4,
      'jumat': 5,
      'sabtu': 6,
    };
    return dayMap.containsKey(dayName.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final filteredSchedules = _getFilteredSchedules();

        final translatedFilterOptions = [
          languageProvider.getTranslatedText({'en': 'All', 'id': 'Semua'}),
          languageProvider.getTranslatedText({'en': 'Today', 'id': 'Hari Ini'}),
          languageProvider.getTranslatedText({
            'en': 'This Week',
            'id': 'Minggu Ini',
          }),
        ];

        return Scaffold(
          backgroundColor: Color(0xFFF8F9FA),
          body: Column(
            children: [
              // Header dengan gradient
              Container(
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
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languageProvider.getTranslatedText({
                                  'en': 'Teaching Schedule',
                                  'id': 'Jadwal Mengajar',
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
                                  'en': 'View your teaching schedule',
                                  'id': 'Lihat jadwal mengajar Anda',
                                }),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // DITAMBAHKAN KEMBALI: Tombol toggle view
                        GestureDetector(
                          onTap: _toggleView,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _isTableView ? Icons.grid_view : Icons.list,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.schedule,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Info Guru
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _guruNama,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  languageProvider.getTranslatedText({
                                    'en': 'Teacher',
                                    'id': 'Guru',
                                  }),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Search Bar dengan Filter
                    EnhancedSearchBar(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      hintText: languageProvider.getTranslatedText({
                        'en': 'Search schedules...',
                        'id': 'Cari jadwal...',
                      }),
                      filterOptions: translatedFilterOptions,
                      selectedFilter:
                          translatedFilterOptions[_selectedFilter == 'All'
                              ? 0
                              : _selectedFilter == 'Today'
                              ? 1
                              : 2],
                      onFilterChanged: _onFilterChanged,
                      showFilter: true,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? LoadingScreen(
                        message: languageProvider.getTranslatedText({
                          'en': 'Loading schedule data...',
                          'id': 'Memuat data jadwal...',
                        }),
                      )
                    : Column(
                        children: [
                          // Filter Section untuk Semester dan Tahun Ajaran
                          FilterSection(
                            selectedSemester: _selectedSemester,
                            selectedAcademicYear: _selectedAcademicYear,
                            semesterList: _semesterList,
                            onSemesterChanged: _onSemesterChanged,
                            onAcademicYearChanged: _onAcademicYearChanged,
                          ),
                          SizedBox(height: 8),

                          // Filter Hari
                          _buildHariFilter(languageProvider),
                          SizedBox(height: 8),

                          // DITAMBAHKAN KEMBALI: View Toggle Info
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Text(
                                  '${filteredSchedules.length} ${languageProvider.getTranslatedText({'en': 'schedules found', 'id': 'jadwal ditemukan'})}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  _isTableView
                                      ? languageProvider.getTranslatedText({
                                          'en': 'Table View',
                                          'id': 'Tampilan Tabel',
                                        })
                                      : languageProvider.getTranslatedText({
                                          'en': 'Card View',
                                          'id': 'Tampilan Kartu',
                                        }),
                                  style: TextStyle(
                                    color: _getPrimaryColor(),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 4),

                          Expanded(
                            child: filteredSchedules.isEmpty
                                ? EmptyState(
                                    icon: Icons.schedule_outlined,
                                    title: languageProvider.getTranslatedText({
                                      'en': 'No Teaching Schedules',
                                      'id': 'Tidak Ada Jadwal Mengajar',
                                    }),
                                    subtitle: languageProvider.getTranslatedText({
                                      'en':
                                          _searchController.text.isNotEmpty ||
                                              _selectedFilter != 'All' ||
                                              _selectedHari != 'Semua Hari'
                                          ? 'No schedules found for your search and filters'
                                          : 'There are no teaching schedules available',
                                      'id':
                                          _searchController.text.isNotEmpty ||
                                              _selectedFilter != 'All' ||
                                              _selectedHari != 'Semua Hari'
                                          ? 'Tidak ada jadwal yang sesuai dengan pencarian dan filter'
                                          : 'Tidak ada jadwal mengajar yang tersedia',
                                    }),
                                    buttonText: languageProvider
                                        .getTranslatedText({
                                          'en': 'Refresh',
                                          'id': 'Muat Ulang',
                                        }),
                                    onPressed: _loadJadwal,
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadJadwal,
                                    color: _getPrimaryColor(),
                                    backgroundColor: Colors.white,
                                    child: _isTableView
                                        ? _buildTableView(
                                            languageProvider,
                                            filteredSchedules,
                                          )
                                        : _buildCardView(
                                            languageProvider,
                                            filteredSchedules,
                                          ),
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

  // DITAMBAHKAN KEMBALI: Method untuk table view dengan format seperti Excel
  Widget _buildTableView(
    LanguageProvider languageProvider,
    List<dynamic> schedules,
  ) {
    // Group schedules by day and class
    final Map<String, Map<String, List<dynamic>>> scheduleMap = {};

    for (var schedule in schedules) {
      final hari = schedule['hari_nama']?.toString() ?? 'Unknown';
      final kelas = schedule['kelas_nama']?.toString() ?? 'Unknown';

      if (!scheduleMap.containsKey(hari)) {
        scheduleMap[hari] = {};
      }
      if (!scheduleMap[hari]!.containsKey(kelas)) {
        scheduleMap[hari]![kelas] = [];
      }

      scheduleMap[hari]![kelas]!.add(schedule);
    }

    // Get unique classes and days
    final classes =
        scheduleMap.values.expand((dayMap) => dayMap.keys).toSet().toList()
          ..sort();

    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final availableDays = days
        .where((day) => scheduleMap.containsKey(day))
        .toList();

    // Get all unique session numbers
    final allSessions =
        schedules
            .map((s) => int.tryParse(s['jam_ke']?.toString() ?? '') ?? 0)
            .toSet()
            .toList()
          ..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'JADWAL PELAJARAN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getPrimaryColor(),
                ),
              ),
              SizedBox(height: 16),

              // Table
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Header Row 1 - Hari
                    Container(
                      decoration: BoxDecoration(
                        color: _getPrimaryColor().withOpacity(0.1),
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Empty cells for time and session
                          Container(
                            width: 80,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade400),
                              ),
                            ),
                            child: Text(
                              'Jam Ke-',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            width: 100,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade400),
                              ),
                            ),
                            child: Text(
                              'Waktu',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),

                          // Hari headers
                          ...availableDays.expand((day) {
                            return [
                              Container(
                                width: 200 * classes.length.toDouble(),
                                height: 60,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: availableDays.last == day
                                          ? Colors.transparent
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _getHariColor(day),
                                  ),
                                ),
                              ),
                            ];
                          }),
                        ],
                      ),
                    ),

                    // Header Row 2 - Kelas
                    Container(
                      decoration: BoxDecoration(
                        color: _getPrimaryColor().withOpacity(0.05),
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Empty cells for time and session
                          Container(
                            width: 80,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade400),
                              ),
                            ),
                          ),
                          Container(
                            width: 100,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade400),
                              ),
                            ),
                          ),

                          // Kelas headers for each day
                          ...availableDays.expand((day) {
                            return classes.asMap().entries.map((classEntry) {
                              final isLastInDay =
                                  classEntry.key == classes.length - 1;
                              final isLastDay = availableDays.last == day;

                              return Container(
                                width: 200,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: (isLastInDay && !isLastDay)
                                          ? Colors.grey.shade400
                                          : Colors.transparent,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  classEntry.value,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              );
                            }).toList();
                          }),
                        ],
                      ),
                    ),

                    // Data Rows
                    ...allSessions.map((session) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: session == allSessions.last
                                  ? Colors.transparent
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Session Number
                            Container(
                              width: 80,
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              child: Text(
                                session.toString(),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),

                            // Time
                            Container(
                              width: 100,
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              child: _buildTimeForSession(session, schedules),
                            ),

                            // Schedule Data for each day and class
                            ...availableDays.expand((day) {
                              return classes.map((kelas) {
                                final scheduleForCell =
                                    _getScheduleForSessionAndDayAndClass(
                                      session,
                                      day,
                                      kelas,
                                      schedules,
                                    );

                                return Container(
                                  width: 200,
                                  height: 60,
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color:
                                            classes.last == kelas &&
                                                availableDays.last != day
                                            ? Colors.grey.shade400
                                            : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                  child: scheduleForCell != null
                                      ? Container(
                                          padding: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: _getHariColor(
                                              day,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: _getHariColor(
                                                day,
                                              ).withOpacity(0.3),
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                scheduleForCell['mata_pelajaran_nama'] ??
                                                    '',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getHariColor(day),
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (scheduleForCell['guru_nama'] !=
                                                  null)
                                                Text(
                                                  scheduleForCell['guru_nama']!,
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        )
                                      : Container(),
                                );
                              }).toList();
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Legend
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keterangan:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      children: availableDays.map((day) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getHariColor(day),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(day, style: TextStyle(fontSize: 12)),
                          ],
                        );
                      }).toList(),
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

  // Helper method to get time for session
  Widget _buildTimeForSession(int session, List<dynamic> schedules) {
    final scheduleForSession = schedules.firstWhere(
      (s) => (int.tryParse(s['jam_ke']?.toString() ?? '') ?? 0) == session,
      orElse: () => <String, dynamic>{},
    );

    if (scheduleForSession.isNotEmpty) {
      final startTime = _formatTime(scheduleForSession['jam_mulai']);
      final endTime = _formatTime(scheduleForSession['jam_selesai']);
      return Text(
        '$startTime\n$endTime',
        style: TextStyle(fontSize: 10),
        textAlign: TextAlign.center,
      );
    }

    return Text(
      '--:--\n--:--',
      style: TextStyle(fontSize: 10, color: Colors.grey),
      textAlign: TextAlign.center,
    );
  }

  // Helper method to find schedule for specific session, day, and class
  Map<String, dynamic>? _getScheduleForSessionAndDayAndClass(
    int session,
    String day,
    String kelas,
    List<dynamic> schedules,
  ) {
    try {
      return schedules.firstWhere(
        (s) =>
            (int.tryParse(s['jam_ke']?.toString() ?? '') ?? 0) == session &&
            s['hari_nama']?.toString() == day &&
            s['kelas_nama']?.toString() == kelas,
        orElse: () => <String, dynamic>{},
      );
    } catch (e) {
      return null;
    }
  }

  // DIPINDAH: Method untuk card view (sebelumnya _buildJadwalCard)
  Widget _buildCardView(
    LanguageProvider languageProvider,
    List<dynamic> schedules,
  ) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        return _buildJadwalCard(schedules[index], languageProvider, index);
      },
    );
  }

  Widget _buildHariFilter(LanguageProvider languageProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            languageProvider.getTranslatedText({
              'en': 'Day Filter',
              'id': 'Filter Hari',
            }),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _hariOptions.map((hari) {
                final isSelected = _selectedHari == hari;
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(hari),
                    selected: isSelected,
                    onSelected: (selected) {
                      _onHariChanged(selected ? hari : 'Semua Hari');
                    },
                    backgroundColor: Colors.white,
                    selectedColor: _getPrimaryColor().withOpacity(0.1),
                    checkmarkColor: _getPrimaryColor(),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? _getPrimaryColor()
                          : Colors.grey.shade700,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isSelected
                            ? _getPrimaryColor()
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalCard(
    Map<String, dynamic> jadwal,
    LanguageProvider languageProvider,
    int index,
  ) {
    final hari = jadwal['hari_nama']?.toString() ?? 'Unknown';
    final hariColor = _getHariColor(hari);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Optional: Add detail view if needed
          },
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
                // Strip berwarna di pinggir kiri sesuai hari
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: hariColor,
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
                      // Header dengan mata pelajaran dan tahun ajaran - DIUBAH
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  jadwal['mata_pelajaran_nama'] ??
                                      languageProvider.getTranslatedText({
                                        'en': 'Subject',
                                        'id': 'Mata Pelajaran',
                                      }),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                // DIUBAH: Tahun ajaran di bawah mata pelajaran dengan ukuran kecil
                                Text(
                                  jadwal['tahun_ajaran_nama'] ??
                                      _selectedAcademicYear,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // DIUBAH: Hari diperbesar
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: hariColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: hariColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              hari,
                              style: TextStyle(
                                color: hariColor,
                                fontSize: 14, // DIUBAH: diperbesar dari 12
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      // Informasi waktu
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
                              Icons.access_time,
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
                                  languageProvider.getTranslatedText({
                                    'en': 'Time',
                                    'id': 'Waktu',
                                  }),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 1),
                                Text(
                                  '${_formatTime(jadwal['jam_mulai'])} - ${_formatTime(jadwal['jam_selesai'])}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _getPrimaryColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.format_list_numbered,
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
                                  languageProvider.getTranslatedText({
                                    'en': 'Session',
                                    'id': 'Sesi',
                                  }),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 1),
                                Text(
                                  '${languageProvider.getTranslatedText({'en': 'Hour', 'id': 'Jam'})} ${jadwal['jam_ke'] ?? ''}',
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

                      // Informasi kelas dan semester - DIUBAH: menghapus tahun ajaran dari sini
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
                              Icons.school,
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
                                  languageProvider.getTranslatedText({
                                    'en': 'Class & Semester',
                                    'id': 'Kelas & Semester',
                                  }),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 1),
                                Text(
                                  '${jadwal['kelas_nama'] ?? '-'} • ${jadwal['semester_nama'] ?? 'Semester'}',
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

                      // DIHAPUS: Section tahun ajaran yang terpisah
                      // karena sudah dipindah ke atas
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';

    // Handle various time formats
    final cleanedTime = time.replaceAll('.', ':');
    final timeParts = cleanedTime.split(':');

    if (timeParts.length >= 2) {
      final hour = timeParts[0].padLeft(2, '0');
      final minute = timeParts[1].padLeft(2, '0');
      return '$hour:$minute';
    }

    return time.length >= 5 ? time.substring(0, 5) : time;
  }
}

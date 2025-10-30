import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/filter_sheet.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/components/new_enhanced_search_bar.dart';
import 'package:manajemensekolah/components/tab_switcher.dart';
import 'package:manajemensekolah/models/siswa.dart';
import 'package:manajemensekolah/services/api_class_services.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/api_student_services.dart';
import 'package:manajemensekolah/services/api_teacher_services.dart';
import 'package:manajemensekolah/utils/color_utils.dart';
import 'package:manajemensekolah/utils/language_utils.dart';
import 'package:provider/provider.dart';

// Model untuk Summary Absensi
class AbsensiSummary {
  final String mataPelajaranId;
  final String mataPelajaranNama;
  final DateTime tanggal;
  final int totalSiswa;
  final int hadir;
  final int tidakHadir;
  final String? kelasId;

  AbsensiSummary({
    required this.mataPelajaranId,
    required this.mataPelajaranNama,
    required this.tanggal,
    required this.totalSiswa,
    required this.hadir,
    required this.tidakHadir,
    this.kelasId,
  });

  String get key =>
      '$mataPelajaranId-${DateFormat('yyyy-MM-dd').format(tanggal)}';
}

class PresencePage extends StatefulWidget {
  final Map<String, dynamic> guru;

  const PresencePage({super.key, required this.guru});

  @override
  PresencePageState createState() => PresencePageState();
}

class PresencePageState extends State<PresencePage>
    with SingleTickerProviderStateMixin {
  // Tab Controller for TabSwitcher
  late TabController _tabController;

  // Data untuk mode View Results
  List<AbsensiSummary> _absensiSummaryList = [];
  bool _isLoadingSummary = false;

  // Data untuk mode Input Absensi
  DateTime _selectedDate = DateTime.now();
  String? _selectedMataPelajaran;
  String? _selectedKelas;
  String? _selectedDateFilter;
  List<dynamic> _mataPelajaranList = [];
  List<dynamic> _mataPelajaranDiampu = [];
  List<dynamic> _kelasList = [];
  List<Siswa> _siswaList = [];
  List<Siswa> _filteredSiswaList = [];
  List<String> _selectedSubjectIds = [];
  final Map<String, String> _absensiStatus = {};
  bool _isLoadingInput = true;
  bool _isSubmitting = false;
  bool _hasActiveFilter = false;

  // Search dan Filter
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filterOptions = ['All', 'Today', 'This Week'];
  final String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {
        // Trigger rebuild when tab changes
        if (_tabController.index == 0) {
          _loadAbsensiSummary();
        }
      });
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final apiServiceClass = ApiClassService();
      final [mataPelajaranDiampu, kelas, siswa] = await Future.wait([
        // Ambil mata pelajaran yang diampu oleh guru
        _getMataPelajaranByGuru(widget.guru['id']),
        apiServiceClass.getClass(),
        ApiStudentService.getStudent(),
      ]);

      setState(() {
        _mataPelajaranDiampu = mataPelajaranDiampu;
        _mataPelajaranList = mataPelajaranDiampu; // Gunakan yang diampu saja
        _kelasList = kelas;
        _siswaList = siswa.map((s) => Siswa.fromJson(s)).toList();
        _filteredSiswaList = _siswaList;

        // Set default status untuk semua siswa
        for (var siswa in _siswaList) {
          _absensiStatus[siswa.id] = 'hadir';
        }

        _isLoadingInput = false;
      });

      // Load summary data untuk mode view
      _loadAbsensiSummary();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${languageProvider.getTranslatedText({'en': 'Error loading initial data: $e', 'id': 'Error loading initial data: $e'})} $e',
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      // Check mounted sebelum setState
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<List<dynamic>> _getMataPelajaranByGuru(String guruId) async {
    try {
      final apiTeacherService = ApiTeacherService();
      final result = await apiTeacherService.getSubjectByTeacher(guruId);
      return result;
    } catch (e) {
      print('Error getting mata pelajaran by guru: $e');
      return [];
    }
  }

  Future<void> _loadAbsensiSummary() async {
    // Check mounted sebelum memulai loading
    if (!mounted) return;

    setState(() {
      _isLoadingSummary = true;
    });

    try {
      final absensiData = await ApiService.getAbsensi(
        guruId: widget.guru['id'],
      );

      final Map<String, AbsensiSummary> summaryMap = {};

      for (var absen in absensiData) {
        // Include kelas_id in the grouping key
        final kelasId = absen['kelas_id']?.toString() ?? '';
        final key =
            '${absen['mata_pelajaran_id']}-${absen['tanggal']}-$kelasId';
        final mataPelajaranNama = _getMataPelajaranName(
          absen['mata_pelajaran_id'],
        );

        if (!summaryMap.containsKey(key)) {
          summaryMap[key] = AbsensiSummary(
            mataPelajaranId: absen['mata_pelajaran_id'],
            mataPelajaranNama: mataPelajaranNama,
            tanggal: _parseLocalDate(absen['tanggal']),
            totalSiswa: 0,
            hadir: 0,
            tidakHadir: 0,
            kelasId: kelasId.isNotEmpty ? kelasId : null,
          );
        }

        final summary = summaryMap[key]!;
        summaryMap[key] = AbsensiSummary(
          mataPelajaranId: summary.mataPelajaranId,
          mataPelajaranNama: summary.mataPelajaranNama,
          tanggal: summary.tanggal,
          totalSiswa: summary.totalSiswa + 1,
          hadir: summary.hadir + (absen['status'] == 'hadir' ? 1 : 0),
          tidakHadir: summary.tidakHadir + (absen['status'] != 'hadir' ? 1 : 0),
          kelasId: summary.kelasId,
        );
      }

      // Check mounted sebelum setState
      if (!mounted) return;

      setState(() {
        _absensiSummaryList = summaryMap.values.toList()
          ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
        _isLoadingSummary = false;
      });

      if (kDebugMode) {
        print('Loaded ${_absensiSummaryList.length} absensi summaries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading absensi summary: $e');
      }
      // Check mounted sebelum setState
      if (mounted) {
        setState(() {
          _isLoadingSummary = false;
        });
      }
    }
  }

  String _getMataPelajaranName(String mataPelajaranId) {
    try {
      final mataPelajaran = _mataPelajaranList.firstWhere(
        (mp) => mp['id'] == mataPelajaranId,
        orElse: () => {'nama': 'Unknown'},
      );
      return mataPelajaran['nama'];
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getKelasName(String kelasId) {
    try {
      final kelas = _kelasList.firstWhere(
        (k) => k['id'].toString() == kelasId,
        orElse: () => {'nama': 'Unknown Class'},
      );
      return kelas['nama'] ?? 'Unknown Class';
    } catch (e) {
      return 'Unknown Class';
    }
  }

  // Helper function to parse date string as local date (not UTC)
  DateTime _parseLocalDate(String dateString) {
    // Handle ISO datetime format (e.g., "2025-10-29T17:00:00.000Z")
    // Extract just the date part before 'T'
    String datePart = dateString.contains('T') 
        ? dateString.split('T')[0] 
        : dateString;
    
    // Parse YYYY-MM-DD as local date to avoid timezone conversion
    final parts = datePart.split('-');
    if (parts.length == 3) {
      return DateTime(
        int.parse(parts[0]), // year
        int.parse(parts[1]), // month
        int.parse(parts[2]), // day
      );
    }
    // Fallback to normal parsing if format is unexpected
    return DateTime.parse(dateString);
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

  // ========== MODE SWITCHER ==========
  Widget _buildModeSwitcher(LanguageProvider languageProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TabSwitcher(
        tabController: _tabController,
        primaryColor: _getPrimaryColor(),
        tabs: [
          TabItem(
            label: languageProvider.getTranslatedText({
              'en': 'Attendance Results',
              'id': 'Hasil Absensi',
            }),
            icon: Icons.list_alt,
          ),
          TabItem(
            label: languageProvider.getTranslatedText({
              'en': 'Add Attendance',
              'id': 'Tambah Absensi',
            }),
            icon: Icons.add_circle,
          ),
        ],
      ),
    );
  }

  // ========== MODE 0: VIEW RESULTS ==========
  // ========== MODIFIKASI BUILD RESULTS MODE ==========
  Widget _buildResultsMode() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        if (_isLoadingSummary) {
          return LoadingScreen(
            message: languageProvider.getTranslatedText({
              'en': 'Loading attendance data...',
              'id': 'Memuat data absensi...',
            }),
          );
        }

        final filteredSummaries = _getFilteredSummaries();

        return Column(
          children: [
            // Search dan Filter Bar
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
                          }),
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

            if (filteredSummaries.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${filteredSummaries.length} ${languageProvider.getTranslatedText({'en': 'attendance records found', 'id': 'catatan absensi ditemukan'})}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 8),

            Expanded(
              child: filteredSummaries.isEmpty
                  ? EmptyState(
                      title: languageProvider.getTranslatedText({
                        'en': 'No attendance records',
                        'id': 'Belum ada data absensi',
                      }),
                      subtitle:
                          _searchController.text.isEmpty && !_hasActiveFilter
                          ? languageProvider.getTranslatedText({
                              'en': 'No attendance data available',
                              'id': 'Tidak ada data absensi tersedia',
                            })
                          : languageProvider.getTranslatedText({
                              'en': 'No search results found',
                              'id': 'Tidak ditemukan hasil pencarian',
                            }),
                      icon: Icons.list_alt,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredSummaries.length,
                      itemBuilder: (context, index) {
                        final summary = filteredSummaries[index];
                        return _buildSummaryCard(summary, languageProvider);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ========== MODIFIKASI GET FILTERED SUMMARIES ==========
  List<AbsensiSummary> _getFilteredSummaries() {
    final searchTerm = _searchController.text.toLowerCase();
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return _absensiSummaryList.where((summary) {
      // Search filter
      final matchesSearch =
          searchTerm.isEmpty ||
          summary.mataPelajaranNama.toLowerCase().contains(searchTerm);

      // Date filter
      bool matchesDateFilter = true;
      if (_selectedDateFilter != null) {
        if (_selectedDateFilter == 'today') {
          matchesDateFilter = _isSameDay(summary.tanggal, now);
        } else if (_selectedDateFilter == 'week') {
          matchesDateFilter =
              summary.tanggal.isAfter(
                startOfWeek.subtract(Duration(days: 1)),
              ) &&
              summary.tanggal.isBefore(endOfWeek.add(Duration(days: 1)));
        } else if (_selectedDateFilter == 'month') {
          matchesDateFilter =
              summary.tanggal.isAfter(
                startOfMonth.subtract(Duration(days: 1)),
              ) &&
              summary.tanggal.isBefore(endOfMonth.add(Duration(days: 1)));
        }
      }

      // Subject filter
      final matchesSubject =
          _selectedSubjectIds.isEmpty ||
          _selectedSubjectIds.contains(summary.mataPelajaranId);

      return matchesSearch && matchesDateFilter && matchesSubject;
    }).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // ========== HEADER BARU SEPERTI ADMIN PRESENCE ==========
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
                      _tabController.index == 0
                          ? languageProvider.getTranslatedText({
                              'en': 'Attendance Results',
                              'id': 'Hasil Absensi',
                            })
                          : languageProvider.getTranslatedText({
                              'en': 'Add Attendance',
                              'id': 'Tambah Absensi',
                            }),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _tabController.index == 0
                          ? languageProvider.getTranslatedText({
                              'en': 'View attendance records',
                              'id': 'Lihat catatan kehadiran',
                            })
                          : languageProvider.getTranslatedText({
                              'en': 'Record student attendance',
                              'id': 'Catat kehadiran siswa',
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
                      if (_tabController.index == 0) {
                        _loadAbsensiSummary();
                      }
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

          // Mode Switcher di dalam header
          _buildModeSwitcher(languageProvider),
        ],
      ),
    );
  }

  // ========== SEARCH BAR DENGAN FILTER SEPERTI ADMIN ==========
  Widget _buildSearchAndFilter(LanguageProvider languageProvider) {
    return NewEnhancedSearchBar(
      controller: _searchController,
      onChanged: (value) => setState(() {}),
      hintText: languageProvider.getTranslatedText({
        'en': 'Search attendance...',
        'id': 'Cari absensi...',
      }),
      showFilter: _tabController.index == 0,
      hasActiveFilter: _hasActiveFilter,
      onFilterPressed: _showFilterSheet,
      primaryColor: _getPrimaryColor(),
    );
  }

  // ========== FILTER SHEET SEPERTI ADMIN ==========
  void _showFilterSheet() {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        primaryColor: _getPrimaryColor(),
        config: FilterConfig(
          sections: [
            FilterSection(
              key: 'dateFilter',
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
              multiSelect: false,
            ),
            FilterSection(
              key: 'subjectIds',
              title: languageProvider.getTranslatedText({
                'en': 'Subject',
                'id': 'Mata Pelajaran',
              }),
              options: _mataPelajaranDiampu.map((subject) {
                return FilterOption(
                  label:
                      subject['nama'] ??
                      subject['mata_pelajaran_nama'] ??
                      'Subject',
                  value: subject['id'].toString(),
                );
              }).toList(),
              multiSelect: true,
            ),
          ],
        ),
        initialFilters: {
          'dateFilter': _selectedDateFilter,
          'subjectIds': _selectedSubjectIds,
        },
        onApplyFilters: (filters) {
          setState(() {
            _selectedDateFilter = filters['dateFilter'];
            _selectedSubjectIds = List<String>.from(
              filters['subjectIds'] ?? [],
            );
            _checkActiveFilter();
          });
        },
      ),
    );
  }

  // ========== FILTER CHIPS SEPERTI ADMIN ==========
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

  // ========== CARD BARU SEPERTI PENGUMUMAN ==========
  Widget _buildSummaryCard(
    AbsensiSummary summary,
    LanguageProvider languageProvider,
  ) {
    final presentaseHadir = summary.totalSiswa > 0
        ? (summary.hadir / summary.totalSiswa * 100).round()
        : 0;

    return GestureDetector(
      onTap: () {
        _navigateToDetailAbsensi(summary);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToDetailAbsensi(summary),
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

                  // Attendance percentage badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: presentaseHadir >= 80
                            ? Colors.green
                            : presentaseHadir >= 60
                            ? Colors.orange
                            : Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$presentaseHadir%',
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
                        // Header dengan judul mata pelajaran
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    summary.mataPelajaranNama,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  if (summary.kelasId != null)
                                    Text(
                                      _getKelasName(summary.kelasId!),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _getPrimaryColor(),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  SizedBox(height: 2),
                                  Text(
                                    DateFormat(
                                      'EEEE, dd MMMM yyyy',
                                      'id_ID',
                                    ).format(summary.tanggal),
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

                        // Total siswa
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
                                Icons.people,
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
                                      'en': 'Total Students',
                                      'id': 'Total Siswa',
                                    }),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 1),
                                  Text(
                                    '${summary.totalSiswa} ${languageProvider.getTranslatedText({'en': 'Students', 'id': 'Siswa'})}',
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

                        // Status kehadiran
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
                                Icons.check_circle,
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
                                      'en': 'Attendance Status',
                                      'id': 'Status Kehadiran',
                                    }),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 1),
                                  Row(
                                    children: [
                                      _buildMiniStatusIndicator(
                                        languageProvider.getTranslatedText({
                                          'en': 'Present',
                                          'id': 'Hadir',
                                        }),
                                        summary.hadir,
                                        Colors.green,
                                      ),
                                      SizedBox(width: 8),
                                      _buildMiniStatusIndicator(
                                        languageProvider.getTranslatedText({
                                          'en': 'Absent',
                                          'id': 'Tidak Hadir',
                                        }),
                                        summary.tidakHadir,
                                        Colors.red,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // Progress bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              languageProvider.getTranslatedText({
                                'en': 'Attendance Rate',
                                'id': 'Tingkat Kehadiran',
                              }),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: summary.totalSiswa > 0
                                  ? summary.hadir / summary.totalSiswa
                                  : 0,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                presentaseHadir >= 80
                                    ? Colors.green
                                    : presentaseHadir >= 60
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              minHeight: 6,
                            ),
                            SizedBox(height: 4),
                            Text(
                              '$presentaseHadir% ${languageProvider.getTranslatedText({'en': 'Attendance', 'id': 'Kehadiran'})}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
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

  Widget _buildMiniStatusIndicator(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _navigateToDetailAbsensi(AbsensiSummary summary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AbsensiDetailPage(
          guru: widget.guru,
          mataPelajaranId: summary.mataPelajaranId,
          mataPelajaranNama: summary.mataPelajaranNama,
          tanggal: summary.tanggal,
          kelasId: summary.kelasId,
        ),
      ),
    );
  }

  // ========== MODE 1: INPUT ABSENSI ==========
  Widget _buildInputMode() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        if (_isLoadingInput) {
          return LoadingScreen(
            message: languageProvider.getTranslatedText({
              'en': 'Loading data...',
              'id': 'Memuat data...',
            }),
          );
        }

        return Column(
          children: [
            // Input Form
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Date Picker
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          languageProvider.getTranslatedText({
                            'en': 'Date:',
                            'id': 'Tanggal:',
                          }),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _selectDate(context),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Class Filter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedKelas,
                      isExpanded: true,
                      underline: Container(),
                      icon: const Icon(Icons.arrow_drop_down),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            languageProvider.getTranslatedText({
                              'en': 'All Classes',
                              'id': 'Semua Kelas',
                            }),
                          ),
                        ),
                        ..._kelasList.map(
                          (kelas) => DropdownMenuItem(
                            value: kelas['id'],
                            child: Text(kelas['nama']),
                          ),
                        ),
                      ],
                      onChanged: _filterStudentsByClass,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subject Selector - HANYA MATA PELAJARAN YANG DIAMPU
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedMataPelajaran,
                      isExpanded: true,
                      underline: Container(),
                      icon: const Icon(Icons.arrow_drop_down),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            languageProvider.getTranslatedText({
                              'en': 'Select Subject',
                              'id': 'Pilih Mata Pelajaran',
                            }),
                          ),
                        ),
                        ..._mataPelajaranDiampu.map(
                          (mp) => DropdownMenuItem(
                            value: mp['id'],
                            child: Text(
                              mp['nama'] ??
                                  mp['mata_pelajaran_nama'] ??
                                  'Unknown',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedMataPelajaran = value;
                        });
                      },
                    ),
                  ),

                  // Tampilkan pesan jika tidak ada mata pelajaran yang diampu
                  if (_mataPelajaranDiampu.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.orange[800],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              languageProvider.getTranslatedText({
                                'en':
                                    'You are not assigned to any subjects. Please contact administrator.',
                                'id':
                                    'Anda tidak mengampu mata pelajaran apapun. Silakan hubungi administrator.',
                              }),
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Student List Header
            if (_filteredSiswaList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${languageProvider.getTranslatedText({'en': 'Student List', 'id': 'Daftar Siswa'})} (${_filteredSiswaList.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      languageProvider.getTranslatedText({
                        'en': 'Status',
                        'id': 'Status',
                      }),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Student List
            Expanded(
              child: _filteredSiswaList.isEmpty
                  ? EmptyState(
                      title: languageProvider.getTranslatedText({
                        'en': 'No Students',
                        'id': 'Tidak ada siswa',
                      }),
                      subtitle: languageProvider.getTranslatedText({
                        'en': 'No students found for selected class',
                        'id': 'Tidak ada siswa untuk kelas yang dipilih',
                      }),
                      icon: Icons.people_outline,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: _filteredSiswaList.length,
                      itemBuilder: (context, index) => _buildStudentItem(
                        _filteredSiswaList[index],
                        languageProvider,
                      ),
                    ),
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitAbsensi,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.save, size: 20),
                  label: Text(
                    _isSubmitting
                        ? languageProvider.getTranslatedText({
                            'en': 'Saving...',
                            'id': 'Menyimpan...',
                          })
                        : languageProvider.getTranslatedText({
                            'en': 'Save Attendance',
                            'id': 'Simpan Absensi',
                          }),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
  } // ========== STUDENT ITEM BUILDER ==========

  Widget _buildStudentItem(Siswa siswa, LanguageProvider languageProvider) {
    final status = _absensiStatus[siswa.id] ?? 'hadir';
    final Color statusColor = _getStatusColor(status);
    final String statusText = _getStatusText(status, languageProvider);
    final Color avatarColor = _getAvatarColor(siswa.nama);
    final String initial = siswa.nama.isNotEmpty
        ? siswa.nama[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  siswa.nama,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${languageProvider.getTranslatedText({'en': 'NIS:', 'id': 'NIS:'})} ${siswa.nis}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Status Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: status,
                  items: [
                    DropdownMenuItem(
                      value: 'hadir',
                      child: Text(
                        languageProvider.getTranslatedText({
                          'en': 'Present',
                          'id': 'Hadir',
                        }),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'terlambat',
                      child: Text(
                        languageProvider.getTranslatedText({
                          'en': 'Late',
                          'id': 'Terlambat',
                        }),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'izin',
                      child: Text(
                        languageProvider.getTranslatedText({
                          'en': 'Permission',
                          'id': 'Izin',
                        }),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'sakit',
                      child: Text(
                        languageProvider.getTranslatedText({
                          'en': 'Sick',
                          'id': 'Sakit',
                        }),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'alpha',
                      child: Text(
                        languageProvider.getTranslatedText({
                          'en': 'Absent',
                          'id': 'Alpha',
                        }),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _absensiStatus[siswa.id] = value!;
                    });
                  },
                  underline: Container(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: statusColor,
                    size: 16,
                  ),
                  dropdownColor: Colors.white,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== HELPER FUNCTIONS ==========
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialEntryMode: DatePickerEntryMode.calendar,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _filterStudentsByClass(String? kelasId) {
    setState(() {
      _selectedKelas = kelasId;
      if (kelasId == null) {
        _filteredSiswaList = _siswaList;
      } else {
        _filteredSiswaList = _siswaList
            .where((siswa) => siswa.kelasId == kelasId)
            .toList();
      }
    });
  }

  Future<void> _submitAbsensi() async {
    final languageProvider = context.read<LanguageProvider>();

    // Validasi guru_id
    final guruId = widget.guru['id'];
    if (guruId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.getTranslatedText({
              'en': 'Invalid teacher data. Please login again.',
              'id': 'Data guru tidak valid. Silakan login ulang.',
            }),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedMataPelajaran == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.getTranslatedText({
              'en': 'Please select a subject first',
              'id': 'Pilih mata pelajaran terlebih dahulu',
            }),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_filteredSiswaList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.getTranslatedText({
              'en': 'No students to save',
              'id': 'Tidak ada siswa untuk disimpan',
            }),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      int successCount = 0;
      int errorCount = 0;
      List<String> errorMessages = [];

      final tanggal = DateFormat('yyyy-MM-dd').format(_selectedDate);

      for (var siswa in _filteredSiswaList) {
        try {
          final status = _absensiStatus[siswa.id] ?? 'hadir';

          await ApiService.tambahAbsensi({
            'siswa_id': siswa.id,
            'guru_id': guruId,
            'mata_pelajaran_id': _selectedMataPelajaran,
            'kelas_id': siswa.kelasId, // Add kelas_id from student data
            'tanggal': tanggal,
            'status': status,
            'keterangan': '',
          });

          successCount++;
          await Future.delayed(const Duration(milliseconds: 50));
        } catch (e) {
          errorCount++;
          errorMessages.add('${siswa.nama}: $e');
        }
      }

      if (!mounted) return;

      // Tampilkan hasil
      if (errorCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.getTranslatedText({
                'en':
                    'Attendance successfully saved for $successCount students',
                'id': 'Absensi berhasil disimpan untuk $successCount siswa',
              }),
            ),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Reset form setelah berhasil
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.getTranslatedText({
                'en': '$successCount successful, $errorCount failed',
                'id': '$successCount berhasil, $errorCount gagal',
              }),
            ),
            backgroundColor: Colors.orange.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _showErrorDetails(errorMessages, languageProvider);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${languageProvider.getTranslatedText({'en': 'Error:', 'id': 'Error:'})} $e',
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorDetails(
    List<String> errors,
    LanguageProvider languageProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          languageProvider.getTranslatedText({
            'en': 'Error Details',
            'id': 'Detail Error',
          }),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                languageProvider.getTranslatedText({
                  'en': 'Some attendance failed to save:',
                  'id': 'Beberapa absensi gagal disimpan:',
                }),
              ),
              const SizedBox(height: 16),
              ...errors.map(
                (error) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('• $error', style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              languageProvider.getTranslatedText({
                'en': 'Close',
                'id': 'Tutup',
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      // Reset status absensi ke default
      for (var siswa in _siswaList) {
        _absensiStatus[siswa.id] = 'hadir';
      }
      // Reset filter kelas
      _selectedKelas = null;
      _filteredSiswaList = _siswaList;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'izin':
        return Colors.blue;
      case 'sakit':
        return Colors.orange;
      case 'alpha':
        return Colors.red;
      case 'terlambat':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  String _getStatusText(String status, LanguageProvider languageProvider) {
    switch (status) {
      case 'izin':
        return languageProvider.getTranslatedText({
          'en': 'Permission',
          'id': 'Izin',
        });
      case 'sakit':
        return languageProvider.getTranslatedText({
          'en': 'Sick',
          'id': 'Sakit',
        });
      case 'alpha':
        return languageProvider.getTranslatedText({
          'en': 'Absent',
          'id': 'Alpha',
        });
      case 'terlambat':
        return languageProvider.getTranslatedText({
          'en': 'Late',
          'id': 'Terlambat',
        });
      default:
        return languageProvider.getTranslatedText({
          'en': 'Present',
          'id': 'Hadir',
        });
    }
  }

  Color _getAvatarColor(String nama) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    final index = nama.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: Color(
            0xFFF8F9FA,
          ), // Background sama dengan pengumuman
          body: Column(
            children: [
              // Header baru seperti pengumuman
              _buildHeader(languageProvider),

              // Content
              Expanded(
                child: _tabController.index == 0
                    ? _buildResultsMode()
                    : _buildInputMode(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ========== ABSENSI DETAIL PAGE ==========
class AbsensiDetailPage extends StatefulWidget {
  final Map<String, dynamic> guru;
  final String mataPelajaranId;
  final String mataPelajaranNama;
  final DateTime tanggal;
  final String? kelasId;

  const AbsensiDetailPage({
    super.key,
    required this.guru,
    required this.mataPelajaranId,
    required this.mataPelajaranNama,
    required this.tanggal,
    this.kelasId,
  });

  @override
  State<AbsensiDetailPage> createState() => _AbsensiDetailPageState();
}

class _AbsensiDetailPageState extends State<AbsensiDetailPage> {
  List<dynamic> _absensiData = [];
  List<Siswa> _siswaList = [];
  List<dynamic> _kelasList = [];
  final Map<String, String> _absensiStatus = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load siswa, absensi, dan kelas data
      final apiServiceClass = ApiClassService();
      final [siswaData, absensiData, kelasData] = await Future.wait([
        ApiStudentService.getStudent(),
        ApiService.getAbsensi(
          guruId: widget.guru['id'],
          mataPelajaranId: widget.mataPelajaranId,
          tanggal: DateFormat('yyyy-MM-dd').format(widget.tanggal),
        ),
        apiServiceClass.getClass(),
      ]);

      setState(() {
        // Filter siswa by class if kelasId is provided
        List<Siswa> allSiswa = siswaData.map((s) => Siswa.fromJson(s)).toList();
        if (widget.kelasId != null && widget.kelasId!.isNotEmpty) {
          _siswaList = allSiswa
              .where((siswa) => siswa.kelasId == widget.kelasId)
              .toList();
        } else {
          _siswaList = allSiswa;
        }

        _kelasList = kelasData;
        _absensiData = absensiData;

        // Map status absensi only for students in this class
        for (var absen in _absensiData) {
          final siswaId = absen['siswa_id']?.toString();
          if (siswaId != null && _siswaList.any((s) => s.id == siswaId)) {
            _absensiStatus[siswaId] = absen['status'];
          }
        }

        // Set default untuk siswa yang belum ada data absensi
        for (var siswa in _siswaList) {
          _absensiStatus[siswa.id] ??= 'hadir';
        }

        _isLoading = false;
      });

      print(
        'Loaded ${_absensiData.length} absensi records for ${_siswaList.length} students in class ${widget.kelasId ?? "all"}',
      );
    } catch (e) {
      print('Error loading absensi detail: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStudentItem(Siswa siswa, LanguageProvider languageProvider) {
    final status = _absensiStatus[siswa.id] ?? 'hadir';
    final Color statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getAvatarColor(siswa.nama),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                siswa.nama.isNotEmpty ? siswa.nama[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  siswa.nama,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${languageProvider.getTranslatedText({'en': 'NIS:', 'id': 'NIS:'})} ${siswa.nis}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Status Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: status,
                  items: [
                    DropdownMenuItem(
                      value: 'hadir',
                      child: Text(
                        languageProvider.getTranslatedText({
                          'en': 'Present',
                          'id': 'Hadir',
                        }),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'terlambat',
                      child: Text(
                        languageProvider.getTranslatedText({
                          'en': 'Late',
                          'id': 'Terlambat',
                        }),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'izin',
                      child: Text(
                        languageProvider.getTranslatedText({
                          'en': 'Permission',
                          'id': 'Izin',
                        }),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'sakit',
                      child: Text(
                        languageProvider.getTranslatedText({
                          'en': 'Sick',
                          'id': 'Sakit',
                        }),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'alpha',
                      child: Text(
                        languageProvider.getTranslatedText({
                          'en': 'Absent',
                          'id': 'Alpha',
                        }),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _absensiStatus[siswa.id] = value!;
                    });
                  },
                  underline: Container(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: statusColor,
                    size: 16,
                  ),
                  dropdownColor: Colors.white,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAbsensi() async {
    final languageProvider = context.read<LanguageProvider>();

    setState(() {
      _isSubmitting = true;
    });

    try {
      int successCount = 0;

      for (var siswa in _siswaList) {
        final status = _absensiStatus[siswa.id]!;

        await ApiService.tambahAbsensi({
          'siswa_id': siswa.id,
          'guru_id': widget.guru['id'],
          'mata_pelajaran_id': widget.mataPelajaranId,
          'tanggal': DateFormat('yyyy-MM-dd').format(widget.tanggal),
          'status': status,
          'keterangan': '',
        });

        successCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.getTranslatedText({
                'en': 'Successfully updated $successCount attendance records',
                'id': 'Berhasil update $successCount absensi',
              }),
            ),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${languageProvider.getTranslatedText({'en': 'Error:', 'id': 'Error:'})} $e',
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Helper functions
  Color _getStatusColor(String status) {
    switch (status) {
      case 'izin':
        return Colors.blue;
      case 'sakit':
        return Colors.orange;
      case 'alpha':
        return Colors.red;
      case 'terlambat':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  Color _getAvatarColor(String nama) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    final index = nama.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  String _getKelasName(String kelasId) {
    try {
      final kelas = _kelasList.firstWhere(
        (k) => k['id'].toString() == kelasId,
        orElse: () => {'nama': 'Unknown Class'},
      );
      return kelas['nama'] ?? 'Unknown Class';
    } catch (e) {
      return 'Unknown Class';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              languageProvider.getTranslatedText({
                'en': 'Edit Attendance',
                'id': 'Edit Absensi',
              }),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.black),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.black),
                onPressed: _loadData,
                tooltip: languageProvider.getTranslatedText({
                  'en': 'Refresh',
                  'id': 'Muat Ulang',
                }),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Container(height: 1, color: Colors.grey.shade300),
            ),
          ),
          body: _isLoading
              ? LoadingScreen(
                  message: languageProvider.getTranslatedText({
                    'en': 'Loading attendance details...',
                    'id': 'Memuat detail absensi...',
                  }),
                )
              : Column(
                  children: [
                    // Header Info
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.mataPelajaranNama,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (widget.kelasId != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _getKelasName(widget.kelasId!),
                              style: TextStyle(
                                color: ColorUtils.getRoleColor("guru"),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            DateFormat(
                              'EEEE, dd MMMM yyyy',
                              'id_ID',
                            ).format(widget.tanggal),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_siswaList.length} ${languageProvider.getTranslatedText({'en': 'Students', 'id': 'Siswa'})}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Student List Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languageProvider.getTranslatedText({
                              'en': 'Student List',
                              'id': 'Daftar Siswa',
                            }),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            languageProvider.getTranslatedText({
                              'en': 'Status',
                              'id': 'Status',
                            }),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Student List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: _siswaList.length,
                        itemBuilder: (context, index) => _buildStudentItem(
                          _siswaList[index],
                          languageProvider,
                        ),
                      ),
                    ),
                    // Update Button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _updateAbsensi,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.update, size: 20),
                          label: Text(
                            _isSubmitting
                                ? languageProvider.getTranslatedText({
                                    'en': 'Updating...',
                                    'id': 'Mengupdate...',
                                  })
                                : languageProvider.getTranslatedText({
                                    'en': 'Update Attendance',
                                    'id': 'Update Absensi',
                                  }),
                            style: const TextStyle(
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
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
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

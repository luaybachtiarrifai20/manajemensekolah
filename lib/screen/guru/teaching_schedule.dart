import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/filter_section.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/components/enhanced_search_bar.dart';
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
              'id': message.replaceAll('Failed to load schedule data:', 'Gagal memuat data jadwal:'),
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

  Color _getHariColor(String hari) {
    return _hariColorMap[hari] ?? Color(0xFF6B7280);
  }

  List<dynamic> _getFilteredSchedules() {
    final searchTerm = _searchController.text.toLowerCase();
    return _jadwalList.where((schedule) {
      final subjectName = schedule['mata_pelajaran_nama']?.toString().toLowerCase() ?? '';
      final className = schedule['kelas_nama']?.toString().toLowerCase() ?? '';
      final dayName = schedule['hari_nama']?.toString().toLowerCase() ?? '';

      final matchesSearch =
          searchTerm.isEmpty ||
          subjectName.contains(searchTerm) ||
          className.contains(searchTerm) ||
          dayName.contains(searchTerm);

      // Filter berdasarkan hari (untuk filter "Today" dan "This Week")
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
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    return days[now.weekday];
  }

  bool _isThisWeek(String dayName) {
    // Implementasi sederhana - dalam aplikasi nyata, 
    // Anda mungkin ingin logika yang lebih kompleks
    final dayMap = {'senin': 1, 'selasa': 2, 'rabu': 3, 'kamis': 4, 'jumat': 5, 'sabtu': 6};
    return dayMap.containsKey(dayName.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        if (_isLoading) {
          return LoadingScreen(
            message: languageProvider.getTranslatedText({
              'en': 'Loading schedule data...',
              'id': 'Memuat data jadwal...',
            }),
          );
        }

        final filteredSchedules = _getFilteredSchedules();

        // Terjemahan filter options
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

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              languageProvider.getTranslatedText({
                'en': 'Teaching Schedule',
                'id': 'Jadwal Mengajar',
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
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.black),
                onPressed: _loadJadwal,
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
          body: Column(
            children: [
              // Header Info Guru
              _buildHeaderInfo(languageProvider),
              
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

              // Search Bar dengan Filter
              EnhancedSearchBar(
                controller: _searchController,
                hintText: languageProvider.getTranslatedText({
                  'en': 'Search schedules...',
                  'id': 'Cari jadwal...',
                }),
                onChanged: (value) {
                  setState(() {});
                },
                filterOptions: translatedFilterOptions,
                selectedFilter: translatedFilterOptions[
                  _selectedFilter == 'All' 
                    ? 0 
                    : _selectedFilter == 'Today' 
                      ? 1 
                      : 2
                ],
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
              ),

              if (filteredSchedules.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${filteredSchedules.length} ${languageProvider.getTranslatedText({
                          'en': 'schedules found',
                          'id': 'jadwal ditemukan',
                        })}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 8),

              Expanded(
                child: filteredSchedules.isEmpty
                    ? EmptyState(
                        title: languageProvider.getTranslatedText({
                          'en': 'No teaching schedules',
                          'id': 'Belum ada jadwal mengajar',
                        }),
                        subtitle: _searchController.text.isEmpty && _selectedFilter == 'All' && _selectedHari == 'Semua Hari'
                            ? languageProvider.getTranslatedText({
                                'en': 'No schedule available for current filters',
                                'id': 'Tidak ada jadwal untuk filter saat ini',
                              })
                            : languageProvider.getTranslatedText({
                                'en': 'No search results found',
                                'id': 'Tidak ditemukan hasil pencarian',
                              }),
                        icon: Icons.schedule_outlined,
                      )
                    : _buildJadwalList(languageProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderInfo(LanguageProvider languageProvider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: ColorUtils.primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.person,
              color: ColorUtils.primaryColor,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  languageProvider.getTranslatedText({
                    'en': 'Teacher',
                    'id': 'Guru',
                  }),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                    selectedColor: ColorUtils.primaryColor.withOpacity(0.1),
                    checkmarkColor: ColorUtils.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? ColorUtils.primaryColor : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isSelected ? ColorUtils.primaryColor : Colors.grey.shade300,
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

  Widget _buildJadwalList(LanguageProvider languageProvider) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _jadwalList.length,
      itemBuilder: (context, index) {
        final jadwal = _jadwalList[index];
        final hari = jadwal['hari_nama']?.toString() ?? 'Unknown';
        final cardColor = _getHariColor(hari);

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Time Section dengan background warna hari
                Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(jadwal['jam_mulai']),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 1,
                        color: Colors.white,
                        margin: EdgeInsets.symmetric(vertical: 4),
                      ),
                      Text(
                        _formatTime(jadwal['jam_selesai']),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Jam ${jadwal['jam_ke'] ?? ''}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content Section
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jadwal['mata_pelajaran_nama'] ?? 'Mata Pelajaran',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.class_, size: 16, color: Colors.grey.shade600),
                            SizedBox(width: 4),
                            Text(
                              jadwal['kelas_nama'] ?? 'Kelas',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_month, size: 16, color: Colors.grey.shade600),
                            SizedBox(width: 4),
                            Text(
                              hari,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cardColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                jadwal['semester_nama'] ?? 'Semester',
                                style: TextStyle(
                                  color: cardColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';
    return time.length >= 5 ? time.substring(0, 5) : time;
  }
}
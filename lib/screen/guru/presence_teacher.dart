import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/components/enhanced_search_bar.dart';
import 'package:manajemensekolah/models/siswa.dart';
import 'package:manajemensekolah/services/api_class_services.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/api_student_services.dart';
import 'package:manajemensekolah/services/api_subject_services.dart';
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

class PresencePageState extends State<PresencePage> {
  // Mode: 0 = View Results, 1 = Input Absensi
  int _currentMode = 0;

  // Data untuk mode View Results
  List<AbsensiSummary> _absensiSummaryList = [];
  bool _isLoadingSummary = false;

  // Data untuk mode Input Absensi
  DateTime _selectedDate = DateTime.now();
  String? _selectedMataPelajaran;
  String? _selectedKelas;
  List<dynamic> _mataPelajaranList = [];
  List<dynamic> _mataPelajaranDiampu = [];
  List<dynamic> _kelasList = [];
  List<Siswa> _siswaList = [];
  List<Siswa> _filteredSiswaList = [];
  final Map<String, String> _absensiStatus = {};
  bool _isLoadingInput = true;
  bool _isSubmitting = false;

  // Search dan Filter
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filterOptions = ['All', 'Today', 'This Week'];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
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
        final key = '${absen['mata_pelajaran_id']}-${absen['tanggal']}';
        final mataPelajaranNama = _getMataPelajaranName(
          absen['mata_pelajaran_id'],
        );

        if (!summaryMap.containsKey(key)) {
          summaryMap[key] = AbsensiSummary(
            mataPelajaranId: absen['mata_pelajaran_id'],
            mataPelajaranNama: mataPelajaranNama,
            tanggal: DateTime.parse(absen['tanggal']),
            totalSiswa: 0,
            hadir: 0,
            tidakHadir: 0,
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

  // ========== MODE SWITCHER ==========
  Widget _buildModeSwitcher() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  0,
                  languageProvider.getTranslatedText({
                    'en': 'Attendance Results',
                    'id': 'Hasil Absensi',
                  }),
                  Icons.list_alt,
                ),
              ),
              Expanded(
                child: _buildModeButton(
                  1,
                  languageProvider.getTranslatedText({
                    'en': 'Add Attendance',
                    'id': 'Tambah Absensi',
                  }),
                  Icons.add_circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeButton(int mode, String text, IconData icon) {
    final isSelected = _currentMode == mode;

    return Material(
      color: isSelected ? ColorUtils.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _currentMode = mode;
          });
          if (mode == 0) {
            _loadAbsensiSummary();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 20,
              ),
              const SizedBox(height: 4),
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

  // ========== MODE 0: VIEW RESULTS ==========
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

        // Terjemahan filter options
        final translatedFilterOptions = [
          languageProvider.getTranslatedText({'en': 'All', 'id': 'Semua'}),
          languageProvider.getTranslatedText({'en': 'Today', 'id': 'Hari Ini'}),
          languageProvider.getTranslatedText({
            'en': 'This Week',
            'id': 'Minggu Ini',
          }),
        ];

        return Column(
          children: [
            // Search Bar dengan Filter
            EnhancedSearchBar(
              controller: _searchController,
              hintText: languageProvider.getTranslatedText({
                'en': 'Search attendance...',
                'id': 'Cari absensi...',
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
            ),

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
                          _searchController.text.isEmpty &&
                              _selectedFilter == 'All'
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

  List<AbsensiSummary> _getFilteredSummaries() {
    final searchTerm = _searchController.text.toLowerCase();
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    return _absensiSummaryList.where((summary) {
      final matchesSearch =
          searchTerm.isEmpty ||
          summary.mataPelajaranNama.toLowerCase().contains(searchTerm);

      final matchesFilter =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'Today' && _isSameDay(summary.tanggal, now)) ||
          (_selectedFilter == 'This Week' &&
              summary.tanggal.isAfter(
                startOfWeek.subtract(Duration(days: 1)),
              ) &&
              summary.tanggal.isBefore(endOfWeek.add(Duration(days: 1))));

      return matchesSearch && matchesFilter;
    }).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildSummaryCard(
    AbsensiSummary summary,
    LanguageProvider languageProvider,
  ) {
    final presentaseHadir = summary.totalSiswa > 0
        ? (summary.hadir / summary.totalSiswa * 100).round()
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: ColorUtils.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.calendar_today, color: ColorUtils.primaryColor),
        ),
        title: Text(
          summary.mataPelajaranNama,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(summary.tanggal),
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusIndicator(
                  languageProvider.getTranslatedText({
                    'en': 'Present',
                    'id': 'Hadir',
                  }),
                  summary.hadir,
                  Colors.green,
                  languageProvider,
                ),
                const SizedBox(width: 12),
                _buildStatusIndicator(
                  languageProvider.getTranslatedText({
                    'en': 'Absent',
                    'id': 'Tidak Hadir',
                  }),
                  summary.tidakHadir,
                  Colors.red,
                  languageProvider,
                ),
              ],
            ),
            const SizedBox(height: 4),
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
            ),
            const SizedBox(height: 4),
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
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () {
          _navigateToDetailAbsensi(summary);
        },
      ),
    );
  }

  Widget _buildStatusIndicator(
    String label,
    int count,
    Color color,
    LanguageProvider languageProvider,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
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
                  // Date Picker (tetap sama)
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

                  // Class Filter (tetap sama)
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
  }

  // ========== STUDENT ITEM BUILDER ==========
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
              '${languageProvider.getTranslatedText({'en': '$successCount successful, $errorCount failed', 'id': '$successCount berhasil, $errorCount gagal'})}',
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
              ...errors
                  .map(
                    (error) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '• $error',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
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
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              _currentMode == 0
                  ? languageProvider.getTranslatedText({
                      'en': 'Attendance Results',
                      'id': 'Hasil Absensi',
                    })
                  : languageProvider.getTranslatedText({
                      'en': 'Add Attendance',
                      'id': 'Tambah Absensi',
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
                onPressed: _currentMode == 0
                    ? _loadAbsensiSummary
                    : _loadInitialData,
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
              _buildModeSwitcher(),
              Expanded(
                child: _currentMode == 0
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

  const AbsensiDetailPage({
    super.key,
    required this.guru,
    required this.mataPelajaranId,
    required this.mataPelajaranNama,
    required this.tanggal,
  });

  @override
  State<AbsensiDetailPage> createState() => _AbsensiDetailPageState();
}

class _AbsensiDetailPageState extends State<AbsensiDetailPage> {
  List<dynamic> _absensiData = [];
  List<Siswa> _siswaList = [];
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
      // Load siswa dan absensi data
      final [siswaData, absensiData] = await Future.wait([
        ApiStudentService.getStudent(),
        ApiService.getAbsensi(
          guruId: widget.guru['id'],
          mataPelajaranId: widget.mataPelajaranId,
          tanggal: DateFormat('yyyy-MM-dd').format(widget.tanggal),
        ),
      ]);

      setState(() {
        _siswaList = siswaData.map((s) => Siswa.fromJson(s)).toList();
        _absensiData = absensiData;

        // Map status absensi
        for (var absen in _absensiData) {
          _absensiStatus[absen['siswa_id']] = absen['status'];
        }

        // Set default untuk siswa yang belum ada data
        for (var siswa in _siswaList) {
          _absensiStatus[siswa.id] ??= 'hadir';
        }

        _isLoading = false;
      });

      print('Loaded ${_absensiData.length} absensi records for detail');
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
                            backgroundColor: Colors.blue,
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

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
import 'package:manajemensekolah/utils/color_utils.dart';
import 'package:manajemensekolah/utils/language_utils.dart';
import 'package:provider/provider.dart';

// Model untuk Summary Absensi (sama seperti di teacher page)
class AbsensiSummary {
  final String mataPelajaranId;
  final String mataPelajaranNama;
  final DateTime tanggal;
  final int totalSiswa;
  final int hadir;
  final int tidakHadir;

  AbsensiSummary({
    required this.mataPelajaranId,
    required this.mataPelajaranNama,
    required this.tanggal,
    required this.totalSiswa,
    required this.hadir,
    required this.tidakHadir,
  });

  String get key =>
      '$mataPelajaranId-${DateFormat('yyyy-MM-dd').format(tanggal)}';
}

class AdminPresenceReportScreen extends StatefulWidget {
  const AdminPresenceReportScreen({super.key});

  @override
  State<AdminPresenceReportScreen> createState() =>
      _AdminPresenceReportScreenState();
}

class _AdminPresenceReportScreenState extends State<AdminPresenceReportScreen> {
  // Data untuk mode View Results
  List<AbsensiSummary> _absensiSummaryList = [];
  bool _isLoadingSummary = false;

  // Search dan Filter
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filterOptions = ['All', 'Today', 'This Week'];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAbsensiSummary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAbsensiSummary() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSummary = true;
    });

    try {
      final absensiData = await ApiService.getAbsensi();

      final Map<String, AbsensiSummary> summaryMap = {};

      // Load data mata pelajaran untuk mendapatkan nama
      final mataPelajaranList = await ApiSubjectService().getSubject();

      for (var absen in absensiData) {
        final key = '${absen['mata_pelajaran_id']}-${absen['tanggal']}';
        final mataPelajaranNama = _getMataPelajaranName(
          absen['mata_pelajaran_id'],
          mataPelajaranList,
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

      if (!mounted) return;

      setState(() {
        _absensiSummaryList = summaryMap.values.toList()
          ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
        _isLoadingSummary = false;
      });

      if (kDebugMode) {
        print(
          'Loaded ${_absensiSummaryList.length} absensi summaries for admin',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading absensi summary for admin: $e');
      }
      if (mounted) {
        setState(() {
          _isLoadingSummary = false;
        });
      }
    }
  }

  String _getMataPelajaranName(
    String mataPelajaranId,
    List<dynamic> mataPelajaranList,
  ) {
    try {
      final mataPelajaran = mataPelajaranList.firstWhere(
        (mp) => mp['id'] == mataPelajaranId,
        orElse: () => {'nama': 'Unknown'},
      );
      return mataPelajaran['nama'];
    } catch (e) {
      return 'Unknown';
    }
  }

  // ========== VIEW RESULTS ==========
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
        builder: (context) => AdminAbsensiDetailPage(
          mataPelajaranId: summary.mataPelajaranId,
          mataPelajaranNama: summary.mataPelajaranNama,
          tanggal: summary.tanggal,
        ),
      ),
    );
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
                'en': 'Attendance Report',
                'id': 'Laporan Absensi',
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
                onPressed: _loadAbsensiSummary,
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
          body: _buildResultsMode(),
        );
      },
    );
  }
}

// ========== ADMIN ABSENSI DETAIL PAGE ==========
class AdminAbsensiDetailPage extends StatefulWidget {
  final String mataPelajaranId;
  final String mataPelajaranNama;
  final DateTime tanggal;

  const AdminAbsensiDetailPage({
    super.key,
    required this.mataPelajaranId,
    required this.mataPelajaranNama,
    required this.tanggal,
  });

  @override
  State<AdminAbsensiDetailPage> createState() => _AdminAbsensiDetailPageState();
}

class _AdminAbsensiDetailPageState extends State<AdminAbsensiDetailPage> {
  List<dynamic> _absensiData = [];
  List<Siswa> _siswaList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load siswa dan absensi data secara parallel
      final [siswaData, absensiData] = await Future.wait([
        ApiStudentService.getStudent(),
        ApiService.getAbsensi(
          mataPelajaranId: widget.mataPelajaranId,
          tanggal: DateFormat('yyyy-MM-dd').format(widget.tanggal),
        ),
      ]);

      if (kDebugMode) {
        print('Loaded ${siswaData.length} students');
        print('Loaded ${absensiData.length} attendance records');
        print('Attendance data: $absensiData');
      }

      setState(() {
        _siswaList = siswaData.map((s) => Siswa.fromJson(s)).toList();
        _absensiData = absensiData;
        _isLoading = false;
      });

    } catch (e) {
      print('Error loading absensi detail for admin: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method untuk mendapatkan status absensi siswa
  String _getStudentStatus(String siswaId) {
    try {
      final absenRecord = _absensiData.firstWhere(
        (a) => a['siswa_id'] == siswaId,
      );
      return absenRecord['status'] ?? 'alpha';
    } catch (e) {
      // Jika tidak ada record, kembalikan 'alpha'
      return 'alpha';
    }
  }

  Widget _buildStudentItem(Siswa siswa, LanguageProvider languageProvider) {
    final status = _getStudentStatus(siswa.id);
    final Color statusColor = _getStatusColor(status);
    final String statusText = _getStatusText(status, languageProvider);

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

          // Status Badge (Read-only)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper functions
  Color _getStatusColor(String status) {
    switch (status) {
      case 'hadir':
        return Colors.green;
      case 'izin':
        return Colors.blue;
      case 'sakit':
        return Colors.orange;
      case 'alpha':
        return Colors.red;
      case 'terlambat':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, LanguageProvider languageProvider) {
    switch (status) {
      case 'hadir':
        return languageProvider.getTranslatedText({
          'en': 'Present',
          'id': 'Hadir',
        });
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
          'en': 'Unknown',
          'id': 'Tidak Diketahui',
        });
    }
  }

  Color _getAvatarColor(String nama) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
    final index = nama.isNotEmpty ? nama.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  // Method untuk menghitung statistik
  Map<String, int> _calculateStatistics() {
    int hadir = 0;
    int terlambat = 0;
    int izin = 0;
    int sakit = 0;
    int alpha = 0;

    for (var siswa in _siswaList) {
      final status = _getStudentStatus(siswa.id);
      switch (status) {
        case 'hadir':
          hadir++;
          break;
        case 'terlambat':
          terlambat++;
          break;
        case 'izin':
          izin++;
          break;
        case 'sakit':
          sakit++;
          break;
        case 'alpha':
          alpha++;
          break;
      }
    }

    return {
      'hadir': hadir,
      'terlambat': terlambat,
      'izin': izin,
      'sakit': sakit,
      'alpha': alpha,
      'total': _siswaList.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final stats = _calculateStatistics();
        final totalTidakHadir = stats['izin']! + stats['sakit']! + stats['alpha']!;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              languageProvider.getTranslatedText({
                'en': 'Attendance Details',
                'id': 'Detail Absensi',
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
                            '${stats['total']} ${languageProvider.getTranslatedText({'en': 'Students', 'id': 'Siswa'})}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Summary Statistics
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            languageProvider.getTranslatedText({
                              'en': 'Present',
                              'id': 'Hadir',
                            }),
                            stats['hadir']!,
                            Colors.green,
                          ),
                          _buildStatItem(
                            languageProvider.getTranslatedText({
                              'en': 'Late',
                              'id': 'Terlambat',
                            }),
                            stats['terlambat']!,
                            Colors.orange,
                          ),
                          _buildStatItem(
                            languageProvider.getTranslatedText({
                              'en': 'Absent',
                              'id': 'Tidak Hadir',
                            }),
                            totalTidakHadir,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),

                    // Detailed Statistics (Optional - bisa dihapus jika tidak perlu)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (stats['izin']! > 0)
                            _buildSmallStatItem('Izin', stats['izin']!, Colors.blue),
                          if (stats['sakit']! > 0)
                            _buildSmallStatItem('Sakit', stats['sakit']!, Colors.orange),
                          if (stats['alpha']! > 0)
                            _buildSmallStatItem('Alpha', stats['alpha']!, Colors.red),
                        ],
                      ),
                    ),

                    // Student List Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _siswaList.length,
                        itemBuilder: (context, index) => _buildStudentItem(
                          _siswaList[index],
                          languageProvider,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
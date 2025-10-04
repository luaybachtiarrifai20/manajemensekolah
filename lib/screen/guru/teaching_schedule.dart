import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_schedule_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TeachingScheduleScreen extends StatefulWidget {
  const TeachingScheduleScreen({super.key});

  @override
  TeachingScheduleScreenState createState() => TeachingScheduleScreenState();
}

class TeachingScheduleScreenState extends State<TeachingScheduleScreen> {
  List<dynamic> _jadwalList = [];
  bool _isLoading = true;
  String _guruId = '';
  String _guruNama = '';
  String _selectedHari = 'Semua Hari';
  String _selectedSemester = 'Semua Semester';
  final String _selectedTahunAjaran = '2024/2025';
  String _debugInfo = '';

  // PERBAIKAN: Opsi termasuk "Semua Semester"
  final List<String> _hariOptions = [
    'Semua Hari',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  final List<String> _semesterOptions = [
    'Semua Semester',
    'Ganjil',
    'Genap',
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

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = json.decode(prefs.getString('user') ?? '{}');
      
      setState(() {
        _guruId = userData['id']?.toString() ?? '';
        _guruNama = userData['nama']?.toString() ?? 'Guru';
      });

      if (_guruId.isEmpty) {
        _debugInfo = 'ERROR: Guru ID tidak ditemukan';
        setState(() => _isLoading = false);
        return;
      }

      _loadJadwal();
    } catch (e) {
      _debugInfo = 'Error load user: $e';
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadJadwal() async {
    if (_guruId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (kDebugMode) {
        print('Loading jadwal dengan filter:');
        print(' - Hari: $_selectedHari');
        print(' - Semester: $_selectedSemester');
        print(' - Tahun: $_selectedTahunAjaran');
      }

      setState(() => _isLoading = true);

      // PERBAIKAN: Gunakan endpoint filtered yang baru
      final jadwal = await ApiScheduleService.getFilteredSchedule(
        guruId: _guruId,
        hari: _selectedHari != 'Semua Hari' ? _selectedHari : null,
        semester: _selectedSemester != 'Semua Semester' ? _selectedSemester : null,
        tahunAjaran: _selectedTahunAjaran,
      );

      if (kDebugMode) {
        print('Jadwal ditemukan: ${jadwal.length} items');
        if (jadwal.isNotEmpty) {
          print('Sample jadwal:');
          jadwal.take(2).forEach((j) {
            print(' - ${j['mata_pelajaran_nama']} | ${j['kelas_nama']} | ${j['hari_nama']} | ${j['semester_nama']}');
          });
        }
      }

      setState(() {
        _jadwalList = jadwal;
        _isLoading = false;
        _debugInfo = '${jadwal.length} jadwal ditemukan\nFilter: $_selectedHari, $_selectedSemester';
      });

    } catch (e) {
      if (kDebugMode) {
        print('Error load jadwal: $e');
      }
      setState(() {
        _isLoading = false;
        _debugInfo = 'Error: $e';
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat jadwal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // PERBAIKAN: Method untuk handle perubahan filter
  void _onHariChanged(String newHari) {
    setState(() {
      _selectedHari = newHari;
    });
    _loadJadwal();
  }

  void _onSemesterChanged(String newSemester) {
    setState(() {
      _selectedSemester = newSemester;
    });
    _loadJadwal();
  }

  Color _getHariColor(String hari) {
    return _hariColorMap[hari] ?? Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Jadwal Mengajar'),
        backgroundColor: Color(0xFF4F46E5),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadJadwal,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          _buildHeaderSection(),
          
          // Filter Section - PERBAIKAN: Pisahkan filter dari header
          _buildFilterSection(),
          
          // Content Section
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _jadwalList.isEmpty
                    ? _buildEmptyState()
                    : _buildJadwalList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C73FA)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _guruNama,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Guru',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  // PERBAIKAN: Widget filter terpisah
  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Info Filter Aktif
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_alt, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filter: $_selectedHari • $_selectedSemester • $_selectedTahunAjaran',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  ),
                ),
                Text(
                  '${_jadwalList.length} jadwal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          
          // Filter Controls
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Hari',
                  value: _selectedHari,
                  options: _hariOptions,
                  onChanged: _onHariChanged,
                  icon: Icons.calendar_today,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Semester',
                  value: _selectedSemester,
                  options: _semesterOptions,
                  onChanged: _onSemesterChanged,
                  icon: Icons.school,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: Colors.grey.shade600),
                        SizedBox(width: 8),
                        Expanded(child: Text(option)),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Memuat jadwal...'),
          if (_debugInfo.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              _debugInfo,
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 64, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(
            'Tidak ada jadwal mengajar',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8),
          Text(
            'Untuk $_selectedHari, $_selectedSemester',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadJadwal,
            child: Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalList() {
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
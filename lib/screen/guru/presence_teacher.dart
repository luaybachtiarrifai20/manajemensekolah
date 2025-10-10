import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manajemensekolah/models/siswa.dart';
import 'package:manajemensekolah/services/api_class_services.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/api_student_services.dart';
import 'package:manajemensekolah/services/api_subject_services.dart';

// Model untuk Summary Absensi
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

  String get key => '${mataPelajaranId}-${DateFormat('yyyy-MM-dd').format(tanggal)}';
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
  List<dynamic> _kelasList = [];
  List<Siswa> _siswaList = [];
  List<Siswa> _filteredSiswaList = [];
  final Map<String, String> _absensiStatus = {};
  bool _isLoadingInput = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    // Debug data guru
    print('=== PRESENCE PAGE DEBUG ===');
    print('Received guru data: ${widget.guru}');
    print('Guru ID: ${widget.guru['id']}');
    print('Guru Name: ${widget.guru['nama']}');
    print('Guru Role: ${widget.guru['role']}');
    print('===========================');
    
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final apiServiceClass = ApiClassService();
      final [mataPelajaran, kelas, siswa] = await Future.wait([
        ApiSubjectService().getSubject(),
        apiServiceClass.getClass(),
        ApiStudentService.getStudent(),
      ]);

      setState(() {
        _mataPelajaranList = mataPelajaran;
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
      print('Error loading initial data: $e');
      setState(() {
        _isLoadingInput = false;
      });
    }
  }

  Future<void> _loadAbsensiSummary() async {
    setState(() {
      _isLoadingSummary = true;
    });

    try {
      // Panggil API untuk mendapatkan semua absensi
      final absensiData = await ApiService.getAbsensi(
        guruId: widget.guru['id'],
      );

      // Process data untuk membuat summary
      final Map<String, AbsensiSummary> summaryMap = {};

      for (var absen in absensiData) {
        final key = '${absen['mata_pelajaran_id']}-${absen['tanggal']}';
        final mataPelajaranNama = _getMataPelajaranName(absen['mata_pelajaran_id']);
        
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

      setState(() {
        _absensiSummaryList = summaryMap.values.toList()
          ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
        _isLoadingSummary = false;
      });

      print('Loaded ${_absensiSummaryList.length} absensi summaries');

    } catch (e) {
      print('Error loading absensi summary: $e');
      setState(() {
        _isLoadingSummary = false;
      });
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
              'Hasil Absensi',
              Icons.list_alt,
            ),
          ),
          Expanded(
            child: _buildModeButton(
              1,
              'Tambah Absensi',
              Icons.add_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(int mode, String text, IconData icon) {
    final isSelected = _currentMode == mode;
    
    return Material(
      color: isSelected ? Colors.blue : Colors.transparent,
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
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 20),
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
    if (_isLoadingSummary) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat data absensi...'),
          ],
        ),
      );
    }

    if (_absensiSummaryList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada data absensi',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan tambah absensi baru',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _absensiSummaryList.length,
      itemBuilder: (context, index) {
        final summary = _absensiSummaryList[index];
        return _buildSummaryCard(summary);
      },
    );
  }

  Widget _buildSummaryCard(AbsensiSummary summary) {
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
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.calendar_today, color: Colors.blue[700]),
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
                _buildStatusIndicator('Hadir', summary.hadir, Colors.green),
                const SizedBox(width: 12),
                _buildStatusIndicator('Tidak Hadir', summary.tidakHadir, Colors.red),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: summary.totalSiswa > 0 ? summary.hadir / summary.totalSiswa : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                presentaseHadir >= 80 ? Colors.green : 
                presentaseHadir >= 60 ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$presentaseHadir% Kehadiran',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          _navigateToDetailAbsensi(summary);
        },
      ),
    );
  }

  Widget _buildStatusIndicator(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count $label', 
          style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
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
    if (_isLoadingInput) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat data...'),
          ],
        ),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tanggal:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Class Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedKelas,
                  isExpanded: true,
                  underline: Container(),
                  icon: const Icon(Icons.arrow_drop_down),
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua Kelas'),
                    ),
                    ..._kelasList.map((kelas) => DropdownMenuItem(
                      value: kelas['id'],
                      child: Text(kelas['nama']),
                    )),
                  ],
                  onChanged: _filterStudentsByClass,
                ),
              ),
              const SizedBox(height: 12),
              
              // Subject Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedMataPelajaran,
                  isExpanded: true,
                  underline: Container(),
                  icon: const Icon(Icons.arrow_drop_down),
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Pilih Mata Pelajaran'),
                    ),
                    ..._mataPelajaranList.map((mp) => DropdownMenuItem(
                      value: mp['id'],
                      child: Text(mp['nama']),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMataPelajaran = value;
                    });
                  },
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
                  'Daftar Siswa (${_filteredSiswaList.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Status',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

        // Student List
        Expanded(
          child: _filteredSiswaList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Tidak ada siswa',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: _filteredSiswaList.length,
                  itemBuilder: (context, index) => _buildStudentItem(_filteredSiswaList[index]),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save, size: 20),
              label: Text(
                _isSubmitting ? 'Menyimpan...' : 'Simpan Absensi',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  }

  // ========== STUDENT ITEM BUILDER ==========
  Widget _buildStudentItem(Siswa siswa) {
    final status = _absensiStatus[siswa.id] ?? 'hadir';
    final Color statusColor = _getStatusColor(status);
    final String statusText = _getStatusText(status);
    final Color avatarColor = _getAvatarColor(siswa.nama);
    final String initial = siswa.nama.isNotEmpty ? siswa.nama[0].toUpperCase() : '?';

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
                  'NIS: ${siswa.nis}',
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
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                DropdownButton<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                    DropdownMenuItem(value: 'terlambat', child: Text('Terlambat')),
                    DropdownMenuItem(value: 'izin', child: Text('Izin')),
                    DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                    DropdownMenuItem(value: 'alpha', child: Text('Alpha')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _absensiStatus[siswa.id] = value!;
                    });
                  },
                  underline: Container(),
                  icon: Icon(Icons.arrow_drop_down, color: statusColor, size: 16),
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
    // Validasi guru_id
    final guruId = widget.guru['id'];
    if (guruId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data guru tidak valid. Silakan login ulang.')),
      );
      return;
    }

    if (_selectedMataPelajaran == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata pelajaran terlebih dahulu')),
      );
      return;
    }

    if (_filteredSiswaList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada siswa untuk disimpan')),
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

      print('=== SUBMITTING ABSENSI ===');
      print('- Guru ID: $guruId');
      print('- Mata Pelajaran ID: $_selectedMataPelajaran');
      print('- Tanggal: $tanggal');
      print('- Jumlah siswa: ${_filteredSiswaList.length}');

      for (var siswa in _filteredSiswaList) {
        try {
          final status = _absensiStatus[siswa.id] ?? 'hadir';

          print('Mengirim absensi untuk: ${siswa.nama}');
          print('- Siswa ID: ${siswa.id}');
          print('- Status: $status');

          final response = await ApiService.tambahAbsensi({
            'siswa_id': siswa.id,
            'guru_id': guruId,
            'mata_pelajaran_id': _selectedMataPelajaran,
            'tanggal': tanggal,
            'status': status,
            'keterangan': '',
          });

          print('Response: $response');
          successCount++;

          // Delay kecil untuk menghindari rate limiting
          await Future.delayed(const Duration(milliseconds: 50));

        } catch (e) {
          print('Error menyimpan absensi untuk ${siswa.nama}: $e');
          errorCount++;
          errorMessages.add('${siswa.nama}: $e');
        }
      }

      if (!mounted) return;

      // Tampilkan hasil
      if (errorCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Absensi berhasil disimpan untuk $successCount siswa'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Reset form setelah berhasil
        _resetForm();
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount berhasil, $errorCount gagal'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
        _showErrorDetails(errorMessages);
      }

    } catch (e) {
      if (!mounted) return;
      print('General error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
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

  void _showErrorDetails(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Error'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Beberapa absensi gagal disimpan:'),
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
            child: const Text('Tutup'),
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

  String _getStatusText(String status) {
    switch (status) {
      case 'izin':
        return 'Izin';
      case 'sakit':
        return 'Sakit';
      case 'alpha':
        return 'Alpha';
      case 'terlambat':
        return 'Terlambat';
      default:
        return 'Hadir';
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _currentMode == 0 ? 'Hasil Absensi' : 'Tambah Absensi',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _buildModeSwitcher(),
          Expanded(
            child: _currentMode == 0 ? _buildResultsMode() : _buildInputMode(),
          ),
        ],
      ),
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

  Widget _buildStudentItem(Siswa siswa) {
    final status = _absensiStatus[siswa.id] ?? 'hadir';
    final Color statusColor = _getStatusColor(status);
    final String statusText = _getStatusText(status);

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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  'NIS: ${siswa.nis}',
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
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                DropdownButton<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                    DropdownMenuItem(value: 'terlambat', child: Text('Terlambat')),
                    DropdownMenuItem(value: 'izin', child: Text('Izin')),
                    DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                    DropdownMenuItem(value: 'alpha', child: Text('Alpha')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _absensiStatus[siswa.id] = value!;
                    });
                  },
                  underline: Container(),
                  icon: Icon(Icons.arrow_drop_down, color: statusColor, size: 16),
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
            content: Text('Berhasil update $successCount absensi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
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
      case 'izin': return Colors.blue;
      case 'sakit': return Colors.orange;
      case 'alpha': return Colors.red;
      case 'terlambat': return Colors.purple;
      default: return Colors.green;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'izin': return 'Izin';
      case 'sakit': return 'Sakit';
      case 'alpha': return 'Alpha';
      case 'terlambat': return 'Terlambat';
      default: return 'Hadir';
    }
  }

  Color _getAvatarColor(String nama) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    final index = nama.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Edit Absensi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(widget.tanggal),
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_siswaList.length} Siswa',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                      const Text(
                        'Daftar Siswa',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Status',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                // Student List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: _siswaList.length,
                    itemBuilder: (context, index) => _buildStudentItem(_siswaList[index]),
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
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.update, size: 20),
                      label: Text(
                        _isSubmitting ? 'Mengupdate...' : 'Update Absensi',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  }
}
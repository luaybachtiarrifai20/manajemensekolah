import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_services.dart';

class GuruDetailScreen extends StatefulWidget {
  final Map<String, dynamic> guru;

  const GuruDetailScreen({super.key, required this.guru});

  @override
  _GuruDetailScreenState createState() => _GuruDetailScreenState();
}

class _GuruDetailScreenState extends State<GuruDetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _guruDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGuruDetail();
  }

  Future<void> _loadGuruDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Mengambil data detail guru dari API
      final guruDetail = await _apiService.getGuruById(widget.guru['id']);

      // Load mata pelajaran guru
      final mataPelajaranGuru = await _apiService.getMataPelajaranByGuru(
        widget.guru['id'],
      );

      // Gabungkan data
      final combinedData = Map<String, dynamic>.from(guruDetail);
      combinedData['mata_pelajaran_list'] = mataPelajaranGuru;
      combinedData['mata_pelajaran_names'] = mataPelajaranGuru
          .map((mp) => mp['nama']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .join(', ');

      setState(() {
        _guruDetail = combinedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat detail guru: $e')));
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Tidak ada',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guru = _guruDetail ?? widget.guru;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Guru'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadGuruDetail,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Terjadi kesalahan: $_errorMessage'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadGuruDetail,
                    child: Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header dengan avatar
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            guru['nama'][0],
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          guru['nama'],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          guru['nip'] ?? 'Tidak ada NIP',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // Informasi Pribadi
                  Text(
                    'Informasi Pribadi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Divider(),
                  _buildInfoRow('Nama', guru['nama']),
                  _buildInfoRow('NIP', guru['nip'] ?? 'Tidak ada'),
                  _buildInfoRow('Email', guru['email']),

                  SizedBox(height: 24),

                  // Informasi Mengajar
                  Text(
                    'Informasi Mengajar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Divider(),
                  _buildInfoRow(
                    'Kelas',
                    guru['kelas_nama'] ?? 'Tidak ditugaskan',
                  ),
                  _buildInfoRow(
                    'Mata Pelajaran',
                    guru['mata_pelajaran_names']?.isNotEmpty == true
                        ? guru['mata_pelajaran_names']
                        : 'Tidak ditugaskan',
                  ),
                  _buildInfoRow('Role', guru['role']?.toUpperCase() ?? 'GURU'),
                  // Di dalam method build, tambahkan informasi wali kelas:
                  _buildInfoRow(
                    'Status Wali Kelas',
                    guru['is_wali_kelas'] == 1 || guru['is_wali_kelas'] == true
                        ? 'Ya'
                        : 'Tidak',
                  ),

                  SizedBox(height: 24),

                  // Informasi Sistem
                  Text(
                    'Informasi Sistem',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Divider(),
                  _buildInfoRow('ID', guru['id'] ?? 'Tidak ada'),
                  _buildInfoRow(
                    'Tanggal Dibuat',
                    guru['created_at'] != null
                        ? DateTime.parse(guru['created_at']).toString()
                        : 'Tidak diketahui',
                  ),
                  _buildInfoRow(
                    'Terakhir Diupdate',
                    guru['updated_at'] != null
                        ? DateTime.parse(guru['updated_at']).toString()
                        : 'Tidak diketahui',
                  ),

                  SizedBox(height: 32),

                  // Tombol Aksi
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: Text('Kembali ke Daftar Guru'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_services.dart';

class KelolaSiswaScreen extends StatefulWidget {
  const KelolaSiswaScreen({super.key});

  @override
  KelolaSiswaScreenState createState() => KelolaSiswaScreenState();
}

class KelolaSiswaScreenState extends State<KelolaSiswaScreen> {
  final TextEditingController _searchController = TextEditingController();
  Color _getColorForIndex(int index) {
    final colors = [
      Color(0xFF6366F1),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
    ];
    return colors[index % colors.length];
  }
  List<dynamic> _siswa = [];
  List<dynamic> _daftarKelas = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
  try {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final siswaData = await ApiService.getSiswa();
    final apiService = ApiService();
    final kelasData = await apiService.getKelas();

    if (!mounted) return;

    setState(() {
      _siswa = siswaData;
      _daftarKelas = kelasData;
      _isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorMessage = e.toString();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal memuat data siswa/kelas: $e')),
    );
  }
}


  // Tambah/Edit Siswa Dialog
  void _showSiswaDialog({Map<String, dynamic>? siswa}) {
    final namaController = TextEditingController(text: siswa?['nama'] ?? '');
    final nisController = TextEditingController(text: siswa?['nis'] ?? '');
    final alamatController = TextEditingController(
      text: siswa?['alamat'] ?? '',
    );
    final tanggalLahirController = TextEditingController(
      text: siswa != null && siswa['tanggal_lahir'] != null
          ? siswa['tanggal_lahir'].toString().substring(0, 10)
          : '',
    );
    final namaWaliController = TextEditingController(
      text: siswa?['nama_wali'] ?? '',
    );
    final noTeleponController = TextEditingController(
      text: siswa?['no_telepon'] ?? '',
    );

    String? selectedKelasId = siswa?['kelas_id'];
    String? selectedJenisKelamin = siswa?['jenis_kelamin'];

    final isEdit = siswa != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Siswa' : 'Tambah Siswa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: InputDecoration(labelText: 'Nama'),
              ),
              TextField(
                controller: nisController,
                decoration: InputDecoration(labelText: 'NIS'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                initialValue: selectedKelasId,
                decoration: InputDecoration(labelText: 'Kelas'),
                items: _daftarKelas.map((kelas) {
                  return DropdownMenuItem<String>(
                    value: kelas['id'],
                    child: Text(kelas['nama']),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedKelasId = value;
                },
              ),
              TextField(
                controller: alamatController,
                decoration: InputDecoration(labelText: 'Alamat'),
                maxLines: 2,
              ),
              TextField(
                controller: tanggalLahirController,
                decoration: InputDecoration(
                  labelText: 'Tanggal Lahir',
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: selectedJenisKelamin,
                decoration: InputDecoration(labelText: 'Jenis Kelamin'),
                items: [
                  DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                  DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                ],
                onChanged: (value) {
                  selectedJenisKelamin = value;
                },
              ),
              TextField(
                controller: namaWaliController,
                decoration: InputDecoration(labelText: 'Nama Wali Murid'),
              ),
              TextField(
                controller: noTeleponController,
                decoration: InputDecoration(labelText: 'No. Telepon'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nama = namaController.text.trim();
              final nis = nisController.text.trim();
              final alamat = alamatController.text.trim();
              final tanggalLahir = tanggalLahirController.text.trim();
              final namaWali = namaWaliController.text.trim();
              final noTelepon = noTeleponController.text.trim();

              if (nama.isEmpty ||
                  nis.isEmpty ||
                  selectedKelasId == null ||
                  alamat.isEmpty ||
                  tanggalLahir.isEmpty ||
                  selectedJenisKelamin == null ||
                  namaWali.isEmpty ||
                  noTelepon.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Semua field harus diisi')),
                );
                return;
              }

              try {
                final data = {
                  'nama': nama,
                  'nis': nis,
                  'kelas_id': selectedKelasId,
                  'alamat': alamat,
                  'tanggal_lahir': tanggalLahir,
                  'jenis_kelamin': selectedJenisKelamin,
                  'nama_wali': namaWali,
                  'no_telepon': noTelepon,
                };

                if (isEdit) {
                  await ApiService.updateSiswa(siswa['id'], data);
                  await _loadData(); // Reload data untuk mendapatkan perubahan
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Siswa berhasil diperbarui')),
                  );
                } else {
                  await ApiService.tambahSiswa(data);
                  await _loadData(); // Reload data untuk mendapatkan data baru
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Siswa berhasil ditambahkan')),
                  );
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menyimpan siswa: $e')),
                );
              }
            },
            child: Text(isEdit ? 'Perbarui' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  // Hapus Siswa
  void _hapusSiswa(Map<String, dynamic> siswa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Siswa'),
        content: Text('Yakin ingin menghapus siswa ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.deleteSiswa(siswa['id']);
                setState(() {
                  _siswa.removeWhere((s) => s['id'] == siswa['id']);
                  final kelasIdx = _daftarKelas.indexWhere(
                    (k) => k['id'] == siswa['kelas_id'],
                  );
                  if (kelasIdx != -1 &&
                      (_daftarKelas[kelasIdx]['jumlah_siswa'] ?? 0) > 0) {
                    _daftarKelas[kelasIdx]['jumlah_siswa'] -= 1;
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Siswa berhasil dihapus')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menghapus siswa: $e')),
                );
              }
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Kelola Siswa')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Kelola Siswa')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Terjadi kesalahan: $_errorMessage'),
              SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Kelola Siswa',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Color(0xFF4F46E5),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.symmetric(horizontal: 16),
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
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari siswa...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                border: InputBorder.none,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: _siswa.where((siswa) {
              final searchTerm = _searchController.text.toLowerCase();
              return searchTerm.isEmpty ||
                  siswa['nama'].toLowerCase().contains(searchTerm) ||
                  (siswa['nis']?.toLowerCase().contains(searchTerm) ?? false);
            }).isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada siswa',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Tap + untuk menambah siswa'
                              : 'Tidak ditemukan hasil pencarian',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _siswa.where((siswa) {
                      final searchTerm = _searchController.text.toLowerCase();
                      return searchTerm.isEmpty ||
                          siswa['nama'].toLowerCase().contains(searchTerm) ||
                          (siswa['nis']?.toLowerCase().contains(searchTerm) ?? false);
                    }).length,
                    itemBuilder: (context, index) {
                      final filteredList = _siswa.where((siswa) {
                        final searchTerm = _searchController.text.toLowerCase();
                        return searchTerm.isEmpty ||
                            siswa['nama'].toLowerCase().contains(searchTerm) ||
                            (siswa['nis']?.toLowerCase().contains(searchTerm) ?? false);
                      }).toList();

                      final siswa = filteredList[index];
                      final color = _getColorForIndex(index);

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.15),
                              child: Text(
                                siswa['nama'] != null && siswa['nama'].isNotEmpty
                                    ? siswa['nama'][0]
                                    : '?',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(siswa['nama'] ?? 'Nama tidak tersedia'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kelas: ${siswa['kelas_nama'] ?? 'Tidak ada'}'),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Hapus')),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showSiswaDialog(siswa: siswa);
                                } else if (value == 'delete') {
                                  _hapusSiswa(siswa);
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showSiswaDialog();
        },
        backgroundColor: Color(0xFF4F46E5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

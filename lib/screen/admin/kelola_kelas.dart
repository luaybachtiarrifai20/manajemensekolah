import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_services.dart';

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

class KelolaKelasScreen extends StatefulWidget {
  const KelolaKelasScreen({super.key});

  @override
  KelolaKelasScreenState createState() => KelolaKelasScreenState();
}

class KelolaKelasScreenState extends State<KelolaKelasScreen> {
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

  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  String? _selectedGuruId;
  bool _isEditMode = false;
  String? _editingKelasId;
  List<dynamic> _daftarKelas = [];
  List<dynamic> _daftarGuru = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final apiService = ApiService();
      final kelasData = await apiService.getKelas();
      final guruData = await apiService.getGuru();

      setState(() {
        _daftarKelas = kelasData;
        _daftarGuru = guruData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    }
  }

  void _tambahKelas() {
    setState(() {
      _isEditMode = false;
      _namaController.clear();
      _selectedGuruId = null;
    });
    _showKelasDialog();
  }

  void _editKelas(dynamic kelas) {
    setState(() {
      _isEditMode = true;
      _editingKelasId = kelas['id'];
      _namaController.text = kelas['nama'];
      _selectedGuruId = kelas['wali_kelas_id'];
    });
    _showKelasDialog();
  }

  Future<void> _hapusKelas(String id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Kelas'),
        content: Text('Apakah Anda yakin ingin menghapus kelas ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Implementasi API delete kelas
                final apiService = ApiService();
                await apiService.deleteKelas(id);

                setState(() {
                  _daftarKelas.removeWhere((kelas) => kelas['id'] == id);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Kelas berhasil dihapus')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menghapus kelas: $e')),
                );
              }
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _simpanKelas() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_isEditMode) {
          // Implementasi API update kelas
          final apiService = ApiService();
          await apiService.updateKelas(_editingKelasId!, {
            'nama': _namaController.text,
            'wali_kelas_id': _selectedGuruId,
          });

          setState(() {
            final index = _daftarKelas.indexWhere(
              (k) => k['id'] == _editingKelasId,
            );
            _daftarKelas[index] = {
              ..._daftarKelas[index],
              'nama': _namaController.text,
              'wali_kelas_id': _selectedGuruId,
              'wali_kelas_nama': _daftarGuru.firstWhere(
                (g) => g['id'] == _selectedGuruId,
              )['nama'],
            };
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Kelas berhasil diperbarui')));
        } else {
          // Implementasi API tambah kelas
          final apiService = ApiService();
          await apiService.tambahKelas({
            'nama': _namaController.text,
            'wali_kelas_id': _selectedGuruId,
          });

          final newKelas = {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'nama': _namaController.text,
            'wali_kelas_id': _selectedGuruId,
            'wali_kelas_nama': _daftarGuru.firstWhere(
              (g) => g['id'] == _selectedGuruId,
            )['nama'],
            'jumlah_siswa': 0,
          };

          setState(() {
            _daftarKelas.add(newKelas);
          });
          await _loadData();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Kelas berhasil ditambahkan')));
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan kelas: $e')));
      }
    }
  }

  void _showKelasDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEditMode ? 'Edit Kelas' : 'Tambah Kelas'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namaController,
                  decoration: InputDecoration(
                    labelText: 'Nama Kelas',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama kelas harus diisi';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Di dalam _showKelasDialog, modifikasi dropdown wali kelas:
                DropdownButtonFormField<String>(
                  initialValue: _selectedGuruId,
                  decoration: InputDecoration(
                    labelText: 'Wali Kelas',
                    border: OutlineInputBorder(),
                  ),
                  items: _daftarGuru
                      .where(
                        (guru) => guru['role'] == 'guru',
                      ) // Hanya tampilkan guru
                      .map((guru) {
                        return DropdownMenuItem<String>(
                          value: guru['id'],
                          child: Text(
                            '${guru['nama']}${guru['is_wali_kelas'] == 1 ? ' (Wali Kelas)' : ''}',
                          ),
                        );
                      })
                      .toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedGuruId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Wali kelas harus dipilih';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _simpanKelas,
            child: Text(_isEditMode ? 'Perbarui' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  void _lihatDetailKelas(dynamic kelas) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Kelas ${kelas['nama']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Nama Kelas', kelas['nama']),
              _buildDetailItem(
                'Wali Kelas',
                kelas['wali_kelas_nama'] ?? 'Tidak ada',
              ),
              _buildDetailItem(
                'Jumlah Siswa',
                (kelas['jumlah_siswa'] ?? 0).toString(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Color getColorForIndex(int index) {
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text('Kelola Kelas', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF4F46E5),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              ),
              SizedBox(height: 16),
              Text(
                'Memuat data kelas...',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text('Kelola Kelas', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF4F46E5),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              SizedBox(height: 16),
              Text(
                'Terjadi kesalahan:',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4F46E5),
                ),
                child: Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final TextEditingController searchController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Kelola Kelas',
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
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari kelas...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                border: InputBorder.none,
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 20),
                        onPressed: () {
                          searchController.clear();
                          // setState(() {}); // Uncomment if you want live search
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                // setState(() {}); // Uncomment if you want live search
              },
            ),
          ),
          Expanded(
            child:
                _daftarKelas.where((kelas) {
                  final searchTerm = searchController.text.toLowerCase();
                  return searchTerm.isEmpty ||
                      kelas['nama'].toLowerCase().contains(searchTerm);
                }).isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.class_,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada kelas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          searchController.text.isEmpty
                              ? 'Tap + untuk menambah kelas'
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
                    itemCount: _daftarKelas.where((kelas) {
                      final searchTerm = searchController.text.toLowerCase();
                      return searchTerm.isEmpty ||
                          kelas['nama'].toLowerCase().contains(searchTerm);
                    }).length,
                    itemBuilder: (context, index) {
                      final filteredList = _daftarKelas.where((kelas) {
                        final searchTerm = searchController.text.toLowerCase();
                        return searchTerm.isEmpty ||
                            kelas['nama'].toLowerCase().contains(searchTerm);
                      }).toList();

                      final kelas = filteredList[index];
                      final color = getColorForIndex(index);

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.15),
                              child: Text(
                                kelas['nama'].substring(0, 1),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              'Kelas ${kelas['nama']}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wali: ${kelas['wali_kelas_nama'] ?? 'Tidak ada'}',
                                ),
                                Text(
                                  'Siswa: ${kelas['jumlah_siswa'] ?? 0} orang',
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'detail',
                                  child: Row(
                                    children: [
                                      Icon(Icons.info, size: 20),
                                      SizedBox(width: 8),
                                      Text('Detail'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Hapus',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'detail') {
                                  _lihatDetailKelas(kelas);
                                } else if (value == 'edit') {
                                  _editKelas(kelas);
                                } else if (value == 'delete') {
                                  _hapusKelas(kelas['id']);
                                }
                              },
                            ),
                            onTap: () => _lihatDetailKelas(kelas),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tambahKelas,
        backgroundColor: Color(0xFF4F46E5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/screen/admin/guru_detail_screen.dart';

class KelolaGuruScreen extends StatefulWidget {
  const KelolaGuruScreen({super.key});

  @override
  KelolaGuruScreenState createState() => KelolaGuruScreenState();
}

class KelolaGuruScreenState extends State<KelolaGuruScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _guru = [];
  List<dynamic> _mataPelajaran = [];
  List<dynamic> _kelas = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();

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

      final [guruData, mataPelajaranData, kelasData] = await Future.wait([
        _apiService.getGuru(),
        _apiService.getMataPelajaran(),
        _apiService.getKelas(),
      ]);

      setState(() {
        _guru = guruData;
        _mataPelajaran = mataPelajaranData;
        _kelas = kelasData;
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
      ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    }
  }

  Future<void> _handleGuruMataPelajaran(
    String guruId,
    List<String> selectedMataPelajaranIds,
  ) async {
    try {
      // Get current mata pelajaran
      final currentMataPelajaran = await _apiService.getMataPelajaranByGuru(
        guruId,
      );
      final currentIds = currentMataPelajaran
          .map((mp) => mp['id'] as String)
          .toList();

      // Add new mata pelajaran
      for (final mpId in selectedMataPelajaranIds) {
        if (!currentIds.contains(mpId)) {
          await _apiService.addMataPelajaranToGuru(guruId, mpId);
        }
      }

      // Remove unselected mata pelajaran
      for (final currentId in currentIds) {
        if (!selectedMataPelajaranIds.contains(currentId)) {
          await _apiService.removeMataPelajaranFromGuru(guruId, currentId);
        }
      }
    } catch (error) {
      print('Error handling guru mata pelajaran: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengupdate mata pelajaran guru: $error')),
      );
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? guru}) {
    final namaController = TextEditingController(text: guru?['nama']);
    final emailController = TextEditingController(text: guru?['email']);
    final nipController = TextEditingController(text: guru?['nip'] ?? '');

    String? selectedKelasId = guru?['kelas_id'];
    bool isWaliKelas =
        guru?['is_wali_kelas'] == 1 || guru?['is_wali_kelas'] == true;

    // Untuk multiple mata pelajaran
    List<String> selectedMataPelajaranIds = [];
    if (guru != null && guru['mata_pelajaran_ids'] != null) {
      selectedMataPelajaranIds = guru['mata_pelajaran_ids'].toString().split(
        ',',
      );
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(guru == null ? 'Tambah Guru' : 'Edit Guru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: namaController,
                    decoration: InputDecoration(
                      labelText: 'Nama Guru',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: nipController,
                    decoration: InputDecoration(
                      labelText: 'NIP',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedKelasId,
                    decoration: InputDecoration(
                      labelText: 'Kelas (Opsional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text('Tidak ada')),
                      ..._kelas.map(
                        (kelas) => DropdownMenuItem(
                          value: kelas['id'],
                          child: Text(kelas['nama']),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => selectedKelasId = value);
                    },
                  ),
                  SizedBox(height: 16),
                  // Multiple mata pelajaran selection
                  Text('Mata Pelajaran:'),
                  ..._mataPelajaran
                      .map(
                        (mp) => CheckboxListTile(
                          title: Text(mp['nama']),
                          value: selectedMataPelajaranIds.contains(mp['id']),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedMataPelajaranIds.add(mp['id']);
                              } else {
                                selectedMataPelajaranIds.remove(mp['id']);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      )
                      .toList(),
                  SizedBox(height: 16),
                  CheckboxListTile(
                    title: Text('Wali Kelas'),
                    value: isWaliKelas,
                    onChanged: (value) {
                      setState(() => isWaliKelas = value ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
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
                // Dalam _showAddEditDialog
                onPressed: () async {
                  if (namaController.text.isEmpty ||
                      emailController.text.isEmpty ||
                      nipController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Nama, email, dan NIP harus diisi'),
                      ),
                    );
                    return;
                  }

                  try {
                    final data = {
                      'nama': namaController.text,
                      'email': emailController.text,
                      'kelas_id': selectedKelasId,
                      'nip': nipController.text,
                      'is_wali_kelas': isWaliKelas,
                      // HAPUS mata_pelajaran_id karena sekarang menggunakan many-to-many
                    };

                    String guruId;
                    if (guru == null) {
                      final result = await _apiService.tambahGuru(data);
                      guruId = result['id'];
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Guru berhasil ditambahkan. Password default: password123',
                          ),
                          duration: Duration(seconds: 5),
                        ),
                      );
                    } else {
                      guruId = guru['id'];
                      await _apiService.updateGuru(guruId, data);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Guru berhasil diupdate')),
                      );
                    }

                    // Handle mata pelajaran secara terpisah menggunakan endpoint many-to-many
                    await _handleGuruMataPelajaran(
                      guruId,
                      selectedMataPelajaranIds,
                    );

                    Navigator.pop(context);
                    _loadData();
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menyimpan data: $error')),
                    );
                  }
                },
                child: Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> guru) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Guru'),
        content: Text('Yakin ingin menghapus guru "${guru['nama']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _apiService.deleteGuru(guru['id']);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Guru berhasil dihapus')),
                );
                Navigator.pop(context);
                _loadData();
              } catch (error) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menghapus guru: $error')),
                );
              }
            },
            child: Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> guru) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GuruDetailScreen(guru: guru)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Kelola Guru')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Kelola Guru')),
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
      appBar: AppBar(
        title: Text('Kelola Guru'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari guru...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _guru.length,
              itemBuilder: (context, index) {
                final guru = _guru[index];
                final searchTerm = _searchController.text.toLowerCase();

                if (searchTerm.isNotEmpty &&
                    !guru['nama'].toLowerCase().contains(searchTerm) &&
                    !(guru['nip']?.toLowerCase().contains(searchTerm) ??
                        false)) {
                  return SizedBox.shrink();
                }

                final isWaliKelas =
                    guru['is_wali_kelas'] == 1 || guru['is_wali_kelas'] == true;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isWaliKelas
                          ? Colors.orange.shade100
                          : Colors.blue.shade100,
                      child: Text(
                        guru['nama'][0],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      guru['nama'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Dalam ListTile builder
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NIP: ${guru['nip'] ?? 'Tidak ada'}'),
                        if (guru['mata_pelajaran_names'] != null)
                          Wrap(
                            spacing: 4,
                            children: (guru['mata_pelajaran_names'] as String)
                                .split(',')
                                .where((name) => name.isNotEmpty)
                                .map(
                                  (name) => Chip(
                                    label: Text(
                                      name,
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: Colors.blue.shade100,
                                  ),
                                )
                                .toList(),
                          ),
                        if (isWaliKelas)
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Wali Kelas',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                          onPressed: () => _showAddEditDialog(guru: guru),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => _showDeleteDialog(guru),
                        ),
                      ],
                    ),
                    onTap: () => _navigateToDetail(guru),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

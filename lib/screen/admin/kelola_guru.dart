import 'package:flutter/material.dart';
import 'package:manajemensekolah/screen/admin/guru_detail_screen.dart';
import 'package:manajemensekolah/services/api_services.dart';

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

    Future<void> showDialogWithSubjects(List<String> subjectIds) async {
      selectedMataPelajaranIds = subjectIds;
      selectedMataPelajaranIds = selectedMataPelajaranIds.toSet().toList();
      await showDialog(
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
                      initialValue: selectedKelasId,
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
                    ..._mataPelajaran.map(
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
                    ),
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

    if (guru == null) {
      // Tambah guru: tidak ada subject terpilih
      showDialogWithSubjects([]);
    } else {
      // Edit guru: ambil data subject terbaru dari database
      _apiService.getMataPelajaranByGuru(guru['id']).then((list) {
        final ids = list.map((mp) => mp['id'].toString()).toList();
        showDialogWithSubjects(ids);
      });
    }
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

  // Fungsi untuk menampilkan popup menu tepat di bawah icon titik tiga
  void _showPopupMenu(BuildContext context, Map<String, dynamic> guru, GlobalKey iconKey) {
    final RenderBox iconRenderBox = iconKey.currentContext!.findRenderObject() as RenderBox;
    final iconOffset = iconRenderBox.localToGlobal(Offset.zero);

    // Hitung posisi tepat di bawah icon titik tiga
    final left = iconOffset.dx - 120; // Sesuaikan agar popup sejajar dengan icon
    final top = iconOffset.dy + iconRenderBox.size.height;
    final right = MediaQuery.of(context).size.width - left - 180;
    final bottom = MediaQuery.of(context).size.height - top - 50;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, right, bottom),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue.shade600, size: 20),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red.shade600, size: 20),
              SizedBox(width: 8),
              Text('Hapus'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        if (value == 'edit') {
          _showAddEditDialog(guru: guru);
        } else if (value == 'delete') {
          _showDeleteDialog(guru);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text('Kelola Guru', style: TextStyle(color: Colors.white)),
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
                'Memuat data guru...',
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
          title: Text('Kelola Guru', style: TextStyle(color: Colors.white)),
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

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Kelola Guru',
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
                hintText: 'Cari guru...',
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
            child:
                _guru.where((guru) {
                  final searchTerm = _searchController.text.toLowerCase();
                  return searchTerm.isEmpty ||
                      guru['nama'].toLowerCase().contains(searchTerm) ||
                      (guru['nip']?.toLowerCase().contains(searchTerm) ??
                          false);
                }).isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada guru',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Tap + untuk menambah guru'
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
                    itemCount: _guru.where((guru) {
                      final searchTerm = _searchController.text.toLowerCase();
                      return searchTerm.isEmpty ||
                          guru['nama'].toLowerCase().contains(searchTerm) ||
                          (guru['nip']?.toLowerCase().contains(searchTerm) ??
                              false);
                    }).length,
                    itemBuilder: (context, index) {
                      final filteredList = _guru.where((guru) {
                        final searchTerm = _searchController.text.toLowerCase();
                        return searchTerm.isEmpty ||
                            guru['nama'].toLowerCase().contains(searchTerm) ||
                            (guru['nip']?.toLowerCase().contains(searchTerm) ??
                                false);
                      }).toList();

                      final guru = filteredList[index];
                      final isWaliKelas =
                          guru['is_wali_kelas'] == 1 ||
                          guru['is_wali_kelas'] == true;
                      final color = _getColorForIndex(index);
                      
                      // Buat GlobalKey khusus untuk icon titik tiga
                      final GlobalKey iconKey = GlobalKey();

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color.withOpacity(0.8),
                                    color.withOpacity(0.6),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: Text(
                                  guru['nama'][0],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              guru['nama'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NIP: ${guru['nip'] ?? 'Tidak ada'}',
                                  style: TextStyle(fontSize: 12),
                                ),
                                if (guru['mata_pelajaran_names'] != null) ...[
                                  SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children:
                                        (guru['mata_pelajaran_names'] as String)
                                            .split(',')
                                            .where((name) => name.isNotEmpty)
                                            .map(
                                              (name) => Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.blue.shade100,
                                                  ),
                                                ),
                                                child: Text(
                                                  name,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blue.shade700,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ],
                                if (isWaliKelas) ...[
                                  SizedBox(height: 4),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.shade100,
                                      ),
                                    ),
                                    child: Text(
                                      'Wali Kelas',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Container(
                              key: iconKey, // Key khusus untuk icon
                              child: IconButton(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                                onPressed: () => _showPopupMenu(context, guru, iconKey),
                                tooltip: 'Menu',
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            onTap: () => _navigateToDetail(guru),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Color(0xFF4F46E5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

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
}
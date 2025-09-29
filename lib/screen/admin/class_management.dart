import 'package:flutter/material.dart';
import 'package:manajemensekolah/components/class_form_dialog.dart';
import 'package:manajemensekolah/components/class_list_item.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/error_screen.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/components/search_bar.dart';
import 'package:manajemensekolah/services/api_class_services.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/api_teacher_services.dart';
import 'package:manajemensekolah/utils/color_utils.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  ClassManagementScreenState createState() => ClassManagementScreenState();
}

class ClassManagementScreenState extends State<ClassManagementScreen> {
  final _namaController = TextEditingController();
  String? _selectedGuruId;
  bool _isEditMode = false;
  String? _editingKelasId;
  List<dynamic> _daftarKelas = [];
  List<dynamic> _daftarGuru = [];
  bool _isLoading = true;
  String? _errorMessage;

  final apiService = ApiService();
  final apiServiceClass = ApiClassService();
  final ApiTeacherService apiTeacherService = ApiTeacherService();

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

      final kelasData = await apiServiceClass.getClass();
      final guruData = await apiTeacherService.getTeacher();

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
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
                final apiServiceClass = ApiClassService();
                await apiServiceClass.deleteClass(id);

                setState(() {
                  _daftarKelas.removeWhere((kelas) => kelas['id'] == id);
                });
                if (context.mounted) {
                  Navigator.pop(context);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kelas berhasil dihapus')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus kelas: $e')),
                  );
                }
              }
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _simpanKelas(String nama, String? waliKelasId) async {
    try {
      if (_isEditMode) {
        await apiServiceClass.updateClass(_editingKelasId!, {
          'nama': nama,
          'wali_kelas_id': waliKelasId,
        });

        setState(() {
          final index = _daftarKelas.indexWhere(
            (k) => k['id'] == _editingKelasId,
          );
          _daftarKelas[index] = {
            ..._daftarKelas[index],
            'nama': nama,
            'wali_kelas_id': waliKelasId,
            'wali_kelas_nama': _daftarGuru.firstWhere(
              (g) => g['id'] == waliKelasId,
            )['nama'],
          };
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kelas berhasil diperbarui')),
          );
        }
      } else {
        await apiServiceClass.addClass({
          'nama': nama,
          'wali_kelas_id': waliKelasId,
        });

        final newKelas = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'nama': nama,
          'wali_kelas_id': waliKelasId,
          'wali_kelas_nama': _daftarGuru.firstWhere(
            (g) => g['id'] == waliKelasId,
          )['nama'],
          'jumlah_siswa': 0,
        };

        setState(() {
          _daftarKelas.add(newKelas);
        });
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kelas berhasil ditambahkan')),
          );
        }
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan kelas: $e')),
        );
      }
    }
  }

  void _showKelasDialog() {
    showDialog(
      context: context,
      builder: (context) => ClassFormDialog(
        isEditMode: _isEditMode,
        initialName: _namaController.text,
        initialTeacherId: _selectedGuruId,
        teachers: _daftarGuru,
        onSave: _simpanKelas,
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

  List<dynamic> _getFilteredKelas(String searchTerm) {
    return _daftarKelas.where((kelas) {
      return searchTerm.isEmpty ||
          kelas['nama'].toLowerCase().contains(searchTerm.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LoadingScreen(message: 'Memuat data kelas...');
    }

    if (_errorMessage != null) {
      return ErrorScreen(
        errorMessage: _errorMessage!,
        onRetry: _loadData,
      );
    }

    final TextEditingController searchController = TextEditingController();
    final filteredKelas = _getFilteredKelas(searchController.text);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Kelola Kelas',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: ColorUtils.primaryColor,
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
          CustomSearchBar(
            controller: searchController,
            hintText: 'Cari kelas...',
            onChanged: (value) {
              setState(() {});
            },
          ),
          Expanded(
            child: filteredKelas.isEmpty
                ? EmptyState(
                    title: 'Tidak ada kelas',
                    subtitle: searchController.text.isEmpty
                        ? 'Tap + untuk menambah kelas'
                        : 'Tidak ditemukan hasil pencarian',
                    icon: Icons.class_,
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredKelas.length,
                    itemBuilder: (context, index) {
                      final kelas = filteredKelas[index];
                      
                      return ClassListItem(
                        kelas: kelas,
                        index: index,
                        onTap: () => _lihatDetailKelas(kelas),
                        onMenuSelected: (value) {
                          if (value == 'detail') {
                            _lihatDetailKelas(kelas);
                          } else if (value == 'edit') {
                            _editKelas(kelas);
                          } else if (value == 'delete') {
                            _hapusKelas(kelas['id']);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tambahKelas,
        backgroundColor: ColorUtils.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
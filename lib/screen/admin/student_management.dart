import 'package:flutter/material.dart';
import 'package:manajemensekolah/components/confirmation_dialog.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/error_screen.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/components/search_bar.dart';
import 'package:manajemensekolah/components/student_list_item.dart';
import 'package:manajemensekolah/services/api_class_services.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/api_student_services.dart';
import 'package:manajemensekolah/utils/color_utils.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  StudentManagementScreenState createState() => StudentManagementScreenState();
}

class StudentManagementScreenState extends State<StudentManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _siswa = [];
  List<dynamic> _daftarKelas = [];
  bool _isLoading = true;
  String? _errorMessage;
  final apiService = ApiService();
  final apiServiceClass = ApiClassService();
  final ApiStudentService apiStudentService = ApiStudentService();

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

      final siswaData = await ApiStudentService.getStudent();
      final kelasData = await apiServiceClass.getClass();

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
    final alamatController = TextEditingController(text: siswa?['alamat'] ?? '');
    final tanggalLahirController = TextEditingController(
      text: siswa != null && siswa['tanggal_lahir'] != null
          ? siswa['tanggal_lahir'].toString().substring(0, 10)
          : '',
    );
    final namaWaliController = TextEditingController(text: siswa?['nama_wali'] ?? '');
    final noTeleponController = TextEditingController(text: siswa?['no_telepon'] ?? '');

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

              if (nama.isEmpty || nis.isEmpty || selectedKelasId == null || 
                  alamat.isEmpty || tanggalLahir.isEmpty || selectedJenisKelamin == null || 
                  namaWali.isEmpty || noTelepon.isEmpty) {
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
                  await ApiStudentService.updateStudent(siswa['id'], data);
                  await _loadData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Siswa berhasil diperbarui')),
                    );
                  }
                } else {
                  await ApiStudentService.addStudent(data);
                  await _loadData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Siswa berhasil ditambahkan')),
                    );
                    Navigator.pop(context);
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan siswa: $e')),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Perbarui' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  // Hapus Siswa
  Future<void> _hapusSiswa(Map<String, dynamic> siswa) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Hapus Siswa',
        content: 'Yakin ingin menghapus siswa ini?',
      ),
    );

    if (confirmed == true) {
      try {
        await ApiStudentService.deleteStudent(siswa['id']);
        setState(() {
          _siswa.removeWhere((s) => s['id'] == siswa['id']);
          final kelasIdx = _daftarKelas.indexWhere((k) => k['id'] == siswa['kelas_id']);
          if (kelasIdx != -1 && (_daftarKelas[kelasIdx]['jumlah_siswa'] ?? 0) > 0) {
            _daftarKelas[kelasIdx]['jumlah_siswa'] -= 1;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Siswa berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus siswa: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LoadingScreen(message: 'Memuat data siswa...');
    }

    if (_errorMessage != null) {
      return ErrorScreen(
        errorMessage: _errorMessage!,
        onRetry: _loadData,
      );
    }

    final filteredSiswa = _siswa.where((siswa) {
      final searchTerm = _searchController.text.toLowerCase();
      return searchTerm.isEmpty ||
          siswa['nama'].toLowerCase().contains(searchTerm) ||
          (siswa['nis']?.toLowerCase().contains(searchTerm) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Kelola Siswa',
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
            controller: _searchController,
            hintText: 'Cari siswa...',
            onChanged: (value) => setState(() {}),
          ),
          Expanded(
            child: filteredSiswa.isEmpty
                ? EmptyState(
                    title: 'Tidak ada siswa',
                    subtitle: _searchController.text.isEmpty
                        ? 'Tap + untuk menambah siswa'
                        : 'Tidak ditemukan hasil pencarian',
                    icon: Icons.people_outline,
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredSiswa.length,
                    itemBuilder: (context, index) {
                      final siswa = filteredSiswa[index];
                      
                      return StudentListItem(
                        siswa: siswa,
                        index: index,
                        onEdit: () => _showSiswaDialog(siswa: siswa),
                        onDelete: () => _hapusSiswa(siswa),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSiswaDialog(),
        backgroundColor: ColorUtils.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
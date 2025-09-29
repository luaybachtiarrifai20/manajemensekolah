import 'package:flutter/material.dart';
import 'package:manajemensekolah/components/confirmation_dialog.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/error_screen.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/components/search_bar.dart';
import 'package:manajemensekolah/components/teacher_list_item.dart';
import 'package:manajemensekolah/screen/admin/teacher_detail_screen.dart';
import 'package:manajemensekolah/services/api_class_services.dart';
import 'package:manajemensekolah/services/api_subject_services.dart';
import 'package:manajemensekolah/services/api_teacher_services.dart';
import 'package:manajemensekolah/utils/color_utils.dart';

class TeacherAdminScreen extends StatefulWidget {
  const TeacherAdminScreen({super.key});

  @override
  TeacherAdminScreenState createState() => TeacherAdminScreenState();
}

class TeacherAdminScreenState extends State<TeacherAdminScreen> {
  final ApiTeacherService _teacherService = ApiTeacherService();
  final ApiClassService _classService = ApiClassService();
  final ApiSubjectService _subjectService = ApiSubjectService();
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

      final guruData = await _teacherService.getTeacher();
      final mataPelajaranData = await _subjectService.getSubject();
      final kelasData = await _classService.getClass();

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    }
  }

  Future<void> _manageTeacherSubject(String guruId, List<String> selectedMataPelajaranIds) async {
    try {
      final currentMataPelajaran = await _teacherService.getSubjectByTeacher(guruId);
      final currentIds = currentMataPelajaran.map((mp) => mp['id'] as String).toList();

      for (final mpId in selectedMataPelajaranIds) {
        if (!currentIds.contains(mpId)) {
          await _teacherService.addSubjectToTeacher(guruId, mpId);
        }
      }

      for (final currentId in currentIds) {
        if (!selectedMataPelajaranIds.contains(currentId)) {
          await _teacherService.removeSubjectFromTeacher(guruId, currentId);
        }
      }
    } catch (error) {
      debugPrint('Error handling guru mata pelajaran: $error');
      if (!mounted) return;
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
                        final result = await _teacherService.addTeacher(data);
                        guruId = result['id'];
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Guru berhasil ditambahkan. Password default: password123',
                              ),
                              duration: Duration(seconds: 5),
                            ),
                          );
                        }
                      } else {
                        guruId = guru['id'];
                        await _teacherService.updateTeacher(guruId, data);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Guru berhasil diupdate')),
                          );
                        }
                      }

                      await _manageTeacherSubject(
                        guruId,
                        selectedMataPelajaranIds,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      _loadData();
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal menyimpan data: $error'),
                          ),
                        );
                      }
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
      _teacherService.getSubjectByTeacher(guru['id']).then((list) {
        final ids = list.map((mp) => mp['id'].toString()).toList();
        showDialogWithSubjects(ids);
      });
    }
  }

   Future<void> _deleteTeacher(Map<String, dynamic> guru) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Hapus Guru',
        content: 'Apakah Anda yakin ingin menghapus guru ini?',
      ),
    );

    if (confirmed == true) {
      try {
        await _teacherService.deleteTeacher(guru['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Guru berhasil dihapus')));
        }
        _loadData();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus guru: $error')),
          );
        }
      }
    }
  }

  void _navigateToDetail(Map<String, dynamic> guru) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TeacherDetailScreen(guru: guru)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LoadingScreen(message: 'Memuat data guru...');
    }

    if (_errorMessage != null) {
      return ErrorScreen(
        errorMessage: _errorMessage!,
        onRetry: _loadData,
      );
    }

    final filteredGuru = _guru.where((guru) {
      final searchTerm = _searchController.text.toLowerCase();
      return searchTerm.isEmpty ||
          guru['nama'].toLowerCase().contains(searchTerm) ||
          (guru['nip']?.toLowerCase().contains(searchTerm) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Kelola Guru',
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
            hintText: 'Cari guru...',
            onChanged: (value) => setState(() {}),
          ),
          Expanded(
            child: filteredGuru.isEmpty
                ? EmptyState(
                    title: 'Tidak ada guru',
                    subtitle: _searchController.text.isEmpty
                        ? 'Tap + untuk menambah guru'
                        : 'Tidak ditemukan hasil pencarian',
                    icon: Icons.person_outline,
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredGuru.length,
                    itemBuilder: (context, index) {
                      final guru = filteredGuru[index];
                      
                      return TeacherListItem(
                        guru: guru,
                        index: index,
                        onTap: () => _navigateToDetail(guru),
                        onEdit: () => _showAddEditDialog(guru: guru),
                        onDelete: () => _deleteTeacher(guru),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: ColorUtils.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
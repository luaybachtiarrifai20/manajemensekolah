import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'package:manajemensekolah/utils/language_utils.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  StudentManagementScreenState createState() => StudentManagementScreenState();
}

class StudentManagementScreenState extends State<StudentManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _students = [];
  List<dynamic> _classList = [];
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

      final studentData = await ApiStudentService.getStudent();
      final classData = await apiServiceClass.getClass();

      if (!mounted) return;

      setState(() {
        _students = studentData;
        _classList = classData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().getTranslatedText({
              'en': 'Failed to load student/class data: $e',
              'id': 'Gagal memuat data siswa/kelas: $e',
            }),
          ),
        ),
      );
    }
  }

  void _showStudentDialog({Map<String, dynamic>? student}) {
    final nameController = TextEditingController(text: student?['name'] ?? '');
    final nisController = TextEditingController(text: student?['nis'] ?? '');
    final addressController = TextEditingController(text: student?['address'] ?? '');
    final birthDateController = TextEditingController(
      text: student != null && student['birth_date'] != null
          ? student['birth_date'].toString().substring(0, 10)
          : '',
    );
    final parentNameController = TextEditingController(text: student?['parent_name'] ?? '');
    final phoneController = TextEditingController(text: student?['phone'] ?? '');

    String? selectedClassId = student?['class_id'];
    String? selectedGender = student?['gender'];

    final isEdit = student != null;

    showDialog(
      context: context,
      builder: (context) => Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return AlertDialog(
            title: Text(
              isEdit
                  ? languageProvider.getTranslatedText({
                      'en': 'Edit Student',
                      'id': 'Edit Siswa',
                    })
                  : languageProvider.getTranslatedText({
                      'en': 'Add Student',
                      'id': 'Tambah Siswa',
                    }),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: languageProvider.getTranslatedText({
                        'en': 'Name',
                        'id': 'Nama',
                      }),
                    ),
                  ),
                  TextField(
                    controller: nisController,
                    decoration: InputDecoration(
                      labelText: 'NIS',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: selectedClassId,
                    decoration: InputDecoration(
                      labelText: languageProvider.getTranslatedText({
                        'en': 'Class',
                        'id': 'Kelas',
                      }),
                    ),
                    items: _classList.map((classItem) {
                      return DropdownMenuItem<String>(
                        value: classItem['id'],
                        child: Text(classItem['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedClassId = value;
                    },
                  ),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: languageProvider.getTranslatedText({
                        'en': 'Address',
                        'id': 'Alamat',
                      }),
                    ),
                    maxLines: 2,
                  ),
                  TextField(
                    controller: birthDateController,
                    decoration: InputDecoration(
                      labelText: languageProvider.getTranslatedText({
                        'en': 'Birth Date',
                        'id': 'Tanggal Lahir',
                      }),
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: selectedGender,
                    decoration: InputDecoration(
                      labelText: languageProvider.getTranslatedText({
                        'en': 'Gender',
                        'id': 'Jenis Kelamin',
                      }),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'L',
                        child: Text(
                          languageProvider.getTranslatedText({
                            'en': 'Male',
                            'id': 'Laki-laki',
                          }),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'P',
                        child: Text(
                          languageProvider.getTranslatedText({
                            'en': 'Female',
                            'id': 'Perempuan',
                          }),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      selectedGender = value;
                    },
                  ),
                  TextField(
                    controller: parentNameController,
                    decoration: InputDecoration(
                      labelText: languageProvider.getTranslatedText({
                        'en': 'Parent Name',
                        'id': 'Nama Wali Murid',
                      }),
                    ),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: languageProvider.getTranslatedText({
                        'en': 'Phone Number',
                        'id': 'No. Telepon',
                      }),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.cancel.tr),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final nis = nisController.text.trim();
                  final address = addressController.text.trim();
                  final birthDate = birthDateController.text.trim();
                  final parentName = parentNameController.text.trim();
                  final phone = phoneController.text.trim();

                  if (name.isEmpty || nis.isEmpty || selectedClassId == null || 
                      address.isEmpty || birthDate.isEmpty || selectedGender == null || 
                      parentName.isEmpty || phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          languageProvider.getTranslatedText({
                            'en': 'All fields must be filled',
                            'id': 'Semua field harus diisi',
                          }),
                        ),
                      ),
                    );
                    return;
                  }

                  try {
                    final data = {
                      'name': name,
                      'nis': nis,
                      'class_id': selectedClassId,
                      'address': address,
                      'birth_date': birthDate,
                      'gender': selectedGender,
                      'parent_name': parentName,
                      'phone': phone,
                    };

                    if (isEdit) {
                      await ApiStudentService.updateStudent(student['id'], data);
                      await _loadData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              languageProvider.getTranslatedText({
                                'en': 'Student successfully updated',
                                'id': 'Siswa berhasil diperbarui',
                              }),
                            ),
                          ),
                        );
                      }
                    } else {
                      await ApiStudentService.addStudent(data);
                      await _loadData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              languageProvider.getTranslatedText({
                                'en': 'Student successfully added',
                                'id': 'Siswa berhasil ditambahkan',
                              }),
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            languageProvider.getTranslatedText({
                              'en': 'Failed to save student: $e',
                              'id': 'Gagal menyimpan siswa: $e',
                            }),
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  isEdit 
                    ? languageProvider.getTranslatedText({
                        'en': 'Update',
                        'id': 'Perbarui',
                      })
                    : AppLocalizations.save.tr,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteStudent(Map<String, dynamic> student) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return ConfirmationDialog(
            title: languageProvider.getTranslatedText({
              'en': 'Delete Student',
              'id': 'Hapus Siswa',
            }),
            content: languageProvider.getTranslatedText({
              'en': 'Are you sure you want to delete this student?',
              'id': 'Yakin ingin menghapus siswa ini?',
            }),
          );
        },
      ),
    );

    if (confirmed == true) {
      try {
        await ApiStudentService.deleteStudent(student['id']);
        setState(() {
          _students.removeWhere((s) => s['id'] == student['id']);
          final classIndex = _classList.indexWhere((c) => c['id'] == student['class_id']);
          if (classIndex != -1 && (_classList[classIndex]['student_count'] ?? 0) > 0) {
            _classList[classIndex]['student_count'] -= 1;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Student successfully deleted',
                  'id': 'Siswa berhasil dihapus',
                }),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Failed to delete student: $e',
                  'id': 'Gagal menghapus siswa: $e',
                }),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        if (_isLoading) {
          return LoadingScreen(
            message: languageProvider.getTranslatedText({
              'en': 'Loading student data...',
              'id': 'Memuat data siswa...',
            }),
          );
        }

        if (_errorMessage != null) {
          return ErrorScreen(
            errorMessage: _errorMessage!,
            onRetry: _loadData,
          );
        }

        final filteredStudents = _students.where((student) {
          final searchTerm = _searchController.text.toLowerCase();
          return searchTerm.isEmpty ||
              student['name'].toLowerCase().contains(searchTerm) ||
              (student['nis']?.toLowerCase().contains(searchTerm) ?? false);
        }).toList();

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              AppLocalizations.manageStudents.tr,
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            backgroundColor: ColorUtils.primaryColor,
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadData,
                tooltip: AppLocalizations.refresh.tr,
              ),
            ],
          ),
          body: Column(
            children: [
              CustomSearchBar(
                controller: _searchController,
                hintText: languageProvider.getTranslatedText({
                  'en': 'Search students...',
                  'id': 'Cari siswa...',
                }),
                onChanged: (value) => setState(() {}),
              ),
              Expanded(
                child: filteredStudents.isEmpty
                    ? EmptyState(
                        title: languageProvider.getTranslatedText({
                          'en': 'No students',
                          'id': 'Tidak ada siswa',
                        }),
                        subtitle: _searchController.text.isEmpty
                            ? languageProvider.getTranslatedText({
                                'en': 'Tap + to add a student',
                                'id': 'Tap + untuk menambah siswa',
                              })
                            : languageProvider.getTranslatedText({
                                'en': 'No search results found',
                                'id': 'Tidak ditemukan hasil pencarian',
                              }),
                        icon: Icons.people_outline,
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          
                          return StudentListItem(
                            student: student,
                            index: index,
                            onEdit: () => _showStudentDialog(student: student),
                            onDelete: () => _deleteStudent(student),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showStudentDialog(),
            backgroundColor: ColorUtils.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}
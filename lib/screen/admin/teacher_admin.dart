import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'package:manajemensekolah/utils/language_utils.dart';

class TeacherAdminScreen extends StatefulWidget {
  const TeacherAdminScreen({super.key});

  @override
  TeacherAdminScreenState createState() => TeacherAdminScreenState();
}

class TeacherAdminScreenState extends State<TeacherAdminScreen> {
  final ApiTeacherService _teacherService = ApiTeacherService();
  final ApiClassService _classService = ApiClassService();
  final ApiSubjectService _subjectService = ApiSubjectService();
  List<dynamic> _teachers = [];
  List<dynamic> _subjects = [];
  List<dynamic> _classes = [];
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

      final teacherData = await _teacherService.getTeacher();
      final subjectData = await _subjectService.getSubject();
      final classData = await _classService.getClass();

      setState(() {
        _teachers = teacherData;
        _subjects = subjectData;
        _classes = classData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().getTranslatedText({
              'en': 'Failed to load data: $e',
              'id': 'Gagal memuat data: $e',
            }),
          ),
        ),
      );
    }
  }

  Future<void> _manageTeacherSubject(String teacherId, List<String> selectedSubjectIds) async {
    try {
      final currentSubjects = await _teacherService.getSubjectByTeacher(teacherId);
      final currentIds = currentSubjects.map((subject) => subject['id'] as String).toList();

      for (final subjectId in selectedSubjectIds) {
        if (!currentIds.contains(subjectId)) {
          await _teacherService.addSubjectToTeacher(teacherId, subjectId);
        }
      }

      for (final currentId in currentIds) {
        if (!selectedSubjectIds.contains(currentId)) {
          await _teacherService.removeSubjectFromTeacher(teacherId, currentId);
        }
      }
    } catch (error) {
      debugPrint('Error handling teacher subjects: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().getTranslatedText({
              'en': 'Failed to update teacher subjects: $error',
              'id': 'Gagal mengupdate mata pelajaran guru: $error',
            }),
          ),
        ),
      );
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? teacher}) {
    final nameController = TextEditingController(text: teacher?['name']);
    final emailController = TextEditingController(text: teacher?['email']);
    final nipController = TextEditingController(text: teacher?['nip'] ?? '');

    String? selectedClassId = teacher?['class_id'];
    bool isHomeroomTeacher = teacher?['is_homeroom_teacher'] == 1 || teacher?['is_homeroom_teacher'] == true;

    List<String> selectedSubjectIds = [];

    Future<void> showDialogWithSubjects(List<String> subjectIds) async {
      selectedSubjectIds = subjectIds;
      selectedSubjectIds = selectedSubjectIds.toSet().toList();
      await showDialog(
        context: context,
        builder: (context) => Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text(
                    teacher == null
                        ? languageProvider.getTranslatedText({
                            'en': 'Add Teacher',
                            'id': 'Tambah Guru',
                          })
                        : languageProvider.getTranslatedText({
                            'en': 'Edit Teacher',
                            'id': 'Edit Guru',
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
                              'en': 'Teacher Name',
                              'id': 'Nama Guru',
                            }),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: languageProvider.getTranslatedText({
                              'en': 'Email',
                              'id': 'Email',
                            }),
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
                          initialValue: selectedClassId,
                          decoration: InputDecoration(
                            labelText: languageProvider.getTranslatedText({
                              'en': 'Class (Optional)',
                              'id': 'Kelas (Opsional)',
                            }),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null, 
                              child: Text(
                                languageProvider.getTranslatedText({
                                  'en': 'None',
                                  'id': 'Tidak ada',
                                }),
                              ),
                            ),
                            ..._classes.map(
                              (classItem) => DropdownMenuItem(
                                value: classItem['id'],
                                child: Text(classItem['name']),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => selectedClassId = value);
                          },
                        ),
                        SizedBox(height: 16),
                        Text(
                          languageProvider.getTranslatedText({
                            'en': 'Subjects:',
                            'id': 'Mata Pelajaran:',
                          }),
                        ),
                        ..._subjects.map(
                          (subject) => CheckboxListTile(
                            title: Text(subject['name']),
                            value: selectedSubjectIds.contains(subject['id']),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedSubjectIds.add(subject['id']);
                                } else {
                                  selectedSubjectIds.remove(subject['id']);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                        SizedBox(height: 16),
                        CheckboxListTile(
                          title: Text(
                            languageProvider.getTranslatedText({
                              'en': 'Homeroom Teacher',
                              'id': 'Wali Kelas',
                            }),
                          ),
                          value: isHomeroomTeacher,
                          onChanged: (value) {
                            setState(() => isHomeroomTeacher = value ?? false);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
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
                        if (nameController.text.isEmpty ||
                            emailController.text.isEmpty ||
                            nipController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                languageProvider.getTranslatedText({
                                  'en': 'Name, email, and NIP must be filled',
                                  'id': 'Nama, email, dan NIP harus diisi',
                                }),
                              ),
                            ),
                          );
                          return;
                        }

                        try {
                          final data = {
                            'name': nameController.text,
                            'email': emailController.text,
                            'class_id': selectedClassId,
                            'nip': nipController.text,
                            'is_homeroom_teacher': isHomeroomTeacher,
                          };

                          String teacherId;
                          if (teacher == null) {
                            final result = await _teacherService.addTeacher(data);
                            teacherId = result['id'];
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    languageProvider.getTranslatedText({
                                      'en': 'Teacher added successfully. Default password: password123',
                                      'id': 'Guru berhasil ditambahkan. Password default: password123',
                                    }),
                                  ),
                                  duration: Duration(seconds: 5),
                                ),
                              );
                            }
                          } else {
                            teacherId = teacher['id'];
                            await _teacherService.updateTeacher(teacherId, data);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    languageProvider.getTranslatedText({
                                      'en': 'Teacher updated successfully',
                                      'id': 'Guru berhasil diupdate',
                                    }),
                                  ),
                                ),
                              );
                            }
                          }

                          await _manageTeacherSubject(
                            teacherId,
                            selectedSubjectIds,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          _loadData();
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  languageProvider.getTranslatedText({
                                    'en': 'Failed to save data: $error',
                                    'id': 'Gagal menyimpan data: $error',
                                  }),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(AppLocalizations.save.tr),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );
    }

    if (teacher == null) {
      showDialogWithSubjects([]);
    } else {
      _teacherService.getSubjectByTeacher(teacher['id']).then((list) {
        final ids = list.map((subject) => subject['id'].toString()).toList();
        showDialogWithSubjects(ids);
      });
    }
  }

  Future<void> _deleteTeacher(Map<String, dynamic> teacher) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return ConfirmationDialog(
            title: languageProvider.getTranslatedText({
              'en': 'Delete Teacher',
              'id': 'Hapus Guru',
            }),
            content: languageProvider.getTranslatedText({
              'en': 'Are you sure you want to delete this teacher?',
              'id': 'Apakah Anda yakin ingin menghapus guru ini?',
            }),
          );
        },
      ),
    );

    if (confirmed == true) {
      try {
        await _teacherService.deleteTeacher(teacher['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Teacher successfully deleted',
                  'id': 'Guru berhasil dihapus',
                }),
              ),
            ),
          );
        }
        _loadData();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Failed to delete teacher: $error',
                  'id': 'Gagal menghapus guru: $error',
                }),
              ),
            ),
          );
        }
      }
    }
  }

  void _navigateToDetail(Map<String, dynamic> teacher) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TeacherDetailScreen(guru: teacher)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        if (_isLoading) {
          return LoadingScreen(
            message: languageProvider.getTranslatedText({
              'en': 'Loading teacher data...',
              'id': 'Memuat data guru...',
            }),
          );
        }

        if (_errorMessage != null) {
          return ErrorScreen(
            errorMessage: _errorMessage!,
            onRetry: _loadData,
          );
        }

        final filteredTeachers = _teachers.where((teacher) {
          final searchTerm = _searchController.text.toLowerCase();
          return searchTerm.isEmpty ||
              teacher['name'].toLowerCase().contains(searchTerm) ||
              (teacher['nip']?.toLowerCase().contains(searchTerm) ?? false);
        }).toList();

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              AppLocalizations.manageTeachers.tr,
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
                  'en': 'Search teachers...',
                  'id': 'Cari guru...',
                }),
                onChanged: (value) => setState(() {}),
              ),
              Expanded(
                child: filteredTeachers.isEmpty
                    ? EmptyState(
                        title: languageProvider.getTranslatedText({
                          'en': 'No teachers',
                          'id': 'Tidak ada guru',
                        }),
                        subtitle: _searchController.text.isEmpty
                            ? languageProvider.getTranslatedText({
                                'en': 'Tap + to add a teacher',
                                'id': 'Tap + untuk menambah guru',
                              })
                            : languageProvider.getTranslatedText({
                                'en': 'No search results found',
                                'id': 'Tidak ditemukan hasil pencarian',
                              }),
                        icon: Icons.person_outline,
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: filteredTeachers.length,
                        itemBuilder: (context, index) {
                          final teacher = filteredTeachers[index];
                          
                          return TeacherListItem(
                            guru: teacher,
                            index: index,
                            onTap: () => _navigateToDetail(teacher),
                            onEdit: () => _showAddEditDialog(teacher: teacher),
                            onDelete: () => _deleteTeacher(teacher),
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
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'package:manajemensekolah/utils/language_utils.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  ClassManagementScreenState createState() => ClassManagementScreenState();
}

class ClassManagementScreenState extends State<ClassManagementScreen> {
  final _nameController = TextEditingController();
  String? _selectedTeacherId;
  bool _isEditMode = false;
  String? _editingClassId;
  List<dynamic> _classList = [];
  List<dynamic> _teacherList = [];
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
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final classData = await apiServiceClass.getClass();
      final teacherData = await apiTeacherService.getTeacher();

      setState(() {
        _classList = classData;
        _teacherList = teacherData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  void _addClass() {
    setState(() {
      _isEditMode = false;
      _nameController.clear();
      _selectedTeacherId = null;
    });
    _showClassDialog();
  }

  void _editClass(dynamic classData) {
    setState(() {
      _isEditMode = true;
      _editingClassId = classData['id'];
      _nameController.text = classData['name'];
      _selectedTeacherId = classData['homeroom_teacher_id'];
    });
    _showClassDialog();
  }

  Future<void> _deleteClass(String id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.delete.tr),
        content: Text(
          context.read<LanguageProvider>().getTranslatedText({
            'en': 'Are you sure you want to delete this class?',
            'id': 'Apakah Anda yakin ingin menghapus kelas ini?',
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.cancel.tr),
          ),
          TextButton(
            onPressed: () async {
              try {
                final apiServiceClass = ApiClassService();
                await apiServiceClass.deleteClass(id);

                setState(() {
                  _classList.removeWhere((classItem) => classItem['id'] == id);
                });
                if (context.mounted) {
                  Navigator.pop(context);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.read<LanguageProvider>().getTranslatedText({
                          'en': 'Class successfully deleted',
                          'id': 'Kelas berhasil dihapus',
                        }),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.read<LanguageProvider>().getTranslatedText({
                          'en': 'Failed to delete class: $e',
                          'id': 'Gagal menghapus kelas: $e',
                        }),
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(
              AppLocalizations.delete.tr,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveClass(String name, String? homeroomTeacherId) async {
    try {
      if (_isEditMode) {
        await apiServiceClass.updateClass(_editingClassId!, {
          'name': name,
          'homeroom_teacher_id': homeroomTeacherId,
        });

        setState(() {
          final index = _classList.indexWhere(
            (k) => k['id'] == _editingClassId,
          );
          _classList[index] = {
            ..._classList[index],
            'name': name,
            'homeroom_teacher_id': homeroomTeacherId,
            'homeroom_teacher_name': _teacherList.firstWhere(
              (g) => g['id'] == homeroomTeacherId,
            )['name'],
          };
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Class successfully updated',
                  'id': 'Kelas berhasil diperbarui',
                }),
              ),
            ),
          );
        }
      } else {
        await apiServiceClass.addClass({
          'name': name,
          'homeroom_teacher_id': homeroomTeacherId,
        });

        final newClass = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': name,
          'homeroom_teacher_id': homeroomTeacherId,
          'homeroom_teacher_name': _teacherList.firstWhere(
            (g) => g['id'] == homeroomTeacherId,
          )['name'],
          'student_count': 0,
        };

        setState(() {
          _classList.add(newClass);
        });
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Class successfully added',
                  'id': 'Kelas berhasil ditambahkan',
                }),
              ),
            ),
          );
        }
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<LanguageProvider>().getTranslatedText({
                'en': 'Failed to save class: $e',
                'id': 'Gagal menyimpan kelas: $e',
              }),
            ),
          ),
        );
      }
    }
  }

  void _showClassDialog() {
    showDialog(
      context: context,
      builder: (context) => ClassFormDialog(
        isEditMode: _isEditMode,
        initialName: _nameController.text,
        initialTeacherId: _selectedTeacherId,
        teachers: _teacherList,
        onSave: _saveClass,
      ),
    );
  }

  void _viewClassDetail(dynamic classData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.read<LanguageProvider>().getTranslatedText({
            'en': 'Class Details ${classData['name']}',
            'id': 'Detail Kelas ${classData['name']}',
          }),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Class Name',
                  'id': 'Nama Kelas',
                }),
                classData['name'],
              ),
              _buildDetailItem(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Homeroom Teacher',
                  'id': 'Wali Kelas',
                }),
                classData['homeroom_teacher_name'] ?? 
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Not assigned',
                  'id': 'Tidak ada',
                }),
              ),
              _buildDetailItem(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Number of Students',
                  'id': 'Jumlah Siswa',
                }),
                (classData['student_count'] ?? 0).toString(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.read<LanguageProvider>().getTranslatedText({
                'en': 'Close',
                'id': 'Tutup',
              }),
            ),
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

  List<dynamic> _getFilteredClasses(String searchTerm) {
    return _classList.where((classItem) {
      return searchTerm.isEmpty ||
          classItem['name'].toLowerCase().contains(searchTerm.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        if (_isLoading) {
          return LoadingScreen(
            message: languageProvider.getTranslatedText({
              'en': 'Loading class data...',
              'id': 'Memuat data kelas...',
            }),
          );
        }

        if (_errorMessage != null) {
          return ErrorScreen(
            errorMessage: _errorMessage!,
            onRetry: _loadData,
          );
        }

        final TextEditingController searchController = TextEditingController();
        final filteredClasses = _getFilteredClasses(searchController.text);

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              AppLocalizations.manageClasses.tr,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.black),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.black),
                onPressed: _loadData,
                tooltip: AppLocalizations.refresh.tr,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Container(
                height: 1,
                color: Colors.grey.shade300,
              ),
            ),
          ),
          body: Column(
            children: [
              CustomSearchBar(
                controller: searchController,
                hintText: languageProvider.getTranslatedText({
                  'en': 'Search classes...',
                  'id': 'Cari kelas...',
                }),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              Expanded(
                child: filteredClasses.isEmpty
                    ? EmptyState(
                        title: languageProvider.getTranslatedText({
                          'en': 'No classes',
                          'id': 'Tidak ada kelas',
                        }),
                        subtitle: searchController.text.isEmpty
                            ? languageProvider.getTranslatedText({
                                'en': 'Tap + to add a class',
                                'id': 'Tap + untuk menambah kelas',
                              })
                            : languageProvider.getTranslatedText({
                                'en': 'No search results found',
                                'id': 'Tidak ditemukan hasil pencarian',
                              }),
                        icon: Icons.class_,
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: filteredClasses.length,
                        itemBuilder: (context, index) {
                          final classData = filteredClasses[index];
                          
                          return ClassListItem(
                            classData: classData,
                            index: index,
                            onTap: () => _viewClassDetail(classData),
                            onMenuSelected: (value) {
                              if (value == 'detail') {
                                _viewClassDetail(classData);
                              } else if (value == 'edit') {
                                _editClass(classData);
                              } else if (value == 'delete') {
                                _deleteClass(classData['id']);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addClass,
            backgroundColor: ColorUtils.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}
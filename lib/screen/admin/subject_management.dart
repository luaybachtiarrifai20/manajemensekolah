import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:manajemensekolah/components/confirmation_dialog.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/error_screen.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/components/search_bar.dart';
import 'package:manajemensekolah/components/subject_list_item.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/utils/color_utils.dart';
import 'package:manajemensekolah/utils/language_utils.dart';

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  SubjectManagementScreenState createState() => SubjectManagementScreenState();
}

class SubjectManagementScreenState extends State<SubjectManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _subjectList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await _apiService.get('/subjects');
      setState(() {
        _subjectList = response;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load subject data';
      });
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? subject}) {
    final codeController = TextEditingController(text: subject?['code']);
    final nameController = TextEditingController(text: subject?['name']);
    final descriptionController = TextEditingController(text: subject?['description']);

    showDialog(
      context: context,
      builder: (context) => Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subject == null 
                      ? languageProvider.getTranslatedText({
                          'en': 'Add Subject',
                          'id': 'Tambah Mata Pelajaran',
                        })
                      : languageProvider.getTranslatedText({
                          'en': 'Edit Subject',
                          'id': 'Edit Mata Pelajaran',
                        }),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ColorUtils.primaryColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    languageProvider.getTranslatedText({
                      'en': 'Code',
                      'id': 'Kode',
                    }),
                    codeController,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    languageProvider.getTranslatedText({
                      'en': 'Subject Name',
                      'id': 'Nama Mata Pelajaran',
                    }),
                    nameController,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    languageProvider.getTranslatedText({
                      'en': 'Description',
                      'id': 'Deskripsi',
                    }),
                    descriptionController, 
                    maxLines: 3
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(AppLocalizations.cancel.tr),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (codeController.text.isEmpty || nameController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    languageProvider.getTranslatedText({
                                      'en': 'Code and name must be filled',
                                      'id': 'Kode dan nama harus diisi',
                                    }),
                                  ),
                                  backgroundColor: Colors.red.shade400,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            try {
                              final data = {
                                'code': codeController.text,
                                'name': nameController.text,
                                'description': descriptionController.text,
                              };

                              if (subject == null) {
                                await _apiService.post('/subjects', data);
                              } else {
                                await _apiService.put('/subjects/${subject['id']}', data);
                              }
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                              _loadSubjects();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      languageProvider.getTranslatedText({
                                        'en': 'Data saved successfully',
                                        'id': 'Data berhasil disimpan',
                                      }),
                                    ),
                                    backgroundColor: Colors.green.shade400,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      languageProvider.getTranslatedText({
                                        'en': 'Failed to save data',
                                        'id': 'Gagal menyimpan data',
                                      }),
                                    ),
                                    backgroundColor: Colors.red.shade400,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorUtils.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(AppLocalizations.save.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteSubject(Map<String, dynamic> subject) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return ConfirmationDialog(
            title: languageProvider.getTranslatedText({
              'en': 'Delete Subject',
              'id': 'Hapus Mata Pelajaran',
            }),
            content: languageProvider.getTranslatedText({
              'en': 'Are you sure you want to delete subject "${subject['name']}"?',
              'id': 'Yakin ingin menghapus mata pelajaran "${subject['name']}"?',
            }),
          );
        },
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/subjects/${subject['id']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Subject successfully deleted',
                  'id': 'Mata pelajaran berhasil dihapus',
                }),
              ),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _loadSubjects();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Failed to delete subject',
                  'id': 'Gagal menghapus mata pelajaran',
                }),
              ),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
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
              'en': 'Loading subject data...',
              'id': 'Memuat data mata pelajaran...',
            }),
          );
        }

        if (_errorMessage.isNotEmpty) {
          return ErrorScreen(
            errorMessage: _errorMessage,
            onRetry: _loadSubjects,
          );
        }

        final filteredSubjects = _subjectList.where((subject) {
          final searchTerm = _searchController.text.toLowerCase();
          return searchTerm.isEmpty ||
              subject['name'].toLowerCase().contains(searchTerm) ||
              subject['code'].toLowerCase().contains(searchTerm);
        }).toList();

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              AppLocalizations.manageSubjects.tr,
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            backgroundColor: ColorUtils.primaryColor,
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadSubjects,
                tooltip: AppLocalizations.refresh.tr,
              ),
            ],
          ),
          body: Column(
            children: [
              CustomSearchBar(
                controller: _searchController,
                hintText: languageProvider.getTranslatedText({
                  'en': 'Search subjects...',
                  'id': 'Cari mata pelajaran...',
                }),
                onChanged: (value) => setState(() {}),
              ),
              Expanded(
                child: filteredSubjects.isEmpty
                    ? EmptyState(
                        title: languageProvider.getTranslatedText({
                          'en': 'No subjects',
                          'id': 'Tidak ada mata pelajaran',
                        }),
                        subtitle: _searchController.text.isEmpty
                            ? languageProvider.getTranslatedText({
                                'en': 'Tap + to add a subject',
                                'id': 'Tap + untuk menambah mata pelajaran',
                              })
                            : languageProvider.getTranslatedText({
                                'en': 'No search results found',
                                'id': 'Tidak ditemukan hasil pencarian',
                              }),
                        icon: Icons.school_outlined,
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: filteredSubjects.length,
                        itemBuilder: (context, index) {
                          final subject = filteredSubjects[index];
                          
                          return SubjectListItem(
                            subject: subject,
                            index: index,
                            onEdit: () => _showAddEditDialog(subject: subject),
                            onDelete: () => _deleteSubject(subject),
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
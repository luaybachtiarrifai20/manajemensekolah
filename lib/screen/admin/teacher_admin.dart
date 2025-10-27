import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/excel_teacher_service.dart';
import 'package:provider/provider.dart';
import 'package:manajemensekolah/components/confirmation_dialog.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/error_screen.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
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

class TeacherAdminScreenState extends State<TeacherAdminScreen>
    with SingleTickerProviderStateMixin {
  final ApiTeacherService _teacherService = ApiTeacherService();
  final ApiClassService _classService = ApiClassService();
  final ApiSubjectService _subjectService = ApiSubjectService();
  List<dynamic> _teachers = [];
  List<dynamic> _subjects = [];
  List<dynamic> _classes = [];
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();

  // Filter States
  String? _selectedHomeroomFilter; // 'wali_kelas', 'guru_biasa', atau null untuk semua
  List<String> _selectedSubjectIds = [];
  String? _selectedGenderFilter; // 'L', 'P', atau null untuk semua
  bool _hasActiveFilter = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _checkActiveFilter() {
    setState(() {
      _hasActiveFilter = _selectedHomeroomFilter != null || 
                         _selectedSubjectIds.isNotEmpty || 
                         _selectedGenderFilter != null;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedHomeroomFilter = null;
      _selectedSubjectIds.clear();
      _selectedGenderFilter = null;
      _hasActiveFilter = false;
    });
  }

  String _buildFilterSummary(LanguageProvider languageProvider) {
    List<String> filters = [];
    
    if (_selectedHomeroomFilter != null) {
      final statusText = _selectedHomeroomFilter == 'wali_kelas'
          ? languageProvider.getTranslatedText({'en': 'Homeroom Teacher', 'id': 'Wali Kelas'})
          : languageProvider.getTranslatedText({'en': 'Regular Teacher', 'id': 'Guru Biasa'});
      filters.add('${languageProvider.getTranslatedText({'en': 'Status', 'id': 'Status'})}: $statusText');
    }
    
    if (_selectedSubjectIds.isNotEmpty) {
      final subjectNames = _subjects
          .where((subject) => _selectedSubjectIds.contains(subject['id'].toString()))
          .map((subject) => subject['nama'])
          .join(', ');
      filters.add('${languageProvider.getTranslatedText({'en': 'Subject', 'id': 'Mata Pelajaran'})}: $subjectNames');
    }
    
    if (_selectedGenderFilter != null) {
      final genderText = _selectedGenderFilter == 'L' 
          ? languageProvider.getTranslatedText({'en': 'Male', 'id': 'Laki-laki'})
          : languageProvider.getTranslatedText({'en': 'Female', 'id': 'Perempuan'});
      filters.add('${languageProvider.getTranslatedText({'en': 'Gender', 'id': 'Jenis Kelamin'})}: $genderText');
    }
    
    return filters.join(' • ');
  }

  void _showFilterSheet() {
    final languageProvider = context.read<LanguageProvider>();
    
    // Temporary state for bottom sheet
    String? tempSelectedHomeroom = _selectedHomeroomFilter;
    List<String> tempSelectedSubjects = List.from(_selectedSubjectIds);
    String? tempSelectedGender = _selectedGenderFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        languageProvider.getTranslatedText({
                          'en': 'Filter',
                          'id': 'Filter',
                        }),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempSelectedHomeroom = null;
                            tempSelectedSubjects.clear();
                            tempSelectedGender = null;
                          });
                        },
                        child: Text(
                          languageProvider.getTranslatedText({
                            'en': 'Reset',
                            'id': 'Reset',
                          }),
                          style: TextStyle(color: _getPrimaryColor()),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Wali Kelas Filter
                        Text(
                          languageProvider.getTranslatedText({
                            'en': 'Status',
                            'id': 'Status',
                          }),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildStatusChip(
                              label: languageProvider.getTranslatedText({
                                'en': 'All',
                                'id': 'Semua',
                              }),
                              value: null,
                              selectedValue: tempSelectedHomeroom,
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedHomeroom = null;
                                });
                              },
                            ),
                            _buildStatusChip(
                              label: languageProvider.getTranslatedText({
                                'en': 'Homeroom Teacher',
                                'id': 'Wali Kelas',
                              }),
                              value: 'wali_kelas',
                              selectedValue: tempSelectedHomeroom,
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedHomeroom = 'wali_kelas';
                                });
                              },
                            ),
                            _buildStatusChip(
                              label: languageProvider.getTranslatedText({
                                'en': 'Regular Teacher',
                                'id': 'Guru Biasa',
                              }),
                              value: 'guru_biasa',
                              selectedValue: tempSelectedHomeroom,
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedHomeroom = 'guru_biasa';
                                });
                              },
                            ),
                          ],
                        ),

                        SizedBox(height: 24),

                        // Mata Pelajaran Filter
                        Text(
                          languageProvider.getTranslatedText({
                            'en': 'Subject',
                            'id': 'Mata Pelajaran',
                          }),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _subjects.map((subject) {
                            final subjectId = subject['id'].toString();
                            final isSelected = tempSelectedSubjects.contains(subjectId);
                            
                            return FilterChip(
                              label: Text(subject['nama'] ?? 'Unknown'),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    tempSelectedSubjects.add(subjectId);
                                  } else {
                                    tempSelectedSubjects.remove(subjectId);
                                  }
                                });
                              },
                              selectedColor: _getPrimaryColor().withOpacity(0.2),
                              checkmarkColor: _getPrimaryColor(),
                              labelStyle: TextStyle(
                                color: isSelected ? _getPrimaryColor() : Colors.grey.shade700,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: isSelected ? _getPrimaryColor() : Colors.grey.shade300,
                              ),
                            );
                          }).toList(),
                        ),

                        SizedBox(height: 24),

                        // Jenis Kelamin Filter
                        Text(
                          languageProvider.getTranslatedText({
                            'en': 'Gender',
                            'id': 'Jenis Kelamin',
                          }),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildGenderChip(
                              label: languageProvider.getTranslatedText({
                                'en': 'All',
                                'id': 'Semua',
                              }),
                              value: null,
                              selectedValue: tempSelectedGender,
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedGender = null;
                                });
                              },
                            ),
                            _buildGenderChip(
                              label: languageProvider.getTranslatedText({
                                'en': 'Male',
                                'id': 'Laki-laki',
                              }),
                              value: 'L',
                              selectedValue: tempSelectedGender,
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedGender = 'L';
                                });
                              },
                            ),
                            _buildGenderChip(
                              label: languageProvider.getTranslatedText({
                                'en': 'Female',
                                'id': 'Perempuan',
                              }),
                              value: 'P',
                              selectedValue: tempSelectedGender,
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedGender = 'P';
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Buttons
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        offset: Offset(0, -2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: _getPrimaryColor()),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            languageProvider.getTranslatedText({
                              'en': 'Cancel',
                              'id': 'Batal',
                            }),
                            style: TextStyle(color: _getPrimaryColor()),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedHomeroomFilter = tempSelectedHomeroom;
                              _selectedSubjectIds = tempSelectedSubjects;
                              _selectedGenderFilter = tempSelectedGender;
                            });
                            _checkActiveFilter();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getPrimaryColor(),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            languageProvider.getTranslatedText({
                              'en': 'Apply Filter',
                              'id': 'Terapkan Filter',
                            }),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required String? value,
    required String? selectedValue,
    required VoidCallback onSelected,
  }) {
    final isSelected = selectedValue == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: _getPrimaryColor().withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? _getPrimaryColor() : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? _getPrimaryColor() : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildGenderChip({
    required String label,
    required String? value,
    required String? selectedValue,
    required VoidCallback onSelected,
  }) {
    final isSelected = selectedValue == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: _getPrimaryColor().withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? _getPrimaryColor() : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? _getPrimaryColor() : Colors.grey.shade300,
      ),
    );
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

      _animationController.forward();
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
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Export teachers to Excel
  Future<void> _exportToExcel() async {
    await ExcelTeacherService.exportTeachersToExcel(
      teachers: _teachers,
      context: context,
    );
  }

  // Import teachers from Excel
  Future<void> _importFromExcel() async {
    final languageProvider = context.read<LanguageProvider>();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        await ApiTeacherService.importTeachersFromExcel(
          File(result.files.single.path!)
        );

        // Refresh data setelah import
        await _loadData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.getTranslatedText({
              'en': 'Failed to import file: $e',
              'id': 'Gagal mengimpor file: $e',
            }),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Download template
  Future<void> _downloadTemplate() async {
    await ExcelTeacherService.downloadTemplate(context);
  }

  // Import teacher from Excel (API call)
  Future<Map<String, dynamic>> importTeachersFromExcelAPI(
    String base64File,
  ) async {
    try {
      final response = await ApiService().post('/guru/import', {
        'file_data': base64File,
      });
      return response;
    } catch (e) {
      debugPrint('Error importing teachers from Excel: $e');
      rethrow;
    }
  }

  // Download teacher template (API call)
  Future<String> downloadTeacherTemplateAPI() async {
    try {
      final response = await ApiService().get('/guru/template');
      return response['file_data'];
    } catch (e) {
      debugPrint('Error downloading teacher template: $e');
      rethrow;
    }
  }

  // Import teacher from Excel
  Future<Map<String, dynamic>> importTeachersFromExcel(
    String base64File,
  ) async {
    try {
      final response = await ApiService().post('/guru/import', {
        'file_data': base64File,
      });
      return response;
    } catch (e) {
      debugPrint('Error importing teachers from Excel: $e');
      rethrow;
    }
  }

  // Download teacher template
  Future<String> downloadTeacherTemplate() async {
    try {
      final response = await ApiService().get('/guru/template');
      return response['file_data'];
    } catch (e) {
      debugPrint('Error downloading teacher template: $e');
      rethrow;
    }
  }

  Future<void> _manageTeacherSubject(
    String teacherId,
    List<String> selectedSubjectIds,
  ) async {
    try {
      final currentSubjects = await _teacherService.getSubjectByTeacher(
        teacherId,
      );
      final currentIds = currentSubjects
          .map((subject) => subject['id'] as String)
          .toList();

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
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? teacher}) {
    final nameController = TextEditingController(
      text: teacher?['nama']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: teacher?['email']?.toString() ?? '',
    );
    final nipController = TextEditingController(
      text: teacher?['nip']?.toString() ?? '',
    );

    String? selectedClassId = teacher?['class_id']?.toString();
    bool isHomeroomTeacher =
        teacher?['is_wali_kelas'] == 1 || teacher?['is_wali_kelas'] == true;

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
                return Dialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header dengan gradient
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: _getCardGradient(),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  teacher == null
                                      ? Icons.person_add
                                      : Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  teacher == null
                                      ? languageProvider.getTranslatedText({
                                          'en': 'Add Teacher',
                                          'id': 'Tambah Guru',
                                        })
                                      : languageProvider.getTranslatedText({
                                          'en': 'Edit Teacher',
                                          'id': 'Edit Guru',
                                        }),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDialogTextField(
                                controller: nameController,
                                label: languageProvider.getTranslatedText({
                                  'en': 'Teacher Name',
                                  'id': 'Nama Guru',
                                }),
                                icon: Icons.person,
                              ),
                              SizedBox(height: 12),
                              _buildDialogTextField(
                                controller: emailController,
                                label: languageProvider.getTranslatedText({
                                  'en': 'Email',
                                  'id': 'Email',
                                }),
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              SizedBox(height: 12),
                              _buildDialogTextField(
                                controller: nipController,
                                label: 'NIP',
                                icon: Icons.badge,
                              ),
                              SizedBox(height: 12),
                              _buildDialogDropdown(
                                value: selectedClassId,
                                label: languageProvider.getTranslatedText({
                                  'en': 'Class (Optional)',
                                  'id': 'Kelas (Opsional)',
                                }),
                                icon: Icons.school,
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
                                  ..._classes
                                      .where(
                                        (classItem) =>
                                            classItem['id'] != null &&
                                            classItem['name'] != null,
                                      )
                                      .map(
                                        (classItem) => DropdownMenuItem<String>(
                                          value: classItem['id'].toString(),
                                          child: Text(
                                            classItem['name']?.toString() ??
                                                'Unknown Class',
                                          ),
                                        ),
                                      ),
                                ],
                                onChanged: (value) {
                                  setState(() => selectedClassId = value);
                                },
                              ),
                              SizedBox(height: 16),

                              // Subjects Section
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      languageProvider.getTranslatedText({
                                        'en': 'Subjects:',
                                        'id': 'Mata Pelajaran:',
                                      }),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ..._subjects
                                        .where(
                                          (subject) =>
                                              subject['id'] != null &&
                                              subject['nama'] != null,
                                        )
                                        .map(
                                          (subject) => CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(
                                              subject['nama']?.toString() ??
                                                  'Unknown Subject',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            value: selectedSubjectIds.contains(
                                              subject['id']?.toString(),
                                            ),
                                            onChanged: (value) {
                                              final subjectId = subject['id']
                                                  ?.toString();
                                              if (subjectId == null) return;

                                              setState(() {
                                                if (value == true) {
                                                  selectedSubjectIds.add(
                                                    subjectId,
                                                  );
                                                } else {
                                                  selectedSubjectIds.remove(
                                                    subjectId,
                                                  );
                                                }
                                              });
                                            },
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12),

                              // Homeroom Teacher Checkbox
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    languageProvider.getTranslatedText({
                                      'en': 'Homeroom Teacher',
                                      'id': 'Wali Kelas',
                                    }),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  value: isHomeroomTeacher,
                                  onChanged: (value) {
                                    setState(
                                      () => isHomeroomTeacher = value ?? false,
                                    );
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Actions
                        Container(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    AppLocalizations.cancel.tr,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final name = nameController.text.trim();
                                    final email = emailController.text.trim();
                                    final nip = nipController.text.trim();

                                    if (name.isEmpty ||
                                        email.isEmpty ||
                                        nip.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            languageProvider.getTranslatedText({
                                              'en':
                                                  'Name, email, and NIP must be filled',
                                              'id':
                                                  'Nama, email, dan NIP harus diisi',
                                            }),
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    try {
                                      final data = {
                                        'name': name,
                                        'email': email,
                                        'class_id': selectedClassId,
                                        'nip': nip,
                                        'is_homeroom_teacher':
                                            isHomeroomTeacher,
                                      };

                                      String teacherId;
                                      if (teacher == null) {
                                        final result = await _teacherService
                                            .addTeacher(data);
                                        teacherId =
                                            result['id']?.toString() ?? '';
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                languageProvider.getTranslatedText({
                                                  'en':
                                                      'Teacher added successfully. Default password: password123',
                                                  'id':
                                                      'Guru berhasil ditambahkan. Password default: password123',
                                                }),
                                              ),
                                              backgroundColor: Colors.green,
                                              duration: Duration(seconds: 5),
                                            ),
                                          );
                                        }
                                      } else {
                                        teacherId =
                                            teacher['id']?.toString() ?? '';
                                        await _teacherService.updateTeacher(
                                          teacherId,
                                          data,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                languageProvider.getTranslatedText({
                                                  'en':
                                                      'Teacher updated successfully',
                                                  'id':
                                                      'Guru berhasil diupdate',
                                                }),
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      }

                                      if (teacherId.isNotEmpty) {
                                        await _manageTeacherSubject(
                                          teacherId,
                                          selectedSubjectIds,
                                        );
                                      }

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                      _loadData();
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              languageProvider.getTranslatedText({
                                                'en':
                                                    'Failed to save data: $error',
                                                'id':
                                                    'Gagal menyimpan data: $error',
                                              }),
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _getPrimaryColor(),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    AppLocalizations.save.tr,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
      _teacherService
          .getSubjectByTeacher(teacher['id']?.toString() ?? '')
          .then((list) {
            final ids = list
                .where((subject) => subject['id'] != null)
                .map((subject) => subject['id'].toString())
                .toList();
            showDialogWithSubjects(ids);
          })
          .catchError((error) {
            showDialogWithSubjects([]);
          });
    }
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _getPrimaryColor(), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildDialogDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _getPrimaryColor(), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        items: items,
        onChanged: onChanged,
        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
      ),
    );
  }

  Future<void> _deleteTeacher(Map<String, dynamic> teacher) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: context.read<LanguageProvider>().getTranslatedText({
          'en': 'Delete Teacher',
          'id': 'Hapus Guru',
        }),
        content: context.read<LanguageProvider>().getTranslatedText({
          'en': 'Are you sure you want to delete this teacher?',
          'id': 'Apakah Anda yakin ingin menghapus guru ini?',
        }),
        confirmText: context.read<LanguageProvider>().getTranslatedText({
          'en': 'Delete',
          'id': 'Hapus',
        }),
        confirmColor: Colors.red,
      ),
    );

    if (confirmed == true) {
      try {
        final teacherId = teacher['id']?.toString();
        if (teacherId != null && teacherId.isNotEmpty) {
          await _teacherService.deleteTeacher(teacherId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.read<LanguageProvider>().getTranslatedText({
                    'en': 'Teacher successfully deleted',
                    'id': 'Guru berhasil dihapus',
                  }),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
          _loadData();
        }
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
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToDetail(Map<String, dynamic> teacher) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherDetailScreen(guru: teacher),
      ),
    );
  }

  Color _getPrimaryColor() {
    return Color(0xFF4361EE); // Blue untuk admin
  }

  LinearGradient _getCardGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_getPrimaryColor(), _getPrimaryColor().withOpacity(0.7)],
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
          return ErrorScreen(errorMessage: _errorMessage!, onRetry: _loadData);
        }

        final filteredTeachers = _teachers.where((teacher) {
          final searchTerm = _searchController.text.toLowerCase();
          final name = teacher['nama']?.toString().toLowerCase() ?? '';
          final nip = teacher['nip']?.toString().toLowerCase() ?? '';

          final matchesSearch =
              searchTerm.isEmpty ||
              name.contains(searchTerm) ||
              nip.contains(searchTerm);

          // Homeroom filter
          final isHomeroom = teacher['is_wali_kelas'] == 1 || teacher['is_wali_kelas'] == true;
          final matchesHomeroomFilter =
              _selectedHomeroomFilter == null ||
              (_selectedHomeroomFilter == 'wali_kelas' && isHomeroom) ||
              (_selectedHomeroomFilter == 'guru_biasa' && !isHomeroom);

          // Subject filter
          final teacherSubjectId = teacher['mata_pelajaran_id']?.toString();
          final matchesSubjectFilter =
              _selectedSubjectIds.isEmpty ||
              (teacherSubjectId != null && _selectedSubjectIds.contains(teacherSubjectId));

          // Gender filter
          final matchesGenderFilter =
              _selectedGenderFilter == null ||
              teacher['jenis_kelamin'] == _selectedGenderFilter;

          return matchesSearch && matchesHomeroomFilter && matchesSubjectFilter && matchesGenderFilter;
        }).toList();

        return Scaffold(
          backgroundColor: Color(0xFFF8F9FA),
          appBar: AppBar(
            title: Text(
              AppLocalizations.manageTeachers.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: _getPrimaryColor(),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'export':
                      _exportToExcel();
                      break;
                    case 'import':
                      _importFromExcel();
                      break;
                    case 'template':
                      _downloadTemplate();
                      break;
                    case 'refresh':
                      _loadData();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.file_download, color: _getPrimaryColor()),
                        SizedBox(width: 8),
                        Text(
                          languageProvider.getTranslatedText({
                            'en': 'Export to Excel',
                            'id': 'Export ke Excel',
                          }),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'import',
                    child: Row(
                      children: [
                        Icon(Icons.file_upload, color: _getPrimaryColor()),
                        SizedBox(width: 8),
                        Text(
                          languageProvider.getTranslatedText({
                            'en': 'Import from Excel',
                            'id': 'Import dari Excel',
                          }),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'template',
                    child: Row(
                      children: [
                        Icon(Icons.download, color: _getPrimaryColor()),
                        SizedBox(width: 8),
                        Text(
                          languageProvider.getTranslatedText({
                            'en': 'Download Template',
                            'id': 'Unduh Template',
                          }),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: _getPrimaryColor()),
                        SizedBox(width: 8),
                        Text(
                          languageProvider.getTranslatedText({
                            'en': 'Refresh',
                            'id': 'Refresh',
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Bar with Filter Button
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: languageProvider.getTranslatedText({
                            'en': 'Search teachers...',
                            'id': 'Cari guru...',
                          }),
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Filter Button
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _hasActiveFilter
                                ? _getPrimaryColor()
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: _showFilterSheet,
                            icon: Icon(
                              Icons.tune,
                              color: _hasActiveFilter
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                            tooltip: languageProvider.getTranslatedText({
                              'en': 'Filter',
                              'id': 'Filter',
                            }),
                          ),
                        ),
                        if (_hasActiveFilter)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Show active filters indicator
              if (_hasActiveFilter)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getPrimaryColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getPrimaryColor().withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_alt,
                        size: 16,
                        color: _getPrimaryColor(),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _buildFilterSummary(languageProvider),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getPrimaryColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      InkWell(
                        onTap: _clearAllFilters,
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              if (filteredTeachers.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${filteredTeachers.length} ${languageProvider.getTranslatedText({'en': 'teachers found', 'id': 'guru ditemukan'})}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 4),
              Expanded(
                child: filteredTeachers.isEmpty
                    ? EmptyState(
                        title: languageProvider.getTranslatedText({
                          'en': 'No teachers',
                          'id': 'Tidak ada guru',
                        }),
                        subtitle:
                            _searchController.text.isEmpty &&
                                !_hasActiveFilter
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
                          return AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              final delay = index * 0.1;
                              final animation = CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  delay,
                                  1.0,
                                  curve: Curves.easeOut,
                                ),
                              );

                              return FadeTransition(
                                opacity: animation,
                                child: Transform.translate(
                                  offset: Offset(0, 50 * (1 - animation.value)),
                                  child: child,
                                ),
                              );
                            },
                            child: TeacherListItem(
                              guru: teacher,
                              index: index,
                              onTap: () => _navigateToDetail(teacher),
                              onEdit: () =>
                                  _showAddEditDialog(teacher: teacher),
                              onDelete: () => _deleteTeacher(teacher),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddEditDialog(),
            backgroundColor: _getPrimaryColor(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.add, color: Colors.white, size: 20),
          ),
        );
      },
    );
  }
}

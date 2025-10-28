import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/excel_student_service.dart';
import 'package:provider/provider.dart';
import 'package:manajemensekolah/components/confirmation_dialog.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/error_screen.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/services/api_class_services.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/api_student_services.dart';
import 'package:manajemensekolah/utils/language_utils.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  StudentManagementScreenState createState() => StudentManagementScreenState();
}

class StudentManagementScreenState extends State<StudentManagementScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _students = [];
  List<dynamic> _classList = [];
  bool _isLoading = true;
  String? _errorMessage;
  final apiService = ApiService();
  final apiServiceClass = ApiClassService();
  final ApiStudentService apiStudentService = ApiStudentService();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Filter States
  String? _selectedStatusFilter; // 'active', 'inactive', atau null untuk semua
  List<String> _selectedKelasIds = [];
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
    super.dispose();
  }

  Future<void> _exportToExcel() async {
    await ExcelService.exportStudentsToExcel(
      students: _students,
      context: context,
    );
  }

  Future<void> _importFromExcel() async {
    final languageProvider = context.read<LanguageProvider>();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        await ApiStudentService.importStudentsFromExcel(
          File(result.files.single.path!),
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

  Future<void> _downloadTemplate() async {
    await ExcelService.downloadTemplate(context);
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

      _animationController.forward();
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
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _checkActiveFilter() {
    setState(() {
      _hasActiveFilter = _selectedStatusFilter != null || 
                         _selectedKelasIds.isNotEmpty || 
                         _selectedGenderFilter != null;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStatusFilter = null;
      _selectedKelasIds.clear();
      _selectedGenderFilter = null;
      _hasActiveFilter = false;
    });
  }

  List<Map<String, dynamic>> _buildFilterChips(LanguageProvider languageProvider) {
    List<Map<String, dynamic>> filterChips = [];
    
    if (_selectedStatusFilter != null) {
      final statusText = _selectedStatusFilter == 'active'
          ? languageProvider.getTranslatedText({'en': 'Active', 'id': 'Aktif'})
          : languageProvider.getTranslatedText({'en': 'Inactive', 'id': 'Tidak Aktif'});
      filterChips.add({
        'label': '${languageProvider.getTranslatedText({'en': 'Status', 'id': 'Status'})}: $statusText',
        'onRemove': () {
          setState(() {
            _selectedStatusFilter = null;
            _checkActiveFilter();
          });
        },
      });
    }
    
    if (_selectedKelasIds.isNotEmpty) {
      for (var kelasId in _selectedKelasIds) {
        final kelas = _classList.firstWhere(
          (k) => k['id'].toString() == kelasId,
          orElse: () => {'nama': kelasId},
        );
        filterChips.add({
          'label': '${languageProvider.getTranslatedText({'en': 'Class', 'id': 'Kelas'})}: ${kelas['nama']}',
          'onRemove': () {
            setState(() {
              _selectedKelasIds.remove(kelasId);
              _checkActiveFilter();
            });
          },
        });
      }
    }
    
    if (_selectedGenderFilter != null) {
      final genderText = _selectedGenderFilter == 'L' 
          ? languageProvider.getTranslatedText({'en': 'Male', 'id': 'Laki-laki'})
          : languageProvider.getTranslatedText({'en': 'Female', 'id': 'Perempuan'});
      filterChips.add({
        'label': '${languageProvider.getTranslatedText({'en': 'Gender', 'id': 'Jenis Kelamin'})}: $genderText',
        'onRemove': () {
          setState(() {
            _selectedGenderFilter = null;
            _checkActiveFilter();
          });
        },
      });
    }
    
    return filterChips;
  }

  void _showFilterSheet() {
    final languageProvider = context.read<LanguageProvider>();
    
    // Temporary state for bottom sheet
    String? tempSelectedStatus = _selectedStatusFilter;
    List<String> tempSelectedKelas = List.from(_selectedKelasIds);
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
                            tempSelectedStatus = null;
                            tempSelectedKelas.clear();
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
                        // Status Filter
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
                              selectedValue: tempSelectedStatus,
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedStatus = null;
                                });
                              },
                            ),
                            _buildStatusChip(
                              label: languageProvider.getTranslatedText({
                                'en': 'Active',
                                'id': 'Aktif',
                              }),
                              value: 'active',
                              selectedValue: tempSelectedStatus,
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedStatus = 'active';
                                });
                              },
                            ),
                            _buildStatusChip(
                              label: languageProvider.getTranslatedText({
                                'en': 'Inactive',
                                'id': 'Tidak Aktif',
                              }),
                              value: 'inactive',
                              selectedValue: tempSelectedStatus,
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedStatus = 'inactive';
                                });
                              },
                            ),
                          ],
                        ),

                        SizedBox(height: 24),

                        // Kelas Filter
                        Text(
                          languageProvider.getTranslatedText({
                            'en': 'Class',
                            'id': 'Kelas',
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
                          children: _classList.map((kelas) {
                            final kelasId = kelas['id'].toString();
                            final isSelected = tempSelectedKelas.contains(kelasId);
                            
                            return FilterChip(
                              label: Text(kelas['nama'] ?? 'Unknown'),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    tempSelectedKelas.add(kelasId);
                                  } else {
                                    tempSelectedKelas.remove(kelasId);
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
                              _selectedStatusFilter = tempSelectedStatus;
                              _selectedKelasIds = tempSelectedKelas;
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

  void _showStudentDialog({Map<String, dynamic>? student}) {
    final nameController = TextEditingController(text: student?['nama'] ?? '');
    final nisController = TextEditingController(text: student?['nis'] ?? '');
    final addressController = TextEditingController(
      text: student?['alamat'] ?? '',
    );
    final birthDateController = TextEditingController(
      text: student != null && student['tanggal_lahir'] != null
          ? student['tanggal_lahir'].toString().substring(0, 10)
          : '',
    );
    final parentNameController = TextEditingController(
      text: student?['nama_wali'] ?? '',
    );
    final phoneController = TextEditingController(
      text: student?['no_telepon'] ?? '',
    );

    final emailWaliController = TextEditingController(
      text: student?['email_wali'] ?? '',
    );

    String? selectedClassId = student?['kelas_id'];
    String? selectedGender = student?['jenis_kelamin'];

    final isEdit = student != null;

    showDialog(
      context: context,
      builder: (context) => Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
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
                            isEdit ? Icons.edit : Icons.person_add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEdit
                                ? languageProvider.getTranslatedText({
                                    'en': 'Edit Student',
                                    'id': 'Edit Siswa',
                                  })
                                : languageProvider.getTranslatedText({
                                    'en': 'Add Student',
                                    'id': 'Tambah Siswa',
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
                            'en': 'Name',
                            'id': 'Nama',
                          }),
                          icon: Icons.person,
                        ),
                        SizedBox(height: 12),
                        _buildDialogTextField(
                          controller: nisController,
                          label: 'NIS',
                          icon: Icons.badge,
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 12),
                        _buildDialogDropdown(
                          value: selectedClassId,
                          label: languageProvider.getTranslatedText({
                            'en': 'Class',
                            'id': 'Kelas',
                          }),
                          icon: Icons.school,
                          items: _classList
                              .where((classItem) => classItem['id'] != null)
                              .map((classItem) {
                                return DropdownMenuItem<String>(
                                  value: classItem['id'].toString(),
                                  child: Text(
                                    classItem['nama'] ?? 'Unknown Class',
                                  ),
                                );
                              })
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedClassId = value;
                            });
                          },
                        ),
                        SizedBox(height: 12),
                        _buildDialogTextField(
                          controller: addressController,
                          label: languageProvider.getTranslatedText({
                            'en': 'Address',
                            'id': 'Alamat',
                          }),
                          icon: Icons.location_on,
                          maxLines: 2,
                        ),
                        SizedBox(height: 12),
                        _buildDialogTextField(
                          controller: birthDateController,
                          label: languageProvider.getTranslatedText({
                            'en': 'Birth Date',
                            'id': 'Tanggal Lahir',
                          }),
                          icon: Icons.cake,
                          hintText: 'YYYY-MM-DD',
                        ),
                        SizedBox(height: 12),
                        _buildDialogDropdown(
                          value: selectedGender,
                          label: languageProvider.getTranslatedText({
                            'en': 'Gender',
                            'id': 'Jenis Kelamin',
                          }),
                          icon: Icons.transgender,
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
                            setState(() {
                              selectedGender = value;
                            });
                          },
                        ),
                        SizedBox(height: 12),
                        _buildDialogTextField(
                          controller: parentNameController,
                          label: languageProvider.getTranslatedText({
                            'en': 'Parent Name',
                            'id': 'Nama Wali Murid',
                          }),
                          icon: Icons.family_restroom,
                        ),
                        SizedBox(height: 12),
                        _buildDialogTextField(
                          controller: emailWaliController,
                          label: languageProvider.getTranslatedText({
                            'en': 'Parent Email',
                            'id': 'Email Wali Murid',
                          }),
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          hintText: 'wali@example.com',
                        ),
                        SizedBox(height: 12),
                        _buildDialogTextField(
                          controller: phoneController,
                          label: languageProvider.getTranslatedText({
                            'en': 'Phone Number',
                            'id': 'No. Telepon',
                          }),
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
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
                              side: BorderSide(color: Colors.blue.shade600),
                            ),
                            child: Text(
                              AppLocalizations.cancel.tr,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final nama = nameController.text.trim();
                              final nis = nisController.text.trim();
                              final alamat = addressController.text.trim();
                              final tanggalLahir = birthDateController.text
                                  .trim();
                              final namaWali = parentNameController.text.trim();
                              final noTelepon = phoneController.text.trim();
                              final emailWali = emailWaliController.text.trim();

                              if (nama.isEmpty ||
                                  nis.isEmpty ||
                                  selectedClassId == null ||
                                  alamat.isEmpty ||
                                  tanggalLahir.isEmpty ||
                                  selectedGender == null ||
                                  namaWali.isEmpty ||
                                  noTelepon.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      languageProvider.getTranslatedText({
                                        'en': 'All fields must be filled',
                                        'id': 'Semua field harus diisi',
                                      }),
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              if (emailWali.isNotEmpty &&
                                  !RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(emailWali)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      languageProvider.getTranslatedText({
                                        'en': 'Invalid email format',
                                        'id': 'Format email tidak valid',
                                      }),
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              try {
                                final data = {
                                  'nama': nama,
                                  'nis': nis,
                                  'kelas_id': selectedClassId,
                                  'alamat': alamat,
                                  'tanggal_lahir': tanggalLahir,
                                  'jenis_kelamin': selectedGender,
                                  'nama_wali': namaWali,
                                  'no_telepon': noTelepon,
                                  'email_wali': emailWali,
                                };

                                if (isEdit) {
                                  await ApiStudentService.updateStudent(
                                    student!['id'],
                                    data,
                                  );
                                  await _loadData();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          languageProvider.getTranslatedText({
                                                'en':
                                                    'Student successfully updated',
                                                'id':
                                                    'Siswa berhasil diperbarui',
                                              }) +
                                              (emailWali.isNotEmpty
                                                  ? languageProvider.getTranslatedText({
                                                      'en':
                                                          '\nParent account created/updated with password: password123',
                                                      'id':
                                                          '\nAkun wali dibuat/diperbarui dengan password: password123',
                                                    })
                                                  : ''),
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                } else {
                                  await ApiStudentService.addStudent(data);
                                  await _loadData();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          languageProvider.getTranslatedText({
                                                'en':
                                                    'Student successfully added',
                                                'id':
                                                    'Siswa berhasil ditambahkan',
                                              }) +
                                              (emailWali.isNotEmpty
                                                  ? languageProvider.getTranslatedText({
                                                      'en':
                                                          '\nParent account created with password: password123',
                                                      'id':
                                                          '\nAkun wali dibuat dengan password: password123',
                                                    })
                                                  : ''),
                                        ),
                                        backgroundColor: Colors.green,
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
                              isEdit
                                  ? languageProvider.getTranslatedText({
                                      'en': 'Update',
                                      'id': 'Perbarui',
                                    })
                                  : AppLocalizations.save.tr,
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
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
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
          hintText: hintText,
          prefixIcon: Icon(icon, color: _getPrimaryColor(), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
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

  Future<void> _deleteStudent(Map<String, dynamic> student) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: context.read<LanguageProvider>().getTranslatedText({
          'en': 'Delete Student',
          'id': 'Hapus Siswa',
        }),
        content: context.read<LanguageProvider>().getTranslatedText({
          'en': 'Are you sure you want to delete this student?',
          'id': 'Yakin ingin menghapus siswa ini?',
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
        await ApiStudentService.deleteStudent(student['id']);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Student successfully deleted',
                  'id': 'Siswa berhasil dihapus',
                }),
              ),
              backgroundColor: Colors.green,
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
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showStudentDetail(Map<String, dynamic> student) {
    final languageProvider = context.read<LanguageProvider>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: _getPrimaryColor(),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      student['nama'] ?? 'No Name',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'NIS: ${student['nis'] ?? 'No NIS'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      icon: Icons.school,
                      label: languageProvider.getTranslatedText({
                        'en': 'Class',
                        'id': 'Kelas',
                      }),
                      value: student['kelas_nama'] ?? 'No Class',
                    ),
                    _buildDetailItem(
                      icon: Icons.transgender,
                      label: languageProvider.getTranslatedText({
                        'en': 'Gender',
                        'id': 'Jenis Kelamin',
                      }),
                      value: _getGenderText(
                        student['jenis_kelamin'],
                        languageProvider,
                      ),
                    ),
                    _buildDetailItem(
                      icon: Icons.cake,
                      label: languageProvider.getTranslatedText({
                        'en': 'Birth Date',
                        'id': 'Tanggal Lahir',
                      }),
                      value: _formatDate(student['tanggal_lahir']),
                    ),
                    _buildDetailItem(
                      icon: Icons.location_on,
                      label: languageProvider.getTranslatedText({
                        'en': 'Address',
                        'id': 'Alamat',
                      }),
                      value: student['alamat'] ?? 'No Address',
                      isMultiline: true,
                    ),

                    SizedBox(height: 16),
                    Text(
                      languageProvider.getTranslatedText({
                        'en': 'Parent Information',
                        'id': 'Informasi Wali',
                      }),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 12),

                    _buildDetailItem(
                      icon: Icons.person,
                      label: languageProvider.getTranslatedText({
                        'en': 'Parent Name',
                        'id': 'Nama Wali',
                      }),
                      value: student['nama_wali'] ?? 'No Parent Name',
                    ),
                    _buildDetailItem(
                      icon: Icons.phone,
                      label: languageProvider.getTranslatedText({
                        'en': 'Phone Number',
                        'id': 'No. Telepon',
                      }),
                      value: student['no_telepon'] ?? 'No Phone',
                    ),
                    _buildDetailItem(
                      icon: Icons.email,
                      label: languageProvider.getTranslatedText({
                        'en': 'Parent Email',
                        'id': 'Email Wali',
                      }),
                      value:
                          student['parent_email'] ??
                          student['email_wali'] ??
                          'No Email',
                    ),

                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              languageProvider.getTranslatedText({
                                'en': 'Close',
                                'id': 'Tutup',
                              }),
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showStudentDialog(student: student);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getPrimaryColor(),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              languageProvider.getTranslatedText({
                                'en': 'Edit',
                                'id': 'Edit',
                              }),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getPrimaryColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: _getPrimaryColor()),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: isMultiline ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGenderText(String? gender, LanguageProvider languageProvider) {
    switch (gender) {
      case 'L':
        return languageProvider.getTranslatedText({
          'en': 'Male',
          'id': 'Laki-laki',
        });
      case 'P':
        return languageProvider.getTranslatedText({
          'en': 'Female',
          'id': 'Perempuan',
        });
      default:
        return languageProvider.getTranslatedText({
          'en': 'Unknown',
          'id': 'Tidak Diketahui',
        });
    }
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    } catch (e) {
      return date;
    }
  }

  Widget _buildStudentCard(Map<String, dynamic> student, int index) {
    final languageProvider = context.read<LanguageProvider>();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = index * 0.1;
        final animation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, 1.0, curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _showStudentDetail(student),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showStudentDetail(student),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Strip biru di pinggir kiri
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 6,
                        decoration: BoxDecoration(
                          color: _getPrimaryColor(),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    // Background pattern effect
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header dengan nama dan NIS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student['nama'] ?? 'No Name',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'NIS: ${student['nis'] ?? 'No NIS'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPrimaryColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getPrimaryColor().withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'Active',
                                  style: TextStyle(
                                    color: _getPrimaryColor(),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Informasi kelas
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _getPrimaryColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.school,
                                  color: _getPrimaryColor(),
                                  size: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      languageProvider.getTranslatedText({
                                        'en': 'Class',
                                        'id': 'Kelas',
                                      }),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 1),
                                    Text(
                                      student['kelas_nama'] ??
                                          languageProvider.getTranslatedText({
                                            'en': 'No Class',
                                            'id': 'Tidak Ada Kelas',
                                          }),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Informasi gender
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _getPrimaryColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.transgender,
                                  color: _getPrimaryColor(),
                                  size: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      languageProvider.getTranslatedText({
                                        'en': 'Gender',
                                        'id': 'Jenis Kelamin',
                                      }),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 1),
                                    Text(
                                      _getGenderText(
                                        student['jenis_kelamin'],
                                        languageProvider,
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildActionButton(
                                icon: Icons.edit,
                                label: languageProvider.getTranslatedText({
                                  'en': 'Edit',
                                  'id': 'Edit',
                                }),
                                color: _getPrimaryColor(),
                                backgroundColor: Colors.white,
                                borderColor: _getPrimaryColor(),
                                onPressed: () =>
                                    _showStudentDialog(student: student),
                              ),
                              SizedBox(width: 8),
                              _buildActionButton(
                                icon: Icons.delete,
                                label: languageProvider.getTranslatedText({
                                  'en': 'Delete',
                                  'id': 'Hapus',
                                }),
                                color: Colors.red,
                                backgroundColor: Colors.white,
                                borderColor: Colors.red,
                                onPressed: () => _deleteStudent(student),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? backgroundColor,
    Color? borderColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor ?? Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPrimaryColor() {
    return Color(0xFF2563EB); // Blue untuk admin
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
              'en': 'Loading student data...',
              'id': 'Memuat data siswa...',
            }),
          );
        }

        if (_errorMessage != null) {
          return ErrorScreen(errorMessage: _errorMessage!, onRetry: _loadData);
        }

        final filteredStudents = _students.where((student) {
          final searchTerm = _searchController.text.toLowerCase();
          final matchesSearch =
              searchTerm.isEmpty ||
              (student['nama']?.toLowerCase().contains(searchTerm) ?? false) ||
              (student['nis']?.toLowerCase().contains(searchTerm) ?? false) ||
              (student['kelas_nama']?.toLowerCase().contains(searchTerm) ??
                  false);

          // Status filter
          final matchesStatusFilter =
              _selectedStatusFilter == null ||
              (student['status'] ?? 'active') == _selectedStatusFilter;

          // Kelas filter
          final matchesKelasFilter =
              _selectedKelasIds.isEmpty ||
              _selectedKelasIds.contains(student['kelas_id']?.toString());

          // Gender filter
          final matchesGenderFilter =
              _selectedGenderFilter == null ||
              student['jenis_kelamin'] == _selectedGenderFilter;

          return matchesSearch && matchesStatusFilter && matchesKelasFilter && matchesGenderFilter;
        }).toList();

        return Scaffold(
          backgroundColor: Color(0xFFF8F9FA),
          // Dalam build method, update AppBar actions:
          appBar: AppBar(
            title: Text(
              languageProvider.getTranslatedText({
                'en': 'Manage Students',
                'id': 'Kelola Siswa',
              }),
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
                            'en': 'Search students...',
                            'id': 'Cari siswa...',
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
              
              // Show active filters as chips
              if (_hasActiveFilter)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  height: 42,
                  child: Row(
                    children: [
                      // Filter icon
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getPrimaryColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.filter_alt,
                          size: 18,
                          color: _getPrimaryColor(),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Scrollable filter chips
                      Expanded(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._buildFilterChips(languageProvider).map((filter) {
                              return Container(
                                margin: EdgeInsets.only(right: 6),
                                child: Chip(
                                  label: Text(
                                    filter['label'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getPrimaryColor(),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  deleteIcon: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: _getPrimaryColor(),
                                  ),
                                  onDeleted: filter['onRemove'],
                                  backgroundColor: _getPrimaryColor().withOpacity(0.1),
                                  side: BorderSide(
                                    color: _getPrimaryColor().withOpacity(0.3),
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  labelPadding: EdgeInsets.only(left: 4),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      // Clear all button
                      InkWell(
                        onTap: _clearAllFilters,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.clear_all,
                            size: 18,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (filteredStudents.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${filteredStudents.length} ${languageProvider.getTranslatedText({'en': 'students found', 'id': 'siswa ditemukan'})}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 4),
              Expanded(
                child: filteredStudents.isEmpty
                    ? EmptyState(
                        title: languageProvider.getTranslatedText({
                          'en': 'No students',
                          'id': 'Tidak ada siswa',
                        }),
                        subtitle:
                            _searchController.text.isEmpty &&
                                !_hasActiveFilter
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
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return _buildStudentCard(student, index);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showStudentDialog(),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:manajemensekolah/components/confirmation_dialog.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/enhanced_search_bar.dart';
import 'package:manajemensekolah/components/error_screen.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
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

  // Filter options untuk EnhancedSearchBar
  final List<String> _filterOptions = ['All', 'Active', 'Inactive'];
  String _selectedFilter = 'All';

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

    // Ambil email wali dari data parent yang sudah ditambahkan
    final emailWaliController = TextEditingController(
      text:
          student?['parent_email'] ??
          '', // Gunakan parent_email bukan email_wali
    );

    String? selectedClassId = student?['kelas_id'];
    String? selectedGender = student?['jenis_kelamin'];

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
                    decoration: InputDecoration(labelText: 'NIS'),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedClassId,
                    decoration: InputDecoration(
                      labelText: languageProvider.getTranslatedText({
                        'en': 'Class',
                        'id': 'Kelas',
                      }),
                    ),
                    items: _classList
                        .where((classItem) => classItem['id'] != null)
                        .map((classItem) {
                          return DropdownMenuItem<String>(
                            value: classItem['id'].toString(),
                            child: Text(classItem['nama'] ?? 'Unknown Class'),
                          );
                        })
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClassId = value;
                      });
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
                    value: selectedGender,
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
                      setState(() {
                        selectedGender = value;
                      });
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
                  // Tambahkan field email wali
                  TextField(
                    controller: emailWaliController,
                    decoration: InputDecoration(
                      labelText: languageProvider.getTranslatedText({
                        'en': 'Parent Email',
                        'id': 'Email Wali Murid',
                      }),
                      hintText: 'wali@example.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
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
                  final nama = nameController.text.trim();
                  final nis = nisController.text.trim();
                  final alamat = addressController.text.trim();
                  final tanggalLahir = birthDateController.text.trim();
                  final namaWali = parentNameController.text.trim();
                  final noTelepon = phoneController.text.trim();
                  final emailWali = emailWaliController.text
                      .trim(); // Ambil email wali

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
                      ),
                    );
                    return;
                  }

                  // Validasi email jika diisi
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
                      'email_wali': emailWali, // Tambahkan email wali ke data
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
                                    'en': 'Student successfully updated',
                                    'id': 'Siswa berhasil diperbarui',
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
                                    'en': 'Student successfully added',
                                    'id': 'Siswa berhasil ditambahkan',
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

  // Method untuk menampilkan detail siswa
  void _showStudentDetail(Map<String, dynamic> student) {
    final languageProvider = context.read<LanguageProvider>();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan background color
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ColorUtils.primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
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
                        color: ColorUtils.primaryColor,
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
                      value: _getGenderText(student['jenis_kelamin'], languageProvider),
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
                      value: student['parent_email'] ?? student['email_wali'] ?? 'No Email',
                    ),
                    
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              languageProvider.getTranslatedText({
                                'en': 'Close',
                                'id': 'Tutup',
                              }),
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
                              backgroundColor: ColorUtils.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ColorUtils.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: ColorUtils.primaryColor,
            ),
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

    return GestureDetector(
      onTap: () => _showStudentDetail(student),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: EdgeInsets.all(12),
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
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'NIS: ${student['nis'] ?? 'No NIS'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // Informasi kelas
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.school, 
                        color: Colors.blue.shade600, 
                        size: 16
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Class',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            student['kelas_nama'] ?? 'No Class',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // Action buttons - lebih kompak
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: Icons.edit,
                      label: 'Edit',
                      color: Colors.blue,
                      onPressed: () => _showStudentDialog(student: student),
                    ),
                    SizedBox(width: 6),
                    _buildActionButton(
                      icon: Icons.delete,
                      label: 'Delete',
                      color: Colors.red,
                      onPressed: () => _deleteStudent(student),
                    ),
                  ],
                ),
              ],
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
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: color,
            ),
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

          final matchesFilter =
              _selectedFilter == 'All' ||
              (_selectedFilter == 'Active' &&
                  (student['status'] ?? 'active') == 'active') ||
              (_selectedFilter == 'Inactive' &&
                  (student['status'] ?? 'active') == 'inactive');

          return matchesSearch && matchesFilter;
        }).toList();

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              languageProvider.getTranslatedText({
                'en': 'Manage Students',
                'id': 'Kelola Siswa',
              }),
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
                tooltip: languageProvider.getTranslatedText({
                  'en': 'Refresh',
                  'id': 'Refresh',
                }),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Container(height: 1, color: Colors.grey.shade300),
            ),
          ),
          body: Column(
            children: [
              EnhancedSearchBar(
                controller: _searchController,
                hintText: languageProvider.getTranslatedText({
                  'en': 'Search students...',
                  'id': 'Cari siswa...',
                }),
                onChanged: (value) => setState(() {}),
                filterOptions: _filterOptions,
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                showFilter: true,
              ),
              if (filteredStudents.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${filteredStudents.length} students found',
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
                                _selectedFilter == 'All'
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
            backgroundColor: ColorUtils.primaryColor,
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
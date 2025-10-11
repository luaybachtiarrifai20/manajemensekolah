import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:manajemensekolah/components/confirmation_dialog.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/error_screen.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/components/enhanced_search_bar.dart';
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
  
  // Search dan filter
  final TextEditingController _searchController = TextEditingController();
  
  // Filter options untuk EnhancedSearchBar
  final List<String> _filterOptions = ['All', 'With Classes', 'Without Classes'];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await _apiService.getMataPelajaranWithKelas();
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
    final codeController = TextEditingController(text: subject?['kode']);
    final nameController = TextEditingController(text: subject?['nama']);
    final descriptionController = TextEditingController(
      text: subject?['deskripsi'],
    );

    showDialog(
      context: context,
      builder: (context) => Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
                    maxLines: 3,
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
                          ),
                          child: Text(AppLocalizations.cancel.tr),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (codeController.text.isEmpty ||
                                nameController.text.isEmpty) {
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
                                'kode': codeController.text,
                                'nama': nameController.text,
                                'deskripsi': descriptionController.text,
                              };

                              if (subject == null) {
                                await _apiService.post('/mata-pelajaran', data);
                              } else {
                                await _apiService.put(
                                  '/mata-pelajaran/${subject['id']}',
                                  data,
                                );
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
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
              'en':
                  'Are you sure you want to delete subject "${subject['nama']}"?',
              'id':
                  'Yakin ingin menghapus mata pelajaran "${subject['nama']}"?',
            }),
          );
        },
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/mata-pelajaran/${subject['id']}');
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

  // Navigasi ke halaman manajemen kelas untuk mata pelajaran
  void _navigateToClassManagement(Map<String, dynamic> subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectClassManagementPage(
          subject: subject,
        ),
      ),
    );
  }

  List<dynamic> _getFilteredSubjects() {
    return _subjectList.where((subject) {
      final searchTerm = _searchController.text.toLowerCase();
      final subjectName = subject['nama']?.toString().toLowerCase() ?? '';
      final subjectCode = subject['kode']?.toString().toLowerCase() ?? '';

      final matchesSearch =
          searchTerm.isEmpty ||
          subjectName.contains(searchTerm) ||
          subjectCode.contains(searchTerm);

      final hasClasses = (subject['jumlah_kelas'] ?? 0) > 0;
      
      final matchesFilter =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'With Classes' && hasClasses) ||
          (_selectedFilter == 'Without Classes' && !hasClasses);

      return matchesSearch && matchesFilter;
    }).toList();
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

        final filteredSubjects = _getFilteredSubjects();

        // Terjemahan filter options
        final translatedFilterOptions = [
          languageProvider.getTranslatedText({'en': 'All', 'id': 'Semua'}),
          languageProvider.getTranslatedText({
            'en': 'With Classes',
            'id': 'Dengan Kelas',
          }),
          languageProvider.getTranslatedText({
            'en': 'Without Classes',
            'id': 'Tanpa Kelas',
          }),
        ];

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              AppLocalizations.manageSubjects.tr,
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
                onPressed: _loadSubjects,
                tooltip: AppLocalizations.refresh.tr,
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
                  'en': 'Search subjects...',
                  'id': 'Cari mata pelajaran...',
                }),
                onChanged: (value) {
                  setState(() {});
                },
                filterOptions: translatedFilterOptions,
                selectedFilter: translatedFilterOptions[
                  _selectedFilter == 'All' 
                    ? 0 
                    : _selectedFilter == 'With Classes' 
                      ? 1 
                      : 2
                ],
                onFilterChanged: (filter) {
                  final index = translatedFilterOptions.indexOf(filter);
                  setState(() {
                    _selectedFilter = index == 0 
                      ? 'All' 
                      : index == 1 
                        ? 'With Classes' 
                        : 'Without Classes';
                  });
                },
                showFilter: true,
              ),
              if (filteredSubjects.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${filteredSubjects.length} ${languageProvider.getTranslatedText({
                          'en': 'subjects found',
                          'id': 'mata pelajaran ditemukan',
                        })}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 8),
              Expanded(
                child: filteredSubjects.isEmpty
                    ? EmptyState(
                        title: languageProvider.getTranslatedText({
                          'en': 'No subjects',
                          'id': 'Tidak ada mata pelajaran',
                        }),
                        subtitle: _searchController.text.isEmpty && _selectedFilter == 'All'
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
                          final kelasNames = subject['kelas_names']?.toString().split(',') ?? [];
                          final jumlahKelas = subject['jumlah_kelas'] ?? 0;

                          return SubjectListItem(
                            subject: subject,
                            index: index,
                            onEdit: () => _showAddEditDialog(subject: subject),
                            onDelete: () => _deleteSubject(subject),
                            onTap: () => _navigateToClassManagement(subject),
                            kelasCount: jumlahKelas,
                            kelasNames: kelasNames,
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddEditDialog(),
            backgroundColor: ColorUtils.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}

// Halaman Manajemen Kelas untuk Mata Pelajaran
class SubjectClassManagementPage extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectClassManagementPage({super.key, required this.subject});

  @override
  SubjectClassManagementPageState createState() => SubjectClassManagementPageState();
}

class SubjectClassManagementPageState extends State<SubjectClassManagementPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _availableClasses = [];
  List<dynamic> _assignedClasses = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Filter options untuk EnhancedSearchBar
  final List<String> _filterOptions = ['All', 'Assigned', 'Unassigned'];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load semua kelas yang tersedia
      final allClasses = await _apiService.get('/kelas');
      
      // Load kelas yang sudah ditetapkan untuk mata pelajaran ini
      final assignedClasses = await _apiService.getKelasByMataPelajaran(widget.subject['id']);

      setState(() {
        _availableClasses = List<dynamic>.from(allClasses);
        _assignedClasses = List<dynamic>.from(assignedClasses);
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  Future<void> _addClassToSubject(Map<String, dynamic> kelas) async {
    try {
      await _apiService.post('/mata-pelajaran-kelas', {
        'mata_pelajaran_id': widget.subject['id'],
        'kelas_id': kelas['id'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kelas ${kelas['nama']} berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadData();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeClassFromSubject(Map<String, dynamic> kelas) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Hapus Kelas',
        content: 'Yakin ingin menghapus kelas ${kelas['nama']} dari mata pelajaran ini?',
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/mata-pelajaran-kelas?mata_pelajaran_id=${widget.subject['id']}&kelas_id=${kelas['id']}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kelas ${kelas['nama']} berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }

        _loadData();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Method untuk menambah kelas secara cepat
  void _showQuickAddClassDialog() {
    final unassignedClasses = _availableClasses.where((kelas) {
      return !_isClassAssigned(kelas['id']);
    }).toList();

    if (unassignedClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Semua kelas sudah ditambahkan ke mata pelajaran ini'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_circle, color: Colors.blue, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Tambah Kelas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Pilih kelas yang ingin ditambahkan ke ${widget.subject['nama']}:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Search bar dalam dialog
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari kelas...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      ),
                      onChanged: (value) {
                        setDialogState(() {});
                      },
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  Container(
                    constraints: BoxConstraints(maxHeight: 300),
                    child: unassignedClasses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, size: 48, color: Colors.green),
                                SizedBox(height: 8),
                                Text(
                                  'Semua kelas sudah ditambahkan',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: unassignedClasses.length,
                            itemBuilder: (context, index) {
                              final kelas = unassignedClasses[index];
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                elevation: 1,
                                child: ListTile(
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(Icons.class_, color: Colors.blue, size: 18),
                                  ),
                                  title: Text(
                                    kelas['nama'] ?? 'Kelas',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (kelas['tingkat'] != null)
                                        Text(
                                          'Tingkat: ${kelas['tingkat']}',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      if (kelas['wali_kelas_nama'] != null)
                                        Text(
                                          'Wali: ${kelas['wali_kelas_nama']}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                    ],
                                  ),
                                  trailing: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: EdgeInsets.all(6),
                                    child: Icon(Icons.add, color: Colors.white, size: 16),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _addClassToSubject(kelas);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Batal'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Lihat Semua',
                            style: TextStyle(color: Colors.white),
                          ),
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

  bool _isClassAssigned(String kelasId) {
    return _assignedClasses.any((kelas) => kelas['id'] == kelasId);
  }

  List<dynamic> _getFilteredClasses() {
    final searchTerm = _searchController.text.toLowerCase();
    return _availableClasses.where((kelas) {
      final className = kelas['nama']?.toString().toLowerCase() ?? '';
      final classLevel = kelas['tingkat']?.toString().toLowerCase() ?? '';
      final homeroomTeacher = kelas['wali_kelas_nama']?.toString().toLowerCase() ?? '';

      final matchesSearch =
          searchTerm.isEmpty ||
          className.contains(searchTerm) ||
          classLevel.contains(searchTerm) ||
          homeroomTeacher.contains(searchTerm);

      final isAssigned = _isClassAssigned(kelas['id']);
      
      final matchesFilter =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'Assigned' && isAssigned) ||
          (_selectedFilter == 'Unassigned' && !isAssigned);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget _buildClassCard(Map<String, dynamic> kelas, bool isAssigned) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isAssigned ? Colors.green.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.class_,
            color: isAssigned ? Colors.green : Colors.blue,
            size: 20,
          ),
        ),
        title: Text(
          kelas['nama'] ?? 'Kelas',
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (kelas['tingkat'] != null)
              Text(
                'Tingkat: ${kelas['tingkat']}',
                style: TextStyle(fontSize: 12),
              ),
            if (kelas['wali_kelas_nama'] != null)
              Text(
                'Wali: ${kelas['wali_kelas_nama']}',
                style: TextStyle(fontSize: 12),
              ),
            if (kelas['jumlah_siswa'] != null)
              Text(
                'Siswa: ${kelas['jumlah_siswa']}',
                style: TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: isAssigned
            ? IconButton(
                icon: Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => _removeClassFromSubject(kelas),
                tooltip: 'Hapus dari mata pelajaran',
              )
            : IconButton(
                icon: Icon(Icons.add_circle, color: Colors.blue),
                onPressed: () => _addClassToSubject(kelas),
                tooltip: 'Tambahkan ke mata pelajaran',
              ),
      ),
    );
  }

  Widget _buildEmptyState(String message, {bool showAddButton = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.class_, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (showAddButton) ...[
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showQuickAddClassDialog,
              icon: Icon(Icons.add),
              label: Text('Tambah Kelas Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Cek apakah masih ada kelas yang bisa ditambahkan
  bool _getCanAddMoreClasses() {
    return _availableClasses.any((kelas) => !_isClassAssigned(kelas['id']));
  }

  @override
  Widget build(BuildContext context) {
    final canAddMoreClasses = _getCanAddMoreClasses();
    final filteredClasses = _getFilteredClasses();
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Kelola Kelas - ${widget.subject['nama']}',
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade300),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Enhanced Search Bar dengan filter
                EnhancedSearchBar(
                  controller: _searchController,
                  hintText: 'Cari kelas...',
                  onChanged: (value) {
                    setState(() {});
                  },
                  filterOptions: _filterOptions,
                  selectedFilter: _selectedFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  showFilter: true,
                ),

                if (filteredClasses.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          '${filteredClasses.length} kelas ditemukan',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 8),

                // Info Mata Pelajaran (Card yang lebih sederhana)
                Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blue.shade50,
                  elevation: 1,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.menu_book, color: Colors.blue, size: 20),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.subject['nama'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '${_assignedClasses.length} kelas terdaftar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (!canAddMoreClasses) ...[
                                SizedBox(height: 2),
                                Text(
                                  'Semua kelas sudah ditambahkan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Daftar Kelas
                Expanded(
                  child: filteredClasses.isEmpty
                      ? _buildEmptyState(
                          _searchController.text.isEmpty && _selectedFilter == 'All'
                              ? 'Belum ada kelas yang tersedia'
                              : 'Tidak ada kelas yang cocok dengan pencarian',
                          showAddButton: _searchController.text.isEmpty && _selectedFilter == 'All' && canAddMoreClasses,
                        )
                      : ListView.builder(
                          itemCount: filteredClasses.length,
                          itemBuilder: (context, index) {
                            final kelas = filteredClasses[index];
                            final isAssigned = _isClassAssigned(kelas['id']);
                            return _buildClassCard(kelas, isAssigned);
                          },
                        ),
                ),
              ],
            ),
      // Floating Action Button untuk menambah kelas - SELALU MUNCUL selama masih ada kelas yang bisa ditambahkan
      floatingActionButton: canAddMoreClasses
          ? FloatingActionButton(
              onPressed: _showQuickAddClassDialog,
              backgroundColor: ColorUtils.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
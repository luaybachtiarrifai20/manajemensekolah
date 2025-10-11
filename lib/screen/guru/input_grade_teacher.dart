import 'package:flutter/material.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/components/enhanced_search_bar.dart';
import 'package:manajemensekolah/models/siswa.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/api_student_services.dart';
import 'package:manajemensekolah/services/api_subject_services.dart';
import 'package:manajemensekolah/services/api_teacher_services.dart';
import 'package:manajemensekolah/utils/color_utils.dart';
import 'package:manajemensekolah/utils/language_utils.dart';
import 'package:provider/provider.dart';

class GradePage extends StatefulWidget {
  final Map<String, dynamic> guru;

  const GradePage({super.key, required this.guru});

  @override
  GradePageState createState() => GradePageState();
}

class GradePageState extends State<GradePage> {
  final ApiSubjectService apiSubjectService = ApiSubjectService();
  final ApiTeacherService apiTeacherService = ApiTeacherService();

  List<dynamic> _mataPelajaranList = [];
  List<dynamic> _filteredMataPelajaranList = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Filter options
  final List<String> _filterOptions = ['All', 'With Grades', 'Without Grades'];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterMataPelajaran);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMataPelajaran() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMataPelajaranList = List.from(_mataPelajaranList);
      } else {
        _filteredMataPelajaranList = _mataPelajaranList
            .where((mapel) =>
                mapel['nama'].toLowerCase().contains(query) ||
                (mapel['kode']?.toString().toLowerCase().contains(query) ?? false))
            .toList();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<dynamic> mataPelajaran;

      if (widget.guru['role'] == 'guru') {
        mataPelajaran = await apiTeacherService.getSubjectByTeacher(
          widget.guru['id'],
        );
      } else {
        mataPelajaran = await apiSubjectService.getSubject();
      }

      setState(() {
        _mataPelajaranList = mataPelajaran;
        _filteredMataPelajaranList = List.from(_mataPelajaranList);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load data: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().getTranslatedText({
              'en': message,
              'id': message.replaceAll('Failed to load data:', 'Gagal memuat data:'),
            }),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().getTranslatedText({
              'en': message,
              'id': message.replaceAll('successfully', 'berhasil'),
            }),
          ),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToClassSelection(Map<String, dynamic> mataPelajaran) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ClassSelectionPage(guru: widget.guru, mataPelajaran: mataPelajaran),
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
              'en': 'Loading subjects...',
              'id': 'Memuat mata pelajaran...',
            }),
          );
        }

        // Terjemahan filter options
        final translatedFilterOptions = [
          languageProvider.getTranslatedText({'en': 'All', 'id': 'Semua'}),
          languageProvider.getTranslatedText({
            'en': 'With Grades',
            'id': 'Dengan Nilai',
          }),
          languageProvider.getTranslatedText({
            'en': 'Without Grades',
            'id': 'Tanpa Nilai',
          }),
        ];

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              languageProvider.getTranslatedText({
                'en': 'Input Grades',
                'id': 'Input Nilai',
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
                  'id': 'Muat Ulang',
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
              // Header Info Guru
              _buildHeaderInfo(languageProvider),
              
              // Search Bar dengan Filter
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
                    : _selectedFilter == 'With Grades' 
                      ? 1 
                      : 2
                ],
                onFilterChanged: (filter) {
                  final index = translatedFilterOptions.indexOf(filter);
                  setState(() {
                    _selectedFilter = index == 0 
                      ? 'All' 
                      : index == 1 
                        ? 'With Grades' 
                        : 'Without Grades';
                  });
                },
                showFilter: true,
              ),

              if (_filteredMataPelajaranList.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${_filteredMataPelajaranList.length} ${languageProvider.getTranslatedText({
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
                child: _filteredMataPelajaranList.isEmpty
                    ? EmptyState(
                        title: languageProvider.getTranslatedText({
                          'en': 'No subjects available',
                          'id': 'Tidak ada mata pelajaran',
                        }),
                        subtitle: _searchController.text.isEmpty && _selectedFilter == 'All'
                            ? languageProvider.getTranslatedText({
                                'en': widget.guru['role'] == 'guru'
                                  ? 'No subjects assigned to you'
                                  : 'No subjects available',
                                'id': widget.guru['role'] == 'guru'
                                  ? 'Tidak ada mata pelajaran yang diajarkan'
                                  : 'Tidak ada mata pelajaran tersedia',
                              })
                            : languageProvider.getTranslatedText({
                                'en': 'No search results found',
                                'id': 'Tidak ditemukan hasil pencarian',
                              }),
                        icon: Icons.menu_book,
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _filteredMataPelajaranList.length,
                        itemBuilder: (context, index) {
                          final subject = _filteredMataPelajaranList[index];
                          return _buildSubjectCard(subject, languageProvider);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderInfo(LanguageProvider languageProvider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: ColorUtils.primaryColor.withOpacity(0.1),
            child: Icon(
              widget.guru['role'] == 'guru' ? Icons.school : Icons.admin_panel_settings,
              color: ColorUtils.primaryColor,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.guru['role'] == 'guru'
                      ? '${languageProvider.getTranslatedText({
                          'en': 'Teacher',
                          'id': 'Guru',
                        })}: ${widget.guru['nama']}'
                      : '${languageProvider.getTranslatedText({
                          'en': 'Admin',
                          'id': 'Admin',
                        })}: ${widget.guru['nama']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  languageProvider.getTranslatedText({
                    'en': 'Select subject to view/input grades',
                    'id': 'Pilih mata pelajaran untuk melihat/menginput nilai',
                  }),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject, LanguageProvider languageProvider) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: ColorUtils.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.menu_book, color: ColorUtils.primaryColor, size: 30),
        ),
        title: Text(
          subject['nama'] ?? languageProvider.getTranslatedText({
            'en': 'Subject',
            'id': 'Mata Pelajaran',
          }),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: subject['kode'] != null
            ? Text('${languageProvider.getTranslatedText({
                'en': 'Code',
                'id': 'Kode',
              })}: ${subject['kode']}')
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey.shade600,
          size: 16,
        ),
        onTap: () => _navigateToClassSelection(subject),
      ),
    );
  }
}

// Halaman Pemilihan Kelas
class ClassSelectionPage extends StatefulWidget {
  final Map<String, dynamic> guru;
  final Map<String, dynamic> mataPelajaran;

  const ClassSelectionPage({
    super.key,
    required this.guru,
    required this.mataPelajaran,
  });

  @override
  ClassSelectionPageState createState() => ClassSelectionPageState();
}

class ClassSelectionPageState extends State<ClassSelectionPage> {
  List<dynamic> _kelasList = [];
  List<dynamic> _filteredKelasList = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKelas();
    _searchController.addListener(_filterKelas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterKelas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredKelasList = List.from(_kelasList);
      } else {
        _filteredKelasList = _kelasList
            .where((kelas) =>
                kelas['nama'].toLowerCase().contains(query) ||
                (kelas['tingkat']?.toString().toLowerCase().contains(query) ?? false))
            .toList();
      }
    });
  }

  Future<void> _loadKelas() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final kelasData = await ApiService().getKelasByMataPelajaran(
        widget.mataPelajaran['id'],
      );

      setState(() {
        _kelasList = kelasData;
        _filteredKelasList = List.from(_kelasList);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load classes: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().getTranslatedText({
              'en': message,
              'id': message.replaceAll('Failed to load classes:', 'Gagal memuat kelas:'),
            }),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToGradeBook(Map<String, dynamic> kelas) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GradeBookPage(
          guru: widget.guru,
          mataPelajaran: widget.mataPelajaran,
          kelas: kelas,
        ),
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> kelas, LanguageProvider languageProvider) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: ColorUtils.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.class_, color: ColorUtils.primaryColor, size: 30),
        ),
        title: Text(
          kelas['nama'] ?? languageProvider.getTranslatedText({
            'en': 'Class',
            'id': 'Kelas',
          }),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: kelas['tingkat'] != null
            ? Text('${languageProvider.getTranslatedText({
                'en': 'Level',
                'id': 'Tingkat',
              })}: ${kelas['tingkat']}')
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey.shade600,
          size: 16,
        ),
        onTap: () => _navigateToGradeBook(kelas),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              '${languageProvider.getTranslatedText({
                'en': 'Select Class',
                'id': 'Pilih Kelas',
              })} - ${widget.mataPelajaran['nama']}',
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.black),
                onPressed: _loadKelas,
                tooltip: languageProvider.getTranslatedText({
                  'en': 'Refresh',
                  'id': 'Muat Ulang',
                }),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Container(height: 1, color: Colors.grey.shade300),
            ),
          ),
          body: _isLoading
              ? LoadingScreen(
                  message: languageProvider.getTranslatedText({
                    'en': 'Loading classes...',
                    'id': 'Memuat kelas...',
                  }),
                )
              : Column(
                  children: [
                    // Header Info
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: ColorUtils.primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.menu_book,
                              color: ColorUtils.primaryColor,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.mataPelajaran['nama'] ?? languageProvider.getTranslatedText({
                                    'en': 'Subject',
                                    'id': 'Mata Pelajaran',
                                  }),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 2),
                                if (widget.mataPelajaran['kode'] != null)
                                  Text(
                                    '${languageProvider.getTranslatedText({
                                      'en': 'Code',
                                      'id': 'Kode',
                                    })}: ${widget.mataPelajaran['kode']}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Search Bar
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: languageProvider.getTranslatedText({
                              'en': 'Search classes...',
                              'id': 'Cari kelas...',
                            }),
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    if (_filteredKelasList.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              '${_filteredKelasList.length} ${languageProvider.getTranslatedText({
                                'en': 'classes found',
                                'id': 'kelas ditemukan',
                              })}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 8),

                    Expanded(
                      child: _filteredKelasList.isEmpty
                          ? EmptyState(
                              title: languageProvider.getTranslatedText({
                                'en': 'No classes available',
                                'id': 'Tidak ada kelas',
                              }),
                              subtitle: _searchController.text.isEmpty
                                  ? languageProvider.getTranslatedText({
                                      'en': 'No classes available for this subject',
                                      'id': 'Tidak ada kelas untuk mata pelajaran ini',
                                    })
                                  : languageProvider.getTranslatedText({
                                      'en': 'No search results found',
                                      'id': 'Tidak ditemukan hasil pencarian',
                                    }),
                              icon: Icons.class_,
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: _filteredKelasList.length,
                              itemBuilder: (context, index) {
                                final kelas = _filteredKelasList[index];
                                return _buildClassCard(kelas, languageProvider);
                              },
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// Halaman Grade Book/Tabel Nilai
class GradeBookPage extends StatefulWidget {
  final Map<String, dynamic> guru;
  final Map<String, dynamic> mataPelajaran;
  final Map<String, dynamic> kelas;

  const GradeBookPage({
    super.key,
    required this.guru,
    required this.mataPelajaran,
    required this.kelas,
  });

  @override
  GradeBookPageState createState() => GradeBookPageState();
}

class GradeBookPageState extends State<GradeBookPage> {
  List<Siswa> _siswaList = [];
  List<Siswa> _filteredSiswaList = [];
  List<Map<String, dynamic>> _nilaiList = [];
  final List<String> _allJenisNilaiList = [
    'harian',
    'tugas',
    'ulangan',
    'uts',
    'uas',
  ];
  List<String> _filteredJenisNilaiList = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Filter state
  final Map<String, bool> _jenisNilaiFilter = {
    'harian': true,
    'tugas': true,
    'ulangan': true,
    'uts': true,
    'uas': true,
  };

  // Scroll controller untuk sinkronisasi scroll horizontal
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _updateFilteredJenisNilai();
    _searchController.addListener(_filterSiswa);
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterSiswa() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSiswaList = List.from(_siswaList);
      } else {
        _filteredSiswaList = _siswaList
            .where((siswa) =>
                siswa.nama.toLowerCase().contains(query) ||
                siswa.nis.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      // Load siswa berdasarkan kelas
      final siswaData = await ApiStudentService.getStudentByClass(
        widget.kelas['id'],
      );

      // Load nilai yang sudah ada
      final nilaiData = await ApiService().getNilaiByMataPelajaran(
        widget.mataPelajaran['id'],
      );

      setState(() {
        _siswaList = siswaData.map((s) => Siswa.fromJson(s)).toList();
        _filteredSiswaList = List.from(_siswaList);
        _nilaiList = List<Map<String, dynamic>>.from(nilaiData);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load grade data: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().getTranslatedText({
              'en': message,
              'id': message.replaceAll('Failed to load grade data:', 'Gagal memuat data nilai:'),
            }),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().getTranslatedText({
              'en': message,
              'id': message.replaceAll('successfully', 'berhasil'),
            }),
          ),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _updateFilteredJenisNilai() {
    setState(() {
      _filteredJenisNilaiList = _allJenisNilaiList
          .where((jenis) => _jenisNilaiFilter[jenis] == true)
          .toList();
    });
  }

  void _showFilterDialog(LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.filter_list, color: ColorUtils.primaryColor),
              SizedBox(width: 8),
              Text(languageProvider.getTranslatedText({
                'en': 'Filter Grade Types',
                'id': 'Filter Jenis Nilai',
              })),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _allJenisNilaiList.map((jenis) {
                return CheckboxListTile(
                  title: Text(_getJenisNilaiLabel(jenis, languageProvider)),
                  value: _jenisNilaiFilter[jenis],
                  onChanged: (bool? value) {
                    setState(() {
                      _jenisNilaiFilter[jenis] = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(languageProvider.getTranslatedText({
                'en': 'Cancel',
                'id': 'Batal',
              })),
            ),
            ElevatedButton(
              onPressed: () {
                _updateFilteredJenisNilai();
                Navigator.of(context).pop();
              },
              child: Text(languageProvider.getTranslatedText({
                'en': 'Apply',
                'id': 'Terapkan',
              })),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorUtils.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic>? _getNilaiForSiswaAndJenis(
    String siswaId,
    String jenis,
  ) {
    try {
      return _nilaiList.firstWhere(
        (nilai) => nilai['siswa_id'] == siswaId && nilai['jenis'] == jenis,
        orElse: () => <String, dynamic>{},
      );
    } catch (e) {
      return null;
    }
  }

  void _openInputForm(Siswa siswa, String jenisNilai, LanguageProvider languageProvider) {
    final existingNilai = _getNilaiForSiswaAndJenis(siswa.id!, jenisNilai);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GradeInputForm(
          guru: widget.guru,
          mataPelajaran: widget.mataPelajaran,
          siswa: siswa,
          jenisNilai: jenisNilai,
          existingNilai: existingNilai?.isNotEmpty == true
              ? existingNilai
              : null,
        ),
      ),
    ).then((_) {
      _loadData();
    });
  }

  void _openNewInputForm(LanguageProvider languageProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GradeInputFormNew(
          guru: widget.guru,
          mataPelajaran: widget.mataPelajaran,
          siswaList: _siswaList,
        ),
      ),
    ).then((_) {
      _loadData();
    });
  }

  Widget _buildGradeTable(LanguageProvider languageProvider) {
    final totalWidth = 120.0 + (_filteredJenisNilaiList.length * 90.0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _horizontalScrollController,
      child: Container(
        width: totalWidth,
        child: Column(
          children: [
            // Header tabel
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  // Kolom Nama Siswa - Lebar tetap
                  Container(
                    width: 120,
                    padding: EdgeInsets.all(12),
                    child: Text(
                      languageProvider.getTranslatedText({
                        'en': 'Name',
                        'id': 'Nama',
                      }),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  // Kolom jenis nilai
                  ..._filteredJenisNilaiList.map((jenis) {
                    return Container(
                      width: 90,
                      padding: EdgeInsets.all(8),
                      child: Text(
                        _getJenisNilaiLabel(jenis, languageProvider),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    );
                  }),
                ],
              ),
            ),
            // Body tabel
            ..._filteredSiswaList.map((siswa) {
              return Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    // Kolom Nama Siswa - Tetap
                    Container(
                      width: 120,
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            siswa.nama ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            '${languageProvider.getTranslatedText({
                              'en': 'NIS',
                              'id': 'NIS',
                            })}: ${siswa.nis ?? ''}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    // Kolom Nilai
                    ..._filteredJenisNilaiList.map((jenis) {
                      final nilai = _getNilaiForSiswaAndJenis(
                        siswa.id!,
                        jenis,
                      );
                      final nilaiText = nilai?.isNotEmpty == true
                          ? nilai!['nilai'].toString()
                          : '-';
                      final hasValue = nilai?.isNotEmpty == true;

                      return Container(
                        width: 90,
                        padding: EdgeInsets.all(4),
                        child: GestureDetector(
                          onTap: () => _openInputForm(siswa, jenis, languageProvider),
                          child: Container(
                            height: 40,
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: hasValue
                                  ? Colors.green.shade50
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: hasValue
                                    ? Colors.green.shade200
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                nilaiText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: hasValue
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: hasValue
                                      ? Colors.green.shade800
                                      : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _getJenisNilaiLabel(String jenis, LanguageProvider languageProvider) {
    switch (jenis) {
      case 'harian':
        return languageProvider.getTranslatedText({
          'en': 'Daily',
          'id': 'Harian',
        });
      case 'tugas':
        return languageProvider.getTranslatedText({
          'en': 'Assignment',
          'id': 'Tugas',
        });
      case 'ulangan':
        return languageProvider.getTranslatedText({
          'en': 'Quiz',
          'id': 'Ulangan',
        });
      case 'uts':
        return languageProvider.getTranslatedText({
          'en': 'Midterm',
          'id': 'UTS',
        });
      case 'uas':
        return languageProvider.getTranslatedText({
          'en': 'Final',
          'id': 'UAS',
        });
      default:
        return jenis;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final activeFilterCount = _jenisNilaiFilter.values.where((v) => v).length;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              '${languageProvider.getTranslatedText({
                'en': 'Grades',
                'id': 'Nilai',
              })} - ${widget.mataPelajaran['nama']} - ${widget.kelas['nama']}',
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              // Tombol Filter dengan badge
              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.filter_list, color: Colors.black),
                    onPressed: () => _showFilterDialog(languageProvider),
                    tooltip: languageProvider.getTranslatedText({
                      'en': 'Filter Grade Types',
                      'id': 'Filter Jenis Nilai',
                    }),
                  ),
                  if (activeFilterCount < _allJenisNilaiList.length)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '${_allJenisNilaiList.length - activeFilterCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.black),
                onPressed: _loadData,
                tooltip: languageProvider.getTranslatedText({
                  'en': 'Refresh',
                  'id': 'Muat Ulang',
                }),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Container(height: 1, color: Colors.grey.shade300),
            ),
          ),
          body: _isLoading
              ? LoadingScreen(
                  message: languageProvider.getTranslatedText({
                    'en': 'Loading grade data...',
                    'id': 'Memuat data nilai...',
                  }),
                )
              : Column(
                  children: [
                    // Header Info
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.mataPelajaran['nama']} - ${widget.kelas['nama']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${languageProvider.getTranslatedText({
                              'en': 'Grade types',
                              'id': 'Jenis nilai',
                            })}: ${_filteredJenisNilaiList.map((jenis) => _getJenisNilaiLabel(jenis, languageProvider)).join(', ')}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Search Bar
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: languageProvider.getTranslatedText({
                              'en': 'Search students...',
                              'id': 'Cari siswa...',
                            }),
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    if (_filteredSiswaList.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              '${_filteredSiswaList.length} ${languageProvider.getTranslatedText({
                                'en': 'students found',
                                'id': 'siswa ditemukan',
                              })}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 8),

                    // Instruction
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        languageProvider.getTranslatedText({
                          'en': 'Click on grade cells to input/edit',
                          'id': 'Klik pada kolom nilai untuk menginput/mengedit',
                        }),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),

                    // Tabel Nilai
                    Expanded(
                      child: _filteredSiswaList.isEmpty
                          ? EmptyState(
                              title: languageProvider.getTranslatedText({
                                'en': 'No students found',
                                'id': 'Tidak ada siswa',
                              }),
                              subtitle: _searchController.text.isEmpty
                                  ? languageProvider.getTranslatedText({
                                      'en': 'No students in this class',
                                      'id': 'Tidak ada siswa di kelas ini',
                                    })
                                  : languageProvider.getTranslatedText({
                                      'en': 'No search results found',
                                      'id': 'Tidak ditemukan hasil pencarian',
                                    }),
                              icon: Icons.people_outline,
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: _buildGradeTable(languageProvider),
                            ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openNewInputForm(languageProvider),
            backgroundColor: ColorUtils.primaryColor,
            foregroundColor: Colors.white,
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
}

// Form Input Nilai (Tetap sama seperti sebelumnya, hanya tambahkan LanguageProvider)
class GradeInputForm extends StatefulWidget {
  final Map<String, dynamic> guru;
  final Map<String, dynamic> mataPelajaran;
  final Siswa siswa;
  final String jenisNilai;
  final Map<String, dynamic>? existingNilai;

  const GradeInputForm({
    super.key,
    required this.guru,
    required this.mataPelajaran,
    required this.siswa,
    required this.jenisNilai,
    this.existingNilai,
  });

  @override
  GradeInputFormState createState() => GradeInputFormState();
}

class GradeInputFormState extends State<GradeInputForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nilaiController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Pre-fill data jika edit
    if (widget.existingNilai != null) {
      _nilaiController.text = widget.existingNilai!['nilai'].toString();
      _deskripsiController.text =
          widget.existingNilai!['deskripsi']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nilaiController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitNilai() async {
    if (_formKey.currentState!.validate()) {
      try {
        final data = {
          'siswa_id': widget.siswa.id,
          'guru_id': widget.guru['id'],
          'mata_pelajaran_id': widget.mataPelajaran['id'],
          'jenis': widget.jenisNilai,
          'nilai': double.parse(_nilaiController.text),
          'deskripsi': _deskripsiController.text,
          'tanggal':
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        };

        if (widget.existingNilai != null) {
          // Update nilai yang sudah ada
          await ApiService().put('/nilai/${widget.existingNilai!['id']}', data);
        } else {
          // Tambah nilai baru
          await ApiService().post('/nilai', data);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<LanguageProvider>().getTranslatedText({
                'en': widget.existingNilai != null
                    ? 'Grade successfully updated'
                    : 'Grade successfully saved',
                'id': widget.existingNilai != null
                    ? 'Nilai berhasil diupdate'
                    : 'Nilai berhasil disimpan',
              }),
            ),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: Text('${context.read<LanguageProvider>().getTranslatedText({
            'en': 'Error:',
            'id': 'Error:',
          })} $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  String _getJenisNilaiLabel(String jenis, LanguageProvider languageProvider) {
    switch (jenis) {
      case 'harian':
        return languageProvider.getTranslatedText({
          'en': 'Daily',
          'id': 'Harian',
        });
      case 'tugas':
        return languageProvider.getTranslatedText({
          'en': 'Assignment',
          'id': 'Tugas',
        });
      case 'ulangan':
        return languageProvider.getTranslatedText({
          'en': 'Quiz',
          'id': 'Ulangan',
        });
      case 'uts':
        return languageProvider.getTranslatedText({
          'en': 'Midterm',
          'id': 'UTS',
        });
      case 'uas':
        return languageProvider.getTranslatedText({
          'en': 'Final',
          'id': 'UAS',
        });
      default:
        return jenis;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              languageProvider.getTranslatedText({
                'en': 'Input Grade',
                'id': 'Input Nilai',
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
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Container(height: 1, color: Colors.grey.shade300),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Info Siswa dan Mata Pelajaran
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: ColorUtils.primaryColor),
                            SizedBox(width: 8),
                            Text(
                              '${languageProvider.getTranslatedText({
                                'en': 'Student',
                                'id': 'Siswa',
                              })}: ${widget.siswa.nama}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ColorUtils.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.badge, color: ColorUtils.primaryColor),
                            SizedBox(width: 8),
                            Text('${languageProvider.getTranslatedText({
                              'en': 'NIS',
                              'id': 'NIS',
                            })}: ${widget.siswa.nis}'),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.menu_book, color: ColorUtils.primaryColor),
                            SizedBox(width: 8),
                            Text(
                              '${languageProvider.getTranslatedText({
                                'en': 'Subject',
                                'id': 'Mata Pelajaran',
                              })}: ${widget.mataPelajaran['nama']}',
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.assignment, color: ColorUtils.primaryColor),
                            SizedBox(width: 8),
                            Text(
                              '${languageProvider.getTranslatedText({
                                'en': 'Type',
                                'id': 'Jenis',
                              })}: ${_getJenisNilaiLabel(widget.jenisNilai, languageProvider)}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Input Nilai
                  TextFormField(
                    controller: _nilaiController,
                    decoration: InputDecoration(
                      labelText: languageProvider.getTranslatedText({
                        'en': 'Grade',
                        'id': 'Nilai',
                      }),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.score, color: ColorUtils.primaryColor),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return languageProvider.getTranslatedText({
                          'en': 'Please enter grade',
                          'id': 'Masukkan nilai',
                        });
                      }
                      if (double.tryParse(value) == null) {
                        return languageProvider.getTranslatedText({
                          'en': 'Please enter valid number',
                          'id': 'Masukkan angka yang valid',
                        });
                      }
                      final nilai = double.parse(value);
                      if (nilai < 0 || nilai > 100) {
                        return languageProvider.getTranslatedText({
                          'en': 'Grade must be between 0-100',
                          'id': 'Nilai harus antara 0-100',
                        });
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Input Deskripsi
                  TextFormField(
                    controller: _deskripsiController,
                    decoration: InputDecoration(
                      labelText: languageProvider.getTranslatedText({
                        'en': 'Description',
                        'id': 'Deskripsi',
                      }),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description, color: ColorUtils.primaryColor),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 16),

                  // Pilih Tanggal
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: ColorUtils.primaryColor),
                        SizedBox(width: 12),
                        Text(
                          languageProvider.getTranslatedText({
                            'en': 'Date:',
                            'id': 'Tanggal:',
                          }),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: () => _selectDate(context),
                          child: Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: TextStyle(fontSize: 16, color: ColorUtils.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tombol Simpan
                  ElevatedButton(
                    onPressed: _submitNilai,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorUtils.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.existingNilai != null
                          ? languageProvider.getTranslatedText({
                              'en': 'Update Grade',
                              'id': 'Update Nilai',
                            })
                          : languageProvider.getTranslatedText({
                              'en': 'Save Grade',
                              'id': 'Simpan Nilai',
                            }),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Form Input Nilai Baru (Tetap sama seperti sebelumnya, hanya tambahkan LanguageProvider)
class GradeInputFormNew extends StatefulWidget {
  final Map<String, dynamic> guru;
  final Map<String, dynamic> mataPelajaran;
  final List<Siswa> siswaList;

  const GradeInputFormNew({
    super.key,
    required this.guru,
    required this.mataPelajaran,
    required this.siswaList,
  });

  @override
  GradeInputFormNewState createState() => GradeInputFormNewState();
}

class GradeInputFormNewState extends State<GradeInputFormNew> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();

  // Variabel untuk state
  String? _selectedJenisNilai;
  final List<String> _jenisNilaiList = [
    'harian',
    'tugas',
    'ulangan',
    'uts',
    'uas',
  ];

  // Map untuk menyimpan nilai per siswa
  final Map<String, Map<String, dynamic>> _nilaiSiswaMap = {};

  @override
  void initState() {
    super.initState();
    // Initialize map dengan nilai default untuk setiap siswa
    for (var siswa in widget.siswaList) {
      _nilaiSiswaMap[siswa.id!] = {
        'nilai': '',
        'deskripsi': '',
      };
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitNilai() async {
    final languageProvider = context.read<LanguageProvider>();
    
    if (_formKey.currentState!.validate()) {
      if (_selectedJenisNilai == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.getTranslatedText({
              'en': 'Please select grade type first',
              'id': 'Pilih jenis nilai terlebih dahulu',
            })),
            backgroundColor: Colors.orange.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Cek apakah ada setidaknya satu siswa yang memiliki nilai
      bool hasData = false;
      for (var siswa in widget.siswaList) {
        final nilaiData = _nilaiSiswaMap[siswa.id!];
        if (nilaiData?['nilai']?.isNotEmpty == true) {
          hasData = true;
          break;
        }
      }

      if (!hasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.getTranslatedText({
              'en': 'Enter grade for at least one student',
              'id': 'Masukkan nilai untuk setidaknya satu siswa',
            })),
            backgroundColor: Colors.orange.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      try {
        int successCount = 0;
        
        for (var siswa in widget.siswaList) {
          final nilaiData = _nilaiSiswaMap[siswa.id!];
          final nilai = nilaiData?['nilai']?.toString().trim();
          
          // Skip jika tidak ada nilai yang diinput
          if (nilai == null || nilai.isEmpty) {
            continue;
          }

          final data = {
            'siswa_id': siswa.id,
            'guru_id': widget.guru['id'],
            'mata_pelajaran_id': widget.mataPelajaran['id'],
            'jenis': _selectedJenisNilai!,
            'nilai': double.parse(nilai),
            'deskripsi': nilaiData?['deskripsi']?.toString().trim() ?? '',
            'tanggal':
                '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
          };

          // Tambah nilai baru
          await ApiService().post('/nilai', data);
          successCount++;
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.getTranslatedText({
                'en': '$successCount grades successfully saved',
                'id': '$successCount nilai berhasil disimpan',
              }),
            ),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: Text('${languageProvider.getTranslatedText({
            'en': 'Error:',
            'id': 'Error:',
          })} $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  String _getJenisNilaiLabel(String jenis, LanguageProvider languageProvider) {
    switch (jenis) {
      case 'harian':
        return languageProvider.getTranslatedText({
          'en': 'Daily',
          'id': 'Harian',
        });
      case 'tugas':
        return languageProvider.getTranslatedText({
          'en': 'Assignment',
          'id': 'Tugas',
        });
      case 'ulangan':
        return languageProvider.getTranslatedText({
          'en': 'Quiz',
          'id': 'Ulangan',
        });
      case 'uts':
        return languageProvider.getTranslatedText({
          'en': 'Midterm',
          'id': 'UTS',
        });
      case 'uas':
        return languageProvider.getTranslatedText({
          'en': 'Final',
          'id': 'UAS',
        });
      default:
        return jenis;
    }
  }

  Widget _buildSiswaInputCard(Siswa siswa, LanguageProvider languageProvider) {
    final nilaiData = _nilaiSiswaMap[siswa.id!] ?? {};
    final nilaiController = TextEditingController(text: nilaiData['nilai'] ?? '');
    final deskripsiController = TextEditingController(text: nilaiData['deskripsi'] ?? '');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: ColorUtils.primaryColor.withOpacity(0.1),
          child: Text(
            siswa.nama?.substring(0, 1).toUpperCase() ?? '?',
            style: TextStyle(color: ColorUtils.primaryColor),
          ),
        ),
        title: Text(
          siswa.nama ?? languageProvider.getTranslatedText({
            'en': 'Student',
            'id': 'Siswa',
          }),
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('${languageProvider.getTranslatedText({
          'en': 'NIS',
          'id': 'NIS',
        })}: ${siswa.nis ?? '-'}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Input Nilai
                TextFormField(
                  controller: nilaiController,
                  decoration: InputDecoration(
                    labelText: languageProvider.getTranslatedText({
                      'en': 'Grade',
                      'id': 'Nilai',
                    }),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.score, color: ColorUtils.primaryColor),
                    hintText: languageProvider.getTranslatedText({
                      'en': 'Enter grade 0-100',
                      'id': 'Masukkan nilai 0-100',
                    }),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _nilaiSiswaMap[siswa.id!]?['nilai'] = value;
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return languageProvider.getTranslatedText({
                          'en': 'Please enter valid number',
                          'id': 'Masukkan angka yang valid',
                        });
                      }
                      final nilai = double.parse(value);
                      if (nilai < 0 || nilai > 100) {
                        return languageProvider.getTranslatedText({
                          'en': 'Grade must be between 0-100',
                          'id': 'Nilai harus antara 0-100',
                        });
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Input Deskripsi
                TextFormField(
                  controller: deskripsiController,
                  decoration: InputDecoration(
                    labelText: languageProvider.getTranslatedText({
                      'en': 'Description (Optional)',
                      'id': 'Deskripsi (Opsional)',
                    }),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description, color: ColorUtils.primaryColor),
                    hintText: languageProvider.getTranslatedText({
                      'en': 'Enter grade description',
                      'id': 'Masukkan deskripsi nilai',
                    }),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    _nilaiSiswaMap[siswa.id!]?['deskripsi'] = value;
                  },
                ),
                const SizedBox(height: 8),
                // Status indicator
                if (nilaiData['nilai']?.isNotEmpty == true)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${languageProvider.getTranslatedText({
                            'en': 'Grade',
                            'id': 'Nilai',
                          })}: ${nilaiData['nilai']}',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final siswaWithNilaiCount = widget.siswaList.where((siswa) {
          final nilaiData = _nilaiSiswaMap[siswa.id!];
          return nilaiData?['nilai']?.isNotEmpty == true;
        }).length;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              languageProvider.getTranslatedText({
                'en': 'New Grade Input',
                'id': 'Input Nilai Baru',
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
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Container(height: 1, color: Colors.grey.shade300),
            ),
          ),
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.menu_book, color: ColorUtils.primaryColor, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${languageProvider.getTranslatedText({
                                    'en': 'Subject',
                                    'id': 'Mata Pelajaran',
                                  })}: ${widget.mataPelajaran['nama']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: ColorUtils.primaryColor,
                                  ),
                                ),
                                if (widget.mataPelajaran['kode'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '${languageProvider.getTranslatedText({
                                        'en': 'Code',
                                        'id': 'Kode',
                                      })}: ${widget.mataPelajaran['kode']}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Pilih Jenis Nilai
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedJenisNilai,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.assignment, color: ColorUtils.primaryColor),
                            hintText: languageProvider.getTranslatedText({
                              'en': 'Select grade type',
                              'id': 'Pilih jenis nilai',
                            }),
                          ),
                          items: _jenisNilaiList.map((String jenis) {
                            return DropdownMenuItem<String>(
                              value: jenis,
                              child: Text(_getJenisNilaiLabel(jenis, languageProvider)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedJenisNilai = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return languageProvider.getTranslatedText({
                                'en': 'Please select grade type',
                                'id': 'Pilih jenis nilai terlebih dahulu',
                              });
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Pilih Tanggal
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: ColorUtils.primaryColor),
                            const SizedBox(width: 12),
                            Text(
                              languageProvider.getTranslatedText({
                                'en': 'Date:',
                                'id': 'Tanggal:',
                              }),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _selectDate(context),
                              child: Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: TextStyle(fontSize: 16, color: ColorUtils.primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Header List Siswa
                if (_selectedJenisNilai != null) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          languageProvider.getTranslatedText({
                            'en': 'Student List',
                            'id': 'Daftar Siswa',
                          }),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: siswaWithNilaiCount > 0 ? Colors.green.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: siswaWithNilaiCount > 0 ? Colors.green.shade200 : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            '$siswaWithNilaiCount/${widget.siswaList.length} ${languageProvider.getTranslatedText({
                              'en': 'students',
                              'id': 'siswa',
                            })}',
                            style: TextStyle(
                              color: siswaWithNilaiCount > 0 ? Colors.green.shade800 : Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      languageProvider.getTranslatedText({
                        'en': 'Click on student name to input grade',
                        'id': 'Klik pada nama siswa untuk menginput nilai',
                      }),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],

                // List Siswa dengan Input Nilai
                if (_selectedJenisNilai != null) ...[
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.siswaList.length,
                      itemBuilder: (context, index) {
                        final siswa = widget.siswaList[index];
                        return _buildSiswaInputCard(siswa, languageProvider);
                      },
                    ),
                  ),
                ] else ...[
                  const Expanded(
                    child: EmptyState(
                      title: 'Select grade type',
                      subtitle: 'Please select grade type first to see student list',
                      icon: Icons.assignment,
                    ),
                  ),
                ],

                // Tombol Simpan
                if (_selectedJenisNilai != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _submitNilai,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorUtils.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        languageProvider.getTranslatedText({
                          'en': 'Save All Grades',
                          'id': 'Simpan Semua Nilai',
                        }),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
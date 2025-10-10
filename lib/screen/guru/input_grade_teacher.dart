import 'package:flutter/material.dart';
import 'package:manajemensekolah/models/siswa.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/api_student_services.dart';
import 'package:manajemensekolah/services/api_subject_services.dart';
import 'package:manajemensekolah/services/api_teacher_services.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Memuat data...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.subject, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            widget.guru['role'] == 'guru'
                ? 'Tidak ada mata pelajaran yang diajarkan'
                : 'Tidak ada mata pelajaran tersedia',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Muat Ulang')),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.menu_book, color: Colors.blue.shade700, size: 30),
        ),
        title: Text(
          subject['nama'] ?? 'Mata Pelajaran',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: subject['kode'] != null
            ? Text('Kode: ${subject['kode']}')
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Nilai'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _mataPelajaranList.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Info role user
                Card(
                  margin: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          widget.guru['role'] == 'guru'
                              ? Icons.school
                              : Icons.admin_panel_settings,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.guru['role'] == 'guru'
                                    ? 'Guru: ${widget.guru['nama']}'
                                    : 'Admin: ${widget.guru['nama']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pilih mata pelajaran untuk melihat/menginput nilai',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // List mata pelajaran
                Expanded(
                  child: ListView.builder(
                    itemCount: _mataPelajaranList.length,
                    itemBuilder: (context, index) {
                      final subject = _mataPelajaranList[index];
                      return _buildSubjectCard(subject);
                    },
                  ),
                ),
              ],
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKelas();
  }

  Future<void> _loadKelas() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Mengambil daftar kelas untuk mata pelajaran ini
      final kelasData = await ApiService().getKelasByMataPelajaran(
        widget.mataPelajaran['id'],
      );

      setState(() {
        _kelasList = kelasData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

  Widget _buildClassCard(Map<String, dynamic> kelas) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.class_, color: Colors.green.shade700, size: 30),
        ),
        title: Text(
          kelas['nama'] ?? 'Kelas',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: kelas['tingkat'] != null
            ? Text('Tingkat: ${kelas['tingkat']}')
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Kelas - ${widget.mataPelajaran['nama']}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _kelasList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.class_, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Tidak ada kelas untuk mata pelajaran ini',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadKelas,
                    child: Text('Muat Ulang'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Info Mata Pelajaran
                Card(
                  margin: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book, color: Colors.blue.shade700),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.mataPelajaran['nama'] ??
                                    'Mata Pelajaran',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (widget.mataPelajaran['kode'] != null)
                                Text(
                                  'Kode: ${widget.mataPelajaran['kode']}',
                                  style: TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // List Kelas
                Expanded(
                  child: ListView.builder(
                    itemCount: _kelasList.length,
                    itemBuilder: (context, index) {
                      final kelas = _kelasList[index];
                      return _buildClassCard(kelas);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// Halaman Grade Book/Tabel Nilai (Diperbarui)
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
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
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
        _nilaiList = List<Map<String, dynamic>>.from(nilaiData);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _updateFilteredJenisNilai() {
    setState(() {
      _filteredJenisNilaiList = _allJenisNilaiList
          .where((jenis) => _jenisNilaiFilter[jenis] == true)
          .toList();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.filter_list, color: Colors.blue),
              SizedBox(width: 8),
              Text('Filter Jenis Nilai'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _allJenisNilaiList.map((jenis) {
                return CheckboxListTile(
                  title: Text(_getJenisNilaiLabel(jenis)),
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
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateFilteredJenisNilai();
                Navigator.of(context).pop();
              },
              child: Text('Terapkan'),
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

  void _openInputForm(Siswa siswa, String jenisNilai) {
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

  void _openNewInputForm() {
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

  Widget _buildGradeTable() {
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
                      'Nama',
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
                        _getJenisNilaiLabel(jenis),
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
            ..._siswaList.map((siswa) {
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
                            'NIS: ${siswa.nis ?? ''}',
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
                          onTap: () => _openInputForm(siswa, jenis),
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

  String _getJenisNilaiLabel(String jenis) {
    switch (jenis) {
      case 'harian':
        return 'Harian';
      case 'tugas':
        return 'Tugas';
      case 'ulangan':
        return 'Ulangan';
      case 'uts':
        return 'UTS';
      case 'uas':
        return 'UAS';
      default:
        return jenis;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFilterCount = _jenisNilaiFilter.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nilai - ${widget.mataPelajaran['nama']} - ${widget.kelas['nama']}',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Tombol Filter dengan badge
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
                tooltip: 'Filter Jenis Nilai',
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
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info Mata Pelajaran dan Kelas
                Card(
                  margin: EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book, color: Colors.blue.shade700, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.mataPelajaran['nama']} - ${widget.kelas['nama']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (widget.mataPelajaran['kode'] != null)
                                Text(
                                  'Kode: ${widget.mataPelajaran['kode']}',
                                  style: TextStyle(fontSize: 11),
                                ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Jenis nilai: ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _filteredJenisNilaiList
                                          .map(_getJenisNilaiLabel)
                                          .join(', '),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Klik pada kolom nilai untuk menginput/mengedit',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tabel Nilai
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: _buildGradeTable(),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewInputForm,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
      ),
    );
  }
}

// Form Input Nilai
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
              widget.existingNilai != null
                  ? 'Nilai berhasil diupdate'
                  : 'Nilai berhasil disimpan',
            ),
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _getJenisNilaiLabel(String jenis) {
    switch (jenis) {
      case 'harian':
        return 'Harian';
      case 'tugas':
        return 'Tugas';
      case 'ulangan':
        return 'Ulangan';
      case 'uts':
        return 'UTS';
      case 'uas':
        return 'UAS';
      default:
        return jenis;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Nilai'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Info Siswa dan Mata Pelajaran
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Siswa: ${widget.siswa.nama}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.badge, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('ID: ${widget.siswa.nis}'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.menu_book, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Mata Pelajaran: ${widget.mataPelajaran['nama']}',
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.assignment, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Jenis: ${_getJenisNilaiLabel(widget.jenisNilai)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Input Nilai
              TextFormField(
                controller: _nilaiController,
                decoration: const InputDecoration(
                  labelText: 'Nilai',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.score),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan nilai';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  final nilai = double.parse(value);
                  if (nilai < 0 || nilai > 100) {
                    return 'Nilai harus antara 0-100';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Input Deskripsi
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Pilih Tanggal
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue),
                      SizedBox(width: 12),
                      Text(
                        'Tanggal:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      TextButton(
                        onPressed: () => _selectDate(context),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tombol Simpan
              ElevatedButton(
                onPressed: _submitNilai,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.existingNilai != null
                      ? 'Update Nilai'
                      : 'Simpan Nilai',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Form Input Nilai Baru
// Form Input Nilai Baru
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
  final TextEditingController _nilaiController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
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
    if (_formKey.currentState!.validate()) {
      if (_selectedJenisNilai == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih jenis nilai terlebih dahulu')),
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
          const SnackBar(content: Text('Masukkan nilai untuk setidaknya satu siswa')),
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
          SnackBar(content: Text('$successCount nilai berhasil disimpan')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _getJenisNilaiLabel(String jenis) {
    switch (jenis) {
      case 'harian':
        return 'Harian';
      case 'tugas':
        return 'Tugas';
      case 'ulangan':
        return 'Ulangan';
      case 'uts':
        return 'UTS';
      case 'uas':
        return 'UAS';
      default:
        return jenis;
    }
  }

  Widget _buildSiswaInputCard(Siswa siswa) {
    final nilaiData = _nilaiSiswaMap[siswa.id!] ?? {};
    final nilaiController = TextEditingController(text: nilaiData['nilai'] ?? '');
    final deskripsiController = TextEditingController(text: nilaiData['deskripsi'] ?? '');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            siswa.nama?.substring(0, 1).toUpperCase() ?? '?',
            style: const TextStyle(color: Colors.blue),
          ),
        ),
        title: Text(
          siswa.nama ?? 'Siswa',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('NIS: ${siswa.nis ?? '-'}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Input Nilai
                TextFormField(
                  controller: nilaiController,
                  decoration: const InputDecoration(
                    labelText: 'Nilai',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.score),
                    hintText: 'Masukkan nilai 0-100',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _nilaiSiswaMap[siswa.id!]?['nilai'] = value;
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return 'Masukkan angka yang valid';
                      }
                      final nilai = double.parse(value);
                      if (nilai < 0 || nilai > 100) {
                        return 'Nilai harus antara 0-100';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Input Deskripsi
                TextFormField(
                  controller: deskripsiController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                    hintText: 'Masukkan deskripsi nilai',
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
                          'Nilai: ${nilaiData['nilai']}',
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
    final siswaWithNilaiCount = widget.siswaList.where((siswa) {
      final nilaiData = _nilaiSiswaMap[siswa.id!];
      return nilaiData?['nilai']?.isNotEmpty == true;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Nilai Baru'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Info Mata Pelajaran
            Card(
              margin: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.menu_book, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mata Pelajaran: ${widget.mataPelajaran['nama']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (widget.mataPelajaran['kode'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Kode: ${widget.mataPelajaran['kode']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pilih Jenis Nilai
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Jenis Nilai *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedJenisNilai,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.assignment),
                        hintText: 'Pilih jenis nilai',
                      ),
                      items: _jenisNilaiList.map((String jenis) {
                        return DropdownMenuItem<String>(
                          value: jenis,
                          child: Text(_getJenisNilaiLabel(jenis)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedJenisNilai = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Pilih jenis nilai terlebih dahulu';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Pilih Tanggal
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Text(
                      'Tanggal:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      child: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Header List Siswa
            if (_selectedJenisNilai != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Daftar Siswa',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey,
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
                        '$siswaWithNilaiCount/${widget.siswaList.length} siswa',
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Klik pada nama siswa untuk menginput nilai',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
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
                    return _buildSiswaInputCard(siswa);
                  },
                ),
              ),
            ] else ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Pilih jenis nilai terlebih dahulu untuk melihat daftar siswa',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
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
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Simpan Semua Nilai',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
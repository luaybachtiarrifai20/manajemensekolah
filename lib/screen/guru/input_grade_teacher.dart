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

  void _navigateToGradeBook(Map<String, dynamic> mataPelajaran) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GradeBookPage(guru: widget.guru, mataPelajaran: mataPelajaran),
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
        onTap: () => _navigateToGradeBook(subject),
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

// Halaman Grade Book/Tabel Nilai
class GradeBookPage extends StatefulWidget {
  final Map<String, dynamic> guru;
  final Map<String, dynamic> mataPelajaran;

  const GradeBookPage({
    super.key,
    required this.guru,
    required this.mataPelajaran,
  });

  @override
  GradeBookPageState createState() => GradeBookPageState();
}

class GradeBookPageState extends State<GradeBookPage> {
  List<Siswa> _siswaList = [];
  List<Map<String, dynamic>> _nilaiList = [];
  final List<String> _jenisNilaiList = ['tugas', 'ulangan', 'uts', 'uas'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load siswa
      final siswaData = await ApiStudentService.getStudent();

      // Load nilai yang sudah ada menggunakan method khusus
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

  Map<String, dynamic>? _getNilaiForSiswaAndJenis(
    String siswaId,
    String jenis,
  ) {
    try {
      return _nilaiList.firstWhere(
        (nilai) => nilai['siswa_id'] == siswaId && nilai['jenis'] == jenis,
        orElse: () => {},
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
      // Refresh data setelah kembali dari form input
      _loadData();
    });
  }

  // Method baru untuk membuka form tanpa siswa dan jenis nilai yang dipilih
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
      // Refresh data setelah kembali dari form input
      _loadData();
    });
  }

  Widget _buildGradeTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          headingRowColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) => Colors.blue.shade50,
          ),
          columns: [
            const DataColumn(
              label: Text(
                'Nama Siswa',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const DataColumn(
              label: Text('NIS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ..._jenisNilaiList.map((jenis) {
              return DataColumn(
                label: Text(
                  _getJenisNilaiLabel(jenis),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ],
          rows: _siswaList.map((siswa) {
            return DataRow(
              cells: [
                DataCell(
                  Text(siswa.nama ?? ''),
                  onTap: () {
                    // Bisa digunakan untuk melihat detail siswa atau input nilai untuk semua jenis
                  },
                ),
                DataCell(Text(siswa.nis ?? '')),
                ..._jenisNilaiList.map((jenis) {
                  final nilai = _getNilaiForSiswaAndJenis(siswa.id!, jenis);
                  final nilaiText = nilai?.isNotEmpty == true
                      ? nilai!['nilai'].toString()
                      : '-';
                  final hasValue = nilai?.isNotEmpty == true;

                  return DataCell(
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasValue
                            ? Colors.green.shade50
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
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
                        ),
                      ),
                    ),
                    onTap: () => _openInputForm(siswa, jenis),
                  );
                }).toList(),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getJenisNilaiLabel(String jenis) {
    switch (jenis) {
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
        title: Text('Nilai - ${widget.mataPelajaran['nama']}'),
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
          ? const Center(child: CircularProgressIndicator())
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.mataPelajaran['nama'] ??
                                    'Mata Pelajaran',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (widget.mataPelajaran['kode'] != null)
                                Text(
                                  'Kode: ${widget.mataPelajaran['kode']}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                'Klik pada kolom nilai untuk menginput/mengedit',
                                style: TextStyle(
                                  fontSize: 12,
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
                Expanded(child: _buildGradeTable()),
              ],
            ),
      // Tambahkan FAB di sini
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewInputForm,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
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
                          Text('NIS: ${widget.siswa.nis}'),
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

// Form Input Nilai Baru (tanpa siswa dan jenis nilai yang dipilih)
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
  
  // Variabel untuk dropdown
  Siswa? _selectedSiswa;
  String? _selectedJenisNilai;
  final List<String> _jenisNilaiList = ['tugas', 'ulangan', 'uts', 'uas'];

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
      if (_selectedSiswa == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih siswa terlebih dahulu')),
        );
        return;
      }
      
      if (_selectedJenisNilai == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih jenis nilai terlebih dahulu')),
        );
        return;
      }

      try {
        final data = {
          'siswa_id': _selectedSiswa!.id,
          'guru_id': widget.guru['id'],
          'mata_pelajaran_id': widget.mataPelajaran['id'],
          'jenis': _selectedJenisNilai!,
          'nilai': double.parse(_nilaiController.text),
          'deskripsi': _deskripsiController.text,
          'tanggal':
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        };

        // Tambah nilai baru
        await ApiService().post('/nilai', data);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nilai berhasil disimpan')),
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
        title: const Text('Input Nilai Baru'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Info Mata Pelajaran
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.menu_book, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Mata Pelajaran: ${widget.mataPelajaran['nama']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (widget.mataPelajaran['kode'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.code, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Kode: ${widget.mataPelajaran['kode']}'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Dropdown Siswa
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Siswa *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Siswa>(
                        value: _selectedSiswa,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        hint: const Text('Pilih Siswa'),
                        items: widget.siswaList.map((Siswa siswa) {
                          return DropdownMenuItem<Siswa>(
                            value: siswa,
                            child: Text('${siswa.nama} (${siswa.nis})'),
                          );
                        }).toList(),
                        onChanged: (Siswa? newValue) {
                          setState(() {
                            _selectedSiswa = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Pilih siswa terlebih dahulu';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Dropdown Jenis Nilai
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Jenis Nilai *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedJenisNilai,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.assignment),
                        ),
                        hint: const Text('Pilih Jenis Nilai'),
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

              const SizedBox(height: 16),

              // Input Nilai
              TextFormField(
                controller: _nilaiController,
                decoration: const InputDecoration(
                  labelText: 'Nilai *',
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
                child: const Text('Simpan Nilai'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
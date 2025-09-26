import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manajemensekolah/models/siswa.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/api_student_services.dart';
import 'package:manajemensekolah/services/api_subject_services.dart';


class NilaiPage extends StatefulWidget {
  final Map<String, dynamic> guru;

  const NilaiPage({super.key, required this.guru});

  @override
  NilaiPageState createState() => NilaiPageState();
}

class NilaiPageState extends State<NilaiPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nilaiController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final ApiSubjectService apiSubjectService = ApiSubjectService();

  DateTime _selectedDate = DateTime.now();
  String? _selectedMataPelajaran;
  String? _selectedSiswa;
  String? _selectedJenis;
  List<dynamic> _mataPelajaranList = [];
  List<Siswa> _siswaList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final mataPelajaran = await apiSubjectService.getMataPelajaran();
      final siswa = await ApiStudentService.getSiswa();
      
      setState(() {
        _mataPelajaranList = mataPelajaran;
        _siswaList = siswa.map((s) => Siswa.fromJson(s)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
        await ApiService.tambahNilai({
          'siswa_id': _selectedSiswa,
          'guru_id': widget.guru['id'],
          'mata_pelajaran_id': _selectedMataPelajaran,
          'jenis': _selectedJenis,
          'nilai': double.parse(_nilaiController.text),
          'deskripsi': _deskripsiController.text,
          'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nilai berhasil disimpan')),
        );

        // Reset form
        _formKey.currentState!.reset();
        _nilaiController.clear();
        _deskripsiController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
              // Pilih Siswa
              DropdownButtonFormField<String>(
                initialValue: _selectedSiswa,
                decoration: const InputDecoration(
                  labelText: 'Siswa',
                  border: OutlineInputBorder(),
                ),
                items: _siswaList.map((siswa) {
                  return DropdownMenuItem<String>(
                    value: siswa.id,
                    child: Text('${siswa.nama} (NIS: ${siswa.nis})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSiswa = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Pilih siswa';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Pilih Mata Pelajaran
              DropdownButtonFormField<String>(
                initialValue: _selectedMataPelajaran,
                decoration: const InputDecoration(
                  labelText: 'Mata Pelajaran',
                  border: OutlineInputBorder(),
                ),
                items: _mataPelajaranList.map((mp) {
                  return DropdownMenuItem<String>(
                    value: mp['id'],
                    child: Text(mp['nama']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMataPelajaran = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Pilih mata pelajaran';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Pilih Jenis Nilai
              DropdownButtonFormField<String>(
                initialValue: _selectedJenis,
                decoration: const InputDecoration(
                  labelText: 'Jenis Nilai',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'tugas', child: Text('Tugas')),
                  DropdownMenuItem(value: 'ulangan', child: Text('Ulangan')),
                  DropdownMenuItem(value: 'uts', child: Text('UTS')),
                  DropdownMenuItem(value: 'uas', child: Text('UAS')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedJenis = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Pilih jenis nilai';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Input Nilai
              TextFormField(
                controller: _nilaiController,
                decoration: const InputDecoration(
                  labelText: 'Nilai',
                  border: OutlineInputBorder(),
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
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Pilih Tanggal
              Row(
                children: [
                  const Text('Tanggal: '),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  ),
                ],
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
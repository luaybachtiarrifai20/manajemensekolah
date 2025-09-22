import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_services.dart';

class MateriPage extends StatefulWidget {
  final Map<String, dynamic> guru;

  const MateriPage({super.key, required this.guru});

  @override
  MateriPageState createState() => MateriPageState();
}

class MateriPageState extends State<MateriPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  String? _selectedMataPelajaran;
  List<dynamic> _mataPelajaranList = [];
  List<dynamic> _materiList = [];
  List<dynamic> _babMateriList = [];
  List<dynamic> _subBabMateriList = [];
  List<dynamic> _kontenMateriList = [];

  // State untuk expanded/collapsed
  final Map<String, bool> _expandedBab = {};
  
  // State untuk ceklis
  final Map<String, bool> _checkedBab = {};
  final Map<String, bool> _checkedSubBab = {};
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    print('Guru data received: ${widget.guru}');
    print('Guru ID: ${widget.guru['id']}');
    print('Guru keys: ${widget.guru.keys}');
    print('Guru values: ${widget.guru}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final String? guruId = widget.guru['id'];
      print('Loading data for guru ID: $guruId');

      if (guruId == null || guruId.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: ID guru tidak valid')),
        );
        return;
      }

      final apiService = ApiService();
      final mataPelajaran = await apiService.getMataPelajaranByGuru(guruId);

      print('Mata pelajaran found: ${mataPelajaran.length}');
      print('Mata pelajaran details: $mataPelajaran');

      // Jika guru tidak memiliki mata pelajaran, tampilkan pesan
      if (mataPelajaran.isEmpty) {
        setState(() {
          _isLoading = false;
          _mataPelajaranList = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Guru ini belum memiliki mata pelajaran yang ditugaskan',
            ),
          ),
        );
        return;
      }

      final materi = await ApiService.getMateri(guruId: guruId);

      setState(() {
        _mataPelajaranList = mataPelajaran;
        _materiList = materi;
        _isLoading = false;

        if (mataPelajaran.isNotEmpty) {
          _selectedMataPelajaran = mataPelajaran[0]['id'];
          _loadBabMateri(_selectedMataPelajaran!);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error in _loadData: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _loadBabMateri(String mataPelajaranId) async {
    try {
      final babMateri = await ApiService.getBabMateri(
        mataPelajaranId: mataPelajaranId,
      );

      setState(() {
        _babMateriList = babMateri;
        // Inisialisasi state expanded dan checked untuk setiap bab
        for (var bab in babMateri) {
          _expandedBab[bab['id']] = false;
          _checkedBab[bab['id']] = false;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _loadSubBabMateri(String babId) async {
    try {
      final subBabMateri = await ApiService.getSubBabMateri(babId: babId);

      setState(() {
        _subBabMateriList = subBabMateri
            .where((subBab) => subBab['bab_id'] == babId)
            .toList();
        // Inisialisasi state checked untuk setiap sub-bab
        for (var subBab in _subBabMateriList) {
          _checkedSubBab[subBab['id']] = false;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Fungsi untuk menangani perubahan ceklis pada sub bab
  void _handleSubBabCheck(String subBabId, String babId, bool? value) {
    setState(() {
      _checkedSubBab[subBabId] = value ?? false;
      
      // Cek apakah semua sub bab dalam bab ini sudah dicentang
      final allSubBabsChecked = _subBabMateriList
          .where((subBab) => subBab['bab_id'] == babId)
          .every((subBab) => _checkedSubBab[subBab['id']] == true);
      
      // Set status ceklis bab berdasarkan apakah semua sub bab sudah dicentang
      _checkedBab[babId] = allSubBabsChecked;
    });
  }

  // Fungsi untuk menangani perubahan ceklis pada bab
  void _handleBabCheck(String babId, bool? value) {
    setState(() {
      _checkedBab[babId] = value ?? false;
      
      // Jika bab dicentang/tidak dicentang, set semua sub bab dalam bab tersebut
      // dengan nilai yang sama
      for (var subBab in _subBabMateriList.where((subBab) => subBab['bab_id'] == babId)) {
        _checkedSubBab[subBab['id']] = value ?? false;
      }
    });
  }

  // Navigasi ke halaman detail sub bab
  void _navigateToSubBabDetail(Map<String, dynamic> subBab, Map<String, dynamic> bab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubBabDetailPage(
          subBab: subBab,
          bab: bab,
          checked: _checkedSubBab[subBab['id']] ?? false,
          onCheckChanged: (value) {
            _handleSubBabCheck(subBab['id'], bab['id'], value);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materi Pembelajaran'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown untuk memilih mata pelajaran
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Pilih Mata Pelajaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedMataPelajaran,
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
                          _babMateriList = [];
                          _subBabMateriList = [];
                          _kontenMateriList = [];
                        });
                        if (value != null) {
                          _loadBabMateri(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Daftar Bab Materi
            Expanded(
              child: _selectedMataPelajaran == null
                  ? const Center(
                      child: Text('Pilih mata pelajaran untuk melihat materi'),
                    )
                  : _babMateriList.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _babMateriList.length,
                      itemBuilder: (context, index) {
                        final bab = _babMateriList[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ExpansionTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'BAB ${bab['urutan']}: ${bab['judul_bab']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Checkbox(
                                  value: _checkedBab[bab['id']] ?? false,
                                  onChanged: (value) {
                                    _handleBabCheck(bab['id'], value);
                                  },
                                ),
                              ],
                            ),
                            initiallyExpanded: _expandedBab[bab['id']] ?? false,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                _expandedBab[bab['id']] = expanded;
                                if (expanded) {
                                  _loadSubBabMateri(bab['id']);
                                }
                              });
                            },
                            children: [
                              _subBabMateriList.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text('Tidak ada sub-bab'),
                                    )
                                  : Column(
                                      children: _subBabMateriList.map((subBab) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                          ),
                                          child: ListTile(
                                            title: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${subBab['urutan']}. ${subBab['judul_sub_bab']}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Checkbox(
                                                  value: _checkedSubBab[subBab['id']] ?? false,
                                                  onChanged: (value) {
                                                    _handleSubBabCheck(subBab['id'], bab['id'], value);
                                                  },
                                                ),
                                              ],
                                            ),
                                            onTap: () {
                                              _navigateToSubBabDetail(subBab, bab);
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Halaman detail untuk sub bab
class SubBabDetailPage extends StatefulWidget {
  final Map<String, dynamic> subBab;
  final Map<String, dynamic> bab;
  final bool checked;
  final ValueChanged<bool?> onCheckChanged;

  const SubBabDetailPage({
    super.key,
    required this.subBab,
    required this.bab,
    required this.checked,
    required this.onCheckChanged,
  });

  @override
  _SubBabDetailPageState createState() => _SubBabDetailPageState();
}

class _SubBabDetailPageState extends State<SubBabDetailPage> {
  late bool _isChecked;
  List<dynamic> _kontenMateriList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.checked;
    _loadKontenMateri();
  }

  Future<void> _loadKontenMateri() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final kontenMateri = await ApiService.getKontenMateri(subBabId: widget.subBab['id']);

      setState(() {
        _kontenMateriList = kontenMateri
            .where((konten) => konten['sub_bab_id'] == widget.subBab['id'])
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BAB ${widget.bab['urutan']}: ${widget.bab['judul_bab']}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Checkbox(
            value: _isChecked,
            onChanged: (value) {
              setState(() {
                _isChecked = value ?? false;
              });
              widget.onCheckChanged(value);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sub Bab ${widget.subBab['urutan']}: ${widget.subBab['judul_sub_bab']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _kontenMateriList.isEmpty
                        ? const Center(child: Text('Tidak ada konten materi'))
                        : ListView(
                            children: _kontenMateriList.map((konten) {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        konten['judul_konten'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      Text(
                                        konten['isi_konten'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
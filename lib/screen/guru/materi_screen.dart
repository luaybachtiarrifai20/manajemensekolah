import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manajemensekolah/screen/guru/rpp_generate_screen.dart';
import 'package:manajemensekolah/services/api_subject_services.dart';
import 'package:manajemensekolah/services/api_teacher_services.dart';

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

  List<Map<String, dynamic>> _getCheckedBab() {
    return _babMateriList
        .where((bab) => _checkedBab[bab['id']] == true)
        .toList()
        .cast<Map<String, dynamic>>();
  }

  // Fungsi untuk mendapatkan sub bab yang dicentang
  List<Map<String, dynamic>> _getCheckedSubBab() {
    return _subBabMateriList
        .where((subBab) => _checkedSubBab[subBab['id']] == true)
        .toList()
        .cast<Map<String, dynamic>>();
  }

  // Fungsi untuk navigate ke halaman generate RPP
  void _navigateToGenerateRPP() {
    final checkedBab = _getCheckedBab();
    final checkedSubBab = _getCheckedSubBab();

    if (checkedBab.isEmpty && checkedSubBab.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih minimal 1 bab atau sub bab untuk generate RPP'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RPPGeneratePage(
          guru: widget.guru,
          selectedMataPelajaran: _selectedMataPelajaran!,
          mataPelajaranName: _getSelectedMataPelajaranName(),
          checkedBab: checkedBab,
          checkedSubBab: checkedSubBab,
        ),
      ),
    );
  }

  bool _isLoading = false;
  String _debugInfo = '';

  // Color scheme matching teaching schedule
  final Map<String, Color> _hariColorMap = {
    'Senin': Color(0xFF6366F1),
    'Selasa': Color(0xFF10B981),
    'Rabu': Color(0xFFF59E0B),
    'Kamis': Color(0xFFEF4444),
    'Jumat': Color(0xFF8B5CF6),
    'Sabtu': Color(0xFF06B6D4),
  };

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      print('Guru data received: ${widget.guru}');
    }
    if (kDebugMode) {
      print('Guru ID: ${widget.guru['id']}');
    }

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
      if (kDebugMode) {
        print('Loading data for guru ID: $guruId');
      }

      if (guruId == null || guruId.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: ID guru tidak valid')),
        );
        return;
      }

      final ApiTeacherService apiTeacherService = ApiTeacherService();
      final mataPelajaran = await apiTeacherService.getSubjectByTeacher(guruId);

      if (kDebugMode) {
        print('Mata pelajaran found: ${mataPelajaran.length}');
      }

      // Jika guru tidak memiliki mata pelajaran, tampilkan pesan
      if (mataPelajaran.isEmpty) {
        setState(() {
          _isLoading = false;
          _mataPelajaranList = [];
          _debugInfo = 'Guru ini belum memiliki mata pelajaran yang ditugaskan';
        });
        return;
      }

      final materi = await ApiSubjectService.getMateri(guruId: guruId);

      setState(() {
        _mataPelajaranList = mataPelajaran;
        _materiList = materi;
        _isLoading = false;
        _debugInfo = '${mataPelajaran.length} mata pelajaran ditemukan';

        if (mataPelajaran.isNotEmpty) {
          _selectedMataPelajaran = mataPelajaran[0]['id'];
          _loadBabMateri(_selectedMataPelajaran!);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _debugInfo = 'Error: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _loadBabMateri(String mataPelajaranId) async {
    try {
      final babMateri = await ApiSubjectService.getBabMateri(
        mataPelajaranId: mataPelajaranId,
      );

      setState(() {
        _babMateriList = babMateri;
        // Inisialisasi state expanded dan checked untuk setiap bab
        for (var bab in babMateri) {
          _expandedBab[bab['id']] = false;
          _checkedBab[bab['id']] = false;
        }
        _debugInfo = '${babMateri.length} bab materi ditemukan';
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Error: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _loadSubBabMateri(String babId) async {
    try {
      final subBabMateri = await ApiSubjectService.getSubBabMateri(
        babId: babId,
      );

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
      for (var subBab in _subBabMateriList.where(
        (subBab) => subBab['bab_id'] == babId,
      )) {
        _checkedSubBab[subBab['id']] = value ?? false;
      }
    });
  }

  // Navigasi ke halaman detail sub bab
  void _navigateToSubBabDetail(
    Map<String, dynamic> subBab,
    Map<String, dynamic> bab,
  ) {
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

  Color _getCardColor(int index) {
    final colors = [
      Color(0xFF6366F1),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Materi Pembelajaran'),
        backgroundColor: Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.auto_awesome),
            onPressed: _navigateToGenerateRPP,
            tooltip: 'Generate RPP',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          _buildHeaderSection(),

          // Filter Section
          _buildFilterSection(),

          // Content Section
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _selectedMataPelajaran == null
                ? _buildEmptyState('Pilih mata pelajaran untuk melihat materi')
                : _babMateriList.isEmpty
                ? _buildEmptyState('Tidak ada materi untuk mata pelajaran ini')
                : _buildMateriList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C73FA)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.guru['nama']?.toString() ?? 'Guru',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Materi Pembelajaran',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  // Update Filter Section untuk tambah info dan tombol
  Widget _buildFilterSection() {
    final totalChecked = _getCheckedCount();

    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Info Filter Aktif
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_alt, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _mataPelajaranList.isEmpty
                        ? 'Tidak ada mata pelajaran'
                        : '${_babMateriList.length} bab materi • ${_getSelectedMataPelajaranName()}',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  ),
                ),
                Text(
                  '$totalChecked dicentang',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),

          // Tombol Generate RPP jika ada yang dicentang
          if (totalChecked > 0) ...[
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToGenerateRPP,
                icon: Icon(Icons.auto_awesome, size: 20),
                label: Text('Generate RPP ($totalChecked dipilih)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
          ],

          // Dropdown Mata Pelajaran
          _buildMataPelajaranDropdown(),
        ],
      ),
    );
  }

  Widget _buildMataPelajaranDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mata Pelajaran',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedMataPelajaran,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              items: _mataPelajaranList.map((mp) {
                return DropdownMenuItem<String>(
                  value: mp['id'],
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.subject,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 8),
                        Expanded(child: Text(mp['nama'] ?? 'Unknown')),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedMataPelajaran = newValue;
                    _babMateriList = [];
                    _subBabMateriList = [];
                    _kontenMateriList = [];
                  });
                  _loadBabMateri(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Memuat materi...'),
          if (_debugInfo.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              _debugInfo,
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 64, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildMateriList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _babMateriList.length,
      itemBuilder: (context, index) {
        final bab = _babMateriList[index];
        final cardColor = _getCardColor(index);
        final isExpanded = _expandedBab[bab['id']] ?? false;

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Bab
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${bab['urutan']}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  bab['judul_bab'] ?? 'Judul Bab',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Bab ${bab['urutan']}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _checkedBab[bab['id']] ?? false,
                      onChanged: (value) {
                        _handleBabCheck(bab['id'], value);
                      },
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _expandedBab[bab['id']] = !isExpanded;
                    if (!isExpanded) {
                      _loadSubBabMateri(bab['id']);
                    }
                  });
                },
              ),

              // Sub Bab List (Expandable)
              if (isExpanded) ...[Divider(height: 1), _buildSubBabList(bab)],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubBabList(Map<String, dynamic> bab) {
    if (_subBabMateriList.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Tidak ada sub-bab',
          style: TextStyle(color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: _subBabMateriList.map((subBab) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getCardColor(
                    int.parse(subBab['urutan']?.toString() ?? '0'),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${subBab['urutan']}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                subBab['judul_sub_bab'] ?? 'Judul Sub Bab',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: Checkbox(
                value: _checkedSubBab[subBab['id']] ?? false,
                onChanged: (value) {
                  _handleSubBabCheck(subBab['id'], bab['id'], value);
                },
              ),
              onTap: () {
                _navigateToSubBabDetail(subBab, bab);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getSelectedMataPelajaranName() {
    if (_selectedMataPelajaran == null) return '-';
    final mp = _mataPelajaranList.firstWhere(
      (mp) => mp['id'] == _selectedMataPelajaran,
      orElse: () => {'nama': '-'},
    );
    return mp['nama'] ?? '-';
  }

  int _getCheckedCount() {
    final babChecked = _checkedBab.values.where((checked) => checked).length;
    final subBabChecked = _checkedSubBab.values
        .where((checked) => checked)
        .length;
    return babChecked + subBabChecked;
  }
}

// Halaman detail untuk sub bab (diperbarui dengan design yang sama)
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
  SubBabDetailPageState createState() => SubBabDetailPageState();
}

class SubBabDetailPageState extends State<SubBabDetailPage> {
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

      final kontenMateri = await ApiSubjectService.getContentMateri(
        subBabId: widget.subBab['id'],
      );

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Color _getCardColor(int index) {
    final colors = [
      Color(0xFF6366F1),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BAB ${widget.bab['urutan']}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            Text(
              widget.bab['judul_bab'] ?? 'Judul Bab',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Text('Selesai', style: TextStyle(fontSize: 14)),
                Checkbox(
                  value: _isChecked,
                  onChanged: (value) {
                    setState(() {
                      _isChecked = value ?? false;
                    });
                    widget.onCheckChanged(value);
                  },
                  fillColor: MaterialStateProperty.all(Colors.white),
                  checkColor: Color(0xFF4F46E5),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Sub Bab
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sub Bab ${widget.subBab['urutan']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.subBab['judul_sub_bab'] ?? 'Judul Sub Bab',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _kontenMateriList.isEmpty
                ? _buildEmptyContent()
                : _buildContentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article, size: 64, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(
            'Tidak ada konten materi',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8),
          Text(
            'Konten untuk sub bab ini belum tersedia',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _kontenMateriList.length,
      itemBuilder: (context, index) {
        final konten = _kontenMateriList[index];
        final cardColor = _getCardColor(index);

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Number Section dengan background warna
                Container(
                  width: 60,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Konten',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Section
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          konten['judul_konten'] ?? 'Judul Konten',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Text(
                          konten['isi_konten'] ?? 'Isi konten tidak tersedia',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

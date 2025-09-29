import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manajemensekolah/components/confirmation_dialog.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/components/search_bar.dart';
import 'package:manajemensekolah/services/api_class_services.dart';
import 'package:manajemensekolah/services/api_schedule_services.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/api_subject_services.dart';
import 'package:manajemensekolah/services/api_teacher_services.dart';
import 'package:manajemensekolah/utils/color_utils.dart';

class TeachingScheduleManagementScreen extends StatefulWidget {
  const TeachingScheduleManagementScreen({super.key});

  @override
  TeachingScheduleManagementScreenState createState() =>
      TeachingScheduleManagementScreenState();
}

class TeachingScheduleManagementScreenState
    extends State<TeachingScheduleManagementScreen> {
  final ApiService _apiService = ApiService();
  final ApiClassService apiServiceClass = ApiClassService();
  final ApiSubjectService _apiSubjectService = ApiSubjectService();
  final ApiTeacherService apiTeacherService = ApiTeacherService();

  List<dynamic> _jadwalList = [];
  List<dynamic> _guruList = [];
  List<dynamic> _mataPelajaranList = [];
  List<dynamic> _kelasList = [];
  bool _isLoading = true;
  String _selectedSemester = 'Ganjil';
  String _selectedTahunAjaran = '2024/2025';

  final List<String> _semesterOptions = ['Ganjil', 'Genap'];
  final List<String> _hariOptions = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final [jadwal, guru, mataPelajaran, kelas] = await Future.wait([
        ApiScheduleService.getSchedule(
          semester: _selectedSemester,
          tahunAjaran: _selectedTahunAjaran,
        ),
        apiTeacherService.getTeacher(),
        _apiSubjectService.getSubject(),
        apiServiceClass.getClass(),
      ]);

      setState(() {
        _jadwalList = jadwal;
        _guruList = guru;
        _mataPelajaranList = mataPelajaran;
        _kelasList = kelas;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _tambahJadwal() async {
    final result = await showDialog(
      context: context,
      builder: (context) => JadwalFormDialog(
        guruList: _guruList,
        mataPelajaranList: _mataPelajaranList,
        kelasList: _kelasList,
        hariOptions: _hariOptions,
        semester: _selectedSemester,
        tahunAjaran: _selectedTahunAjaran,
        apiService: _apiService,
        apiTeacherService: apiTeacherService
      ),
    );

    if (result != null) {
      try {
        await ApiScheduleService.addSchedule(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Jadwal berhasil ditambahkan'),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menambah jadwal: $e'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _editJadwal(dynamic jadwal) async {
    final result = await showDialog(
      context: context,
      builder: (context) => JadwalFormDialog(
        guruList: _guruList,
        mataPelajaranList: _mataPelajaranList,
        kelasList: _kelasList,
        hariOptions: _hariOptions,
        semester: _selectedSemester,
        tahunAjaran: _selectedTahunAjaran,
        jadwal: jadwal,
        apiService: _apiService,
        apiTeacherService: apiTeacherService
      ),
    );

    if (result != null) {
      try {
        await ApiScheduleService.updateSchedule(jadwal['id'], result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Jadwal berhasil diupdate'),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengupdate jadwal: $e'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _hapusJadwal(String id) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Hapus Jadwal',
        content: 'Apakah Anda yakin ingin menghapus jadwal ini?',
      ),
    );

    if (confirmed == true) {
      try {
        await ApiScheduleService.deleteSchedule(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Jadwal berhasil dihapus'),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus jadwal: $e'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LoadingScreen(message: 'Memuat data jadwal...');
    }

    final TextEditingController searchController = TextEditingController();
    final filteredJadwal = _jadwalList.where((jadwal) {
      final searchTerm = searchController.text.toLowerCase();
      return searchTerm.isEmpty ||
          jadwal['mata_pelajaran_nama'].toLowerCase().contains(searchTerm) ||
          jadwal['guru_nama'].toLowerCase().contains(searchTerm) ||
          jadwal['kelas_nama'].toLowerCase().contains(searchTerm);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Kelola Jadwal Mengajar',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: ColorUtils.primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header dengan Filter
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ColorUtils.primaryColor, Color(0xFF7C73FA)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Kelola Jadwal Mengajar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '$_selectedSemester • $_selectedTahunAjaran',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 16),

                // Filter Section
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterCard(
                        'Semester',
                        _selectedSemester,
                        Icons.school,
                        () => _showSemesterFilter(),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterCard(
                        'Tahun Ajaran',
                        _selectedTahunAjaran,
                        Icons.calendar_today,
                        () => _showTahunAjaranDialog(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Search Bar
          CustomSearchBar(
            controller: searchController,
            hintText: 'Cari jadwal...',
            onChanged: (value) => setState(() {}),
          ),

          // Content
          Expanded(
            child: filteredJadwal.isEmpty
                ? EmptyState(
                    title: 'Belum ada jadwal mengajar',
                    subtitle: searchController.text.isEmpty
                        ? 'Tap + untuk menambah jadwal baru'
                        : 'Tidak ditemukan hasil pencarian',
                    icon: Icons.schedule_outlined,
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredJadwal.length,
                    itemBuilder: (context, index) {
                      final jadwal = filteredJadwal[index];
                      final hari = jadwal['hari'];
                      final cardColor = ColorUtils.getHariColor(hari);

                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Material(
                          elevation: 3,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  cardColor.withValues(alpha: 0.9),
                                  cardColor.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Time Section
                                  SizedBox(
                                    width: 70,
                                    child: Column(
                                      children: [
                                        Text(
                                          jadwal['jam_mulai'].substring(0, 5),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 20,
                                          color: Colors.white10,
                                          margin: EdgeInsets.symmetric(vertical: 4),
                                        ),
                                        Text(
                                          jadwal['jam_selesai'].substring(0, 5),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Vertical Divider
                                  Container(
                                    width: 1,
                                    height: 60,
                                    margin: EdgeInsets.symmetric(horizontal: 16),
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),

                                  // Content Section
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          jadwal['mata_pelajaran_nama'],
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person,
                                              size: 16,
                                              color: Colors.white.withValues(alpha: 0.8),
                                            ),
                                            SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                jadwal['guru_nama'],
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.class_,
                                              size: 16,
                                              color: Colors.white.withValues(alpha: 0.8),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              jadwal['kelas_nama'],
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.9),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_month,
                                              size: 16,
                                              color: Colors.white.withValues(alpha: 0.8),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              hari,
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.9),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Action Buttons
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.white),
                                        onPressed: () => _editJadwal(jadwal),
                                        tooltip: 'Edit Jadwal',
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.white.withValues(alpha: 0.8),
                                        ),
                                        onPressed: () => _hapusJadwal(jadwal['id']),
                                        tooltip: 'Hapus Jadwal',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tambahJadwal,
        backgroundColor: ColorUtils.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _showTahunAjaranDialog() async {
    final TextEditingController controller = TextEditingController(text: _selectedTahunAjaran);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pilih Tahun Ajaran'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Contoh: 2024/2025'),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorUtils.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Pilih', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != _selectedTahunAjaran) {
      setState(() {
        _selectedTahunAjaran = result;
        _isLoading = true;
      });
      await _loadData();
    }
  }

  void _showSemesterFilter() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _semesterOptions.map((semester) {
              return ListTile(
                title: Text(semester),
                onTap: () => Navigator.pop(context, semester),
                selected: _selectedSemester == semester,
              );
            }).toList(),
          ),
        );
      },
    );
    if (selected != null && selected != _selectedSemester) {
      setState(() {
        _selectedSemester = selected;
        _isLoading = true;
      });
      await _loadData();
    }
  }

  Widget _buildFilterCard(String label, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label: $value',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class JadwalFormDialog extends StatefulWidget {
  final List<dynamic> guruList;
  final List<dynamic> mataPelajaranList;
  final List<dynamic> kelasList;
  final List<String> hariOptions;
  final String semester;
  final String tahunAjaran;
  final dynamic jadwal;
  final ApiService apiService;
  final ApiTeacherService apiTeacherService;

  const JadwalFormDialog({
    super.key,
    required this.guruList,
    required this.mataPelajaranList,
    required this.kelasList,
    required this.hariOptions,
    required this.semester,
    required this.tahunAjaran,
    this.jadwal,
    required this.apiService,
    required this.apiTeacherService
  });

  @override
  JadwalFormDialogState createState() => JadwalFormDialogState();
}

class JadwalFormDialogState extends State<JadwalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedGuru;
  late String _selectedMataPelajaran;
  late String _selectedKelas;
  late String _selectedHari;
  late TimeOfDay _jamMulai;
  late TimeOfDay _jamSelesai;

  List<dynamic> _filteredMataPelajaranList = [];
  bool _isLoadingMataPelajaran = false;

  @override
  void initState() {
    super.initState();
    _selectedGuru = widget.jadwal != null ? widget.jadwal['guru_id'] : '';
    _selectedMataPelajaran = widget.jadwal != null
        ? widget.jadwal['mata_pelajaran_id']
        : '';
    _selectedKelas = widget.jadwal != null ? widget.jadwal['kelas_id'] : '';
    _selectedHari = widget.jadwal != null
        ? widget.jadwal['hari']
        : widget.hariOptions.first;

    _filteredMataPelajaranList = widget.mataPelajaranList;

    if (widget.jadwal != null) {
      final jamMulaiParts = widget.jadwal['jam_mulai'].split(':');
      final jamSelesaiParts = widget.jadwal['jam_selesai'].split(':');
      _jamMulai = TimeOfDay(
        hour: int.parse(jamMulaiParts[0]),
        minute: int.parse(jamMulaiParts[1]),
      );
      _jamSelesai = TimeOfDay(
        hour: int.parse(jamSelesaiParts[0]),
        minute: int.parse(jamSelesaiParts[1]),
      );

      if (_selectedGuru.isNotEmpty) {
        _filterMataPelajaranByGuru(_selectedGuru);
      }
    } else {
      _jamMulai = TimeOfDay(hour: 7, minute: 0);
      _jamSelesai = TimeOfDay(hour: 8, minute: 0);
    }
  }

  Future<void> _filterMataPelajaranByGuru(String guruId) async {
    try {
      setState(() {
        _isLoadingMataPelajaran = true;
      });
      final mataPelajaranGuru = await widget.apiTeacherService.getSubjectByTeacher(
        guruId,
      );

      final filtered = widget.mataPelajaranList.where((mp) {
        return mataPelajaranGuru.any((mpGuru) => mpGuru['id'] == mp['id']);
      }).toList();

      setState(() {
        _filteredMataPelajaranList = filtered;
        _isLoadingMataPelajaran = false;

        if (_selectedMataPelajaran.isNotEmpty) {
          final currentMpExists = filtered.any(
            (mp) => mp['id'] == _selectedMataPelajaran,
          );
          if (!currentMpExists) {
            _selectedMataPelajaran = '';
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error filtering mata pelajaran: $e');
      }
      setState(() {
        _filteredMataPelajaranList = widget.mataPelajaranList;
        _isLoadingMataPelajaran = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat mata pelajaran guru'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isMulai) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isMulai ? _jamMulai : _jamSelesai,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: Color(0xFF4F46E5)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isMulai) {
          _jamMulai = picked;
        } else {
          _jamSelesai = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.jadwal != null ? 'Edit Jadwal' : 'Tambah Jadwal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F46E5),
              ),
            ),
            SizedBox(height: 20),
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDropdownField(
                      'Guru',
                      _selectedGuru,
                      widget.guruList,
                      'nama',
                      (value) {
                        setState(() {
                          _selectedGuru = value!;
                          _selectedMataPelajaran = '';
                        });

                        if (value != null && value.isNotEmpty) {
                          _filterMataPelajaranByGuru(value);
                        } else {
                          setState(() {
                            _filteredMataPelajaranList =
                                widget.mataPelajaranList;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mata Pelajaran',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        _isLoadingMataPelajaran
                            ? Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Memuat mata pelajaran...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _buildDropdownFieldWithoutLabel(
                                _selectedMataPelajaran,
                                _filteredMataPelajaranList,
                                'nama',
                                (value) => setState(
                                  () => _selectedMataPelajaran = value!,
                                ),
                                'Pilih Mata Pelajaran',
                              ),
                      ],
                    ),

                    SizedBox(height: 16),
                    _buildDropdownField(
                      'Kelas',
                      _selectedKelas,
                      widget.kelasList,
                      'nama',
                      (value) => setState(() => _selectedKelas = value!),
                    ),
                    SizedBox(height: 16),
                    _buildDropdownField(
                      'Hari',
                      _selectedHari,
                      widget.hariOptions
                          .map((e) => {'value': e, 'nama': e})
                          .toList(),
                      'nama',
                      (value) => setState(() => _selectedHari = value!),
                    ),
                    SizedBox(height: 16),
                    _buildTimeField('Jam Mulai', _jamMulai, true),
                    SizedBox(height: 16),
                    _buildTimeField('Jam Selesai', _jamSelesai, false),
                  ],
                ),
              ),
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
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: Colors.black, // Warna text hitam
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (_selectedGuru.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Pilih guru terlebih dahulu'),
                              backgroundColor: Colors.red.shade400,
                            ),
                          );
                          return;
                        }

                        if (_selectedMataPelajaran.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Pilih mata pelajaran terlebih dahulu',
                              ),
                              backgroundColor: Colors.red.shade400,
                            ),
                          );
                          return;
                        }

                        final data = {
                          'guru_id': _selectedGuru,
                          'mata_pelajaran_id': _selectedMataPelajaran,
                          'kelas_id': _selectedKelas,
                          'hari': _selectedHari,
                          'jam_mulai':
                              '${_jamMulai.hour.toString().padLeft(2, '0')}:${_jamMulai.minute.toString().padLeft(2, '0')}:00',
                          'jam_selesai':
                              '${_jamSelesai.hour.toString().padLeft(2, '0')}:${_jamSelesai.minute.toString().padLeft(2, '0')}:00',
                          'semester': widget.semester,
                          'tahun_ajaran': widget.tahunAjaran,
                        };
                        Navigator.pop(context, data);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Simpan',
                      style: TextStyle(
                        color: Colors.white, // Warna text putih
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<dynamic> items,
    String displayField,
    ValueChanged<String?> onChanged,
  ) {
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              initialValue: value.isEmpty ? null : value,
              items: items.map<DropdownMenuItem<String>>((item) {
                final displayValue =
                    item[displayField] ?? item['value'] ?? item.toString();
                return DropdownMenuItem<String>(
                  value: item['id'] ?? item['value'] ?? item,
                  child: Text(
                    displayValue.toString(),
                    style: TextStyle(
                      color: Colors.black, // Warna text hitam
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              validator: (value) => value == null ? 'Pilih $label' : null,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black, // Warna text hitam
              ),
              dropdownColor: Colors.white, // Background dropdown putih
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.black,
              ), // Icon hitam
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFieldWithoutLabel(
    String value,
    List<dynamic> items,
    String displayField,
    ValueChanged<String?> onChanged,
    String hintText,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonFormField<String>(
          initialValue: value.isEmpty ? null : value,
          items: items.map<DropdownMenuItem<String>>((item) {
            final displayValue =
                item[displayField] ?? item['value'] ?? item.toString();
            return DropdownMenuItem<String>(
              value: item['id'] ?? item['value'] ?? item,
              child: Text(
                displayValue.toString(),
                style: TextStyle(
                  color: Colors.black, // Warna text hitam
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey.shade600, // Warna hint abu-abu
            ),
          ),
          validator: (value) => value == null ? 'Pilih Mata Pelajaran' : null,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black, // Warna text hitam
          ),
          dropdownColor: Colors.white, // Background dropdown putih
          icon: Icon(Icons.arrow_drop_down, color: Colors.black), // Icon hitam
        ),
      ),
    );
  }

  Widget _buildTimeField(String label, TimeOfDay time, bool isMulai) {
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
        GestureDetector(
          onTap: () => _selectTime(context, isMulai),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 20, color: Colors.grey.shade600),
                SizedBox(width: 12),
                Text(
                  time.format(context),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black, // Warna text hitam
                  ),
                ),
                Spacer(),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


// JadwalFormDialog tetap sama seperti sebelumnya...
// [Kode JadwalFormDialog tetap seperti semula]
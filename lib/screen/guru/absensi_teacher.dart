import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manajemensekolah/models/siswa.dart';
import 'package:manajemensekolah/services/api_class_services.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/api_student_services.dart';
import 'package:manajemensekolah/services/api_subject_services.dart';

class AbsensiPage extends StatefulWidget {
  final Map<String, dynamic> guru;

  const AbsensiPage({super.key, required this.guru});

  @override
  AbsensiPageState createState() => AbsensiPageState();
}

class AbsensiPageState extends State<AbsensiPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String? _selectedMataPelajaran;
  String? _selectedKelas;
  List<dynamic> _mataPelajaranList = [];
  List<dynamic> _kelasList = [];
  List<Siswa> _siswaList = [];
  List<Siswa> _filteredSiswaList = [];
  final Map<String, String> _absensiStatus = {};
  int _currentStudentIndex = 0;
  bool _isLoading = true;
  int _viewMode = 0; // 0: Default, 1: Gulungan, 2: Buku Absensi
  final ScrollController _scrollController = ScrollController();
  final ApiSubjectService apiSubjectService = ApiSubjectService();
  
  // Animation controller for rolling effect
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _previousStudentIndex = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _animationController.addListener(() {
      setState(() {});
    });
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final apiServiceClass = ApiClassService();
      final [mataPelajaran, kelas, siswa] = await Future.wait([
        apiSubjectService.getMataPelajaran(),
        apiServiceClass.getKelas(),
        ApiStudentService.getSiswa(),
      ]);
      
      setState(() {
        _mataPelajaranList = mataPelajaran;
        _kelasList = kelas;
        _siswaList = siswa.map((s) => Siswa.fromJson(s)).toList();
        _filteredSiswaList = _siswaList;
        _isLoading = false;
        
        for (var siswa in _siswaList) {
          _absensiStatus[siswa.id] = 'hadir';
        }
      });
    } catch (e) {
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
        _currentStudentIndex = 0;
      });
    }
  }

  void _filterStudentsByClass(String? kelasId) {
    setState(() {
      _selectedKelas = kelasId;
      if (kelasId == null) {
        _filteredSiswaList = _siswaList;
      } else {
        _filteredSiswaList = _siswaList.where((siswa) => siswa.kelasId == kelasId).toList();
      }
      _currentStudentIndex = 0;
    });
  }

  void _nextStudent() {
    if (_filteredSiswaList.isEmpty || _isAnimating) return;
    
    setState(() {
      _previousStudentIndex = _currentStudentIndex;
      if (_viewMode == 1) {
        // Mode gulungan: hapus siswa yang sudah diabsen
        _filteredSiswaList.removeAt(_currentStudentIndex);
        if (_currentStudentIndex >= _filteredSiswaList.length) {
          _currentStudentIndex = 0;
        }
      } else {
        // Mode default atau buku: hanya increment index
        _currentStudentIndex = (_currentStudentIndex + 1) % _filteredSiswaList.length;
      }
      _isAnimating = true;
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _previousStudent() {
    if (_filteredSiswaList.isEmpty || _isAnimating) return;
    
    setState(() {
      if (_viewMode == 1) {
        // Mode gulungan tidak bisa kembali ke sebelumnya
        return;
      } else {
        // Mode default atau buku: decrement index
        _previousStudentIndex = _currentStudentIndex;
        _currentStudentIndex = (_currentStudentIndex - 1) % _filteredSiswaList.length;
        if (_currentStudentIndex < 0) {
          _currentStudentIndex = _filteredSiswaList.length - 1;
        }
      }
      _isAnimating = true;
      _animationController.reset();
      _animationController.forward();
    });
  }

  Future<void> _submitAbsensi() async {
    if (_selectedMataPelajaran == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata pelajaran terlebih dahulu')),
      );
      return;
    }

    try {
      for (var siswa in _siswaList) {
        await ApiService.tambahAbsensi({
          'siswa_id': siswa.id,
          'guru_id': widget.guru['id'],
          'mata_pelajaran_id': _selectedMataPelajaran,
          'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'status': _absensiStatus[siswa.id] ?? 'hadir',
          'keterangan': '',
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absensi berhasil disimpan')),
      );
      
      setState(() {
        _currentStudentIndex = 0;
        _filteredSiswaList = _siswaList;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'izin':
        return Colors.blue;
      case 'sakit':
        return Colors.orange;
      case 'alpha':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  Widget _buildMinimalStudentCard(Siswa siswa, {bool isRolling = false, double scale = 1.0, double opacity = 1.0}) {
    final status = _absensiStatus[siswa.id] ?? 'hadir';
    Color statusColor = _getStatusColor(status);

    return Container(
      height: 60, // Fixed height for each student row
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: isRolling ? 0.3 * opacity : 0.1),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Center(
        child: Text(
          siswa.nama,
          style: TextStyle(
            fontSize: isRolling ? 20 * scale : 18,
            fontWeight: FontWeight.bold,
            color: statusColor.withValues(alpha: opacity),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStatusButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatusButton('Hadir', Colors.green, Icons.check_circle),
        _buildStatusButton('Izin', Colors.blue, Icons.event_available),
        _buildStatusButton('Sakit', Colors.orange, Icons.medical_services),
        _buildStatusButton('Alpha', Colors.red, Icons.cancel),
      ],
    );
  }

  Widget _buildStatusButton(String status, Color color, IconData icon) {
    final currentStatus = _absensiStatus[_filteredSiswaList.isNotEmpty ? _filteredSiswaList[_currentStudentIndex].id : ''] ?? 'hadir';
    final isSelected = currentStatus == status.toLowerCase();

    return ElevatedButton.icon(
      onPressed: () {
        if (_filteredSiswaList.isNotEmpty) {
          setState(() {
            _absensiStatus[_filteredSiswaList[_currentStudentIndex].id] = status.toLowerCase();
          });
          
          // Auto next untuk mode gulungan
          if (_viewMode == 1 && _filteredSiswaList.length > 1) {
            Future.delayed(const Duration(milliseconds: 300), _nextStudent);
          }
        }
      },
      icon: Icon(icon, color: isSelected ? Colors.white : color),
      label: Text(status),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withValues(alpha: 0.1),
        foregroundColor: isSelected ? Colors.white : color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color),
        ),
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildViewModeButton(0, Icons.view_carousel, 'Default'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildViewModeButton(1, Icons.view_stream, 'Gulungan'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildViewModeButton(2, Icons.list, 'Buku Absensi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeButton(int mode, IconData icon, String label) {
    final isSelected = _viewMode == mode;
    
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _viewMode = mode;
          _currentStudentIndex = 0;
        });
      },
      icon: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.blue),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.blue,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.blue),
        ),
      ),
    );
  }

  Widget _buildDefaultView() {
    return Column(
      children: [
        if (_filteredSiswaList.isNotEmpty)
          LinearProgressIndicator(
            value: (_currentStudentIndex + 1) / _filteredSiswaList.length,
            backgroundColor: Colors.grey[300],
            color: Colors.blue,
          ),

        const SizedBox(height: 20),

        _filteredSiswaList.isEmpty
            ? const Center(
                child: Text(
                  'Tidak ada siswa',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMinimalStudentCard(_filteredSiswaList[_currentStudentIndex]),

                  const SizedBox(height: 30),

                  _buildStatusButtons(),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _previousStudent,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Sebelumnya'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _nextStudent,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Selanjutnya'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

        const SizedBox(height: 20),

        if (_filteredSiswaList.isNotEmpty)
          Text(
            '${_currentStudentIndex + 1} dari ${_filteredSiswaList.length} siswa',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
      ],
    );
  }

  Widget _buildRollingWheelView() {
    return Column(
      children: [
        if (_filteredSiswaList.isNotEmpty)
          LinearProgressIndicator(
            value: 1 - (_filteredSiswaList.length / _siswaList.length),
            backgroundColor: Colors.grey[300],
            color: Colors.green,
          ),

        const SizedBox(height: 20),

        _filteredSiswaList.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      'Semua siswa telah diabsen',
                      style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            : Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey, width: 3),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'ABSENSI SISWA',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      
                      // Area gulungan (wheel)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Next students (blurred and smaller)
                              if (_filteredSiswaList.length > 1)
                                ..._buildNextStudents(),
                              
                              // Current student (main)
                              Transform.translate(
                                offset: Offset(0, -80 * _animation.value),
                                child: Opacity(
                                  opacity: 1 - _animation.value * 0.5,
                                  child: _buildStudentWheelItem(
                                    _filteredSiswaList[_currentStudentIndex],
                                    isCurrent: true,
                                  ),
                                ),
                              ),
                              
                              // Previous student (moving out)
                              if (_isAnimating && _filteredSiswaList.isNotEmpty)
                                Transform.translate(
                                  offset: Offset(0, 80 * _animation.value),
                                  child: Opacity(
                                    opacity: 0.5 - _animation.value * 0.5,
                                    child: _buildStudentWheelItem(
                                      _filteredSiswaList[_previousStudentIndex],
                                      isCurrent: false,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Info siswa saat ini
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Siswa: ${_currentStudentIndex + 1}/${_filteredSiswaList.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Status: ${_absensiStatus[_filteredSiswaList.isNotEmpty ? _filteredSiswaList[_currentStudentIndex].id : '']}'.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(_absensiStatus[_filteredSiswaList.isNotEmpty ? _filteredSiswaList[_currentStudentIndex].id : ''] ?? 'hadir'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

        const SizedBox(height: 20),

        if (_filteredSiswaList.isNotEmpty) _buildStatusButtons(),

        const SizedBox(height: 20),

        if (_filteredSiswaList.isNotEmpty)
          Text(
            'Siswa tersisa: ${_filteredSiswaList.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
      ],
    );
  }

  List<Widget> _buildNextStudents() {
    List<Widget> widgets = [];
    int nextIndex = (_currentStudentIndex + 1) % _filteredSiswaList.length;
    
    // Add up to 3 next students with decreasing opacity and size
    for (int i = 0; i < 3 && i < _filteredSiswaList.length - 1; i++) {
      widgets.add(
        Transform.translate(
          offset: Offset(0, 60 + i * 40),
          child: Opacity(
            opacity: 0.6 - i * 0.2,
            child: Transform.scale(
              scale: 0.9 - i * 0.1,
              child: _buildStudentWheelItem(
                _filteredSiswaList[nextIndex],
                isCurrent: false,
              ),
            ),
          ),
        ),
      );
      
      nextIndex = (nextIndex + 1) % _filteredSiswaList.length;
    }
    
    return widgets;
  }

  Widget _buildStudentWheelItem(Siswa siswa, {bool isCurrent = false}) {
    final status = _absensiStatus[siswa.id] ?? 'hadir';
    Color statusColor = _getStatusColor(status);

    return Container(
      width: isCurrent ? 250 : 200,
      height: isCurrent ? 70 : 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: isCurrent ? 0.3 : 0.2),
        border: Border.all(color: statusColor.withValues(alpha: 0.7), width: isCurrent ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isCurrent ? [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ] : null,
      ),
      child: Center(
        child: Text(
          siswa.nama,
          style: TextStyle(
            fontSize: isCurrent ? 22 : 16,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: statusColor,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildBookView() {
    return Expanded(
      child: ListView.builder(
        itemCount: _filteredSiswaList.length,
        itemBuilder: (context, index) {
          final siswa = _filteredSiswaList[index];
          final status = _absensiStatus[siswa.id] ?? 'hadir';
          
          Color statusColor = _getStatusColor(status);
          // String statusText = 'Hadir';

          // switch (status) {
          //   case 'izin':
          //     statusText = 'Izin';
          //     break;
          //   case 'sakit':
          //     statusText = 'Sakit';
          //     break;
          //   case 'alpha':
          //     statusText = 'Alpha';
          //     break;
          // }

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.2),
                child: Text(
                  siswa.nama[0],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              title: Text(siswa.nama),
              subtitle: Text('NIS: ${siswa.nis}'),
              trailing: DropdownButton<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                  DropdownMenuItem(value: 'izin', child: Text('Izin')),
                  DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                  DropdownMenuItem(value: 'alpha', child: Text('Alpha')),
                ],
                onChanged: (value) {
                  setState(() {
                    _absensiStatus[siswa.id] = value!;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Absensi Siswa'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Siswa'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildViewModeSelector(),
              
              Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tanggal:'),
                          TextButton(
                            onPressed: () => _selectDate(context),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedKelas,
                        decoration: const InputDecoration(
                          labelText: 'Filter Kelas',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Semua Kelas')),
                          ..._kelasList.map((kelas) => DropdownMenuItem(
                                value: kelas['id'],
                                child: Text(kelas['nama']),
                              )),
                        ],
                        onChanged: _filterStudentsByClass,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMataPelajaran,
                        decoration: const InputDecoration(
                          labelText: 'Mata Pelajaran',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Tampilan berdasarkan mode yang dipilih
              if (_viewMode == 0) 
                Expanded(child: SingleChildScrollView(child: _buildDefaultView())),
              
              if (_viewMode == 1) 
                Expanded(child: _buildRollingWheelView()),
              
              if (_viewMode == 2) 
                _buildBookView(),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _submitAbsensi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'SIMPAN ABSENSI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
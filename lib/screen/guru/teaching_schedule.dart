import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_schedule_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeachingScheduleScreen extends StatefulWidget {
  const TeachingScheduleScreen({super.key});

  @override
  TeachingScheduleScreenState createState() => TeachingScheduleScreenState();
}

class TeachingScheduleScreenState extends State<TeachingScheduleScreen> {
  List<dynamic> _jadwalList = [];
  bool _isLoading = true;
  String _guruId = '';
  String _selectedHari = 'Semua Hari'; // Default: Semua Hari
  String _selectedSemester = 'Ganjil';
  final String _selectedTahunAjaran = '2024/2025';

  // Opsi hari sekarang termasuk "Semua Hari"
  final List<String> _hariOptions = ['Semua Hari', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
  final List<String> _semesterOptions = ['Ganjil', 'Genap'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = json.decode(prefs.getString('user') ?? '{}');
      setState(() => _guruId = userData['id'] ?? '');
      _loadJadwal();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadJadwal() async {
    if (_guruId.isEmpty) return;

    try {
      // Jika "Semua Hari" dipilih, kirim string kosong ke API
      final jadwal = await ApiScheduleService.getSchedule(
        guruId: _guruId,
        hari: _selectedHari == 'Semua Hari' ? '' : _selectedHari,
        semester: _selectedSemester,
        tahunAjaran: _selectedTahunAjaran,
      );

      setState(() {
        _jadwalList = jadwal;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading jadwal: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat jadwal: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  Color _getHariColor(String hari) {
    final Map<String, Color> hariColorMap = {
      'Senin': Color(0xFF6366F1),
      'Selasa': Color(0xFF10B981),
      'Rabu': Color(0xFFF59E0B),
      'Kamis': Color(0xFFEF4444),
      'Jumat': Color(0xFF8B5CF6),
      'Sabtu': Color(0xFF06B6D4),
      'Minggu': Color(0xFFEC4899),
    };
    return hariColorMap[hari] ?? Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Jadwal Mengajar',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF4F46E5),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadJadwal,
            tooltip: 'Refresh Jadwal',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Memuat jadwal...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header dengan informasi filter
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4F46E5), Color(0xFF7C73FA)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal Mengajar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _selectedHari == 'Semua Hari' 
                            ? 'Semua Hari • $_selectedSemester • $_selectedTahunAjaran'
                            : '$_selectedHari • $_selectedSemester • $_selectedTahunAjaran',
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
                            child: _buildFilterChip(
                              'Hari',
                              _selectedHari,
                              Icons.calendar_today,
                              () => _showHariFilter(),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildFilterChip(
                              'Semester',
                              _selectedSemester,
                              Icons.school,
                              () => _showSemesterFilter(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Content
                Expanded(
                  child: _jadwalList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Tidak ada jadwal mengajar',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _selectedHari == 'Semua Hari'
                                    ? 'Untuk semester $_selectedSemester'
                                    : 'Untuk hari $_selectedHari',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _jadwalList.length,
                          itemBuilder: (context, index) {
                            final jadwal = _jadwalList[index];
                            final hari = jadwal['hari'];
                            final cardColor = _getHariColor(hari);
                            
                            return Container(
                              margin: EdgeInsets.only(bottom: 16),
                              child: Material(
                                elevation: 2,
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
                                                color: Colors.white.withValues(alpha: 0.5),
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
                                                  Icon(Icons.class_, size: 16, color: Colors.white.withValues(alpha: 0.8)),
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
                                                  Icon(Icons.calendar_month, size: 16, color: Colors.white.withValues(alpha: 0.8)),
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
                                        
                                        // Hari Badge
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            hari,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
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
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _showHariFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(
        'Pilih Hari',
        _hariOptions,
        _selectedHari,
        (value) {
          setState(() => _selectedHari = value);
          _loadJadwal();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSemesterFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(
        'Pilih Semester',
        _semesterOptions,
        _selectedSemester,
        (value) {
          setState(() => _selectedSemester = value);
          _loadJadwal();
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildFilterBottomSheet(String title, List<String> options, String selectedValue, ValueChanged<String> onSelected) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Divider(height: 1),
          ...options.map((option) => ListTile(
            title: Text(option),
            trailing: option == selectedValue 
                ? Icon(Icons.check, color: Color(0xFF4F46E5))
                : null,
            onTap: () => onSelected(option),
          )),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
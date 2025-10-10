// screen/guru/absensi_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manajemensekolah/models/siswa.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/api_student_services.dart';

class AbsensiDetailPage extends StatefulWidget {
  final Map<String, dynamic> guru;
  final String mataPelajaranId;
  final String mataPelajaranNama;
  final DateTime tanggal;

  const AbsensiDetailPage({
    super.key,
    required this.guru,
    required this.mataPelajaranId,
    required this.mataPelajaranNama,
    required this.tanggal,
  });

  @override
  State<AbsensiDetailPage> createState() => _AbsensiDetailPageState();
}

class _AbsensiDetailPageState extends State<AbsensiDetailPage> {
  List<dynamic> _absensiData = [];
  List<Siswa> _siswaList = [];
  final Map<String, String> _absensiStatus = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load siswa dan absensi data
      final [siswaData, absensiData] = await Future.wait([
        ApiStudentService.getStudent(),
        ApiService.getAbsensi(
          guruId: widget.guru['id'],
          mataPelajaranId: widget.mataPelajaranId,
          tanggal: DateFormat('yyyy-MM-dd').format(widget.tanggal),
        ),
      ]);

      setState(() {
        _siswaList = siswaData.map((s) => Siswa.fromJson(s)).toList();
        _absensiData = absensiData;

        // Map status absensi
        for (var absen in _absensiData) {
          _absensiStatus[absen['siswa_id']] = absen['status'];
        }

        // Set default untuk siswa yang belum ada data
        for (var siswa in _siswaList) {
          _absensiStatus[siswa.id] ??= 'hadir';
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading absensi detail: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStudentItem(Siswa siswa) {
    final status = _absensiStatus[siswa.id] ?? 'hadir';
    final Color statusColor = _getStatusColor(status);
    final String statusText = _getStatusText(status);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getAvatarColor(siswa.nama),
        child: Text(
          siswa.nama.isNotEmpty ? siswa.nama[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(siswa.nama),
      subtitle: Text('NIS: ${siswa.nis}'),
      trailing: DropdownButton<String>(
        value: status,
        items: const [
          DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
          DropdownMenuItem(value: 'terlambat', child: Text('Terlambat')),
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
    );
  }

  Future<void> _updateAbsensi() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      int successCount = 0;

      for (var siswa in _siswaList) {
        final status = _absensiStatus[siswa.id]!;
        
        await ApiService.tambahAbsensi({
          'siswa_id': siswa.id,
          'guru_id': widget.guru['id'],
          'mata_pelajaran_id': widget.mataPelajaranId,
          'tanggal': DateFormat('yyyy-MM-dd').format(widget.tanggal),
          'status': status,
          'keterangan': '',
        });

        successCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil update $successCount absensi')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Helper functions (sama seperti di PresencePage)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'izin': return Colors.blue;
      case 'sakit': return Colors.orange;
      case 'alpha': return Colors.red;
      case 'terlambat': return Colors.purple;
      default: return Colors.green;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'izin': return 'Izin';
      case 'sakit': return 'Sakit';
      case 'alpha': return 'Alpha';
      case 'terlambat': return 'Terlambat';
      default: return 'Hadir';
    }
  }

  Color _getAvatarColor(String nama) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    final index = nama.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Absensi - ${widget.mataPelajaranNama}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Info
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          widget.mataPelajaranNama,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('dd MMMM yyyy').format(widget.tanggal),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                // Student List
                Expanded(
                  child: ListView.builder(
                    itemCount: _siswaList.length,
                    itemBuilder: (context, index) => _buildStudentItem(_siswaList[index]),
                  ),
                ),
                // Update Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _updateAbsensi,
                    icon: const Icon(Icons.update),
                    label: Text(_isSubmitting ? 'Mengupdate...' : 'Update Absensi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
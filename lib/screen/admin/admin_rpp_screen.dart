import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/utils/color_utils.dart';

class AdminRppScreen extends StatefulWidget {
  final String? teacherId;
  final String? teacherName;

  const AdminRppScreen({super.key, this.teacherId, this.teacherName});

  @override
  State<AdminRppScreen> createState() => _AdminRppScreenState();
}

class _AdminRppScreenState extends State<AdminRppScreen> {
  List<dynamic> _rppList = [];
  List<dynamic> _filteredRppList = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterStatus = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadRppByTeacher();
  }

  Future<void> _loadRppByTeacher() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final rppData = await ApiService.getRPP();

      List<dynamic> filteredData;
      if (widget.teacherId != null) {
        filteredData = rppData
            .where((rpp) => rpp['guru_id']?.toString() == widget.teacherId)
            .toList();
      } else {
        filteredData = rppData;
      }

      setState(() {
        _rppList = filteredData;
        _filteredRppList = filteredData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadAllRpp() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final rppData = await ApiService.getRPP();

      setState(() {
        _rppList = rppData;
        _filteredRppList = rppData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _filterRpp(String status) {
    setState(() {
      _filterStatus = status;
      if (status == 'Semua') {
        _filteredRppList = _rppList;
      } else {
        _filteredRppList = _rppList
            .where((rpp) => rpp['status'] == status)
            .toList();
      }
    });
  }

  void _updateStatus(String rppId, String status) {
    showDialog(
      context: context,
      builder: (context) => UpdateStatusDialog(
        rppId: rppId,
        currentStatus: _rppList.firstWhere(
          (rpp) => rpp['id'] == rppId,
        )['status'],
        onStatusUpdated: _loadAllRpp,
      ),
    );
  }

  void _lihatDetailRpp(Map<String, dynamic> rpp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RppAdminDetailPage(rpp: rpp),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return Colors.green;
      case 'Menunggu':
        return Colors.orange;
      case 'Ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Disetujui':
        return Icons.check_circle;
      case 'Menunggu':
        return Icons.access_time;
      case 'Ditolak':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.teacherName != null
              ? 'RPP - ${widget.teacherName}'
              : 'Kelola RPP - Admin',
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
        leading: widget.teacherId != null
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadRppByTeacher,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade300),
        ),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  'Filter Status:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField(
                    value: _filterStatus,
                    items: ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'].map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) => _filterRpp(value!),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1),
          // List Section
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Terjadi kesalahan',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAllRpp,
                          child: Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : _filteredRppList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada RPP',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _filterStatus == 'Semua' 
                            ? 'Belum ada RPP yang dibuat'
                            : 'Tidak ada RPP dengan status $_filterStatus',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _filteredRppList.length,
                    itemBuilder: (context, index) {
                      final rpp = _filteredRppList[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _getStatusColor(rpp['status']).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getStatusIcon(rpp['status']),
                              color: _getStatusColor(rpp['status']),
                              size: 24,
                            ),
                          ),
                          title: Text(
                            rpp['judul'] ?? '-',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                '${rpp['mata_pelajaran_nama'] ?? '-'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              if (rpp['kelas_nama'] != null) 
                                Text(
                                  'Kelas: ${rpp['kelas_nama']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              SizedBox(height: 4),
                              Text(
                                'Oleh: ${rpp['guru_nama'] ?? '-'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(rpp['status']),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              rpp['status'] == 'Menunggu' ? 'Menunggu' :
                              rpp['status'] == 'Disetujui' ? 'Disetujui' : 'Ditolak',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () => _lihatDetailRpp(rpp),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class UpdateStatusDialog extends StatefulWidget {
  final String rppId;
  final String currentStatus;
  final VoidCallback onStatusUpdated;

  const UpdateStatusDialog({
    super.key,
    required this.rppId,
    required this.currentStatus,
    required this.onStatusUpdated,
  });

  @override
  State<UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<UpdateStatusDialog> {
  String _selectedStatus = 'Menunggu';
  final _catatanController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == widget.currentStatus) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await ApiService.updateStatusRPP(
        widget.rppId,
        _selectedStatus,
        catatan: _catatanController.text.isNotEmpty
            ? _catatanController.text
            : null,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onStatusUpdated();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status RPP berhasil diupdate')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Status RPP'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: ['Menunggu', 'Disetujui', 'Ditolak'].map((status) {
                return DropdownMenuItem(
                  value: status, 
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _catatanController,
              decoration: InputDecoration(
                labelText: 'Catatan (Opsional)',
                border: OutlineInputBorder(),
                hintText: 'Berikan catatan untuk guru...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : _updateStatus,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorUtils.primaryColor,
          ),
          child: _isUpdating
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Update',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}

// Halaman Detail RPP untuk Admin
class RppAdminDetailPage extends StatelessWidget {
  final Map<String, dynamic> rpp;

  const RppAdminDetailPage({super.key, required this.rpp});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Detail RPP',
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
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'approve') {
                _showUpdateStatusDialog(context, 'Disetujui');
              } else if (value == 'reject') {
                _showUpdateStatusDialog(context, 'Ditolak');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'approve',
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('Setujui RPP'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reject',
                child: Row(
                  children: [
                    Icon(Icons.close, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Tolak RPP'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan status
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rpp['judul'] ?? '-',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(rpp['status']),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      rpp['status'] == 'Menunggu' ? 'Menunggu' :
                      rpp['status'] == 'Disetujui' ? 'Disetujui' : 'Ditolak',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Informasi Detail
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi RPP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildDetailItem('Guru Pengajar', rpp['guru_nama'] ?? '-'),
                  _buildDetailItem('Mata Pelajaran', rpp['mata_pelajaran_nama'] ?? '-'),
                  _buildDetailItem('Kelas', rpp['kelas_nama'] ?? '-'),
                  _buildDetailItem('Semester', rpp['semester'] ?? '-'),
                  _buildDetailItem('Tahun Ajaran', rpp['tahun_ajaran'] ?? '-'),
                  _buildDetailItem('Tanggal Dibuat', rpp['created_at']?.toString().substring(0, 10) ?? '-'),
                  
                  if (rpp['catatan_admin'] != null) ...[
                    SizedBox(height: 8),
                    Divider(),
                    SizedBox(height: 8),
                    Text(
                      'Catatan Admin',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      rpp['catatan_admin']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // File Attachment
            if (rpp['file_path'] != null) ...[
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lampiran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fitur download akan datang...')),
                        );
                      },
                      icon: Icon(Icons.download),
                      label: Text('Download RPP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorUtils.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showUpdateStatusDialog(BuildContext context, String status) {
    showDialog(
      context: context,
      builder: (context) => UpdateStatusDialog(
        rppId: rpp['id'],
        currentStatus: rpp['status'],
        onStatusUpdated: () {
          Navigator.pop(context); // Tutup dialog detail
          Navigator.pop(context); // Kembali ke list
          // TODO: Refresh data atau navigasi ulang
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return Colors.green;
      case 'Menunggu':
        return Colors.orange;
      case 'Ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
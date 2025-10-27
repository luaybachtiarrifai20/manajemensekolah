import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/utils/color_utils.dart';
import 'package:manajemensekolah/utils/language_utils.dart';

class RppScreen extends StatefulWidget {
  final String guruId;
  final String guruName;

  const RppScreen({super.key, required this.guruId, required this.guruName});

  @override
  RppScreenState createState() => RppScreenState();
}

class RppScreenState extends State<RppScreen> {
  List<dynamic> _rppList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRpp();
  }

  Future<void> _loadRpp() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final rppData = await ApiService.getRPP(guruId: widget.guruId);

      setState(() {
        _rppList = rppData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _tambahRpp() {
    showDialog(
      context: context,
      builder: (context) =>
          RppFormDialog(guruId: widget.guruId, onSaved: _loadRpp),
    );
  }

  void _lihatDetailRpp(Map<String, dynamic> rpp) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RppDetailPage(rpp: rpp)),
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

  Color _getPrimaryColor() {
    return ColorUtils.getRoleColor('guru');
  }

  LinearGradient _getCardGradient() {
    final primaryColor = _getPrimaryColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, primaryColor.withOpacity(0.7)],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: _getCardGradient(),
        boxShadow: [
          BoxShadow(
            color: _getPrimaryColor().withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.rppList.tr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      AppLocalizations.viewAndManageRpp.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadRpp,
                tooltip: AppLocalizations.refresh.tr,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRppContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${AppLocalizations.error.tr}: $_errorMessage'),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _loadRpp, child: Text('Coba Lagi')),
          ],
        ),
      );
    }

    if (_rppList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              AppLocalizations.noRppCreated.tr,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              AppLocalizations.clickPlusToCreate.tr,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _rppList.length,
      itemBuilder: (context, index) {
        final rpp = _rppList[index];
        return _buildRppCard(rpp);
      },
    );
  }

  Widget _buildRppCard(Map<String, dynamic> rpp) {
    return GestureDetector(
      onTap: () => _lihatDetailRpp(rpp),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _lihatDetailRpp(rpp),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 5,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Strip berwarna di pinggir kiri
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 6,
                      decoration: BoxDecoration(
                        color: _getStatusColor(rpp['status']),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  // Background pattern effect
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // Status badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(rpp['status']),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rpp['status'] == 'Menunggu'
                            ? AppLocalizations.pending.tr
                            : rpp['status'] == 'Disetujui'
                            ? AppLocalizations.approved.tr
                            : AppLocalizations.rejected.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Judul
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rpp['judul'] ?? '-',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    rpp['mata_pelajaran_nama'] ?? '-',
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

                        if (rpp['kelas_nama'] != null) ...[
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _getPrimaryColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.class_,
                                  color: _getPrimaryColor(),
                                  size: 12,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kelas',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 1),
                                    Text(
                                      rpp['kelas_nama'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header dengan gradient seperti presence_teacher
          _buildHeader(),

          // Content
          Expanded(child: _buildRppContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tambahRpp,
        backgroundColor: ColorUtils.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// RppFormDialog tetap sama seperti sebelumnya
class RppFormDialog extends StatefulWidget {
  final String guruId;
  final VoidCallback onSaved;

  const RppFormDialog({super.key, required this.guruId, required this.onSaved});

  @override
  State<RppFormDialog> createState() => _RppFormDialogState();
}

class _RppFormDialogState extends State<RppFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _tahunAjaranController = TextEditingController();

  String? _selectedMataPelajaranId;
  String? _selectedKelasId;
  String? _selectedSemester = 'Ganjil';
  String? _selectedFileName;
  File? _selectedFile;
  bool _isUploading = false;

  List<dynamic> _mataPelajaranList = [];
  List<dynamic> _kelasList = [];

  @override
  void initState() {
    super.initState();
    _loadMataPelajaranByGuru();
    _tahunAjaranController.text = DateTime.now().year.toString();
  }

  Future<void> _loadMataPelajaranByGuru() async {
    try {
      final apiService = ApiService();
      final result = await apiService.get(
        '/guru/${widget.guruId}/mata-pelajaran',
      );
      setState(() {
        _mataPelajaranList = result is List ? result : [];
      });
    } catch (e) {
      print('Error loading mata pelajaran by guru: $e');
      _loadAllMataPelajaran();
    }
  }

  Future<void> _loadAllMataPelajaran() async {
    try {
      final apiService = ApiService();
      final result = await apiService.get('/mata-pelajaran');
      setState(() {
        _mataPelajaranList = result is List ? result : [];
      });
    } catch (e) {
      print('Error loading all mata pelajaran: $e');
    }
  }

  Future<void> _loadKelasByMataPelajaran(String mataPelajaranId) async {
    try {
      final apiService = ApiService();
      final result = await apiService.get(
        '/kelas-by-mata-pelajaran?mata_pelajaran_id=$mataPelajaranId',
      );
      setState(() {
        _kelasList = result is List ? result : [];
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading kelas by mata pelajaran: $e');
        setState(() {
          _kelasList = [];
        });
      }
    }
  }

  void _showFilePickerDialog() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        PlatformFile file = result.files.first;

        // Pastikan file benar-benar ada
        File selectedFile = File(file.path!);
        bool fileExists = await selectedFile.exists();

        print('File picked: ${file.name}');
        print('File path: ${file.path}');
        print('File exists: $fileExists');
        print('File size: ${file.size} bytes');

        if (fileExists) {
          setState(() {
            _selectedFileName = file.name;
            _selectedFile = selectedFile;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File dipilih: ${file.name} (${file.size} bytes)'),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File tidak ditemukan di path tersebut'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('Pemilihan file dibatalkan atau path null');
      }
    } catch (e) {
      print('Error memilih file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error memilih file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setSelectedFile(String fileName) {
    setState(() {
      _selectedFileName = fileName;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      String? filePath;

      // Debug: Cek apakah file ada
      print('File selected: $_selectedFile');
      print('File name: $_selectedFileName');

      if (_selectedFile != null) {
        try {
          print('Starting file upload...');
          final uploadResult = await ApiService.uploadFileRPP(_selectedFile!);
          print('Upload result: $uploadResult');

          filePath = uploadResult['file_path'];
          print('File uploaded successfully: $filePath');
        } catch (uploadError) {
          print('Error during file upload: $uploadError');
          // Tetap lanjut tanpa file jika upload gagal
          filePath = null;
        }
      } else {
        print('No file selected for upload');
      }

      // Debug data yang akan dikirim
      print('Submitting RPP data:');
      print('- Guru ID: ${widget.guruId}');
      print('- Mata Pelajaran ID: $_selectedMataPelajaranId');
      print('- Kelas ID: $_selectedKelasId');
      print('- Judul: ${_judulController.text}');
      print('- File Path: $filePath');

      // Submit data RPP
      await ApiService.tambahRPP({
        'guru_id': widget.guruId,
        'mata_pelajaran_id': _selectedMataPelajaranId,
        'kelas_id': _selectedKelasId,
        'judul': _judulController.text,
        'semester': _selectedSemester,
        'tahun_ajaran': _tahunAjaranController.text,
        'file_path': filePath,
      });

      print('RPP created successfully');

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.rppCreatedSuccess.tr)),
      );
    } catch (e) {
      print('Error creating RPP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.error.tr}: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.createRpp.tr),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _judulController,
                decoration: InputDecoration(
                  labelText: '${AppLocalizations.title.tr} *',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.titleRequired.tr;
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              DropdownButtonFormField(
                decoration: InputDecoration(
                  labelText: '${AppLocalizations.subject.tr} *',
                ),
                items: _mataPelajaranList.map((mp) {
                  return DropdownMenuItem(
                    value: mp['id'],
                    child: Text(mp['nama'] ?? mp['name'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMataPelajaranId = value as String?;
                    _selectedKelasId = null;
                    if (value != null) {
                      _loadKelasByMataPelajaran(value);
                    } else {
                      _kelasList = [];
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return AppLocalizations.subjectRequired.tr;
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              DropdownButtonFormField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.class_.tr,
                ),
                initialValue: _selectedKelasId,
                items: _kelasList.map((kelas) {
                  return DropdownMenuItem(
                    value: kelas['id'],
                    child: Text(kelas['nama'] ?? kelas['name'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedKelasId = value as String?;
                  });
                },
              ),
              SizedBox(height: 10),
              DropdownButtonFormField(
                decoration: InputDecoration(
                  labelText: '${AppLocalizations.semester.tr} *',
                ),
                initialValue: _selectedSemester,
                items: ['Ganjil', 'Genap'].map((semester) {
                  return DropdownMenuItem(
                    value: semester,
                    child: Text(semester),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSemester = value;
                  });
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _tahunAjaranController,
                decoration: InputDecoration(
                  labelText: '${AppLocalizations.academicYear.tr} *',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.academicYearRequired.tr;
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _showFilePickerDialog,
                icon: Icon(Icons.attach_file),
                label: Text(
                  _selectedFileName ?? AppLocalizations.chooseFile.tr,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.blue,
                  side: BorderSide(color: Colors.blue),
                ),
              ),
              if (_selectedFileName != null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'File: $_selectedFileName',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 8),
              Text(
                AppLocalizations.supportedFormats.tr,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.cancel.tr),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _submitForm,
          child: _isUploading
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppLocalizations.createRpp.tr),
        ),
      ],
    );
  }
}

// Halaman Detail RPP yang baru
class RppDetailPage extends StatelessWidget {
  final Map<String, dynamic> rpp;

  const RppDetailPage({super.key, required this.rpp});

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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade300),
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(rpp['status']),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      rpp['status'] == 'Menunggu'
                          ? 'Menunggu'
                          : rpp['status'] == 'Disetujui'
                          ? 'Disetujui'
                          : 'Ditolak',
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
                  _buildDetailItem(
                    'Mata Pelajaran',
                    rpp['mata_pelajaran_nama'] ?? '-',
                  ),
                  _buildDetailItem('Kelas', rpp['kelas_nama'] ?? '-'),
                  _buildDetailItem('Semester', rpp['semester'] ?? '-'),
                  _buildDetailItem('Tahun Ajaran', rpp['tahun_ajaran'] ?? '-'),
                  _buildDetailItem(
                    'Tanggal Dibuat',
                    rpp['created_at']?.toString().substring(0, 10) ?? '-',
                  ),

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
                          SnackBar(
                            content: Text('Fitur download akan datang...'),
                          ),
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
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
            child: Text(value, style: TextStyle(color: Colors.grey[800])),
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

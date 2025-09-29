import 'package:flutter/material.dart';
import 'package:manajemensekolah/components/confirmation_dialog.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/error_screen.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/components/search_bar.dart';
import 'package:manajemensekolah/components/subject_list_item.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/utils/color_utils.dart';

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  SubjectManagementScreenState createState() => SubjectManagementScreenState();
}

class SubjectManagementScreenState extends State<SubjectManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _mataPelajaranList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMataPelajaran();
  }

  Future<void> _loadMataPelajaran() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await _apiService.get('/mata-pelajaran');
      setState(() {
        _mataPelajaranList = response;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data mata pelajaran';
      });
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? mataPelajaran}) {
    final kodeController = TextEditingController(text: mataPelajaran?['kode']);
    final namaController = TextEditingController(text: mataPelajaran?['nama']);
    final deskripsiController = TextEditingController(text: mataPelajaran?['deskripsi']);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mataPelajaran == null ? 'Tambah Mata Pelajaran' : 'Edit Mata Pelajaran',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ColorUtils.primaryColor,
                ),
              ),
              SizedBox(height: 20),
              _buildTextField('Kode', kodeController),
              SizedBox(height: 16),
              _buildTextField('Nama Mata Pelajaran', namaController),
              SizedBox(height: 16),
              _buildTextField('Deskripsi', deskripsiController, maxLines: 3),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Batal'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (kodeController.text.isEmpty || namaController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Kode dan nama harus diisi'),
                              backgroundColor: Colors.red.shade400,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        try {
                          final data = {
                            'kode': kodeController.text,
                            'nama': namaController.text,
                            'deskripsi': deskripsiController.text,
                          };

                          if (mataPelajaran == null) {
                            await _apiService.post('/mata-pelajaran', data);
                          } else {
                            await _apiService.put('/mata-pelajaran/${mataPelajaran['id']}', data);
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          _loadMataPelajaran();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Data berhasil disimpan'),
                                backgroundColor: Colors.green.shade400,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menyimpan data'),
                                backgroundColor: Colors.red.shade400,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorUtils.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
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
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _hapusMataPelajaran(Map<String, dynamic> mataPelajaran) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Hapus Mata Pelajaran',
        content: 'Yakin ingin menghapus mata pelajaran "${mataPelajaran['nama']}"?',
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/mata-pelajaran/${mataPelajaran['id']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mata pelajaran berhasil dihapus'),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _loadMataPelajaran();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus mata pelajaran'),
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
      return LoadingScreen(message: 'Memuat data mata pelajaran...');
    }

    if (_errorMessage.isNotEmpty) {
      return ErrorScreen(
        errorMessage: _errorMessage,
        onRetry: _loadMataPelajaran,
      );
    }

    final filteredMataPelajaran = _mataPelajaranList.where((mp) {
      final searchTerm = _searchController.text.toLowerCase();
      return searchTerm.isEmpty ||
          mp['nama'].toLowerCase().contains(searchTerm) ||
          mp['kode'].toLowerCase().contains(searchTerm);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Kelola Mata Pelajaran',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: ColorUtils.primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMataPelajaran,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          CustomSearchBar(
            controller: _searchController,
            hintText: 'Cari mata pelajaran...',
            onChanged: (value) => setState(() {}),
          ),
          Expanded(
            child: filteredMataPelajaran.isEmpty
                ? EmptyState(
                    title: 'Tidak ada mata pelajaran',
                    subtitle: _searchController.text.isEmpty
                        ? 'Tap + untuk menambah mata pelajaran'
                        : 'Tidak ditemukan hasil pencarian',
                    icon: Icons.school_outlined,
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredMataPelajaran.length,
                    itemBuilder: (context, index) {
                      final mataPelajaran = filteredMataPelajaran[index];
                      
                      return SubjectListItem(
                        mataPelajaran: mataPelajaran,
                        index: index,
                        onEdit: () => _showAddEditDialog(mataPelajaran: mataPelajaran),
                        onDelete: () => _hapusMataPelajaran(mataPelajaran),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: ColorUtils.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
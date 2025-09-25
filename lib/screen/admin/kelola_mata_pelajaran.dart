import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_services.dart';

class KelolaMataPelajaranScreen extends StatefulWidget {
  const KelolaMataPelajaranScreen({super.key});

  @override
  _KelolaMataPelajaranScreenState createState() => _KelolaMataPelajaranScreenState();
}

class _KelolaMataPelajaranScreenState extends State<KelolaMataPelajaranScreen> {
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
                  color: Color(0xFF4F46E5),
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

                          Navigator.pop(context);
                          _loadMataPelajaran();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Data berhasil disimpan'),
                              backgroundColor: Colors.green.shade400,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal menyimpan data'),
                              backgroundColor: Colors.red.shade400,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4F46E5),
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

  void _showDeleteDialog(Map<String, dynamic> mataPelajaran) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Hapus Mata Pelajaran',
          style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
        ),
        content: Text('Yakin ingin menghapus mata pelajaran "${mataPelajaran['nama']}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              try {
                await _apiService.delete('/mata-pelajaran/${mataPelajaran['id']}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Mata pelajaran berhasil dihapus'),
                    backgroundColor: Colors.green.shade400,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pop(context);
                _loadMataPelajaran();
              } catch (error) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus mata pelajaran'),
                    backgroundColor: Colors.red.shade400,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Kelola Mata Pelajaran',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Color(0xFF4F46E5),
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
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5))),
                  SizedBox(height: 16),
                  Text('Memuat data...', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                      SizedBox(height: 16),
                      Text(_errorMessage, style: TextStyle(color: Colors.grey.shade600)),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMataPelajaran,
                        style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4F46E5)),
                        child: Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.symmetric(horizontal: 16),
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
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari mata pelajaran...',
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                          border: InputBorder.none,
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    Expanded(
                      child: _mataPelajaranList.where((mp) {
                        final searchTerm = _searchController.text.toLowerCase();
                        return searchTerm.isEmpty ||
                            mp['nama'].toLowerCase().contains(searchTerm) ||
                            mp['kode'].toLowerCase().contains(searchTerm);
                      }).isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade300),
                                  SizedBox(height: 16),
                                  Text(
                                    'Tidak ada mata pelajaran',
                                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _searchController.text.isEmpty
                                        ? 'Tap + untuk menambah mata pelajaran'
                                        : 'Tidak ditemukan hasil pencarian',
                                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: _mataPelajaranList.where((mp) {
                                final searchTerm = _searchController.text.toLowerCase();
                                return searchTerm.isEmpty ||
                                    mp['nama'].toLowerCase().contains(searchTerm) ||
                                    mp['kode'].toLowerCase().contains(searchTerm);
                              }).length,
                              itemBuilder: (context, index) {
                                final filteredList = _mataPelajaranList.where((mp) {
                                  final searchTerm = _searchController.text.toLowerCase();
                                  return searchTerm.isEmpty ||
                                      mp['nama'].toLowerCase().contains(searchTerm) ||
                                      mp['kode'].toLowerCase().contains(searchTerm);
                                }).toList();
                                
                                final mataPelajaran = filteredList[index];
                                final color = _getColorForIndex(index);
                                
                                return Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  child: Material(
                                    elevation: 2,
                                    borderRadius: BorderRadius.circular(16),
                                    child: ListTile(
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.school, color: Colors.white),
                                      ),
                                      title: Text(
                                        mataPelajaran['nama'],
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Kode: ${mataPelajaran['kode']}', style: TextStyle(fontSize: 12)),
                                          if (mataPelajaran['deskripsi'] != null)
                                            Text(
                                              mataPelajaran['deskripsi'],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                            ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit, color: Colors.blue.shade600, size: 20),
                                            onPressed: () => _showAddEditDialog(mataPelajaran: mataPelajaran),
                                            tooltip: 'Edit',
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red.shade600, size: 20),
                                            onPressed: () => _showDeleteDialog(mataPelajaran),
                                            tooltip: 'Hapus',
                                          ),
                                        ],
                                      ),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Color(0xFF4F46E5),
        child: Icon(Icons.add, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Color(0xFF6366F1), Color(0xFF10B981), Color(0xFFF59E0B),
      Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFF06B6D4),
    ];
    return colors[index % colors.length];
  }
}
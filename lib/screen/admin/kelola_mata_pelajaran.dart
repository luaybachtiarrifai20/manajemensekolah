import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_services.dart';

class KelolaMataPelajaranScreen extends StatefulWidget {
  const KelolaMataPelajaranScreen({super.key});

  @override
  _KelolaMataPelajaranScreenState createState() =>
      _KelolaMataPelajaranScreenState();
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
    final deskripsiController = TextEditingController(
      text: mataPelajaran?['deskripsi'],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          mataPelajaran == null
              ? 'Tambah Mata Pelajaran'
              : 'Edit Mata Pelajaran',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: kodeController,
                decoration: InputDecoration(
                  labelText: 'Kode',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: namaController,
                decoration: InputDecoration(
                  labelText: 'Nama Mata Pelajaran',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: deskripsiController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (kodeController.text.isEmpty || namaController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Kode dan nama harus diisi')),
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
                  await _apiService.put(
                    '/mata-pelajaran/${mataPelajaran['id']}',
                    data,
                  );
                }

                Navigator.pop(context);
                _loadMataPelajaran();
              } catch (error) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data')));
              }
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> mataPelajaran) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Mata Pelajaran'),
        content: Text(
          'Yakin ingin menghapus mata pelajaran "${mataPelajaran['nama']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _apiService.delete(
                  '/mata-pelajaran/${mataPelajaran['id']}',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mata pelajaran berhasil dihapus')),
                );
                Navigator.pop(context);
                _loadMataPelajaran();
              } catch (error) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menghapus mata pelajaran')),
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
      appBar: AppBar(
        title: Text('Kelola Mata Pelajaran'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari mata pelajaran...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _mataPelajaranList.length,
                    itemBuilder: (context, index) {
                      final mataPelajaran = _mataPelajaranList[index];
                      final searchTerm = _searchController.text.toLowerCase();

                      if (searchTerm.isNotEmpty &&
                          !mataPelajaran['nama'].toLowerCase().contains(
                            searchTerm,
                          ) &&
                          !mataPelajaran['kode'].toLowerCase().contains(
                            searchTerm,
                          )) {
                        return SizedBox.shrink();
                      }

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(mataPelajaran['nama']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Kode: ${mataPelajaran['kode']}'),
                              if (mataPelajaran['deskripsi'] != null)
                                Text(
                                  mataPelajaran['deskripsi'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showAddEditDialog(
                                  mataPelajaran: mataPelajaran,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _showDeleteDialog(mataPelajaran),
                              ),
                            ],
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
}

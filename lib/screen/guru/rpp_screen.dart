import 'package:flutter/material.dart';

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
      
      // Simulasi data RPP (ganti dengan API call)
      await Future.delayed(Duration(seconds: 1));
      
      setState(() {
        _rppList = [
          {
            'id': '1',
            'judul': 'RPP Matematika Kelas X',
            'kelas': 'X IPA 1',
            'semester': 'Ganjil',
            'tanggal': '2024-01-15',
            'status': 'Disetujui'
          },
          {
            'id': '2',
            'judul': 'RPP Fisika Kelas X',
            'kelas': 'X IPA 2',
            'semester': 'Ganjil',
            'tanggal': '2024-01-16',
            'status': 'Menunggu'
          }
        ];
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
      builder: (context) => AlertDialog(
        title: Text('Buat RPP Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Judul RPP'),
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Kelas'),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField(
                decoration: InputDecoration(labelText: 'Semester'),
                items: ['Ganjil', 'Genap'].map((semester) {
                  return DropdownMenuItem(
                    value: semester,
                    child: Text(semester),
                  );
                }).toList(),
                onChanged: (value) {},
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
            onPressed: () {
              // Simpan RPP
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('RPP berhasil dibuat')),
              );
            },
            child: Text('Buat RPP'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rencana Pelaksanaan Pembelajaran (RPP)'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _tambahRpp,
            tooltip: 'Buat RPP',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRpp,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_errorMessage'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRpp,
                        child: Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _rppList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada RPP',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tekan tombol + untuk membuat RPP',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _rppList.length,
                      itemBuilder: (context, index) {
                        final rpp = _rppList[index];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: Icon(Icons.description, color: Colors.purple),
                            title: Text(rpp['judul']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kelas: ${rpp['kelas']}'),
                                Text('Semester: ${rpp['semester']}'),
                                Text('Tanggal: ${rpp['tanggal']}'),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(
                                rpp['status'],
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: _getStatusColor(rpp['status']),
                            ),
                            onTap: () {
                              // Navigate to RPP detail
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:manajemensekolah/data/data_dummy.dart';

class PengumumanScreen extends StatelessWidget {
  const PengumumanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pengumuman')),
      body: ListView.builder(
        itemCount: DataDummy.pengumuman.length,
        itemBuilder: (context, index) {
          final pengumuman = DataDummy.pengumuman[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              leading: Icon(Icons.announcement, color: Colors.orange),
              title: Text(pengumuman.judul),
              subtitle: Text(pengumuman.isi),
              trailing: Chip(
                label: Text(pengumuman.kategori),
                backgroundColor: Colors.blue[100],
              ),
            ),
          );
        },
      ),
    );
  }
}
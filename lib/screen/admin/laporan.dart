import 'package:flutter/material.dart';

class LaporanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Laporan')),
      body: Center(child: Text('Fitur Laporan')),
    );
  }
}






class KegiatanKelasScreen extends StatelessWidget {
  const KegiatanKelasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kegiatan Kelas')),
      body: Center(child: Text('Fitur Kegiatan Kelas')),
    );
  }
}
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





class JadwalMengajarScreen extends StatelessWidget {
  const JadwalMengajarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Jadwal Mengajar')),
      body: Center(child: Text('Fitur Jadwal Mengajar')),
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
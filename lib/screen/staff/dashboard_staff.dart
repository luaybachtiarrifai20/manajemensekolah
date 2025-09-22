import 'package:flutter/material.dart';
import 'package:manajemensekolah/screen/staff/administrasi.dart';
import 'package:manajemensekolah/screen/staff/data_siswa.dart';
import 'package:manajemensekolah/screen/staff/inventaris.dart';
import 'package:manajemensekolah/screen/staff/surat.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Staff'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        children: [
          _buildDashboardCard('Data Siswa', Icons.people, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => DataSiswaScreen()));
          }),
          _buildDashboardCard('Administrasi', Icons.folder, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AdministrasiScreen()));
          }),
          _buildDashboardCard('Inventaris', Icons.inventory, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => InventarisScreen()));
          }),
          _buildDashboardCard('Surat Menyurat', Icons.mail, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SuratMenyuratScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.orange),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
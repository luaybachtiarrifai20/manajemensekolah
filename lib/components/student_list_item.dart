import 'package:flutter/material.dart';

import '../utils/color_utils.dart';

class StudentListItem extends StatelessWidget {
  final dynamic siswa;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StudentListItem({
    super.key,
    required this.siswa,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.getColorForIndex(index);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              siswa['nama'] != null && siswa['nama'].isNotEmpty
                  ? siswa['nama'][0]
                  : '?',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(siswa['nama'] ?? 'Nama tidak tersedia'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text('Kelas: ${siswa['kelas_nama'] ?? 'Tidak ada'}')],
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
          ),
        ),
      ),
    );
  }
}

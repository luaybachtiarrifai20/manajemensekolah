import 'package:flutter/material.dart';
import '../utils/color_utils.dart';

class ClassListItem extends StatelessWidget {
  final dynamic classData;
  final int index;
  final VoidCallback onTap;
  final Function(String) onMenuSelected;

  const ClassListItem({
    super.key,
    required this.classData,
    required this.index,
    required this.onTap,
    required this.onMenuSelected,
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
              classData['nama'].substring(0, 1),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            'Kelas ${classData['nama']}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wali: ${classData['wali_kelas_nama'] ?? 'Tidak ada'}',
              ),
              Text(
                'Siswa: ${classData['jumlah_siswa'] ?? 0} orang',
              ),
            ],
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'detail',
                child: Row(
                  children: [
                    Icon(Icons.info, size: 20),
                    SizedBox(width: 8),
                    Text('Detail'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      size: 20,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Hapus',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: onMenuSelected,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
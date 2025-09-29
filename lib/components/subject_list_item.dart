import 'package:flutter/material.dart';
import '../utils/color_utils.dart';

class SubjectListItem extends StatelessWidget {
  final dynamic mataPelajaran;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SubjectListItem({
    super.key,
    required this.mataPelajaran,
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
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.6)],
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
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red.shade600, size: 20),
                onPressed: onDelete,
                tooltip: 'Hapus',
              ),
            ],
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}
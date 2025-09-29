import 'package:flutter/material.dart';

import '../utils/color_utils.dart';

class TeacherListItem extends StatelessWidget {
  final dynamic guru;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TeacherListItem({
    super.key,
    required this.guru,
    required this.index,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isWaliKelas =
        guru['is_wali_kelas'] == 1 || guru['is_wali_kelas'] == true;
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
                colors: [
                  color.withValues(alpha: 0.8),
                  color.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                guru['nama'][0],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          title: Text(
            guru['nama'],
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NIP: ${guru['nip'] ?? 'Tidak ada'}',
                style: TextStyle(fontSize: 12),
              ),
              if (guru['mata_pelajaran_names'] != null) ...[
                SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: (guru['mata_pelajaran_names'] as String)
                      .split(',')
                      .where((name) => name.isNotEmpty)
                      .map(
                        (name) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (isWaliKelas) ...[
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Text(
                    'Wali Kelas',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
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
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onTap: onTap,
        ),
      ),
    );
  }
}

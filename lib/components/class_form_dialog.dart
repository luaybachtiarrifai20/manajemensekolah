import 'package:flutter/material.dart';

class ClassFormDialog extends StatefulWidget {
  final bool isEditMode;
  final String? initialName;
  final String? initialTeacherId;
  final List<dynamic> teachers;
  final Function(String name, String? teacherId) onSave;

  const ClassFormDialog({
    super.key,
    required this.isEditMode,
    this.initialName,
    this.initialTeacherId,
    required this.teachers,
    required this.onSave,
  });

  @override
  ClassFormDialogState createState() => ClassFormDialogState();
}

class ClassFormDialogState extends State<ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  String? _selectedGuruId;

  @override
  void initState() {
    super.initState();
    _namaController.text = widget.initialName ?? '';
    _selectedGuruId = widget.initialTeacherId;
  }

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  void _simpan() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(_namaController.text, _selectedGuruId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditMode ? 'Edit Kelas' : 'Tambah Kelas'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: 'Nama Kelas',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama kelas harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGuruId,
                decoration: InputDecoration(
                  labelText: 'Wali Kelas',
                  border: OutlineInputBorder(),
                ),
                items: widget.teachers
                    .where((guru) => guru['role'] == 'guru')
                    .map((guru) {
                  return DropdownMenuItem<String>(
                    value: guru['id'],
                    child: Text(
                      '${guru['nama']}${guru['is_wali_kelas'] == 1 ? ' (Wali Kelas)' : ''}',
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedGuruId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Wali kelas harus dipilih';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _simpan,
          child: Text(widget.isEditMode ? 'Perbarui' : 'Simpan'),
        ),
      ],
    );
  }
}
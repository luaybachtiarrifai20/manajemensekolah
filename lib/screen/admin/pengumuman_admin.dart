import 'dart:io';
import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:provider/provider.dart';
import 'package:manajemensekolah/components/confirmation_dialog.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/enhanced_search_bar.dart';
import 'package:manajemensekolah/components/error_screen.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/utils/color_utils.dart';
import 'package:manajemensekolah/utils/language_utils.dart';

class PengumumanManagementScreen extends StatefulWidget {
  const PengumumanManagementScreen({super.key});

  @override
  PengumumanManagementScreenState createState() => PengumumanManagementScreenState();
}

class PengumumanManagementScreenState extends State<PengumumanManagementScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _pengumuman = [];
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  final List<String> _filterOptions = ['All', 'Penting', 'Biasa'];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final pengumumanData = await _apiService.get('/pengumuman');

      setState(() {
        _pengumuman = pengumumanData is List ? pengumumanData : [];
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().getTranslatedText({
              'en': 'Failed to load announcement data: $e',
              'id': 'Gagal memuat data pengumuman: $e',
            }),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? pengumumanData}) {
    final judulController = TextEditingController(text: pengumumanData?['judul'] ?? '');
    final kontenController = TextEditingController(text: pengumumanData?['konten'] ?? '');
    String? selectedKelas = pengumumanData?['kelas_id'];
    String? selectedRole = pengumumanData?['role_target'] ?? 'all';
    String? selectedPrioritas = pengumumanData?['prioritas'] ?? 'biasa';
    DateTime? tanggalAwal = pengumumanData?['tanggal_awal'] != null 
        ? DateTime.parse(pengumumanData!['tanggal_awal']) 
        : null;
    DateTime? tanggalAkhir = pengumumanData?['tanggal_akhir'] != null 
        ? DateTime.parse(pengumumanData!['tanggal_akhir']) 
        : null;

    final isEdit = pengumumanData != null;

    showDialog(
      context: context,
      builder: (context) => Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header dengan gradient
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: _getCardGradient(),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEdit ? Icons.edit : Icons.announcement,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEdit
                                ? languageProvider.getTranslatedText({
                                    'en': 'Edit Announcement',
                                    'id': 'Edit Pengumuman',
                                  })
                                : languageProvider.getTranslatedText({
                                    'en': 'Add Announcement',
                                    'id': 'Tambah Pengumuman',
                                  }),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDialogTextField(
                          controller: judulController,
                          label: languageProvider.getTranslatedText({
                            'en': 'Title',
                            'id': 'Judul',
                          }),
                          icon: Icons.title,
                        ),
                        SizedBox(height: 12),
                        _buildDialogTextField(
                          controller: kontenController,
                          label: languageProvider.getTranslatedText({
                            'en': 'Content',
                            'id': 'Konten',
                          }),
                          icon: Icons.description,
                          maxLines: 4,
                        ),
                        SizedBox(height: 12),
                        _buildPrioritasDropdown(
                          value: selectedPrioritas,
                          onChanged: (value) {
                            setState(() {
                              selectedPrioritas = value;
                            });
                          },
                          languageProvider: languageProvider,
                        ),
                        SizedBox(height: 12),
                        _buildRoleTargetDropdown(
                          value: selectedRole,
                          onChanged: (value) {
                            setState(() {
                              selectedRole = value;
                            });
                          },
                          languageProvider: languageProvider,
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                label: languageProvider.getTranslatedText({
                                  'en': 'Start Date',
                                  'id': 'Tanggal Mulai',
                                }),
                                value: tanggalAwal,
                                onTap: () => _selectDate(context, true, (date) {
                                  setState(() {
                                    tanggalAwal = date;
                                  });
                                }),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                label: languageProvider.getTranslatedText({
                                  'en': 'End Date',
                                  'id': 'Tanggal Berakhir',
                                }),
                                value: tanggalAkhir,
                                onTap: () => _selectDate(context, false, (date) {
                                  setState(() {
                                    tanggalAkhir = date;
                                  });
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              languageProvider.getTranslatedText({
                                'en': 'Cancel',
                                'id': 'Batal',
                              }),
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final judul = judulController.text.trim();
                              final konten = kontenController.text.trim();

                              if (judul.isEmpty || konten.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      languageProvider.getTranslatedText({
                                        'en': 'Title and content must be filled',
                                        'id': 'Judul dan konten harus diisi',
                                      }),
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              try {
                                final data = {
                                  'judul': judul,
                                  'konten': konten,
                                  'role_target': selectedRole,
                                  'prioritas': selectedPrioritas,
                                  'tanggal_awal': tanggalAwal?.toIso8601String().split('T')[0],
                                  'tanggal_akhir': tanggalAkhir?.toIso8601String().split('T')[0],
                                };

                                if (isEdit) {
                                  await _apiService.put('/pengumuman/${pengumumanData!['id']}', data);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          languageProvider.getTranslatedText({
                                            'en': 'Announcement successfully updated',
                                            'id': 'Pengumuman berhasil diperbarui',
                                          }),
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                } else {
                                  await _apiService.post('/pengumuman', data);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          languageProvider.getTranslatedText({
                                            'en': 'Announcement successfully added',
                                            'id': 'Pengumuman berhasil ditambahkan',
                                          }),
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                }
                                _loadData();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        languageProvider.getTranslatedText({
                                          'en': 'Failed to save announcement: $e',
                                          'id': 'Gagal menyimpan pengumuman: $e',
                                        }),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getPrimaryColor(),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              isEdit
                                  ? languageProvider.getTranslatedText({
                                      'en': 'Update',
                                      'id': 'Perbarui',
                                    })
                                  : languageProvider.getTranslatedText({
                                      'en': 'Save',
                                      'id': 'Simpan',
                                    }),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _getPrimaryColor(), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPrioritasDropdown({
    required String? value,
    required Function(String?) onChanged,
    required LanguageProvider languageProvider,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: languageProvider.getTranslatedText({
            'en': 'Priority',
            'id': 'Prioritas',
          }),
          prefixIcon: Icon(Icons.priority_high, color: _getPrimaryColor(), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        items: [
          DropdownMenuItem(
            value: 'biasa',
            child: Row(
              children: [
                Icon(Icons.circle, color: Colors.grey, size: 16),
                SizedBox(width: 8),
                Text(languageProvider.getTranslatedText({
                  'en': 'Normal',
                  'id': 'Biasa',
                })),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'penting',
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text(languageProvider.getTranslatedText({
                  'en': 'Important',
                  'id': 'Penting',
                })),
              ],
            ),
          ),
        ],
        onChanged: onChanged,
        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
      ),
    );
  }

  Widget _buildRoleTargetDropdown({
    required String? value,
    required Function(String?) onChanged,
    required LanguageProvider languageProvider,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: languageProvider.getTranslatedText({
            'en': 'Target Role',
            'id': 'Role Target',
          }),
          prefixIcon: Icon(Icons.people, color: _getPrimaryColor(), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        items: [
          DropdownMenuItem(
            value: 'all',
            child: Text(languageProvider.getTranslatedText({
              'en': 'All Users',
              'id': 'Semua Pengguna',
            })),
          ),
          DropdownMenuItem(
            value: 'admin',
            child: Text('Admin'),
          ),
          DropdownMenuItem(
            value: 'guru',
            child: Text('Guru'),
          ),
          DropdownMenuItem(
            value: 'siswa',
            child: Text('Siswa'),
          ),
          DropdownMenuItem(
            value: 'wali',
            child: Text('Wali'),
          ),
        ],
        onChanged: onChanged,
        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: _getPrimaryColor(), size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                value != null 
                  ? '${value.day}/${value.month}/${value.year}'
                  : label,
                style: TextStyle(
                  color: value != null ? Colors.grey.shade800 : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _deletePengumuman(Map<String, dynamic> pengumumanData) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: context.read<LanguageProvider>().getTranslatedText({
          'en': 'Delete Announcement',
          'id': 'Hapus Pengumuman',
        }),
        content: context.read<LanguageProvider>().getTranslatedText({
          'en': 'Are you sure you want to delete this announcement?',
          'id': 'Yakin ingin menghapus pengumuman ini?',
        }),
        confirmText: context.read<LanguageProvider>().getTranslatedText({
          'en': 'Delete',
          'id': 'Hapus',
        }),
        confirmColor: Colors.red,
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/pengumuman/${pengumumanData['id']}');
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Announcement successfully deleted',
                  'id': 'Pengumuman berhasil dihapus',
                }),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Failed to delete announcement: $e',
                  'id': 'Gagal menghapus pengumuman: $e',
                }),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildPengumumanCard(Map<String, dynamic> pengumumanData, int index) {
    final languageProvider = context.read<LanguageProvider>();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = index * 0.1;
        final animation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, 1.0, curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          _showPengumumanDetail(pengumumanData);
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showPengumumanDetail(pengumumanData),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: _getCardGradient(),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getPrimaryColor().withOpacity(0.2),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      right: -10,
                      top: -10,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    // Priority badge
                    if (pengumumanData['prioritas'] == 'penting')
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              languageProvider.getTranslatedText({
                                'en': 'IMPORTANT',
                                'id': 'PENTING',
                              }),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header dengan judul
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pengumumanData['judul'] ?? 'No Title',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _formatDate(pengumumanData['created_at']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Konten preview
                          Text(
                            pengumumanData['konten'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: 12),

                          // Informasi tambahan
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      languageProvider.getTranslatedText({
                                        'en': 'Created by',
                                        'id': 'Dibuat oleh',
                                      }),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 1),
                                    Text(
                                      pengumumanData['pembuat_nama'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8),

                          // Target informasi
                          Row(
                            children: [
                              Icon(Icons.people_outline, size: 14, color: Colors.white.withOpacity(0.8)),
                              SizedBox(width: 4),
                              Text(
                                _getTargetText(pengumumanData, languageProvider),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildActionButton(
                                icon: Icons.edit,
                                label: languageProvider.getTranslatedText({
                                  'en': 'Edit',
                                  'id': 'Edit',
                                }),
                                color: Colors.white,
                                onPressed: () => _showAddEditDialog(pengumumanData: pengumumanData),
                              ),
                              SizedBox(width: 8),
                              _buildActionButton(
                                icon: Icons.delete,
                                label: languageProvider.getTranslatedText({
                                  'en': 'Delete',
                                  'id': 'Hapus',
                                }),
                                color: Colors.white,
                                onPressed: () => _deletePengumuman(pengumumanData),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPengumumanDetail(Map<String, dynamic> pengumumanData) {
    final languageProvider = context.read<LanguageProvider>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan gradient
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: _getCardGradient(),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.announcement,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pengumumanData['judul'] ?? 'No Title',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      _formatDate(pengumumanData['created_at']),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Priority badge
                    if (pengumumanData['prioritas'] == 'penting')
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, size: 14, color: Colors.orange),
                          SizedBox(width: 6),
                          Text(
                            languageProvider.getTranslatedText({
                              'en': 'Important Announcement',
                              'id': 'Pengumuman Penting',
                            }),
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Content text
                    Text(
                      pengumumanData['konten'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.grey.shade800,
                      ),
                    ),

                    SizedBox(height: 20),

                    // Metadata
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.person,
                            label: languageProvider.getTranslatedText({
                              'en': 'Created by',
                              'id': 'Dibuat oleh',
                            }),
                            value: pengumumanData['pembuat_nama'] ?? 'Unknown',
                          ),
                          SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.people,
                            label: languageProvider.getTranslatedText({
                              'en': 'Target Role',
                              'id': 'Role Target',
                            }),
                            value: _getTargetText(pengumumanData, languageProvider),
                          ),
                          if (pengumumanData['tanggal_awal'] != null)
                          SizedBox(height: 8),
                          if (pengumumanData['tanggal_awal'] != null)
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            label: languageProvider.getTranslatedText({
                              'en': 'Start Date',
                              'id': 'Tanggal Mulai',
                            }),
                            value: _formatDate(pengumumanData['tanggal_awal']),
                          ),
                          if (pengumumanData['tanggal_akhir'] != null)
                          SizedBox(height: 8),
                          if (pengumumanData['tanggal_akhir'] != null)
                          _buildDetailRow(
                            icon: Icons.event_busy,
                            label: languageProvider.getTranslatedText({
                              'en': 'End Date',
                              'id': 'Tanggal Berakhir',
                            }),
                            value: _formatDate(pengumumanData['tanggal_akhir']),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Close button
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getPrimaryColor(),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          languageProvider.getTranslatedText({
                            'en': 'Close',
                            'id': 'Tutup',
                          }),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _getPrimaryColor()),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTargetText(Map<String, dynamic> pengumumanData, LanguageProvider languageProvider) {
    final roleTarget = pengumumanData['role_target'] ?? 'all';
    final kelasNama = pengumumanData['kelas_nama'];

    if (roleTarget == 'all' && kelasNama == null) {
      return languageProvider.getTranslatedText({
        'en': 'All Users',
        'id': 'Semua Pengguna',
      });
    } else if (kelasNama != null) {
      return '$kelasNama (${roleTarget.toUpperCase()})';
    } else {
      return roleTarget.toUpperCase();
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getPrimaryColor() {
    return ColorUtils.primaryColor;
  }

  LinearGradient _getCardGradient() {
    final primaryColor = _getPrimaryColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryColor,
        ColorUtils.primaryColor,
      ],
    );
  }

  List<dynamic> get _filteredPengumuman {
    var filtered = _pengumuman;

    // Filter berdasarkan search
    if (_searchController.text.isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
      filtered = filtered.where((p) {
        final judul = p['judul']?.toString().toLowerCase() ?? '';
        final konten = p['konten']?.toString().toLowerCase() ?? '';
        final pembuat = p['pembuat_nama']?.toString().toLowerCase() ?? '';
        return judul.contains(searchLower) || 
               konten.contains(searchLower) || 
               pembuat.contains(searchLower);
      }).toList();
    }

    // Filter berdasarkan prioritas
    if (_selectedFilter != 'All') {
      filtered = filtered.where((p) {
        return p['prioritas']?.toLowerCase() == _selectedFilter.toLowerCase();
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: Color(0xFFF8F9FA),
          body: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  gradient: _getCardGradient(),
                  boxShadow: [
                    BoxShadow(
                      color: _getPrimaryColor().withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languageProvider.getTranslatedText({
                                  'en': 'Announcement Management',
                                  'id': 'Manajemen Pengumuman',
                                }),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                languageProvider.getTranslatedText({
                                  'en': 'Manage and create announcements',
                                  'id': 'Kelola dan buat pengumuman',
                                }),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.announcement,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Search Bar dan Filter
                    EnhancedSearchBar(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      hintText: languageProvider.getTranslatedText({
                        'en': 'Search announcements...',
                        'id': 'Cari pengumuman...',
                      }),
                    ),
                    SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filterOptions.map((filter) {
                          return Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                filter == 'All' 
                                  ? languageProvider.getTranslatedText({
                                      'en': 'All',
                                      'id': 'Semua',
                                    })
                                  : filter == 'Penting'
                                    ? languageProvider.getTranslatedText({
                                        'en': 'Important',
                                        'id': 'Penting',
                                      })
                                    : languageProvider.getTranslatedText({
                                        'en': 'Normal',
                                        'id': 'Biasa',
                                      }),
                                style: TextStyle(
                                  color: _selectedFilter == filter 
                                    ? Colors.white 
                                    : _getPrimaryColor(),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              selected: _selectedFilter == filter,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = selected ? filter : 'All';
                                });
                              },
                              backgroundColor: Colors.white.withOpacity(0.2),
                              selectedColor: _getPrimaryColor(),
                              checkmarkColor: Colors.white,
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: _selectedFilter == filter 
                                    ? Colors.transparent 
                                    : Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? LoadingScreen(
                        message: languageProvider.getTranslatedText({
                          'en': 'Loading announcements...',
                          'id': 'Memuat pengumuman...',
                        }),
                      )
                    : _errorMessage != null
                        ? ErrorScreen(
                            errorMessage: _errorMessage!, onRetry: _loadData,
                          )
                        : _filteredPengumuman.isEmpty
                            ? EmptyState(
                                icon: Icons.announcement_outlined,
                                title: languageProvider.getTranslatedText({
                                  'en': 'No Announcements',
                                  'id': 'Tidak Ada Pengumuman',
                                }),
                                subtitle: languageProvider.getTranslatedText({
                                  'en': _searchController.text.isNotEmpty
                                      ? 'No announcements found for your search'
                                      : 'Start creating announcements to share information',
                                  'id': _searchController.text.isNotEmpty
                                      ? 'Tidak ada pengumuman yang sesuai dengan pencarian'
                                      : 'Mulai buat pengumuman untuk berbagi informasi',
                                }),
                                buttonText: languageProvider.getTranslatedText({
                                  'en': 'Create Announcement',
                                  'id': 'Buat Pengumuman',
                                }),
                                onPressed: () => _showAddEditDialog(),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadData,
                                color: _getPrimaryColor(),
                                backgroundColor: Colors.white,
                                child: ListView.builder(
                                  padding: EdgeInsets.only(top: 8, bottom: 16),
                                  itemCount: _filteredPengumuman.length,
                                  itemBuilder: (context, index) {
                                    return _buildPengumumanCard(
                                      _filteredPengumuman[index],
                                      index,
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),

          // Floating Action Button
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddEditDialog(),
            backgroundColor: _getPrimaryColor(),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
}
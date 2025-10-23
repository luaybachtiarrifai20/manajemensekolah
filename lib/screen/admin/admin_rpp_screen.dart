import 'package:flutter/material.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/excel_rpp_service.dart';
import 'package:manajemensekolah/utils/color_utils.dart';
import 'package:manajemensekolah/components/enhanced_search_bar.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/error_screen.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:provider/provider.dart';
import 'package:manajemensekolah/utils/language_utils.dart';

class AdminRppScreen extends StatefulWidget {
  final String? teacherId;
  final String? teacherName;

  const AdminRppScreen({super.key, this.teacherId, this.teacherName});

  @override
  State<AdminRppScreen> createState() => _AdminRppScreenState();
}

class _AdminRppScreenState extends State<AdminRppScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _rppList = [];
  List<dynamic> _filteredRppList = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterStatus = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  // Filter options untuk EnhancedSearchBar
  final List<String> _filterOptions = [
    'Semua',
    'Menunggu',
    'Disetujui',
    'Ditolak',
  ];

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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

    _loadRppByTeacher();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _exportToExcel() async {
    await ExcelRppService.exportRppToExcel(rppList: _rppList, context: context);
  }

  Future<void> _loadRppByTeacher() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final rppData = await ApiService.getRPP();

      List<dynamic> filteredData;
      if (widget.teacherId != null) {
        filteredData = rppData
            .where((rpp) => rpp['guru_id']?.toString() == widget.teacherId)
            .toList();
      } else {
        filteredData = rppData;
      }

      setState(() {
        _rppList = filteredData;
        _filteredRppList = filteredData;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadAllRpp() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final rppData = await ApiService.getRPP();

      setState(() {
        _rppList = rppData;
        _filteredRppList = rppData;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _filterRpp(String status) {
    setState(() {
      _filterStatus = status;
      if (status == 'Semua') {
        _filteredRppList = _rppList;
      } else {
        _filteredRppList = _rppList
            .where((rpp) => rpp['status'] == status)
            .toList();
      }
    });
  }

  void _updateStatus(String rppId, String status) {
    showDialog(
      context: context,
      builder: (context) => UpdateStatusDialog(
        rppId: rppId,
        currentStatus: _rppList.firstWhere(
          (rpp) => rpp['id'] == rppId,
        )['status'],
        onStatusUpdated: _loadAllRpp,
      ),
    );
  }

  void _lihatDetailRpp(Map<String, dynamic> rpp) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RppAdminDetailPage(rpp: rpp)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return Colors.green;
      case 'Menunggu':
        return Colors.orange;
      case 'Ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Disetujui':
        return Icons.check_circle;
      case 'Menunggu':
        return Icons.access_time;
      case 'Ditolak':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getPrimaryColor() {
    return Color(0xFF4361EE); // Blue untuk admin
  }

  LinearGradient _getCardGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_getPrimaryColor(), _getPrimaryColor().withOpacity(0.7)],
    );
  }

  Widget _buildRppCard(Map<String, dynamic> rpp, int index) {
    final languageProvider = context.read<LanguageProvider>();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AnimatedBuilder(
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _lihatDetailRpp(rpp),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 5,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Strip biru di pinggir kiri
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 6,
                      decoration: BoxDecoration(
                        color: _getPrimaryColor(),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
      
                  // Background pattern effect
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
      
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header dengan judul dan status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rpp['judul'] ?? 'No Title',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${rpp['mata_pelajaran_nama'] ?? 'No Subject'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  rpp['status'],
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getStatusColor(
                                    rpp['status'],
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                rpp['status'] == 'Menunggu'
                                    ? 'Menunggu'
                                    : rpp['status'] == 'Disetujui'
                                    ? 'Disetujui'
                                    : 'Ditolak',
                                style: TextStyle(
                                  color: _getStatusColor(rpp['status']),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
      
                        SizedBox(height: 12),
      
                        // Informasi kelas dan guru
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _getPrimaryColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.school,
                                color: _getPrimaryColor(),
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kelas',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 1),
                                  Text(
                                    rpp['kelas_nama'] ?? 'No Class',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
      
                        SizedBox(height: 8),
      
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _getPrimaryColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.person,
                                color: _getPrimaryColor(),
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Guru',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 1),
                                  Text(
                                    rpp['guru_nama'] ?? 'No Teacher',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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
                              icon: Icons.visibility,
                              label: 'Detail',
                              color: _getPrimaryColor(),
                              onPressed: () => _lihatDetailRpp(rpp),
                            ),
                            SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.edit,
                              label: 'Status',
                              color: _getPrimaryColor(),
                              onPressed: () =>
                                  _updateStatus(rpp['id'], rpp['status']),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        if (_isLoading) {
          return LoadingScreen(
            message: languageProvider.getTranslatedText({
              'en': 'Loading RPP data...',
              'id': 'Memuat data RPP...',
            }),
          );
        }

        if (_errorMessage != null) {
          return ErrorScreen(
            errorMessage: _errorMessage!,
            onRetry: _loadAllRpp,
          );
        }

        final filteredRpp = _filteredRppList.where((rpp) {
          final searchTerm = _searchController.text.toLowerCase();
          return searchTerm.isEmpty ||
              (rpp['judul']?.toLowerCase().contains(searchTerm) ?? false) ||
              (rpp['mata_pelajaran_nama']?.toLowerCase().contains(searchTerm) ??
                  false) ||
              (rpp['guru_nama']?.toLowerCase().contains(searchTerm) ?? false) ||
              (rpp['kelas_nama']?.toLowerCase().contains(searchTerm) ?? false);
        }).toList();

        return Scaffold(
          backgroundColor: Color(0xFFF8F9FA),
          appBar: AppBar(
            title: Text(
              widget.teacherName != null
                  ? 'RPP - ${widget.teacherName}'
                  : languageProvider.getTranslatedText({
                      'en': 'Manage RPP',
                      'id': 'Kelola RPP',
                    }),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: _getPrimaryColor(),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            leading: widget.teacherId != null
                ? IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'export':
                      _exportToExcel();
                      break;
                    case 'refresh':
                      _loadRppByTeacher();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.file_download, color: _getPrimaryColor()),
                        SizedBox(width: 8),
                        Text(
                          languageProvider.getTranslatedText({
                            'en': 'Export to Excel',
                            'id': 'Export ke Excel',
                          }),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: _getPrimaryColor()),
                        SizedBox(width: 8),
                        Text(
                          languageProvider.getTranslatedText({
                            'en': 'Refresh',
                            'id': 'Refresh',
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              EnhancedSearchBar(
                controller: _searchController,
                hintText: languageProvider.getTranslatedText({
                  'en': 'Search RPP...',
                  'id': 'Cari RPP...',
                }),
                onChanged: (value) => setState(() {}),
                filterOptions: _filterOptions,
                selectedFilter: _filterStatus,
                onFilterChanged: (filter) {
                  setState(() {
                    _filterStatus = filter;
                    _filterRpp(filter);
                  });
                },
                showFilter: true,
              ),
              if (filteredRpp.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${filteredRpp.length} ${languageProvider.getTranslatedText({'en': 'RPP found', 'id': 'RPP ditemukan'})}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 4),
              Expanded(
                child: filteredRpp.isEmpty
                    ? EmptyState(
                        title: languageProvider.getTranslatedText({
                          'en': 'No RPP',
                          'id': 'Tidak ada RPP',
                        }),
                        subtitle:
                            _searchController.text.isEmpty &&
                                _filterStatus == 'Semua'
                            ? languageProvider.getTranslatedText({
                                'en': 'No RPP data available',
                                'id': 'Tidak ada data RPP',
                              })
                            : languageProvider.getTranslatedText({
                                'en': 'No search results found',
                                'id': 'Tidak ditemukan hasil pencarian',
                              }),
                        icon: Icons.description,
                      )
                    : ListView.builder(
                        itemCount: filteredRpp.length,
                        itemBuilder: (context, index) {
                          final rpp = filteredRpp[index];
                          return _buildRppCard(rpp, index);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ... (UpdateStatusDialog dan RppAdminDetailPage tetap sama seperti sebelumnya)
class UpdateStatusDialog extends StatefulWidget {
  final String rppId;
  final String currentStatus;
  final VoidCallback onStatusUpdated;

  const UpdateStatusDialog({
    super.key,
    required this.rppId,
    required this.currentStatus,
    required this.onStatusUpdated,
  });

  @override
  State<UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<UpdateStatusDialog> {
  String _selectedStatus = 'Menunggu';
  final _catatanController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == widget.currentStatus) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await ApiService.updateStatusRPP(
        widget.rppId,
        _selectedStatus,
        catatan: _catatanController.text.isNotEmpty
            ? _catatanController.text
            : null,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onStatusUpdated();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status RPP berhasil diupdate')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Status RPP'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: ['Menunggu', 'Disetujui', 'Ditolak'].map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _catatanController,
              decoration: InputDecoration(
                labelText: 'Catatan (Opsional)',
                border: OutlineInputBorder(),
                hintText: 'Berikan catatan untuk guru...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : _updateStatus,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorUtils.primaryColor,
          ),
          child: _isUpdating
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('Update', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Halaman Detail RPP untuk Admin
class RppAdminDetailPage extends StatelessWidget {
  final Map<String, dynamic> rpp;

  const RppAdminDetailPage({super.key, required this.rpp});
  Color _getPrimaryColor() {
    return Color(0xFF4361EE); // Blue untuk admin
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Detail RPP',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _getPrimaryColor(),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'approve') {
                _showUpdateStatusDialog(context, 'Disetujui');
              } else if (value == 'reject') {
                _showUpdateStatusDialog(context, 'Ditolak');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'approve',
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('Setujui RPP'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reject',
                child: Row(
                  children: [
                    Icon(Icons.close, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Tolak RPP'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade300),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan status
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rpp['judul'] ?? '-',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(rpp['status']),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      rpp['status'] == 'Menunggu'
                          ? 'Menunggu'
                          : rpp['status'] == 'Disetujui'
                          ? 'Disetujui'
                          : 'Ditolak',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Informasi Detail
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi RPP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildDetailItem('Guru Pengajar', rpp['guru_nama'] ?? '-'),
                  _buildDetailItem(
                    'Mata Pelajaran',
                    rpp['mata_pelajaran_nama'] ?? '-',
                  ),
                  _buildDetailItem('Kelas', rpp['kelas_nama'] ?? '-'),
                  _buildDetailItem('Semester', rpp['semester'] ?? '-'),
                  _buildDetailItem('Tahun Ajaran', rpp['tahun_ajaran'] ?? '-'),
                  _buildDetailItem(
                    'Tanggal Dibuat',
                    rpp['created_at']?.toString().substring(0, 10) ?? '-',
                  ),

                  if (rpp['catatan_admin'] != null) ...[
                    SizedBox(height: 8),
                    Divider(),
                    SizedBox(height: 8),
                    Text(
                      'Catatan Admin',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      rpp['catatan_admin']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // File Attachment
            if (rpp['file_path'] != null) ...[
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lampiran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fitur download akan datang...'),
                          ),
                        );
                      },
                      icon: Icon(Icons.download),
                      label: Text('Download RPP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorUtils.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showUpdateStatusDialog(BuildContext context, String status) {
    showDialog(
      context: context,
      builder: (context) => UpdateStatusDialog(
        rppId: rpp['id'],
        currentStatus: rpp['status'],
        onStatusUpdated: () {
          Navigator.pop(context); // Tutup dialog detail
          Navigator.pop(context); // Kembali ke list
          // TODO: Refresh data atau navigasi ulang
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return Colors.green;
      case 'Menunggu':
        return Colors.orange;
      case 'Ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

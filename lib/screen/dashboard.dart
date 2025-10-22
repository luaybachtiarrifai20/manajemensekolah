import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:manajemensekolah/screen/admin/admin_class_activity.dart';
import 'package:manajemensekolah/screen/admin/admin_presence_report.dart';
import 'package:manajemensekolah/screen/admin/admin_rpp_screen.dart';
import 'package:manajemensekolah/screen/admin/admin_teachers_screen.dart';
import 'package:manajemensekolah/screen/admin/class_management.dart';
import 'package:manajemensekolah/screen/admin/keuangan.dart';
import 'package:manajemensekolah/screen/admin/laporan.dart';
import 'package:manajemensekolah/screen/admin/pengumuman_admin.dart';
import 'package:manajemensekolah/screen/admin/student_management.dart';
import 'package:manajemensekolah/screen/admin/subject_management.dart';
import 'package:manajemensekolah/screen/admin/teacher_admin.dart';
import 'package:manajemensekolah/screen/admin/teaching_schedule_management.dart';
import 'package:manajemensekolah/screen/guru/input_grade_teacher.dart';
import 'package:manajemensekolah/screen/guru/class_activity.dart';
import 'package:manajemensekolah/screen/guru/materi_screen.dart';
import 'package:manajemensekolah/screen/guru/presence_teacher.dart';
import 'package:manajemensekolah/screen/guru/teaching_schedule.dart';
import 'package:manajemensekolah/screen/guru/rpp_screen.dart';
import 'package:manajemensekolah/screen/walimurid/parent_class_activity.dart';
import 'package:manajemensekolah/screen/walimurid/pengumuman_screen.dart';
import 'package:manajemensekolah/screen/walimurid/presence_parent.dart';
import 'package:manajemensekolah/screen/walimurid/tagihan_wali.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/api_student_services.dart';
import 'package:manajemensekolah/utils/language_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  final String role;

  const Dashboard({super.key, required this.role});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Map<String, dynamic> _userData = {};
  List<dynamic> _accessibleSchools = [];
  bool _isLoadingSchools = false;

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

    _animationController.forward();
    _loadUserData();
    _loadAccessibleSchools();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      setState(() {
        _userData = json.decode(userString);
      });
    }
  }

  Future<void> _loadAccessibleSchools() async {
    setState(() {
      _isLoadingSchools = true;
    });

    try {
      final schools = await ApiService.getUserSchools();
      setState(() {
        _accessibleSchools = schools;
        _isLoadingSchools = false;
      });
    } catch (e) {
      print('Error loading schools: $e');
      setState(() {
        _isLoadingSchools = false;
      });
    }
  }

  Future<void> _switchSchool(Map<String, dynamic> school) async {
    try {
      final response = await ApiService.switchSchool(school['sekolah_id']);

      // Update token dan user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response['token']);

      // Update user data dengan sekolah baru
      final updatedUserData = Map<String, dynamic>.from(_userData);
      updatedUserData['sekolah_id'] = school['sekolah_id'];
      updatedUserData['nama_sekolah'] = school['nama_sekolah'];
      updatedUserData['sekolah_alamat'] = school['alamat'];
      updatedUserData['sekolah_telepon'] = school['telepon'];
      updatedUserData['sekolah_email'] = school['email'];

      await prefs.setString('user', json.encode(updatedUserData));

      setState(() {
        _userData = updatedUserData;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil pindah ke ${school['nama_sekolah']}'),
          ),
        );
        Navigator.pop(context); // Close bottom sheet
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal pindah sekolah: $e')));
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: _getBackgroundColor(),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Header dengan gradient seperti Duolingo
                _buildModernHeader(context, languageProvider),
                SizedBox(height: 16),

                // Welcome Section dengan animasi
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildWelcomeSection(),
                  ),
                ),
                SizedBox(height: 20),

                // Search Bar dengan design modern
                _buildModernSearchBar(),
                SizedBox(height: 20),

                // Grid Menu dengan animasi bertahap
                Expanded(child: _buildAnimatedGridMenu(context)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernHeader(
    BuildContext context,
    LanguageProvider languageProvider,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: _getHeaderGradient(),
        boxShadow: [
          BoxShadow(
            color: _getPrimaryColor().withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo dengan animasi
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.school, color: _getPrimaryColor(), size: 24),
            ),
          ),
          SizedBox(width: 12),

          // App Title dan Nama Sekolah
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userData['nama_sekolah'] ?? AppLocalizations.appTitle.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  _getRoleTitle(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Action Icons
          Row(
            children: [
              _buildIconButton(
                icon: Icons.language,
                color: Colors.white,
                onPressed: () => _showLanguageDialog(context, languageProvider),
              ),
              _buildIconButton(
                icon: Icons.notifications_none,
                color: Colors.white,
                onPressed: () {},
              ),
              _buildIconButton(
                icon: Icons.account_circle,
                color: Colors.white,
                onPressed: () => _showAccountBottomSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _getCardGradient(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getPrimaryColor().withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar dengan efek glowing
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _getPrimaryColor().withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.account_circle_rounded,
              color: _getPrimaryColor(),
              size: 40,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.welcome.tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _userData['nama'] ?? _getRoleTitle(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                Text(
                  _userData['nama_sekolah'] ?? AppLocalizations.appTitle.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: AppLocalizations.searchHint.tr,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search_rounded, color: _getPrimaryColor()),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
          style: TextStyle(color: Colors.grey.shade700),
          onChanged: (value) {
            // Implement search functionality
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedGridMenu(BuildContext context) {
    final cards = _getDashboardCards(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14, // Sedikit lebih kecil
          mainAxisSpacing: 14, // Sedikit lebih kecil
          childAspectRatio: 1.1, // Lebih pendek - sebelumnya 0.85
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
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
            child: cards[index],
          );
        },
      ),
    );
  }

  Widget _buildDashboardCard(String title, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16), // Sedikit lebih kecil
        child: Container(
          decoration: BoxDecoration(
            gradient: _getCardGradient(),
            borderRadius: BorderRadius.circular(16), // Sedikit lebih kecil
            boxShadow: [
              BoxShadow(
                color: _getPrimaryColor().withOpacity(0.2),
                blurRadius: 12, // Sedikit lebih kecil
                offset: Offset(0, 4), // Sedikit lebih kecil
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background pattern effect - lebih kecil
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  width: 40, // Lebih kecil
                  height: 40, // Lebih kecil
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Content dengan padding lebih kecil
              Padding(
                padding: const EdgeInsets.all(12), // Lebih kecil dari 16
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Container lebih kecil
                    Container(
                      width: 42, // Lebih kecil
                      height: 42, // Lebih kecil
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10), // Lebih kecil
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 20, // Lebih kecil
                      ),
                    ),
                    SizedBox(height: 8), // Lebih kecil
                    // Title dengan font lebih kecil
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12, // Lebih kecil dari 14
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  void _showLanguageDialog(
    BuildContext context,
    LanguageProvider languageProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Pilih Bahasa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getPrimaryColor(),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              context,
              languageProvider,
              'Indonesia',
              'id',
              Colors.green,
            ),
            SizedBox(height: 12),
            _buildLanguageOption(
              context,
              languageProvider,
              'English',
              'en',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    LanguageProvider languageProvider,
    String language,
    String code,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          Navigator.pop(context);
          await languageProvider.setLanguage(code);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.language, color: color),
              SizedBox(width: 12),
              Text(
                language,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              Spacer(),
              if (languageProvider.currentLanguage == code)
                Icon(Icons.check_circle, color: color),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: EdgeInsets.all(20),
          child: Wrap(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // User Info
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: _getCardGradient(),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.account_circle,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userData['nama'] ?? _getRoleTitle(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _userData['email'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  _userData['nama_sekolah'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Switch Sekolah Button (bukan langsung list)
                      if (_accessibleSchools.length > 1) ...[
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context); // Tutup bottom sheet
                              _showSchoolSelectionDialog(
                                context,
                              ); // Tampilkan dialog pilih sekolah
                            },
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _getPrimaryColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: _getPrimaryColor().withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    color: _getPrimaryColor(),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ganti Sekolah',
                                    style: TextStyle(
                                      color: _getPrimaryColor(),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Divider(),
                        SizedBox(height: 16),
                      ],

                      // Logout Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                (route) => false,
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.logout_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  AppLocalizations.logout.tr,
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Method baru untuk menampilkan dialog pilihan sekolah
  void _showSchoolSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.school_rounded, color: _getPrimaryColor()),
            SizedBox(width: 8),
            Text(
              'Pilih Sekolah',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoadingSchools)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                )
              else
                ..._accessibleSchools.map((school) {
                  final isCurrent =
                      school['sekolah_id'] == _userData['sekolah_id'];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isCurrent ? null : () => _switchSchool(school),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? _getPrimaryColor().withOpacity(0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent
                                ? _getPrimaryColor().withOpacity(0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.school,
                              color: isCurrent
                                  ? _getPrimaryColor()
                                  : Colors.grey,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    school['nama_sekolah'],
                                    style: TextStyle(
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    school['alamat'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              Icon(
                                Icons.check_circle,
                                color: _getPrimaryColor(),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  // Helper methods untuk colors dan gradients
  Color _getPrimaryColor() {
    switch (widget.role) {
      case 'admin':
        return Color(0xFF4361EE); // Blue
      case 'guru':
        return Color(0xFF2EC4B6); // Teal
      case 'staff':
        return Color(0xFFFF9F1C); // Orange
      case 'wali':
        return Color(0xFF7209B7); // Purple
      default:
        return Color(0xFF4361EE);
    }
  }

  Color _getBackgroundColor() {
    return Color(0xFFF8F9FA);
  }

  LinearGradient _getHeaderGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_getPrimaryColor(), _getPrimaryColor().withOpacity(0.8)],
    );
  }

  LinearGradient _getCardGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_getPrimaryColor(), _getPrimaryColor().withOpacity(0.7)],
    );
  }

  String _getRoleTitle() {
    switch (widget.role) {
      case 'admin':
        return AppLocalizations.adminRole.tr;
      case 'guru':
        return AppLocalizations.teacherRole.tr;
      case 'staff':
        return AppLocalizations.staffRole.tr;
      case 'wali':
        return AppLocalizations.parentRole.tr;
      default:
        return 'User';
    }
  }

  // Keep existing methods for dashboard cards functionality
  List<Widget> _getDashboardCards(BuildContext context) {
    List<Map<String, dynamic>> allCards = [
      {
        'title': AppLocalizations.manageStudents.tr,
        'icon': Icons.people,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StudentManagementScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': AppLocalizations.manageTeachers.tr,
        'icon': Icons.person,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TeacherAdminScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': AppLocalizations.manageClasses.tr,
        'icon': Icons.class_,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ClassManagementScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': AppLocalizations.manageSubjects.tr,
        'icon': Icons.menu_book,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SubjectManagementScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': AppLocalizations.announcements.tr,
        'icon': Icons.announcement,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PengumumanManagementScreen()),
        ),
        'roles': ['admin'],
      },
      // Dalam file dashboard atau menu configuration
      {
        'title': AppLocalizations.announcements.tr,
        'icon': Icons.announcement,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PengumumanScreen()),
        ),
        'roles': ['guru', 'wali'],
      },
      {
        'title': AppLocalizations.studentAttendance.tr,
        'icon': Icons.how_to_reg,
        'onTap': () async {
          final prefs = await SharedPreferences.getInstance();
          final userData = json.decode(prefs.getString('user') ?? '{}');

          print('👤 User data for attendance: $userData');

          final guruData = {
            'id': userData['id'] ?? '',
            'nama': userData['nama'] ?? 'Teacher',
            'email': userData['email'] ?? '',
            'role': widget.role,
          };

          if (guruData['id']!.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: Teacher ID not found')),
              );
            }
            return;
          }

          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PresencePage(guru: guruData),
            ),
          );
        },
        'roles': ['guru'],
      },
      {
        'title': AppLocalizations.inputGrades.tr,
        'icon': Icons.grade,
        'onTap': () async {
          final prefs = await SharedPreferences.getInstance();
          final userData = json.decode(prefs.getString('user') ?? '{}');

          print('👤 User data for grade input: $userData');

          final guruData = {
            'id': userData['id'] ?? '',
            'nama': userData['nama'] ?? 'Teacher',
            'email': userData['email'] ?? '',
            'role': widget.role,
          };

          if (guruData['id']!.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: Teacher ID not found')),
              );
            }
            return;
          }

          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GradePage(guru: guruData)),
          );
        },
        'roles': ['admin', 'guru'],
      },
      {
        'title': AppLocalizations.teachingSchedule.tr,
        'icon': Icons.schedule,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TeachingScheduleScreen()),
        ),
        'roles': ['guru'],
      },
      {
        'title': AppLocalizations.classActivities.tr,
        'icon': Icons.event,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ClassActifityScreen()),
        ),
        'roles': ['guru'],
      },
      {
        'title': 'Kegiatan Kelas',
        'icon': Icons.event_available,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminClassActivityScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': AppLocalizations.learningMaterials.tr,
        'icon': Icons.book,
        'onTap': () async {
          final prefs = await SharedPreferences.getInstance();
          final userData = json.decode(prefs.getString('user') ?? '{}');

          final teacherData = {
            'id': userData['id'] ?? '',
            'name': userData['name'] ?? 'Teacher',
            'role': widget.role,
          };

          if (teacherData['id']!.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: Teacher ID not found')),
              );
            }
            return;
          }
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MateriPage(guru: teacherData),
            ),
          );
        },
        'roles': ['guru'],
      },
      {
        'title': AppLocalizations.manageTeachingSchedule.tr,
        'icon': Icons.schedule,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeachingScheduleManagementScreen(),
          ),
        ),
        'roles': ['admin'],
      },
      {
        'title': AppLocalizations.myRpp.tr,
        'icon': Icons.description,
        'onTap': () async {
          final prefs = await SharedPreferences.getInstance();
          final userData = json.decode(prefs.getString('user') ?? '{}');

          print('👤 User data for RPP: $userData');

          final guruData = {
            'id': userData['id'] ?? '',
            'nama': userData['nama'] ?? 'Teacher',
            'email': userData['email'] ?? '',
            'role': widget.role,
          };

          if (guruData['id']!.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: Teacher ID not found')),
              );
            }
            return;
          }

          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RppScreen(
                guruId: guruData['id']!,
                guruName: guruData['nama']!,
              ),
            ),
          );
        },
        'roles': ['guru'],
      },
      {
        'title': AppLocalizations.manageRpp.tr,
        'icon': Icons.assignment,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminRppScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': 'Laporan Presensi',
        'icon': Icons.assignment,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminPresenceReportScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': 'Keuangan',
        'icon': Icons.event_note,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => KeuanganScreen()),
        ),
        'roles': ['admin'],
      },
      {
        'title': 'Absensi Anak',
        'icon': Icons.calendar_today,
        'onTap': () async {
          final prefs = await SharedPreferences.getInstance();
          final userData = json.decode(prefs.getString('user') ?? '{}');

          print('👤 Parent data: $userData');

          final siswaData = await _getSiswaDataForParent(userData['id'] ?? '');

          if (siswaData.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Tidak ada data siswa/anak ditemukan untuk akun ini',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Informasi'),
                  content: Text(
                    'Tidak ada data siswa yang terhubung dengan akun wali murid ini. Silakan hubungi administrator.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            }
            return;
          }

          if (!context.mounted) return;

          if (siswaData.length == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PresenceParentPage(
                  parent: userData,
                  siswaId: siswaData[0]['id'],
                ),
              ),
            );
          } else {
            _showStudentSelectionDialog(context, userData, siswaData);
          }
        },
        'roles': ['wali'],
      },
      {
        'title': 'Aktivitas Kelas Anak',
        'icon': Icons.event_note,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ParentClassActivityScreen()),
        ),
        'roles': ['wali'],
      },
      {
        'title': 'Keunganan',
        'icon': Icons.event_note,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TagihanWaliScreen()),
        ),
        'roles': ['wali'],
      },
    ];

    return allCards
        .where((card) => card['roles'].contains(widget.role))
        .map(
          (card) =>
              _buildDashboardCard(card['title'], card['icon'], card['onTap']),
        )
        .toList();
  }
}

// Keep your existing helper functions
Future<List<dynamic>> _getSiswaDataForParent(String parentId) async {
  try {
    final allStudents = await ApiStudentService.getStudent();
    final prefs = await SharedPreferences.getInstance();
    final userData = json.decode(prefs.getString('user') ?? '{}');

    if (userData['siswa_id'] != null && userData['siswa_id'].isNotEmpty) {
      final siswa = allStudents.firstWhere(
        (student) => student['id'] == userData['siswa_id'],
        orElse: () => null,
      );
      return siswa != null ? [siswa] : [];
    }

    final siswaWithThisParent = allStudents.where((student) {
      return student['email_wali'] == userData['email'] ||
          student['nama_wali'] == userData['nama'];
    }).toList();

    if (siswaWithThisParent.isNotEmpty) {
      return siswaWithThisParent;
    }

    print('⚠️  Using fallback - showing all students for parent');
    return allStudents;
  } catch (e) {
    print('Error getting student data for parent: $e');
    return [];
  }
}

void _showStudentSelectionDialog(
  BuildContext context,
  Map<String, dynamic> parent,
  List<dynamic> siswaData,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Pilih Anak', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: siswaData.length,
          itemBuilder: (context, index) {
            final siswa = siswaData[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PresenceParentPage(
                        parent: parent,
                        siswaId: siswa['id'],
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFF4361EE).withOpacity(0.1),
                        child: Text(
                          siswa['nama'][0],
                          style: TextStyle(color: Color(0xFF4361EE)),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              siswa['nama'],
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Kelas: ${siswa['kelas_nama'] ?? '-'}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
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
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
        ),
      ],
    ),
  );
}

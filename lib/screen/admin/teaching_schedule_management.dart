import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manajemensekolah/components/confirmation_dialog.dart';
import 'package:manajemensekolah/components/conflict_resolution_dialog.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/filter_section.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/components/schedule_form_dialog.dart';
import 'package:manajemensekolah/components/schedule_list.dart';
import 'package:manajemensekolah/components/enhanced_search_bar.dart';
import 'package:manajemensekolah/services/api_class_services.dart';
import 'package:manajemensekolah/services/api_schedule_services.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/api_subject_services.dart';
import 'package:manajemensekolah/services/api_teacher_services.dart';
import 'package:manajemensekolah/utils/color_utils.dart';
import 'package:manajemensekolah/utils/language_utils.dart';
import 'package:provider/provider.dart';

class TeachingScheduleManagementScreen extends StatefulWidget {
  const TeachingScheduleManagementScreen({super.key});

  @override
  TeachingScheduleManagementScreenState createState() =>
      TeachingScheduleManagementScreenState();
}

class TeachingScheduleManagementScreenState
    extends State<TeachingScheduleManagementScreen> {
  final ApiService _apiService = ApiService();
  final ApiClassService apiServiceClass = ApiClassService();
  final ApiSubjectService _apiSubjectService = ApiSubjectService();
  final ApiTeacherService apiTeacherService = ApiTeacherService();

  List<dynamic> _scheduleList = [];
  List<dynamic> _teacherList = [];
  List<dynamic> _subjectList = [];
  List<dynamic> _classList = [];
  List<dynamic> _hariList = [];
  List<dynamic> _semesterList = [];
  List<dynamic> _jamPelajaranList = [];

  bool _isLoading = true;
  String _selectedSemester = '1';
  String _selectedAcademicYear = '2024/2025';
  final TextEditingController _searchController = TextEditingController();

  // Filter options untuk EnhancedSearchBar
  final List<String> _filterOptions = ['All', 'With Conflicts', 'Without Conflicts'];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final [
        schedule,
        teacher,
        subject,
        classData,
        hari,
        semester,
        jamPelajaran,
      ] = await Future.wait([
        ApiScheduleService.getSchedule(
          semesterId: _selectedSemester,
          tahunAjaran: _selectedAcademicYear,
        ),
        apiTeacherService.getTeacher(),
        _apiSubjectService.getSubject(),
        apiServiceClass.getClass(),
        ApiScheduleService.getHari(),
        ApiScheduleService.getSemester(),
        ApiScheduleService.getJamPelajaran(),
      ]);

      setState(() {
        _scheduleList = schedule;
        _teacherList = teacher;
        _subjectList = subject;
        _classList = classData;
        _hariList = hari;
        _semesterList = semester;
        _jamPelajaranList = jamPelajaran;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data: $e');
      }
      _showErrorSnackBar('Failed to load data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().getTranslatedText({
              'en': message,
              'id': message.replaceAll('Failed to load data:', 'Gagal memuat data:'),
            }),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().getTranslatedText({
              'en': message,
              'id': message.replaceAll('successfully', 'berhasil'),
            }),
          ),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addSchedule() async {
    final result = await showDialog(
      context: context,
      builder: (context) => ScheduleFormDialog(
        teacherList: _teacherList,
        subjectList: _subjectList,
        classList: _classList,
        hariList: _hariList,
        semesterList: _semesterList,
        jamPelajaranList: _jamPelajaranList,
        semester: _selectedSemester,
        academicYear: _selectedAcademicYear,
        apiService: _apiService,
        apiTeacherService: apiTeacherService,
      ),
    );

    if (result != null) {
      await _checkAndResolveConflicts(result);
    }
  }

  Future<void> _editSchedule(dynamic schedule) async {
    final result = await showDialog(
      context: context,
      builder: (context) => ScheduleFormDialog(
        teacherList: _teacherList,
        subjectList: _subjectList,
        classList: _classList,
        hariList: _hariList,
        semesterList: _semesterList,
        jamPelajaranList: _jamPelajaranList,
        semester: _selectedSemester,
        academicYear: _selectedAcademicYear,
        schedule: schedule,
        apiService: _apiService,
        apiTeacherService: apiTeacherService,
      ),
    );

    if (result != null) {
      await _checkAndResolveConflicts(
        result,
        editingScheduleId: schedule['id'],
      );
    }
  }

  Future<void> _deleteSchedule(String id) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return ConfirmationDialog(
            title: languageProvider.getTranslatedText({
              'en': 'Delete Schedule',
              'id': 'Hapus Jadwal',
            }),
            content: languageProvider.getTranslatedText({
              'en': 'Are you sure you want to delete this schedule?',
              'id': 'Apakah Anda yakin ingin menghapus jadwal ini?',
            }),
          );
        },
      ),
    );

    if (confirmed == true) {
      try {
        await ApiScheduleService.deleteSchedule(id);
        _showSuccessSnackBar('Schedule successfully deleted');
        _loadData();
      } catch (e) {
        _showErrorSnackBar('Failed to delete schedule: $e');
      }
    }
  }

  Future<void> _checkAndResolveConflicts(
    Map<String, dynamic> newScheduleData, {
    String? editingScheduleId,
  }) async {
    try {
      // final languageProvider = context.read<LanguageProvider>();

      final conflicts = await ApiScheduleService.getConflictingSchedules(
        hariId: newScheduleData['hari_id'],
        kelasId: newScheduleData['kelas_id'],
        semesterId: newScheduleData['semester_id'],
        tahunAjaran: newScheduleData['tahun_ajaran'],
        jamPelajaranId: newScheduleData['jam_pelajaran_id'],
        excludeScheduleId: editingScheduleId,
      );

      if (conflicts.isNotEmpty) {
        if (!mounted) return;
        final result = await showDialog<String>(
          context: context,
          builder: (context) => ConflictResolutionDialog(
            conflictingSchedules: conflicts,
            onDeleteConfirmed: (scheduleId) =>
                Navigator.pop(context, scheduleId),
            onCancel: () => Navigator.pop(context),
          ),
        );

        if (result != null) {
          await _deleteSchedule(result);

          if (editingScheduleId != null) {
            await ApiScheduleService.updateSchedule(
              editingScheduleId,
              newScheduleData,
            );
          } else {
            await ApiScheduleService.addSchedule(newScheduleData);
          }

          _showSuccessSnackBar('Schedule successfully saved');
          _loadData();
        }
      } else {
        if (editingScheduleId != null) {
          await ApiScheduleService.updateSchedule(
            editingScheduleId,
            newScheduleData,
          );
        } else {
          await ApiScheduleService.addSchedule(newScheduleData);
        }

        _showSuccessSnackBar('Schedule successfully saved');
        _loadData();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save schedule: $e');
    }
  }

  void _onSemesterChanged(String semesterId) {
    setState(() {
      _selectedSemester = semesterId;
      _isLoading = true;
    });
    _loadData();
  }

  void _onAcademicYearChanged(String academicYear) {
    setState(() {
      _selectedAcademicYear = academicYear;
      _isLoading = true;
    });
    _loadData();
  }

  List<dynamic> _getFilteredSchedules() {
    final searchTerm = _searchController.text.toLowerCase();
    return _scheduleList.where((schedule) {
      final subjectName = schedule['mata_pelajaran_nama']?.toString().toLowerCase() ?? '';
      final teacherName = schedule['guru_nama']?.toString().toLowerCase() ?? '';
      final className = schedule['kelas_nama']?.toString().toLowerCase() ?? '';
      final dayName = schedule['hari_nama']?.toString().toLowerCase() ?? '';

      final matchesSearch =
          searchTerm.isEmpty ||
          subjectName.contains(searchTerm) ||
          teacherName.contains(searchTerm) ||
          className.contains(searchTerm) ||
          dayName.contains(searchTerm);

      // Untuk sementara, kita asumsikan semua schedule tanpa konflik
      // Di implementasi nyata, Anda perlu mengecek konflik sebenarnya
      final hasConflict = false; // Ganti dengan logika deteksi konflik sebenarnya
      
      final matchesFilter =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'With Conflicts' && hasConflict) ||
          (_selectedFilter == 'Without Conflicts' && !hasConflict);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        if (_isLoading) {
          return LoadingScreen(
            message: languageProvider.getTranslatedText({
              'en': 'Loading schedule data...',
              'id': 'Memuat data jadwal...',
            }),
          );
        }

        final filteredSchedules = _getFilteredSchedules();

        // Terjemahan filter options
        final translatedFilterOptions = [
          languageProvider.getTranslatedText({'en': 'All', 'id': 'Semua'}),
          languageProvider.getTranslatedText({
            'en': 'With Conflicts',
            'id': 'Dengan Konflik',
          }),
          languageProvider.getTranslatedText({
            'en': 'Without Conflicts',
            'id': 'Tanpa Konflik',
          }),
        ];

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              AppLocalizations.manageTeachingSchedule.tr,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.black),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.black),
                onPressed: _loadData,
                tooltip: AppLocalizations.refresh.tr,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Container(height: 1, color: Colors.grey.shade300),
            ),
          ),
          body: Column(
            children: [
              FilterSection(
                selectedSemester: _selectedSemester,
                selectedAcademicYear: _selectedAcademicYear,
                semesterList: _semesterList,
                onSemesterChanged: _onSemesterChanged,
                onAcademicYearChanged: _onAcademicYearChanged,
              ),
              SizedBox(height: 8),
              EnhancedSearchBar(
                controller: _searchController,
                hintText: languageProvider.getTranslatedText({
                  'en': 'Search schedules...',
                  'id': 'Cari jadwal...',
                }),
                onChanged: (value) {
                  setState(() {});
                },
                filterOptions: translatedFilterOptions,
                selectedFilter: translatedFilterOptions[
                  _selectedFilter == 'All' 
                    ? 0 
                    : _selectedFilter == 'With Conflicts' 
                      ? 1 
                      : 2
                ],
                onFilterChanged: (filter) {
                  final index = translatedFilterOptions.indexOf(filter);
                  setState(() {
                    _selectedFilter = index == 0 
                      ? 'All' 
                      : index == 1 
                        ? 'With Conflicts' 
                        : 'Without Conflicts';
                  });
                },
                showFilter: true,
              ),
              if (filteredSchedules.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${filteredSchedules.length} ${languageProvider.getTranslatedText({
                          'en': 'schedules found',
                          'id': 'jadwal ditemukan',
                        })}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 8),
              Expanded(
                child: filteredSchedules.isEmpty
                    ? EmptyState(
                        title: languageProvider.getTranslatedText({
                          'en': 'No teaching schedules',
                          'id': 'Belum ada jadwal mengajar',
                        }),
                        subtitle: _searchController.text.isEmpty && _selectedFilter == 'All'
                            ? languageProvider.getTranslatedText({
                                'en': 'Tap + to add new schedule',
                                'id': 'Tap + untuk menambah jadwal baru',
                              })
                            : languageProvider.getTranslatedText({
                                'en': 'No search results found',
                                'id': 'Tidak ditemukan hasil pencarian',
                              }),
                        icon: Icons.schedule_outlined,
                      )
                    : ScheduleList(
                        schedules: filteredSchedules,
                        onEditSchedule: _editSchedule,
                        onDeleteSchedule: _deleteSchedule,
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addSchedule,
            backgroundColor: ColorUtils.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}
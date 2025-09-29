import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:manajemensekolah/components/confirmation_dialog.dart';
import 'package:manajemensekolah/components/empty_state.dart';
import 'package:manajemensekolah/components/loading_screen.dart';
import 'package:manajemensekolah/components/search_bar.dart';
import 'package:manajemensekolah/services/api_class_services.dart';
import 'package:manajemensekolah/services/api_schedule_services.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:manajemensekolah/services/api_subject_services.dart';
import 'package:manajemensekolah/services/api_teacher_services.dart';
import 'package:manajemensekolah/utils/color_utils.dart';
import 'package:manajemensekolah/utils/language_utils.dart';

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
  bool _isLoading = true;
  String _selectedSemester = 'Ganjil';
  String _selectedAcademicYear = '2024/2025';

  final List<String> _semesterOptions = ['Ganjil', 'Genap'];
  final List<String> _dayOptions = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final [schedule, teacher, subject, classData] = await Future.wait([
        ApiScheduleService.getSchedule(
          semester: _selectedSemester,
          tahunAjaran: _selectedAcademicYear,
        ),
        apiTeacherService.getTeacher(),
        _apiSubjectService.getSubject(),
        apiServiceClass.getClass(),
      ]);

      setState(() {
        _scheduleList = schedule;
        _teacherList = teacher;
        _subjectList = subject;
        _classList = classData;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().getTranslatedText({
              'en': 'Failed to load data: $e',
              'id': 'Gagal memuat data: $e',
            }),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  // Method helper untuk mendapatkan hari yang valid
  String _getValidDay(String? day) {
    if (day == null || day.isEmpty) return 'Monday';
    
    final dayMapping = {
      'Senin': 'Monday',
      'Selasa': 'Tuesday', 
      'Rabu': 'Wednesday',
      'Kamis': 'Thursday',
      'Jumat': 'Friday',
      'Sabtu': 'Saturday',
      'Minggu': 'Monday'
    };
    
    return dayMapping[day] ?? day;
  }

  // Method helper untuk mendapatkan display day (dalam bahasa Indonesia)
  String _getDisplayDay(String? day) {
    if (day == null || day.isEmpty) return 'Senin';
    
    final dayMapping = {
      'Monday': 'Senin',
      'Tuesday': 'Selasa',
      'Wednesday': 'Rabu',
      'Thursday': 'Kamis',
      'Friday': 'Jumat',
      'Saturday': 'Sabtu',
      'Sunday': 'Minggu',
      'Senin': 'Senin',
      'Selasa': 'Selasa',
      'Rabu': 'Rabu',
      'Kamis': 'Kamis',
      'Jumat': 'Jumat',
      'Sabtu': 'Sabtu',
      'Minggu': 'Minggu'
    };
    
    return dayMapping[day] ?? 'Senin';
  }

  Future<void> _addSchedule() async {
    final result = await showDialog(
      context: context,
      builder: (context) => ScheduleFormDialog(
        teacherList: _teacherList,
        subjectList: _subjectList,
        classList: _classList,
        dayOptions: _dayOptions,
        semester: _selectedSemester,
        academicYear: _selectedAcademicYear,
        apiService: _apiService,
        apiTeacherService: apiTeacherService
      ),
    );

    if (result != null) {
      try {
        await ApiScheduleService.addSchedule(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Schedule successfully added',
                  'id': 'Jadwal berhasil ditambahkan',
                }),
              ),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Failed to add schedule: $e',
                  'id': 'Gagal menambah jadwal: $e',
                }),
              ),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _editSchedule(dynamic schedule) async {
    final result = await showDialog(
      context: context,
      builder: (context) => ScheduleFormDialog(
        teacherList: _teacherList,
        subjectList: _subjectList,
        classList: _classList,
        dayOptions: _dayOptions,
        semester: _selectedSemester,
        academicYear: _selectedAcademicYear,
        schedule: schedule,
        apiService: _apiService,
        apiTeacherService: apiTeacherService
      ),
    );

    if (result != null) {
      try {
        await ApiScheduleService.updateSchedule(schedule['id'], result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Schedule successfully updated',
                  'id': 'Jadwal berhasil diupdate',
                }),
              ),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Failed to update schedule: $e',
                  'id': 'Gagal mengupdate jadwal: $e',
                }),
              ),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Schedule successfully deleted',
                  'id': 'Jadwal berhasil dihapus',
                }),
              ),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageProvider>().getTranslatedText({
                  'en': 'Failed to delete schedule: $e',
                  'id': 'Gagal menghapus jadwal: $e',
                }),
              ),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
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

        final TextEditingController searchController = TextEditingController();
        final filteredSchedules = _scheduleList.where((schedule) {
          final searchTerm = searchController.text.toLowerCase();
          return searchTerm.isEmpty ||
              schedule['subject_name'].toLowerCase().contains(searchTerm) ||
              schedule['teacher_name'].toLowerCase().contains(searchTerm) ||
              schedule['class_name'].toLowerCase().contains(searchTerm);
        }).toList();

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              AppLocalizations.manageTeachingSchedule.tr,
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            backgroundColor: ColorUtils.primaryColor,
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadData,
                tooltip: AppLocalizations.refresh.tr,
              ),
            ],
          ),
          body: Column(
            children: [
              // Header dengan Filter
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ColorUtils.primaryColor, Color(0xFF7C73FA)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.manageTeachingSchedule.tr,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '$_selectedSemester • $_selectedAcademicYear',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Filter Section
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterCard(
                            languageProvider.getTranslatedText({
                              'en': 'Semester',
                              'id': 'Semester',
                            }),
                            _selectedSemester,
                            Icons.school,
                            () => _showSemesterFilter(),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildFilterCard(
                            languageProvider.getTranslatedText({
                              'en': 'Academic Year',
                              'id': 'Tahun Ajaran',
                            }),
                            _selectedAcademicYear,
                            Icons.calendar_today,
                            () => _showAcademicYearDialog(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Search Bar
              CustomSearchBar(
                controller: searchController,
                hintText: languageProvider.getTranslatedText({
                  'en': 'Search schedules...',
                  'id': 'Cari jadwal...',
                }),
                onChanged: (value) => setState(() {}),
              ),

              // Content
              Expanded(
                child: filteredSchedules.isEmpty
                    ? EmptyState(
                        title: languageProvider.getTranslatedText({
                          'en': 'No teaching schedules',
                          'id': 'Belum ada jadwal mengajar',
                        }),
                        subtitle: searchController.text.isEmpty
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
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: filteredSchedules.length,
                        itemBuilder: (context, index) {
                          final schedule = filteredSchedules[index];
                          final day = schedule['day'];
                          final validDay = _getValidDay(day);
                          final displayDay = _getDisplayDay(day);
                          final cardColor = ColorUtils.getDayColor(validDay);

                          return Container(
                            margin: EdgeInsets.only(bottom: 16),
                            child: Material(
                              elevation: 3,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      cardColor.withOpacity(0.9),
                                      cardColor.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Time Section
                                      SizedBox(
                                        width: 70,
                                        child: Column(
                                          children: [
                                            Text(
                                              schedule['jam_mulai'].substring(0, 5),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              height: 20,
                                              color: Colors.white10,
                                              margin: EdgeInsets.symmetric(vertical: 4),
                                            ),
                                            Text(
                                              schedule['jam_selesai'].substring(0, 5),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Vertical Divider
                                      Container(
                                        width: 1,
                                        height: 60,
                                        margin: EdgeInsets.symmetric(horizontal: 16),
                                        color: Colors.white.withOpacity(0.3),
                                      ),

                                      // Content Section
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              schedule['mata_pelajaran_nama'],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  size: 16,
                                                  color: Colors.white.withOpacity(0.8),
                                                ),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    schedule['guru_nama'],
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.9),
                                                      fontSize: 14,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.class_,
                                                  size: 16,
                                                  color: Colors.white.withOpacity(0.8),
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  schedule['kelas_nama'],
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.9),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_month,
                                                  size: 16,
                                                  color: Colors.white.withOpacity(0.8),
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  displayDay,
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.9),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Action Buttons
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit, color: Colors.white),
                                            onPressed: () => _editSchedule(schedule),
                                            tooltip: languageProvider.getTranslatedText({
                                              'en': 'Edit Schedule',
                                              'id': 'Edit Jadwal',
                                            }),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                            onPressed: () => _deleteSchedule(schedule['id']),
                                            tooltip: languageProvider.getTranslatedText({
                                              'en': 'Delete Schedule',
                                              'id': 'Hapus Jadwal',
                                            }),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addSchedule,
            backgroundColor: ColorUtils.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Future<void> _showAcademicYearDialog() async {
    final TextEditingController controller = TextEditingController(text: _selectedAcademicYear);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return AlertDialog(
            title: Text(
              languageProvider.getTranslatedText({
                'en': 'Select Academic Year',
                'id': 'Pilih Tahun Ajaran',
              }),
            ),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: languageProvider.getTranslatedText({
                  'en': 'Example: 2024/2025',
                  'id': 'Contoh: 2024/2025',
                }),
              ),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.cancel.tr),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorUtils.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  languageProvider.getTranslatedText({
                    'en': 'Select',
                    'id': 'Pilih',
                  }),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
    if (result != null && result.isNotEmpty && result != _selectedAcademicYear) {
      setState(() {
        _selectedAcademicYear = result;
        _isLoading = true;
      });
      await _loadData();
    }
  }

  void _showSemesterFilter() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _semesterOptions.map((semester) {
              return ListTile(
                title: Text(semester),
                onTap: () => Navigator.pop(context, semester),
                selected: _selectedSemester == semester,
              );
            }).toList(),
          ),
        );
      },
    );
    if (selected != null && selected != _selectedSemester) {
      setState(() {
        _selectedSemester = selected;
        _isLoading = true;
      });
      await _loadData();
    }
  }

  Widget _buildFilterCard(String label, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label: $value',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class ScheduleFormDialog extends StatefulWidget {
  final List<dynamic> teacherList;
  final List<dynamic> subjectList;
  final List<dynamic> classList;
  final List<String> dayOptions;
  final String semester;
  final String academicYear;
  final dynamic schedule;
  final ApiService apiService;
  final ApiTeacherService apiTeacherService;

  const ScheduleFormDialog({
    super.key,
    required this.teacherList,
    required this.subjectList,
    required this.classList,
    required this.dayOptions,
    required this.semester,
    required this.academicYear,
    this.schedule,
    required this.apiService,
    required this.apiTeacherService
  });

  @override
  ScheduleFormDialogState createState() => ScheduleFormDialogState();
}

class ScheduleFormDialogState extends State<ScheduleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedTeacher;
  late String _selectedSubject;
  late String _selectedClass;
  late String _selectedDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  List<dynamic> _filteredSubjectList = [];
  bool _isLoadingSubjects = false;

  @override
  void initState() {
    super.initState();
    _selectedTeacher = widget.schedule != null ? widget.schedule['teacher_id'] : '';
    _selectedSubject = widget.schedule != null
        ? widget.schedule['subject_id']
        : '';
    _selectedClass = widget.schedule != null ? widget.schedule['class_id'] : '';
    _selectedDay = widget.schedule != null
        ? widget.schedule['day']
        : widget.dayOptions.first;

    _filteredSubjectList = widget.subjectList;

    if (widget.schedule != null) {
      final startTimeParts = widget.schedule['start_time'].split(':');
      final endTimeParts = widget.schedule['end_time'].split(':');
      _startTime = TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      );
      _endTime = TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      );

      if (_selectedTeacher.isNotEmpty) {
        _filterSubjectsByTeacher(_selectedTeacher);
      }
    } else {
      _startTime = TimeOfDay(hour: 7, minute: 0);
      _endTime = TimeOfDay(hour: 8, minute: 0);
    }
  }

  Future<void> _filterSubjectsByTeacher(String teacherId) async {
    try {
      setState(() {
        _isLoadingSubjects = true;
      });
      final teacherSubjects = await widget.apiTeacherService.getSubjectByTeacher(
        teacherId,
      );

      final filtered = widget.subjectList.where((subject) {
        return teacherSubjects.any((teacherSubject) => teacherSubject['id'] == subject['id']);
      }).toList();

      setState(() {
        _filteredSubjectList = filtered;
        _isLoadingSubjects = false;

        if (_selectedSubject.isNotEmpty) {
          final currentSubjectExists = filtered.any(
            (subject) => subject['id'] == _selectedSubject,
          );
          if (!currentSubjectExists) {
            _selectedSubject = '';
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error filtering subjects: $e');
      }
      setState(() {
        _filteredSubjectList = widget.subjectList;
        _isLoadingSubjects = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<LanguageProvider>().getTranslatedText({
                'en': 'Failed to load teacher subjects',
                'id': 'Gagal memuat mata pelajaran guru',
              }),
            ),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: Color(0xFF4F46E5)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.schedule != null 
                    ? languageProvider.getTranslatedText({
                        'en': 'Edit Schedule',
                        'id': 'Edit Jadwal',
                      })
                    : languageProvider.getTranslatedText({
                        'en': 'Add Schedule',
                        'id': 'Tambah Jadwal',
                      }),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDropdownField(
                          languageProvider.getTranslatedText({
                            'en': 'Teacher',
                            'id': 'Guru',
                          }),
                          _selectedTeacher,
                          widget.teacherList,
                          'name',
                          (value) {
                            setState(() {
                              _selectedTeacher = value!;
                              _selectedSubject = '';
                            });

                            if (value != null && value.isNotEmpty) {
                              _filterSubjectsByTeacher(value);
                            } else {
                              setState(() {
                                _filteredSubjectList = widget.subjectList;
                              });
                            }
                          },
                        ),
                        SizedBox(height: 16),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              languageProvider.getTranslatedText({
                                'en': 'Subject',
                                'id': 'Mata Pelajaran',
                              }),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            _isLoadingSubjects
                                ? Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          languageProvider.getTranslatedText({
                                            'en': 'Loading subjects...',
                                            'id': 'Memuat mata pelajaran...',
                                          }),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : _buildDropdownFieldWithoutLabel(
                                    _selectedSubject,
                                    _filteredSubjectList,
                                    'name',
                                    (value) => setState(
                                      () => _selectedSubject = value!,
                                    ),
                                    languageProvider.getTranslatedText({
                                      'en': 'Select Subject',
                                      'id': 'Pilih Mata Pelajaran',
                                    }),
                                  ),
                          ],
                        ),

                        SizedBox(height: 16),
                        _buildDropdownField(
                          languageProvider.getTranslatedText({
                            'en': 'Class',
                            'id': 'Kelas',
                          }),
                          _selectedClass,
                          widget.classList,
                          'name',
                          (value) => setState(() => _selectedClass = value!),
                        ),
                        SizedBox(height: 16),
                        _buildDropdownField(
                          languageProvider.getTranslatedText({
                            'en': 'Day',
                            'id': 'Hari',
                          }),
                          _selectedDay,
                          widget.dayOptions
                              .map((e) => {'value': e, 'name': e})
                              .toList(),
                          'name',
                          (value) => setState(() => _selectedDay = value!),
                        ),
                        SizedBox(height: 16),
                        _buildTimeField(
                          languageProvider.getTranslatedText({
                            'en': 'Start Time',
                            'id': 'Jam Mulai',
                          }),
                          _startTime, 
                          true
                        ),
                        SizedBox(height: 16),
                        _buildTimeField(
                          languageProvider.getTranslatedText({
                            'en': 'End Time',
                            'id': 'Jam Selesai',
                          }),
                          _endTime, 
                          false
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: Text(
                          AppLocalizations.cancel.tr,
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            if (_selectedTeacher.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    languageProvider.getTranslatedText({
                                      'en': 'Please select teacher first',
                                      'id': 'Pilih guru terlebih dahulu',
                                    }),
                                  ),
                                  backgroundColor: Colors.red.shade400,
                                ),
                              );
                              return;
                            }

                            if (_selectedSubject.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    languageProvider.getTranslatedText({
                                      'en': 'Please select subject first',
                                      'id': 'Pilih mata pelajaran terlebih dahulu',
                                    }),
                                  ),
                                  backgroundColor: Colors.red.shade400,
                                ),
                              );
                              return;
                            }

                            final data = {
                              'teacher_id': _selectedTeacher,
                              'subject_id': _selectedSubject,
                              'class_id': _selectedClass,
                              'day': _selectedDay,
                              'start_time':
                                  '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00',
                              'end_time':
                                  '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00',
                              'semester': widget.semester,
                              'academic_year': widget.academicYear,
                            };
                            Navigator.pop(context, data);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          AppLocalizations.save.tr,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<dynamic> items,
    String displayField,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              initialValue: value.isEmpty ? null : value,
              items: items.map<DropdownMenuItem<String>>((item) {
                final displayValue =
                    item[displayField] ?? item['value'] ?? item.toString();
                return DropdownMenuItem<String>(
                  value: item['id'] ?? item['value'] ?? item,
                  child: Text(
                    displayValue.toString(),
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              validator: (value) => value == null ? 'Select $label' : null,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
              dropdownColor: Colors.white,
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFieldWithoutLabel(
    String value,
    List<dynamic> items,
    String displayField,
    ValueChanged<String?> onChanged,
    String hintText,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonFormField<String>(
          initialValue: value.isEmpty ? null : value,
          items: items.map<DropdownMenuItem<String>>((item) {
            final displayValue =
                item[displayField] ?? item['value'] ?? item.toString();
            return DropdownMenuItem<String>(
              value: item['id'] ?? item['value'] ?? item,
              child: Text(
                displayValue.toString(),
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          validator: (value) => value == null ? 'Select Subject' : null,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
          dropdownColor: Colors.white,
          icon: Icon(Icons.arrow_drop_down, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildTimeField(String label, TimeOfDay time, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        GestureDetector(
          onTap: () => _selectTime(context, isStart),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 20, color: Colors.grey.shade600),
                SizedBox(width: 12),
                Text(
                  time.format(context),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                Spacer(),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
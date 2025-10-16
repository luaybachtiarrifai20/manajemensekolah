import 'package:file_picker/file_picker.dart';
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
import 'package:manajemensekolah/services/excel_schedule_service.dart';
import 'package:manajemensekolah/utils/color_utils.dart';
import 'package:manajemensekolah/utils/language_utils.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class TeachingScheduleManagementScreen extends StatefulWidget {
  const TeachingScheduleManagementScreen({super.key});

  @override
  TeachingScheduleManagementScreenState createState() =>
      TeachingScheduleManagementScreenState();
}

class TeachingScheduleManagementScreenState
    extends State<TeachingScheduleManagementScreen>
    with SingleTickerProviderStateMixin {
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

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Filter options untuk EnhancedSearchBar
  final List<String> _filterOptions = [
    'All',
    'With Conflicts',
    'Without Conflicts',
  ];
  String _selectedFilter = 'All';

  // Tambahan untuk tampilan tabel
  bool _showTableView = false;
  List<ScheduleGridData> _gridData = [];
  ScheduleDataSource? _scheduleDataSource;

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

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

      if (!mounted) return;

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

      // Update grid data
      _updateGridData();

      _animationController.forward();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data: $e');
      }

      if (!mounted) return;

      _showErrorSnackBar('Failed to load data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importFromExcel() async {
    final languageProvider = context.read<LanguageProvider>();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);

        await (result != null && result.files.single.path != null
            ? ApiScheduleService.importSchedulesFromExcel(
                File(result.files.single.path!),
              )
            : Future.value());

        // Reload data
        _loadData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.getTranslatedText({
              'en': 'Failed to import file: $e',
              'id': 'Gagal mengimpor file: $e',
            }),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Export jadwal ke Excel
  Future<void> _exportToExcel() async {
    await ExcelScheduleService.exportSchedulesToExcel(
      schedules: _scheduleList,
      context: context,
    );
  }

  // Download template
  Future<void> _downloadTemplate() async {
    try {
      await ExcelScheduleService.downloadTemplate(context);
    } catch (e) {
      _showErrorSnackBar('Download template failed: $e');
    }
  }

  void _updateGridData() {
    _gridData = _generateTimetableData();
    _scheduleDataSource = ScheduleDataSource(_gridData);
  }

  // Method baru untuk menghasilkan data timetable dalam format yang diinginkan
  List<ScheduleGridData> _generateTimetableData() {
    final List<ScheduleGridData> timetableData = [];

    // Group schedules by day and class
    final Map<String, Map<String, Map<String, dynamic>>> dayClassScheduleMap =
        {};

    // Initialize the structure
    for (var day in _hariList) {
      final dayName = day['nama'] ?? '';
      dayClassScheduleMap[dayName] = {};

      for (var classItem in _classList) {
        final className = classItem['nama'] ?? '';
        dayClassScheduleMap[dayName]![className] = {};

        // Initialize all time slots as empty
        for (var jam in _jamPelajaranList) {
          final timeSlot =
              '${jam['jam_mulai'] ?? ''}-${jam['jam_selesai'] ?? ''}';
          dayClassScheduleMap[dayName]![className]![timeSlot] = null;
        }
      }
    }

    // Fill the structure with actual schedules
    for (var schedule in _getFilteredSchedules()) {
      final dayName = schedule['hari_nama'] ?? '';
      final className = schedule['kelas_nama'] ?? '';
      final timeSlot =
          '${schedule['jam_mulai'] ?? ''}-${schedule['jam_selesai'] ?? ''}';
      final subjectName = schedule['mata_pelajaran_nama'] ?? '';
      final teacherName = schedule['guru_nama'] ?? '';

      if (dayClassScheduleMap.containsKey(dayName) &&
          dayClassScheduleMap[dayName]!.containsKey(className)) {
        dayClassScheduleMap[dayName]![className]![timeSlot] = {
          'subject': subjectName,
          'teacher': teacherName,
        };
      }
    }

    // Convert to grid data format
    for (var jam in _jamPelajaranList) {
      final timeSlot = '${jam['jam_mulai'] ?? ''}-${jam['jam_selesai'] ?? ''}';

      // Create a row for each time slot
      for (var day in _hariList) {
        final dayName = day['nama'] ?? '';

        for (var classItem in _classList) {
          final className = classItem['nama'] ?? '';

          final scheduleInfo =
              dayClassScheduleMap[dayName]?[className]?[timeSlot];

          timetableData.add(
            ScheduleGridData(
              id: '${timeSlot}_${dayName}_$className',
              waktu: timeSlot,
              hari: dayName,
              kelas: className,
              mataPelajaran: scheduleInfo?['subject'] ?? '-',
              guru: scheduleInfo?['teacher'] ?? '',
            ),
          );
        }
      }
    }

    return timetableData;
  }

  String _getGradeLevel(String kelasId) {
    try {
      final kelas = _classList.firstWhere(
        (k) => k['id'] == kelasId,
        orElse: () => {},
      );
      return kelas['grade_level']?.toString() ?? '-';
    } catch (e) {
      return '-';
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().getTranslatedText({
              'en': message,
              'id': message.replaceAll(
                'Failed to load data:',
                'Gagal memuat data:',
              ),
            }),
          ),
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.green,
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
            confirmText: languageProvider.getTranslatedText({
              'en': 'Delete',
              'id': 'Hapus',
            }),
            confirmColor: Colors.red,
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

  List<dynamic> _getFilteredSchedules() {
    final searchTerm = _searchController.text.toLowerCase();
    return _scheduleList.where((schedule) {
      final subjectName =
          schedule['mata_pelajaran_nama']?.toString().toLowerCase() ?? '';
      final teacherName = schedule['guru_nama']?.toString().toLowerCase() ?? '';
      final className = schedule['kelas_nama']?.toString().toLowerCase() ?? '';
      final dayName = schedule['hari_nama']?.toString().toLowerCase() ?? '';

      final matchesSearch =
          searchTerm.isEmpty ||
          subjectName.contains(searchTerm) ||
          teacherName.contains(searchTerm) ||
          className.contains(searchTerm) ||
          dayName.contains(searchTerm);

      final hasConflict = false;

      final matchesFilter =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'With Conflicts' && hasConflict) ||
          (_selectedFilter == 'Without Conflicts' && !hasConflict);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // Method untuk export ke Excel
  // Future<void> _exportToExcel() async {
  //   try {
  //     final languageProvider = context.read<LanguageProvider>();

  //     // Create a new Excel document
  //     final xlsio.Workbook workbook = xlsio.Workbook();
  //     final xlsio.Worksheet sheet = workbook.worksheets[0];

  //     // Set header
  //     sheet
  //         .getRangeByIndex(1, 1)
  //         .setText(
  //           languageProvider.getTranslatedText({
  //             'en': 'Teaching Schedule',
  //             'id': 'Jadwal Mengajar',
  //           }),
  //         );
  //     sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 16;
  //     sheet.getRangeByIndex(1, 1).cellStyle.bold = true;

  //     // Set column headers untuk format timetable
  //     final List<String> headers = [
  //       languageProvider.getTranslatedText({'en': 'Time', 'id': 'Waktu'}),
  //     ];

  //     // Add day headers with class subheaders
  //     final days = _hariList.map((day) => day['nama'] ?? '').toList();
  //     final classes = _classList.map((cls) => cls['nama'] ?? '').toList();

  //     for (var day in days) {
  //       for (var className in classes) {
  //         headers.add('$day - $className');
  //       }
  //     }

  //     for (int i = 0; i < headers.length; i++) {
  //       sheet.getRangeByIndex(3, i + 1).setText(headers[i]);
  //       sheet.getRangeByIndex(3, i + 1).cellStyle.bold = true;
  //       sheet.getRangeByIndex(3, i + 1).cellStyle.backColor = '#4361EE';
  //       sheet.getRangeByIndex(3, i + 1).cellStyle.fontColor = '#FFFFFF';
  //     }

  //     // Fill data dalam format timetable
  //     final timeSlots = _jamPelajaranList
  //         .map((jam) => '${jam['jam_mulai'] ?? ''}-${jam['jam_selesai'] ?? ''}')
  //         .toList();

  //     for (int i = 0; i < timeSlots.length; i++) {
  //       final timeSlot = timeSlots[i];
  //       sheet.getRangeByIndex(i + 4, 1).setText(timeSlot);

  //       int colIndex = 2;
  //       for (var day in days) {
  //         for (var className in classes) {
  //           final schedule = _gridData.firstWhere(
  //             (data) =>
  //                 data.waktu == timeSlot &&
  //                 data.hari == day &&
  //                 data.kelas == className,
  //             orElse: () => ScheduleGridData(
  //               id: '',
  //               waktu: '',
  //               hari: '',
  //               kelas: '',
  //               mataPelajaran: '-',
  //               guru: '',
  //             ),
  //           );

  //           final cellValue = schedule.mataPelajaran != '-'
  //               ? '${schedule.mataPelajaran}\n(${schedule.guru})'
  //               : '-';

  //           sheet.getRangeByIndex(i + 4, colIndex).setText(cellValue);
  //           colIndex++;
  //         }
  //       }
  //     }

  //     // Auto fit columns
  //     for (int i = 1; i <= headers.length; i++) {
  //       sheet.autoFitColumn(i);
  //     }

  //     // Save the document
  //     final List<int> bytes = workbook.saveAsStream();
  //     workbook.dispose();

  //     // Get directory
  //     final Directory directory = await getApplicationDocumentsDirectory();
  //     final String path =
  //         '${directory.path}/Jadwal_Mengajar_${DateTime.now().millisecondsSinceEpoch}.xlsx';
  //     final File file = File(path);

  //     await file.writeAsBytes(bytes, flush: true);

  //     // Open the file
  //     await OpenFile.open(path);

  //     _showSuccessSnackBar(
  //       languageProvider.getTranslatedText({
  //         'en': 'Schedule exported successfully',
  //         'id': 'Jadwal berhasil diekspor',
  //       }),
  //     );
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Error exporting to Excel: $e');
  //     }
  //     _showErrorSnackBar('Failed to export schedule: $e');
  //   }
  // }

  Widget _buildTableView() {
    final languageProvider = context.read<LanguageProvider>();
    final days = _hariList.map((day) => day['nama'] ?? '').toList();
    final classes = _classList.map((cls) => cls['nama'] ?? '').toList();
    final timeSlots = _jamPelajaranList
        .map((jam) => '${jam['jam_mulai'] ?? ''}-${jam['jam_selesai'] ?? ''}')
        .toList();

    return Column(
      children: [
        // Header dengan tombol export
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_gridData.length} ${languageProvider.getTranslatedText({'en': 'schedule entries', 'id': 'entri jadwal'})}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _exportToExcel,
                icon: Icon(Icons.file_download, size: 16),
                label: Text(
                  languageProvider.getTranslatedText({
                    'en': 'Export Excel',
                    'id': 'Ekspor Excel',
                  }),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getPrimaryColor(),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // DataGrid dengan format timetable yang di-merge
        Expanded(
          child: Card(
            margin: EdgeInsets.all(8), // Margin lebih kecil
            elevation: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columnSpacing: 1, // Spacing lebih kecil
                  horizontalMargin: 4,
                  headingRowHeight: 80, // Tinggi header tetap
                  dataRowMinHeight: 60, // Tinggi minimum row
                  dataRowMaxHeight: 120, // Tinggi maksimum row
                  headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) => _getPrimaryColor(),
                  ),
                  dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) =>
                        states.contains(MaterialState.selected)
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.08)
                        : null,
                  ),
                  columns: [
                    DataColumn(
                      label: Container(
                        width: 80, // Lebar lebih kecil
                        padding: EdgeInsets.all(4),
                        child: Text(
                          languageProvider.getTranslatedText({
                            'en': 'Time',
                            'id': 'Waktu',
                          }),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12, // Font lebih kecil
                          ),
                        ),
                      ),
                    ),
                    for (var day in days)
                      DataColumn(
                        label: Container(
                          width: 150, // Lebar kolom yang disesuaikan
                          padding: EdgeInsets.all(4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 12, // Font lebih kecil
                                ),
                              ),
                              SizedBox(height: 2),
                              Wrap(
                                spacing: 2,
                                runSpacing: 1,
                                children: classes.map((className) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      className.length > 3
                                          ? className.substring(0, 3)
                                          : className,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8, // Font sangat kecil
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  rows: timeSlots.map((timeSlot) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Container(
                            width: 80,
                            padding: EdgeInsets.all(4),
                            child: Text(
                              timeSlot.length > 11
                                  ? '${timeSlot.substring(0, 11)}\n${timeSlot.substring(11)}'
                                  : timeSlot,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10, // Font lebih kecil
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        for (var day in days)
                          DataCell(
                            Container(
                              width: 150,
                              padding: EdgeInsets.all(2),
                              constraints: BoxConstraints(minHeight: 60),
                              child: _buildDayScheduleCell(timeSlot, day),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayScheduleCell(String timeSlot, String day) {
    final classes = _classList.map((cls) => cls['nama'] ?? '').toList();

    return Container(
      padding: EdgeInsets.all(2),
      constraints: BoxConstraints(
        minHeight: 60, // Tinggi minimum untuk cell
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: classes.map((className) {
          final schedule = _gridData.firstWhere(
            (data) =>
                data.waktu == timeSlot &&
                data.hari == day &&
                data.kelas == className,
            orElse: () => ScheduleGridData(
              id: '',
              waktu: '',
              hari: '',
              kelas: '',
              mataPelajaran: '-',
              guru: '',
            ),
          );

          return Container(
            margin: EdgeInsets.only(bottom: 2),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: schedule.mataPelajaran != '-'
                  ? _getPrimaryColor().withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: schedule.mataPelajaran != '-'
                    ? _getPrimaryColor().withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama kelas - lebih kompak
                Container(
                  width: 30, // Lebar lebih kecil
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  decoration: BoxDecoration(
                    color: schedule.mataPelajaran != '-'
                        ? _getPrimaryColor().withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    className,
                    style: TextStyle(
                      fontSize: 8, // Font lebih kecil
                      fontWeight: FontWeight.bold,
                      color: schedule.mataPelajaran != '-'
                          ? _getPrimaryColor()
                          : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 4),
                // Info mapel dan guru
                Expanded(
                  child: schedule.mataPelajaran != '-'
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schedule.mataPelajaran,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 9, // Font lebih kecil
                                color: Colors.grey[800],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (schedule.guru.isNotEmpty) ...[
                              SizedBox(height: 1),
                              Text(
                                schedule.guru,
                                style: TextStyle(
                                  fontSize: 7, // Font lebih kecil
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        )
                      : Center(
                          child: Text(
                            '-',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                              fontSize: 9,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        }).toList(),
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
          backgroundColor: Color(0xFFF8F9FA),
          appBar: AppBar(
            title: Text(
              languageProvider.getTranslatedText({
                'en': 'Manage Teaching Schedule',
                'id': 'Kelola Jadwal Mengajar',
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
            actions: [
              IconButton(
                icon: Icon(
                  _showTableView ? Icons.view_list : Icons.table_chart,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _showTableView = !_showTableView;
                    if (_showTableView) {
                      _updateGridData();
                    }
                  });
                },
                tooltip: _showTableView
                    ? languageProvider.getTranslatedText({
                        'en': 'Card View',
                        'id': 'Tampilan Kartu',
                      })
                    : languageProvider.getTranslatedText({
                        'en': 'Table View',
                        'id': 'Tampilan Tabel',
                      }),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'export':
                      _exportToExcel();
                      break;
                    case 'import':
                      _importFromExcel();
                      break;
                    case 'template':
                      _downloadTemplate();
                      break;
                    case 'refresh':
                      _loadData();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'export',
                    child: Text(
                      languageProvider.getTranslatedText({
                        'en': 'Export to Excel',
                        'id': 'Export ke Excel',
                      }),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'import',
                    child: Text(
                      languageProvider.getTranslatedText({
                        'en': 'Import from Excel',
                        'id': 'Import dari Excel',
                      }),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'template',
                    child: Text(
                      languageProvider.getTranslatedText({
                        'en': 'Download Template',
                        'id': 'Download Template',
                      }),
                    ),
                  ),
                ],
              ),
            ],
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
                  setState(() {
                    if (_showTableView) {
                      _updateGridData();
                    }
                  });
                },
                filterOptions: translatedFilterOptions,
                selectedFilter:
                    translatedFilterOptions[_selectedFilter == 'All'
                        ? 0
                        : _selectedFilter == 'With Conflicts'
                        ? 1
                        : 2],
                onFilterChanged: (filter) {
                  final index = translatedFilterOptions.indexOf(filter);
                  setState(() {
                    _selectedFilter = index == 0
                        ? 'All'
                        : index == 1
                        ? 'With Conflicts'
                        : 'Without Conflicts';
                    if (_showTableView) {
                      _updateGridData();
                    }
                  });
                },
                showFilter: true,
              ),
              if (!_showTableView && filteredSchedules.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${filteredSchedules.length} ${languageProvider.getTranslatedText({'en': 'schedules found', 'id': 'jadwal ditemukan'})}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 4),
              Expanded(
                child: _showTableView
                    ? _buildTableView()
                    : filteredSchedules.isEmpty
                    ? EmptyState(
                        title: languageProvider.getTranslatedText({
                          'en': 'No teaching schedules',
                          'id': 'Belum ada jadwal mengajar',
                        }),
                        subtitle:
                            _searchController.text.isEmpty &&
                                _selectedFilter == 'All'
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
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: filteredSchedules.length,
                          itemBuilder: (context, index) {
                            final schedule = filteredSchedules[index];
                            return _buildScheduleCard(schedule, index);
                          },
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addSchedule,
            backgroundColor: _getPrimaryColor(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.add, color: Colors.white, size: 20),
          ),
        );
      },
    );
  }

  // ... (sisanya tetap sama - _buildScheduleCard, _buildActionButton, _formatTime, _showScheduleDetail, _buildDetailItem)

  Widget _buildScheduleCard(Map<String, dynamic> schedule, int index) {
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
        onTap: () => _showScheduleDetail(schedule),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showScheduleDetail(schedule),
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

                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header dengan subject dan status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      schedule['mata_pelajaran_nama'] ??
                                          'No Subject',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      schedule['guru_nama'] ?? 'No Teacher',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'Active',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Informasi kelas dan hari
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
                                  Icons.school,
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
                                        'en': 'Class',
                                        'id': 'Kelas',
                                      }),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 1),
                                    Text(
                                      schedule['kelas_nama'] ?? 'No Class',
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

                          // Informasi hari dan jam
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
                                  Icons.access_time,
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
                                        'en': 'Schedule',
                                        'id': 'Jadwal',
                                      }),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 1),
                                    Text(
                                      '${schedule['hari_nama'] ?? ''} • ${_formatTime(schedule)}',
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
                                onPressed: () => _editSchedule(schedule),
                              ),
                              SizedBox(width: 8),
                              _buildActionButton(
                                icon: Icons.delete,
                                label: languageProvider.getTranslatedText({
                                  'en': 'Delete',
                                  'id': 'Hapus',
                                }),
                                color: Colors.white,
                                onPressed: () =>
                                    _deleteSchedule(schedule['id']),
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
    return Container(
      height: 28,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 12, color: _getPrimaryColor()),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _getPrimaryColor(),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 1,
        ),
      ),
    );
  }

  String _formatTime(Map<String, dynamic> schedule) {
    final startTime = schedule['jam_mulai'] ?? '';
    final endTime = schedule['jam_selesai'] ?? '';
    return '$startTime - $endTime';
  }

  void _showScheduleDetail(Map<String, dynamic> schedule) {
    final languageProvider = context.read<LanguageProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.schedule, color: _getPrimaryColor()),
            SizedBox(width: 8),
            Text(
              languageProvider.getTranslatedText({
                'en': 'Schedule Details',
                'id': 'Detail Jadwal',
              }),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getPrimaryColor(),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem(
              icon: Icons.subject,
              title: languageProvider.getTranslatedText({
                'en': 'Subject',
                'id': 'Mata Pelajaran',
              }),
              value: schedule['mata_pelajaran_nama'] ?? 'No Subject',
            ),
            _buildDetailItem(
              icon: Icons.person,
              title: languageProvider.getTranslatedText({
                'en': 'Teacher',
                'id': 'Guru',
              }),
              value: schedule['guru_nama'] ?? 'No Teacher',
            ),
            _buildDetailItem(
              icon: Icons.school,
              title: languageProvider.getTranslatedText({
                'en': 'Class',
                'id': 'Kelas',
              }),
              value: schedule['kelas_nama'] ?? 'No Class',
            ),
            _buildDetailItem(
              icon: Icons.calendar_today,
              title: languageProvider.getTranslatedText({
                'en': 'Day',
                'id': 'Hari',
              }),
              value: schedule['hari_nama'] ?? 'No Day',
            ),
            _buildDetailItem(
              icon: Icons.access_time,
              title: languageProvider.getTranslatedText({
                'en': 'Time',
                'id': 'Waktu',
              }),
              value: _formatTime(schedule),
            ),
            _buildDetailItem(
              icon: Icons.school,
              title: languageProvider.getTranslatedText({
                'en': 'Grade Level',
                'id': 'Tingkat Kelas',
              }),
              value: _getGradeLevel(schedule['kelas_id'] ?? ''),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              languageProvider.getTranslatedText({
                'en': 'Close',
                'id': 'Tutup',
              }),
              style: TextStyle(color: _getPrimaryColor()),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editSchedule(schedule);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getPrimaryColor(),
            ),
            child: Text(
              languageProvider.getTranslatedText({'en': 'Edit', 'id': 'Edit'}),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _getPrimaryColor()),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Data class untuk grid view
class ScheduleGridData {
  final String id;
  final String waktu;
  final String hari;
  final String kelas;
  final String mataPelajaran;
  final String guru;

  ScheduleGridData({
    required this.id,
    required this.waktu,
    required this.hari,
    required this.kelas,
    required this.mataPelajaran,
    required this.guru,
  });
}

// Data source untuk grid view
class ScheduleDataSource extends DataGridSource {
  ScheduleDataSource(List<ScheduleGridData> scheduleData) {
    _scheduleData = scheduleData
        .map<DataGridRow>(
          (e) => DataGridRow(
            cells: [
              DataGridCell<String>(columnName: 'waktu', value: e.waktu),
              DataGridCell<String>(columnName: 'hari', value: e.hari),
              DataGridCell<String>(columnName: 'kelas', value: e.kelas),
              DataGridCell<String>(
                columnName: 'mataPelajaran',
                value: e.mataPelajaran,
              ),
              DataGridCell<String>(columnName: 'guru', value: e.guru),
            ],
          ),
        )
        .toList();
  }

  List<DataGridRow> _scheduleData = [];

  @override
  List<DataGridRow> get rows => _scheduleData;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((e) {
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(8.0),
          child: Text(e.value.toString()),
        );
      }).toList(),
    );
  }
}

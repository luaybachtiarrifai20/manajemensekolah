import 'dart:convert';
import 'dart:io';
import 'package:manajemensekolah/services/api_class_activity_services.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:manajemensekolah/utils/language_utils.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ExcelClassActivityService {
  static const String baseUrl = ApiService.baseUrl;

  // Export data kegiatan kelas ke Excel melalui backend
  static Future<void> exportClassActivitiesToExcel({
    required List<dynamic> activities,
    required BuildContext context,
  }) async {
    final languageProvider = context.read<LanguageProvider>();

    try {
      // Format data terlebih dahulu
      final formattedData = formatActivitiesForExport(activities);

      // Validasi data (dengan handling error yang lebih baik)
      final validatedData = await _validateAndPrepareData(formattedData);

      // Gunakan ApiService yang sudah ada
      final response = await ApiClassActivityService.exportClassActivities(validatedData);

      if (response.statusCode == 200) {
        // Get directory untuk menyimpan file
        final Directory directory = await getApplicationDocumentsDirectory();
        final String filePath =
            '${directory.path}/Data_Kegiatan_Kelas_${DateTime.now().millisecondsSinceEpoch}.xlsx';

        // Simpan file yang didownload
        final File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Buka file
        await OpenFile.open(filePath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.getTranslatedText({
                'en': 'Class activities data exported successfully',
                'id': 'Data kegiatan kelas berhasil diexport',
              }),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ??
              'Failed to export data. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.getTranslatedText({
              'en': 'Failed to export data: $e',
              'id': 'Gagal mengexport data: $e',
            }),
          ),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  // Validasi data yang lebih toleran
  static Future<List<Map<String, dynamic>>> _validateAndPrepareData(
    List<Map<String, dynamic>> activities,
  ) async {
    final List<Map<String, dynamic>> preparedData = [];

    for (final activity in activities) {
      final Map<String, dynamic> preparedActivity = {};

      // Field required dengan default value jika kosong
      preparedActivity['judul'] =
          activity['judul']?.toString() ?? 'Tidak Ada Judul';
      preparedActivity['mata_pelajaran_nama'] =
          activity['mata_pelajaran_nama']?.toString() ??
          'Tidak Ada Mata Pelajaran';
      preparedActivity['kelas_nama'] =
          activity['kelas_nama']?.toString() ?? 'Tidak Ada Kelas';
      preparedActivity['guru_nama'] =
          activity['guru_nama']?.toString() ?? 'Tidak Ada Guru';
      preparedActivity['jenis'] = activity['jenis']?.toString() ?? 'tugas';
      preparedActivity['target'] = activity['target']?.toString() ?? 'umum';

      // Handle tanggal - convert ke format string jika perlu
      if (activity['tanggal'] != null) {
        if (activity['tanggal'] is DateTime) {
          preparedActivity['tanggal'] = (activity['tanggal'] as DateTime)
              .toIso8601String();
        } else {
          preparedActivity['tanggal'] = activity['tanggal'].toString();
        }
      } else {
        preparedActivity['tanggal'] = DateTime.now().toIso8601String();
      }

      // Field optional
      preparedActivity['deskripsi'] = activity['deskripsi'] ?? '';
      preparedActivity['hari'] = activity['hari'] ?? '';
      preparedActivity['batas_waktu'] = activity['batas_waktu'] ?? '';
      preparedActivity['judul_bab'] = activity['judul_bab'] ?? '';
      preparedActivity['judul_sub_bab'] = activity['judul_sub_bab'] ?? '';

      preparedData.add(preparedActivity);
    }

    return preparedData;
  }

  // Method untuk memformat data kegiatan sebelum export
  static List<Map<String, dynamic>> formatActivitiesForExport(
    List<dynamic> rawActivities,
  ) {
    return rawActivities.map((activity) {
      return {
        'judul': activity['judul'] ?? '',
        'mata_pelajaran_nama': activity['mata_pelajaran_nama'] ?? '',
        'kelas_nama': activity['kelas_nama'] ?? '',
        'guru_nama': activity['guru_nama'] ?? '',
        'jenis': activity['jenis'] ?? '',
        'target': activity['target'] ?? '',
        'deskripsi': activity['deskripsi'] ?? '',
        'tanggal': activity['tanggal'] ?? '',
        'hari': activity['hari'] ?? '',
        'batas_waktu': activity['batas_waktu'] ?? '',
        'judul_bab': activity['judul_bab'] ?? '',
        'judul_sub_bab': activity['judul_sub_bab'] ?? '',
      };
    }).toList();
  }
}

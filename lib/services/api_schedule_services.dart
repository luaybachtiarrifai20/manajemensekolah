import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:manajemensekolah/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiScheduleService {
  static const String baseUrl = ApiService.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static dynamic _handleResponse(http.Response response) {
    final responseBody = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      throw Exception(
        responseBody['error'] ??
            'Request failed with status: ${response.statusCode}',
      );
    }
  }

  // Get Hari
  static Future<List<dynamic>> getHari() async {
    final response = await http.get(
      Uri.parse('$baseUrl/hari'),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    return result is List ? result : [];
  }

  // Get Semester
  static Future<List<dynamic>> getSemester() async {
    final response = await http.get(
      Uri.parse('$baseUrl/semester'),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    return result is List ? result : [];
  }

  // Get Jam Pelajaran
  static Future<List<dynamic>> getJamPelajaran() async {
    final response = await http.get(
      Uri.parse('$baseUrl/jam-pelajaran'),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    return result is List ? result : [];
  }

  // Add Jam Pelajaran
  static Future<dynamic> addJamPelajaran(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/jam-pelajaran'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  // Jadwal Mengajar dengan struktur baru
  static Future<List<dynamic>> getSchedule({
    String? guruId,
    String? kelasId,
    String? hariId,
    String? semesterId,
    String? tahunAjaran,
  }) async {
    String url = '$baseUrl/jadwal-mengajar?';
    if (guruId != null) url += 'guru_id=$guruId&';
    if (kelasId != null) url += 'kelas_id=$kelasId&';
    if (hariId != null) url += 'hari_id=$hariId&';
    if (semesterId != null) url += 'semester_id=$semesterId&';
    if (tahunAjaran != null) url += 'tahun_ajaran=$tahunAjaran&';

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    return result is List ? result : [];
  }

  static Future<dynamic> addSchedule(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/jadwal-mengajar'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  static Future<void> updateSchedule(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/jadwal-mengajar/$id'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    _handleResponse(response);
  }

  static Future<void> deleteSchedule(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/jadwal-mengajar/$id'),
      headers: await _getHeaders(),
    );

    _handleResponse(response);
  }

  // Tambahkan method untuk mendapatkan jam pelajaran berdasarkan filter
  static Future<List<dynamic>> getJamPelajaranByFilter({
    String? hariId,
    String? semesterId,
    String? kelasId,
  }) async {
    String url = '$baseUrl/jam-pelajaran-filter?';
    if (hariId != null) url += 'hari_id=$hariId&';
    if (semesterId != null) url += 'semester_id=$semesterId&';
    if (kelasId != null) url += 'kelas_id=$kelasId&';

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    return result is List ? result : [];
  }

  // Tambahkan method ini di class ApiScheduleService
  static Future<List<dynamic>> getConflictingSchedules({
    required String hariId,
    required String kelasId,
    required String semesterId,
    required String tahunAjaran,
    required String jamPelajaranId,
    String? excludeScheduleId, // Untuk edit, exclude jadwal yang sedang diedit
  }) async {
    try {
      String url = '$baseUrl/jadwal-mengajar/conflicts?';
      url += 'hari_id=$hariId&';
      url += 'kelas_id=$kelasId&';
      url += 'semester_id=$semesterId&';
      url += 'tahun_ajaran=$tahunAjaran&';
      url += 'jam_pelajaran_id=$jamPelajaranId&';

      if (excludeScheduleId != null) {
        url += 'exclude_id=$excludeScheduleId&';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      final result = _handleResponse(response);
      return result is List ? result : [];
    } catch (e) {
      if (kDebugMode) {
        print('Error checking conflicts: $e');
      }
      return [];
    }
  }

  // Di class ApiScheduleService, tambahkan method berikut:

  // Get Jadwal Mengajar by Guru ID
  static Future<List<dynamic>> getScheduleByGuru({
    required String guruId,
    String? hariId,
    String? semesterId,
    String? tahunAjaran,
  }) async {
    try {
      String url = '$baseUrl/jadwal-mengajar/guru/$guruId?';
      if (hariId != null && hariId.isNotEmpty) url += 'hari_id=$hariId&';
      if (semesterId != null) url += 'semester_id=$semesterId&';
      if (tahunAjaran != null) url += 'tahun_ajaran=$tahunAjaran&';

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      final result = _handleResponse(response);
      return result is List ? result : [];
    } catch (e) {
      if (kDebugMode) {
        print('Error loading schedule by guru: $e');
      }
      return [];
    }
  }

  // Get Jadwal Mengajar for Current User
  static Future<List<dynamic>> getCurrentUserSchedule({
    String? hariId,
    String? semesterId,
    String? tahunAjaran,
  }) async {
    try {
      String url = '$baseUrl/jadwal-mengajar/current?';
      if (hariId != null && hariId.isNotEmpty) url += 'hari_id=$hariId&';
      if (semesterId != null) url += 'semester_id=$semesterId&';
      if (tahunAjaran != null) url += 'tahun_ajaran=$tahunAjaran&';

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      final result = _handleResponse(response);
      return result is List ? result : [];
    } catch (e) {
      if (kDebugMode) {
        print('Error loading current user schedule: $e');
      }
      return [];
    }
  }

  // Tambahkan method ini di ApiScheduleService
  static Future<List<dynamic>> getFilteredSchedule({
    required String guruId,
    String? hari,
    String? semester,
    String? tahunAjaran,
  }) async {
    try {
      String url = '$baseUrl/jadwal-mengajar/filtered?';
      url += 'guru_id=$guruId&';

      if (hari != null && hari != 'Semua Hari') {
        url += 'hari=$hari&';
      }

      if (semester != null && semester != 'Semua Semester') {
        url += 'semester=$semester&';
      }

      if (tahunAjaran != null) {
        url += 'tahun_ajaran=$tahunAjaran&';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      final result = _handleResponse(response);
      return result is List ? result : [];
    } catch (e) {
      if (kDebugMode) {
        print('Error loading filtered schedule: $e');
      }
      return [];
    }
  }
}

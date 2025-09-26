import 'dart:convert';

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

  // Jadwal Mengajar
  static Future<List<dynamic>> getJadwalMengajar({
    String? guruId,
    String? kelasId,
    String? hari,
    String? semester,
    String? tahunAjaran,
  }) async {
    String url = '$baseUrl/jadwal-mengajar?';
    if (guruId != null) url += 'guru_id=$guruId&';
    if (kelasId != null) url += 'kelas_id=$kelasId&';
    if (hari != null) url += 'hari=$hari&';
    if (semester != null) url += 'semester=$semester&';
    if (tahunAjaran != null) url += 'tahun_ajaran=$tahunAjaran&';

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    return result is List ? result : [];
  }

  static Future<dynamic> tambahJadwalMengajar(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/jadwal-mengajar'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  static Future<void> updateJadwalMengajar(
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

  static Future<void> deleteJadwalMengajar(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/jadwal-mengajar/$id'),
      headers: await _getHeaders(),
    );

    _handleResponse(response);
  }
}

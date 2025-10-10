import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:manajemensekolah/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiSubjectService {
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

  Future<List<dynamic>> getSubject() async {
    final result = await ApiService().get('/mata-pelajaran');
    return result is List ? result : [];
  }

  Future<dynamic> addSubject(Map<String, dynamic> data) async {
    return await ApiService().post('/mata-pelajaran', data);
  }

  Future<void> updateSubject(String id, Map<String, dynamic> data) async {
    await ApiService().put('/mata-pelajaran/$id', data);
  }

  Future<void> deleteSubject(String id) async {
    await ApiService().delete('/mata-pelajaran/$id');
  }

  static Future<List<dynamic>> getContentMateri({
    required String subBabId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/konten-materi?sub_bab_id=$subBabId'),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    return result is List ? result : [];
  }

  static Future<List<dynamic>> getBabMateri({String? mataPelajaranId}) async {
    String url = '$baseUrl/bab-materi?';
    if (mataPelajaranId != null) url += 'mata_pelajaran_id=$mataPelajaranId&';

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    return result is List ? result : [];
  }

  // Sub Bab Materi
  static Future<List<dynamic>> getSubBabMateri({required String babId}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sub-bab-materi?bab_id=$babId'),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    return result is List ? result : [];
  }

  // Tambah Bab Materi
  static Future<dynamic> addBabMateri(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bab-materi'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  // Tambah Sub Bab Materi
  static Future<dynamic> addSubBabMateri(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sub-bab-materi'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  // Tambah Konten Materi
  static Future<dynamic> addContentMateri(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/konten-materi'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  // Update Bab Materi
  static Future<void> updateBabMateri(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/bab-materi/$id'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    _handleResponse(response);
  }

  // Update Sub Bab Materi
  static Future<void> updateSubBabMateri(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/sub-bab-materi/$id'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    _handleResponse(response);
  }

  // Update Konten Materi
  static Future<void> updateContentMateri(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/konten-materi/$id'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    _handleResponse(response);
  }

  // Delete Bab Materi
  static Future<void> deleteBabMateri(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/bab-materi/$id'),
      headers: await _getHeaders(),
    );

    _handleResponse(response);
  }

  // Delete Sub Bab Materi
  static Future<void> deleteSubBabMateri(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/sub-bab-materi/$id'),
      headers: await _getHeaders(),
    );

    _handleResponse(response);
  }

  // Delete Konten Materi
  static Future<void> deleteContentMateri(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/konten-materi/$id'),
      headers: await _getHeaders(),
    );

    _handleResponse(response);
  }

  // Materi
  static Future<List<dynamic>> getMateri({
    String? guruId,
    String? mataPelajaranId,
  }) async {
    String url = '$baseUrl/materi?';
    if (guruId != null) url += 'guru_id=$guruId&';
    if (mataPelajaranId != null) url += 'mata_pelajaran_id=$mataPelajaranId&';

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    return result is List ? result : [];
  }

  static Future<dynamic> addMateri(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/materi'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  static Future<dynamic> saveRPP(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rpp'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getRPPByTeacher(String guruId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/rpp?guru_id=$guruId'),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    return result is List ? result : [];
  }
}

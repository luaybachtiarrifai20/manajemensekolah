import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:manajemensekolah/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiStudentService {
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
  // Kelola Siswa
  static Future<List<dynamic>> getSiswa() async {
    final response = await http.get(
      Uri.parse('$baseUrl/siswa'),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    // Backend mengembalikan array langsung, bukan object dengan property 'data'
    return result is List ? result : [];
  }

  static Future<dynamic> tambahSiswa(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/siswa'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<void> updateSiswa(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/siswa/$id'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    _handleResponse(response);
  }

  static Future<void> deleteSiswa(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/siswa/$id'),
      headers: await _getHeaders(),
    );
    _handleResponse(response);
  }
}

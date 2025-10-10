import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:3000/api'; // iOS simulator atau web

  static const String baseUrl = 'https://backendmanajemensekolah2.vercel.app/api';
  // static const String baseUrl = 'https://libra.web.id/apimanajemen';

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Instance method untuk POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  // Instance method untuk PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  // Dalam ApiService class
  Future<List<dynamic>> getNilaiByMataPelajaran(String mataPelajaranId) async {
    try {
      final semuaNilai = await get('/nilai');
      if (semuaNilai is List) {
        return semuaNilai.where((nilai) {
          return nilai['mata_pelajaran_id'] == mataPelajaranId;
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error filtering nilai: $e');
      return [];
    }
  }

  // Instance method untuk DELETE request
  Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

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

  Future<List<dynamic>> getData(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        // Add authorization header if needed
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load data');
    }
  }

  // Login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['error'] ?? 'Login failed');
    }
  }

  // Nilai
  static Future<List<dynamic>> getNilai({
    String? siswaId,
    String? guruId,
    String? mataPelajaranId,
    String? jenis,
  }) async {
    String url = '$baseUrl/nilai?';
    if (siswaId != null) url += 'siswa_id=$siswaId&';
    if (guruId != null) url += 'guru_id=$guruId&';
    if (mataPelajaranId != null) url += 'mata_pelajaran_id=$mataPelajaranId&';
    if (jenis != null) url += 'jenis=$jenis&';

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    return result is List ? result : [];
  }

  static Future<dynamic> tambahNilai(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/nilai'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  // RPP methods
  static Future<List<dynamic>> getRPP({String? guruId, String? status}) async {
    String url = '$baseUrl/rpp?';
    if (guruId != null) url += 'guru_id=$guruId&';
    if (status != null) url += 'status=$status&';

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    return result is List ? result : [];
  }

  static Future<dynamic> tambahRPP(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rpp'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  static Future<dynamic> updateStatusRPP(
    String rppId,
    String status, {
    String? catatan,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/rpp/$rppId/status'),
      headers: await _getHeaders(),
      body: json.encode({'status': status, 'catatan': catatan}),
    );

    return _handleResponse(response);
  }

  static Future<dynamic> deleteRPP(String rppId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/rpp/$rppId'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Di api_services.dart - Perbaiki fungsi uploadFileRPP
  static Future<dynamic> uploadFileRPP(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/rpp'),
      );

      // Add headers
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      request.headers['Authorization'] = 'Bearer $token';

      // Add file dengan cara yang benar
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Nama field harus sesuai dengan backend
          file.path,
          filename: file.path.split('/').last,
        ),
      );

      // Send request dan dapatkan response
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Upload Response Status: ${response.statusCode}');
      print('Upload Response Body: $responseBody');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(responseBody);
      } else {
        throw Exception(
          'Upload failed with status: ${response.statusCode}. Response: $responseBody',
        );
      }
    } catch (e) {
      print('Upload error details: $e');
      throw Exception('Upload error: $e');
    }
  }

  // Absensi
  static Future<List<dynamic>> getAbsensi({
    String? guruId,
    String? tanggal,
    String? mataPelajaranId,
    String? siswaId,
  }) async {
    String url = '$baseUrl/absensi?';
    if (guruId != null) url += 'guru_id=$guruId&';
    if (tanggal != null) url += 'tanggal=$tanggal&';
    if (mataPelajaranId != null) url += 'mata_pelajaran_id=$mataPelajaranId&';
    if (siswaId != null) url += 'siswa_id=$siswaId&';

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    return result is List ? result : [];
  }

  static Future<List<dynamic>> getAbsensiSummary({String? guruId}) async {
    String url = '$baseUrl/absensi-summary?';
    if (guruId != null) url += 'guru_id=$guruId&';

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    return result is List ? result : [];
  }

  static Future<dynamic> tambahAbsensi(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/absensi'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  // Get kelas by mata pelajaran
  Future<List<dynamic>> getKelasByMataPelajaran(String mataPelajaranId) async {
    try {
      final result = await get(
        '/kelas-by-mata-pelajaran?mata_pelajaran_id=$mataPelajaranId',
      );
      return result is List ? result : [];
    } catch (e) {
      print('Error getting kelas by mata pelajaran: $e');
      return [];
    }
  }

  // Get mata pelajaran with kelas data
  Future<List<dynamic>> getMataPelajaranWithKelas() async {
    try {
      final result = await get('/mata-pelajaran-with-kelas');
      return result is List ? result : [];
    } catch (e) {
      print('Error getting mata pelajaran with kelas: $e');
      return [];
    }
  }

  // Check server health
  static Future<Map<String, dynamic>> checkHealth() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));
    return _handleResponse(response);
  }
}

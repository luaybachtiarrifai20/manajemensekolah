import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  static const String baseUrl =
      'http://localhost:3001/api'; // iOS simulator atau web

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

  Future<List<dynamic>> getKelas() async {
    final result = await get('/kelas');
    return result is List ? result : [];
  }

  Future<dynamic> tambahKelas(Map<String, dynamic> data) async {
    return await post('/kelas', data);
  }

  Future<void> updateKelas(String id, Map<String, dynamic> data) async {
    await put('/kelas/$id', data);
  }

  Future<void> deleteKelas(String id) async {
    await delete('/kelas/$id');
  }

  // Method khusus untuk mendapatkan mata pelajaran by guru ID
  // Future<List<dynamic>> getMataPelajaranByGuru(String guruId) async {
  //   try {
  //     print('Requesting mata pelajaran for guru: $guruId');
  //     final result = await get('/mata-pelajaran-by-guru?guru_id=$guruId');
  //     print('Response received: $result');
  //     return result is List ? result : [];
  //   } catch (e) {
  //     print('Error getting mata pelajaran by guru: $e');
  //     return [];
  //   }
  // }

  // Get mata pelajaran by guru ID
  Future<List<dynamic>> getMataPelajaranByGuru(String guruId) async {
    try {
      print('Requesting mata pelajaran for guru: $guruId');
      final result = await get('/guru/$guruId/mata-pelajaran');
      print('Response received: $result');
      return result is List ? result : [];
    } catch (e) {
      print('Error getting mata pelajaran by guru: $e');
      return [];
    }
  }

  // Add mata pelajaran to guru
  Future<dynamic> addMataPelajaranToGuru(
    String guruId,
    String mataPelajaranId,
  ) async {
    try {
      final result = await post('/guru/$guruId/mata-pelajaran', {
        'mata_pelajaran_id': mataPelajaranId,
      });
      return result;
    } catch (e) {
      print('Error adding mata pelajaran to guru: $e');
      rethrow;
    }
  }

  // Remove mata pelajaran from guru
  Future<void> removeMataPelajaranFromGuru(
    String guruId,
    String mataPelajaranId,
  ) async {
    try {
      await delete('/guru/$guruId/mata-pelajaran/$mataPelajaranId');
    } catch (e) {
      print('Error removing mata pelajaran from guru: $e');
      rethrow;
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

  Future<List<dynamic>> getMataPelajaran() async {
    final result = await get('/mata-pelajaran');
    return result is List ? result : [];
  }

  // Tambahkan method untuk CRUD mata pelajaran
  Future<dynamic> tambahMataPelajaran(Map<String, dynamic> data) async {
    return await post('/mata-pelajaran', data);
  }

  Future<void> updateMataPelajaran(String id, Map<String, dynamic> data) async {
    await put('/mata-pelajaran/$id', data);
  }

  Future<void> deleteMataPelajaran(String id) async {
    await delete('/mata-pelajaran/$id');
  }

  // Guru by ID
  Future<dynamic> getGuruById(String id) async {
    return await get('/guru/$id');
  }

  Future<List<dynamic>> getGuru() async {
    final result = await get('/guru');
    return result is List ? result : [];
  }

  Future<dynamic> tambahGuru(Map<String, dynamic> data) async {
    return await post('/guru', data);
  }

  Future<void> updateGuru(String id, Map<String, dynamic> data) async {
    // Hapus mata_pelajaran_id dari data jika ada
    final cleanData = Map<String, dynamic>.from(data);
    cleanData.remove('mata_pelajaran_id');

    await put('/guru/$id', cleanData);
  }

  Future<void> deleteGuru(String id) async {
    await delete('/guru/$id');
  }

  // Absensi
  static Future<List<dynamic>> getAbsensi({
    String? guruId,
    String? tanggal,
    String? mataPelajaranId,
  }) async {
    String url = '$baseUrl/absensi?';
    if (guruId != null) url += 'guru_id=$guruId&';
    if (tanggal != null) url += 'tanggal=$tanggal&';
    if (mataPelajaranId != null) url += 'mata_pelajaran_id=$mataPelajaranId&';

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

  // Bab Materi
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

  // Konten Materi
  static Future<List<dynamic>> getKontenMateri({
    required String subBabId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/konten-materi?sub_bab_id=$subBabId'),
      headers: await _getHeaders(),
    );

    final result = _handleResponse(response);
    return result is List ? result : [];
  }

  // Tambah Bab Materi
  static Future<dynamic> tambahBabMateri(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bab-materi'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  // Tambah Sub Bab Materi
  static Future<dynamic> tambahSubBabMateri(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sub-bab-materi'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  // Tambah Konten Materi
  static Future<dynamic> tambahKontenMateri(Map<String, dynamic> data) async {
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
  static Future<void> updateKontenMateri(
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
  static Future<void> deleteKontenMateri(String id) async {
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

  static Future<dynamic> tambahMateri(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/materi'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  // RPP
  static Future<List<dynamic>> getRPP({
    String? guruId,
    String? mataPelajaranId,
  }) async {
    String url = '$baseUrl/rpp?';
    if (guruId != null) url += 'guru_id=$guruId&';
    if (mataPelajaranId != null) url += 'mata_pelajaran_id=$mataPelajaranId&';

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

  // Check server health
  static Future<Map<String, dynamic>> checkHealth() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));
    return _handleResponse(response);
  }
}

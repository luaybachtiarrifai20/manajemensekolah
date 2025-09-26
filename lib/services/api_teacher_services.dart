import 'package:flutter/foundation.dart';

import 'api_services.dart';

class ApiTeacherService {
  static const String baseUrl = ApiService.baseUrl;

  // static Future<Map<String, String>> _getHeaders() => ApiService._getHeaders();
  // static dynamic _handleResponse(http.Response response) => ApiService._handleResponse(response);

  Future<List<dynamic>> getTeacher() async {
    final result = await ApiService().get('/guru');
    return result is List ? result : [];
  }

  Future<dynamic> getTeacherById(String id) async {
    return await ApiService().get('/guru/$id');
  }

  Future<dynamic> addTeacher(Map<String, dynamic> data) async {
    return await ApiService().post('/guru', data);
  }

  Future<void> updateTeacher(String id, Map<String, dynamic> data) async {
    final cleanData = Map<String, dynamic>.from(data);
    cleanData.remove('mata_pelajaran_id');
    await ApiService().put('/guru/$id', cleanData);
  }

  Future<void> deleteTeacher(String id) async {
    await ApiService().delete('/guru/$id');
  }

  Future<List<dynamic>> getSubjectByTeacher(String guruId) async {
    try {
      if (kDebugMode) {
        print('Requesting mata pelajaran for guru: $guruId');
      }
      final result = await ApiService().get('/guru/$guruId/mata-pelajaran');
      if (kDebugMode) {
        print('Response received: $result');
      }
      return result is List ? result : [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting mata pelajaran by guru: $e');
      }
      return [];
    }
  }

  Future<dynamic> addSubjectToTeacher(
    String guruId,
    String mataPelajaranId,
  ) async {
    try {
      final result = await ApiService().post('/guru/$guruId/mata-pelajaran', {
        'mata_pelajaran_id': mataPelajaranId,
      });
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding mata pelajaran to guru: $e');
      }
      rethrow;
    }
  }

  Future<void> removeSubjectFromTeacher(
    String guruId,
    String mataPelajaranId,
  ) async {
    try {
      await ApiService().delete(
        '/guru/$guruId/mata-pelajaran/$mataPelajaranId',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error removing mata pelajaran from guru: $e');
      }
      rethrow;
    }
  }
}

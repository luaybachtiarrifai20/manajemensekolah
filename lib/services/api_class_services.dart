import 'package:manajemensekolah/services/api_services.dart';

class ApiClassService {
  static const String baseUrl = ApiService.baseUrl;

  Future<List<dynamic>> getClass() async {
    final result = await ApiService().get('/kelas');
    return result is List ? result : [];
  }

  Future<dynamic> addClass(Map<String, dynamic> data) async {
    return await ApiService().post('/kelas', data);
  }

  Future<void> updateClass(String id, Map<String, dynamic> data) async {
    await ApiService().put('/kelas/$id', data);
  }

  Future<void> deleteClass(String id) async {
    await ApiService().delete('/kelas/$id');
  }
}

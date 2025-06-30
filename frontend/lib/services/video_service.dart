import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config.dart';
import '../models/video.dart';

class VideoService {
  final _storage = const FlutterSecureStorage();

  Future<List<Video>?> fetchVideos() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/videos'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map<Video>((json) => Video.fromJson(json)).toList();
    }
    return null;
  }

  Future<bool> addVideo(Video video) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/videos'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(video.toJson()),
    );
    return response.statusCode == 201;
  }

  Future<bool> editVideo(Video video) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/videos/${video.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(video.toJson()),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteVideo(String id) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/api/videos/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteAllVideos() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/api/videos'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }
}

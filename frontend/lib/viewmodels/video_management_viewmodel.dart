//video_management_viewmodel.dart
import 'package:flutter/material.dart';
import '../models/video.dart';
import '../services/video_service.dart';

class VideoManagementViewModel extends ChangeNotifier {
  final VideoService _videoService = VideoService();

  List<Video> videos = [];
  bool loading = false;
  String? error;

  Future<void> fetchVideos() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      videos = await _videoService.fetchVideos() ?? [];
    } catch (e) {
      error = 'Error al cargar videos';
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> addVideo(Video video) async {
    loading = true;
    notifyListeners();
    final ok = await _videoService.addVideo(video);
    await fetchVideos();
    return ok;
  }

  Future<bool> editVideo(Video video) async {
    loading = true;
    notifyListeners();
    final ok = await _videoService.editVideo(video);
    await fetchVideos();
    return ok;
  }

  Future<bool> deleteVideo(String id) async {
    loading = true;
    notifyListeners();
    final ok = await _videoService.deleteVideo(id);
    await fetchVideos();
    return ok;
  }

  Future<void> deleteAllVideos() async {
    loading = true;
    notifyListeners();
    await _videoService.deleteAllVideos();
    await fetchVideos();
  }
}

import 'package:flutter/material.dart';
import '../models/video.dart';
import '../services/video_service.dart';

class VideoViewModel extends ChangeNotifier {
  final VideoService _service = VideoService();

  List<Video> videos = [];
  bool loading = true;
  String? error;

  Future<void> fetchVideos() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      videos = await _service.fetchVideos() ?? [];
    } catch (e) {
      error = 'Error al cargar los videos';
    }
    loading = false;
    notifyListeners();
  }
}

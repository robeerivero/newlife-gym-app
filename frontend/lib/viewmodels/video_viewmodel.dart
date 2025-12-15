// viewmodels/video_viewmodel.dart
import 'package:flutter/material.dart';
import '../models/video.dart';
import '../services/video_service.dart';

class VideoViewModel extends ChangeNotifier {
  final VideoService _service = VideoService();

  List<Video> videos = [];
  bool loading = false; // Cambiado a false por defecto
  String? error;

  Future<void> fetchVideos({bool forceRefresh = false}) async {
    // Si ya tenemos videos y no forzamos refresco, no hacemos nada
    if (videos.isNotEmpty && !forceRefresh) return;

    loading = true;
    error = null;
    notifyListeners();

    try {
      final fetchedVideos = await _service.fetchVideos();
      videos = fetchedVideos ?? [];
    } catch (e) {
      error = 'Error al cargar los videos';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
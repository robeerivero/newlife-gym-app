// screens/video_player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/video.dart';
import '../../theme/app_theme.dart'; // Tu clase de tema

class VideoPlayerScreen extends StatefulWidget {
  final Video initialVideo;
  final List<Video> playlist;

  const VideoPlayerScreen({
    super.key,
    required this.initialVideo,
    required this.playlist,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  late Video _currentVideo;

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.initialVideo;
    
    final videoId = YoutubePlayer.convertUrlToId(_currentVideo.url) ?? '';

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    );
  }

  // Método clave para no recargar la pantalla completa
  void _loadVideo(Video video) {
    setState(() => _currentVideo = video);
    final id = YoutubePlayer.convertUrlToId(video.url);
    if (id != null) {
      _controller.load(id);
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppTheme.secondary,
        progressColors: const ProgressBarColors(
          playedColor: AppTheme.primary,
          handleColor: AppTheme.secondary,
        ),
        topActions: [
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _currentVideo.titulo,
              style: const TextStyle(color: Colors.white, fontSize: 16.0),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        onReady: () => debugPrint('Reproductor listo'),
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: Text(_currentVideo.titulo)),
          body: Column(
            children: [
              player, // El reproductor
              Expanded(
                child: ListView.builder(
                  itemCount: widget.playlist.length,
                  itemBuilder: (context, index) {
                    final video = widget.playlist[index];
                    final isPlaying = video.id == _currentVideo.id;
                    
                    return ListTile(
                      leading: Image.network(
                        video.thumbnail,
                        width: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.video_library),
                      ),
                      title: Text(
                        video.titulo,
                        style: TextStyle(
                          color: isPlaying ? AppTheme.primary : AppTheme.textPrimary,
                          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: isPlaying ? const Text('Reproduciendo ahora') : null,
                      trailing: isPlaying ? const Icon(Icons.play_circle_fill, color: AppTheme.primary) : null,
                      onTap: () => _loadVideo(video),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
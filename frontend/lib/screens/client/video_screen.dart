import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:convert';
import '../../config.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _videos = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: 'jwt_token');
      
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/videos'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => _videos = json.decode(response.body));
      } else {
        setState(() => _errorMessage = 'Error cargando videos');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error de conexión');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showVideoPlayer(String videoUrl) {
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace no válido')),
      );
      return;
    }

    final currentVideo = _videos.firstWhere(
      (v) => v['url'] == videoUrl,
      orElse: () => {'titulo': 'Video sin título'},
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: OrientationBuilder(
            builder: (context, orientation) {
              return _VideoPlayerContent(
                videoId: videoId,
                videoTitle: currentVideo['titulo'],
                orientation: orientation,
                allVideos: _videos,
                onVideoSelected: (newUrl) => _showVideoPlayer(newUrl),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Tutoriales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: VideoSearch(videos: _videos),
            ),
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return _buildContent(orientation);
        },
      ),
    );
  }

  Widget _buildContent(Orientation orientation) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    if (orientation == Orientation.portrait) {
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildVideoGrid(2),
            _buildRecommendedSection(),
          ],
        ),
      );
    } else {
      return _buildVideoGrid(4);
    }
  }

  Widget _buildVideoGrid(int crossAxisCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return _buildVideoCard(video);
      },
    );
  }

  Widget _buildRecommendedSection() {
    final recommendedVideos = _videos.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Recomendados para ti',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendedVideos.length,
            itemBuilder: (context, index) {
              final video = recommendedVideos[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildVideoCard(video),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(dynamic video) {
    return GestureDetector(
      onTap: () => _showVideoPlayer(video['url']),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10)),
                    child: Image.network(
                      video['thumbnail'] ?? 
                      'https://via.placeholder.com/150',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  const Icon(Icons.play_circle_filled,
                      size: 50, color: Colors.white),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                video['titulo'] ?? 'Sin título',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerContent extends StatefulWidget {
  final String videoId;
  final String videoTitle;
  final Orientation orientation;
  final List<dynamic> allVideos;
  final Function(String) onVideoSelected;

  const _VideoPlayerContent({
    required this.videoId,
    required this.videoTitle,
    required this.orientation,
    required this.allVideos,
    required this.onVideoSelected,
  });

  @override
  State<_VideoPlayerContent> createState() => __VideoPlayerContentState();
}

class __VideoPlayerContentState extends State<_VideoPlayerContent> {
  late YoutubePlayerController _controller;
  Duration _currentPosition = Duration.zero;
  bool _isControllerReady = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        forceHD: true,
      ),
    )..addListener(() {
        if (_isControllerReady) {
          _currentPosition = _controller.value.position;
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.orientation == Orientation.portrait
          ? AppBar(
              title: Text(
                widget.videoTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : null,
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    if (widget.orientation == Orientation.portrait) {
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildVideoPlayer(16 / 9),
            _buildRecommendedVideos(),
          ],
        ),
      );
    } else {
      return _buildVideoPlayer(MediaQuery.of(context).size.aspectRatio);
    }
  }

  Widget _buildVideoPlayer(double aspectRatio) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapPosition = details.globalPosition.dx;
          
          if (tapPosition < screenWidth / 2) {
            _seekBackward();
          } else {
            _seekForward();
          }
        },
        child: YoutubePlayer(
          controller: _controller,
          onReady: () {
            if (_currentPosition.inSeconds > 0) {
              _controller.seekTo(_currentPosition);
            }
            setState(() => _isControllerReady = true);
          },
        ),
      ),
    );
  }

  void _seekForward() {
    final newPosition = _controller.value.position + const Duration(seconds: 10);
    _controller.seekTo(newPosition);
  }

  void _seekBackward() {
    final newPosition = _controller.value.position - const Duration(seconds: 10);
    _controller.seekTo(newPosition > Duration.zero 
        ? newPosition 
        : Duration.zero);
  }

  Widget _buildRecommendedVideos() {
    final recommendedVideos = widget.allVideos
        .where((v) => v['url'] != _controller.metadata.videoId)
        .take(5)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Videos Recomendados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendedVideos.length,
            itemBuilder: (context, index) {
              final video = recommendedVideos[index];
              return Container(
                width: 250,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    onTap: () => widget.onVideoSelected(video['url']),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10)),
                            child: Image.network(
                              video['thumbnail'] ?? 
                              'https://via.placeholder.com/150',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            video['titulo'] ?? 'Sin título',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class VideoSearch extends SearchDelegate {
  final List<dynamic> videos;

  VideoSearch({required this.videos});

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        )
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final results = videos.where((video) =>
        (video['titulo']?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final video = results[index];
        return ListTile(
          leading: Image.network(
            video['thumbnail'] ?? 'https://via.placeholder.com/150',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
          title: Text(video['titulo'] ?? 'Sin título'),
          onTap: () {
            final videoId = YoutubePlayer.convertUrlToId(video['url']);
            if (videoId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(),
                    body: YoutubePlayer(
                      controller: YoutubePlayerController(
                        initialVideoId: videoId,
                        flags: const YoutubePlayerFlags(autoPlay: true),
                      ),
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}



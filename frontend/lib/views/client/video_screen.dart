import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../viewmodels/video_viewmodel.dart';
import '../../models/video.dart';

class VideoScreen extends StatelessWidget {
  const VideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VideoViewModel()..fetchVideos(),
      child: const _VideoScreenBody(),
    );
  }
}

class _VideoScreenBody extends StatefulWidget {
  const _VideoScreenBody({Key? key}) : super(key: key);

  @override
  State<_VideoScreenBody> createState() => _VideoScreenBodyState();
}

class _VideoScreenBodyState extends State<_VideoScreenBody> {
  void _showPlayer(BuildContext context, Video video, List<Video> allVideos) {
    final videoId = YoutubePlayer.convertUrlToId(video.url);

    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace no válido')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          idVideo: videoId,
          tituloVideo: video.titulo,
          todosVideos: allVideos,
        ),
      ),
    );
  }

  Widget _buildVideoCard(Video video, List<Video> allVideos) {
    return GestureDetector(
      onTap: () => _showPlayer(context, video, allVideos),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                video.thumbnail ?? 'https://via.placeholder.com/150',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                video.titulo,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Video> videos, int columns, List<Video> allVideos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: videos.length,
      itemBuilder: (context, idx) => _buildVideoCard(videos[idx], allVideos),
    );
  }

  Widget _buildRecommended(List<Video> videos, List<Video> allVideos) {
    final recomendados = videos.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Recomendados para ti',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recomendados.length,
            itemBuilder: (context, idx) {
              final video = recomendados[idx];
              return Container(
                width: 160,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildVideoCard(video, allVideos),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoViewModel>(
      builder: (context, vm, _) {
        if (vm.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.error != null) {
          return Center(child: Text(vm.error!));
        }
        if (vm.videos.isEmpty) {
          return const Center(child: Text('No hay videos disponibles'));
        }
        final orientation = MediaQuery.of(context).orientation;
        return Scaffold(
          backgroundColor: const Color(0xFFE3F2FD),
          appBar: AppBar(
            title: const Text('Video Tutoriales'),
            backgroundColor: const Color(0xFF1E88E5),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => showSearch(
                  context: context,
                  delegate: VideoSearchDelegate(
                    videos: vm.videos,
                    onSelected: (video) => _showPlayer(context, video, vm.videos),
                  ),
                ),
              ),
            ],
          ),
          body: orientation == Orientation.portrait
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildGrid(vm.videos, 2, vm.videos),
                      _buildRecommended(vm.videos, vm.videos),
                    ],
                  ),
                )
              : _buildGrid(vm.videos, 4, vm.videos),
        );
      },
    );
  }
}

// --- Video Player (igual que antes, pero con modelo) ---
class VideoPlayerScreen extends StatefulWidget {
  final String idVideo;
  final String tituloVideo;
  final List<Video> todosVideos;

  const VideoPlayerScreen({
    required this.idVideo,
    required this.tituloVideo,
    required this.todosVideos,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with AutomaticKeepAliveClientMixin {
  late YoutubePlayerController _controller;
  late String _currentId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentId = widget.idVideo;
    _controller = YoutubePlayerController(
      initialVideoId: _currentId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        forceHD: true,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant VideoPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.idVideo != _currentId) {
      _currentId = widget.idVideo;
      _controller.load(_currentId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDoubleTap(TapDownDetails details, BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;
    final pos = _controller.value.position;
    if (dx < width / 2) {
      _controller.seekTo(pos - const Duration(seconds: 10) > Duration.zero ? pos - const Duration(seconds: 10) : Duration.zero);
    } else {
      _controller.seekTo(pos + const Duration(seconds: 10));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final orientation = MediaQuery.of(context).orientation;
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: orientation == Orientation.portrait
          ? AppBar(
              backgroundColor: const Color(0xFF1E88E5),
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                widget.tituloVideo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : null,
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: orientation == Orientation.portrait
                ? 16 / 9
                : MediaQuery.of(context).size.aspectRatio,
            child: GestureDetector(
              onDoubleTapDown: (details) => _onDoubleTap(details, context),
              child: YoutubePlayer(
                controller: _controller,
                onReady: () {},
              ),
            ),
          ),
          if (orientation == Orientation.portrait)
            ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Videos Recomendados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: widget.todosVideos
                      .where((v) => YoutubePlayer.convertUrlToId(v.url) != _currentId)
                      .take(5)
                      .map((video) => GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentId = YoutubePlayer.convertUrlToId(video.url)!;
                                _controller.load(_currentId);
                              });
                            },
                            child: Card(
                              child: SizedBox(
                                width: 160,
                                child: Column(
                                  children: [
                                    Image.network(video.thumbnail ?? 'https://via.placeholder.com/150'),
                                    Text(
                                      video.titulo,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ]
        ],
      ),
    );
  }
}

// --- Buscador de videos usando modelo ---
class VideoSearchDelegate extends SearchDelegate {
  final List<Video> videos;
  final Function(Video) onSelected;

  VideoSearchDelegate({required this.videos, required this.onSelected});

  @override
  String get searchFieldLabel => 'Buscar por título...';

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
  Widget buildResults(BuildContext context) => _buildResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults();

  Widget _buildResults() {
    final resultados = videos.where((video) =>
        video.titulo.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: resultados.length,
      itemBuilder: (context, index) {
        final video = resultados[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(video.thumbnail ?? 'https://via.placeholder.com/150'),
          ),
          title: Text(video.titulo),
          subtitle: const Text('Haz clic para reproducir'),
          onTap: () {
            close(context, null);
            onSelected(video);
          },
        );
      },
    );
  }
}

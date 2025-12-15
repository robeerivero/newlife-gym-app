// lib/views/client/video_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importaciones con rutas corregidas (subiendo dos niveles)
import '../../viewmodels/video_viewmodel.dart';
import '../../models/video.dart';
import '../../theme/app_theme.dart';
import 'video_player_screen.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  @override
  void initState() {
    super.initState();
    // Persistencia: Solo cargamos de la API si la lista en memoria está vacía
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<VideoViewModel>(context, listen: false);
      if (vm.videos.isEmpty) {
        vm.fetchVideos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Videos'),
        actions: [
          // Botón de búsqueda que utiliza el Delegate de abajo
          Consumer<VideoViewModel>(
            builder: (context, vm, child) {
              return IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: VideoSearchDelegate(vm.videos),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<VideoViewModel>(
        builder: (context, vm, child) {
          if (vm.loading && vm.videos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.error != null && vm.videos.isEmpty) {
            return Center(child: Text(vm.error!));
          }

          return RefreshIndicator(
            onRefresh: () => vm.fetchVideos(forceRefresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: vm.videos.length,
              itemBuilder: (context, index) {
                final video = vm.videos[index];
                return _VideoLargeCard(video: video, playlist: vm.videos);
              },
            ),
          );
        },
      ),
    );
  }
}

/// Widget interno para la Tarjeta Grande del Video
class _VideoLargeCard extends StatelessWidget {
  final Video video;
  final List<Video> playlist;

  const _VideoLargeCard({required this.video, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              initialVideo: video,
              playlist: playlist,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen con Icono de Play superpuesto
            Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  video.thumbnail,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.videocam_off, size: 50),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                ),
              ],
            ),
            // Título e Información
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Entrenamiento disponible",
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      Text(
                        "VER AHORA",
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lógica de Búsqueda
class VideoSearchDelegate extends SearchDelegate {
  final List<Video> allVideos;

  VideoSearchDelegate(this.allVideos);

  @override
  String get searchFieldLabel => 'Buscar por nombre...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final filtered = allVideos
        .where((v) => v.titulo.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      return const Center(child: Text("No se encontraron resultados"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final video = filtered[index];
        // Usamos la misma tarjeta para mantener la estética
        return _VideoLargeCard(video: video, playlist: allVideos);
      },
    );
  }
}
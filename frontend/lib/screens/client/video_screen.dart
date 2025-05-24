import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:convert';
import '../../config.dart';

// Pantalla principal de videos
class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _EstadoVideoScreen();
}

class _EstadoVideoScreen extends State<VideoScreen> {
  final FlutterSecureStorage _almacenamiento = const FlutterSecureStorage();
  bool _cargando = true;
  String _mensajeError = '';
  List<dynamic> _videos = [];

  @override
  void initState() {
    super.initState();
    _obtenerVideos();
  }

  Future<void> _obtenerVideos() async {
    setState(() => _cargando = true);

    try {
      final token = await _almacenamiento.read(key: 'jwt_token');
      final respuesta = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/videos'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (respuesta.statusCode == 200) {
        setState(() => _videos = json.decode(respuesta.body));
      } else {
        setState(() => _mensajeError = 'Error cargando videos');
      }
    } catch (e) {
      setState(() => _mensajeError = 'Error de conexión');
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _mostrarReproductor(String urlVideo) {
    final idVideo = YoutubePlayer.convertUrlToId(urlVideo);

    if (idVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace no válido')),
      );
      return;
    }

    final videoActual = _videos.firstWhere(
      (v) => v['url'] == urlVideo,
      orElse: () => {'titulo': 'Video sin título'},
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContenidoReproductorConEstado(
          idVideo: idVideo,
          tituloVideo: videoActual['titulo'],
          todosVideos: _videos,
        ),
      ),
    );
  }

  Widget _construirTarjetaVideo(dynamic video) {
    return GestureDetector(
      onTap: () => _mostrarReproductor(video['url']),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                video['thumbnail'] ?? 'https://via.placeholder.com/150',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                video['titulo'] ?? 'Sin título',
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

  Widget _construirCuadricula(int columnas) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnas,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: _videos.length,
      itemBuilder: (context, indice) {
        final video = _videos[indice];
        return _construirTarjetaVideo(video);
      },
    );
  }

  Widget _construirSeccionRecomendados() {
    final recomendados = _videos.take(5).toList();

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
            itemBuilder: (context, indice) {
              final video = recomendados[indice];
              return Container(
                width: 160,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: _construirTarjetaVideo(video),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _construirContenido(Orientation orientacion) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_mensajeError.isNotEmpty) {
      return Center(child: Text(_mensajeError));
    }

    return orientacion == Orientation.portrait
        ? SingleChildScrollView(
            child: Column(
              children: [
                _construirCuadricula(2),
                _construirSeccionRecomendados(),
              ],
            ),
          )
        : _construirCuadricula(4);
  }

  @override
  Widget build(BuildContext context) {
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
              delegate: BuscadorVideos(
                videos: _videos,
                alSeleccionar: _mostrarReproductor,
              ),
            ),
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientacion) {
          return _construirContenido(orientacion);
        },
      ),
    );
  }
}

// El reproductor ahora es Stateful y mantiene el controlador mientras la pantalla esté en memoria
class ContenidoReproductorConEstado extends StatefulWidget {
  final String idVideo;
  final String tituloVideo;
  final List<dynamic> todosVideos;

  const ContenidoReproductorConEstado({
    required this.idVideo,
    required this.tituloVideo,
    required this.todosVideos,
  });

  @override
  State<ContenidoReproductorConEstado> createState() => _ContenidoReproductorConEstadoState();
}

class _ContenidoReproductorConEstadoState extends State<ContenidoReproductorConEstado> with AutomaticKeepAliveClientMixin {
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
  void didUpdateWidget(covariant ContenidoReproductorConEstado oldWidget) {
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

  // Doble tap para avanzar/retroceder 10 segundos
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

    final orientacion = MediaQuery.of(context).orientation;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: orientacion == Orientation.portrait
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
            aspectRatio: orientacion == Orientation.portrait ? 16 / 9 : MediaQuery.of(context).size.aspectRatio,
            child: GestureDetector(
              onDoubleTapDown: (details) => _onDoubleTap(details, context),
              child: YoutubePlayer(
                controller: _controller,
                onReady: () {},
              ),
            ),
          ),
          if (orientacion == Orientation.portrait)
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
                      .where((v) => YoutubePlayer.convertUrlToId(v['url']) != _currentId)
                      .take(5)
                      .map((video) => GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentId = YoutubePlayer.convertUrlToId(video['url'])!;
                                _controller.load(_currentId);
                              });
                            },
                            child: Card(
                              child: SizedBox(
                                width: 160,
                                child: Column(
                                  children: [
                                    Image.network(video['thumbnail'] ?? 'https://via.placeholder.com/150'),
                                    Text(
                                      video['titulo'] ?? 'Sin título',
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

// Buscador de videos
class BuscadorVideos extends SearchDelegate {
  final List<dynamic> videos;
  final Function(String) alSeleccionar;

  BuscadorVideos({required this.videos, required this.alSeleccionar});

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
  Widget buildResults(BuildContext context) => _construirResultados();

  @override
  Widget buildSuggestions(BuildContext context) => _construirResultados();

  Widget _construirResultados() {
    final resultados = videos.where((video) =>
        (video['titulo']?.toString().toLowerCase().contains(query.toLowerCase()) ?? false)).toList();

    return ListView.builder(
      itemCount: resultados.length,
      itemBuilder: (context, index) {
        final video = resultados[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(video['thumbnail'] ?? 'https://via.placeholder.com/150'),
          ),
          title: Text(video['titulo'] ?? 'Sin título'),
          subtitle: const Text('Haz clic para reproducir'),
          onTap: () {
            close(context, null);
            alSeleccionar(video['url']);
          },
        );
      },
    );
  }
}

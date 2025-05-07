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
  final TextEditingController _controladorBusqueda = TextEditingController();

  @override
  void initState() {
    super.initState();
    _obtenerVideos();
  }

  // Obtiene los videos desde la API
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

  // Muestra el reproductor de video
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
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFFE3F2FD),
          body: OrientationBuilder(
            builder: (context, orientacion) {
              return ContenidoReproductor(
                idVideo: idVideo,
                tituloVideo: videoActual['titulo'],
                orientacion: orientacion,
                todosVideos: _videos,
                alSeleccionarVideo: (nuevaUrl) => _mostrarReproductor(nuevaUrl),
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

  // Construye el contenido según la orientación
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

  // Cuadrícula de videos
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

  // Sección de videos recomendados
  Widget _construirSeccionRecomendados() {
    final recomendados = _videos.take(5).toList();
    
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

  // Tarjeta individual de video
  Widget _construirTarjetaVideo(dynamic video) {
    return GestureDetector(
      onTap: () => _mostrarReproductor(video['url']),
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
                      cacheWidth: 300,
                      loadingBuilder: (context, child, progreso) => progreso == null 
                          ? child 
                          : const CircularProgressIndicator(),
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

// Contenido del reproductor de video
class ContenidoReproductor extends StatefulWidget {
  final String idVideo;
  final String tituloVideo;
  final Orientation orientacion;
  final List<dynamic> todosVideos;
  final Function(String) alSeleccionarVideo;

  const ContenidoReproductor({
    required this.idVideo,
    required this.tituloVideo,
    required this.orientacion,
    required this.todosVideos,
    required this.alSeleccionarVideo,
  });

  @override
  State<ContenidoReproductor> createState() => _EstadoContenidoReproductor();
}

class _EstadoContenidoReproductor extends State<ContenidoReproductor> {
  late YoutubePlayerController _controlador;
  Duration _posicionActual = Duration.zero;
  bool _controladorListo = false;

  @override
  void initState() {
    super.initState();
    _inicializarControlador();
  }

  void _inicializarControlador() {
    _controlador = YoutubePlayerController(
      initialVideoId: widget.idVideo,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        forceHD: true,
      ),
    )..addListener(() {
        if (_controladorListo) {
          _posicionActual = _controlador.value.position;
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: widget.orientacion == Orientation.portrait
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
      body: _construirContenidoPrincipal(),
    );
  }

  Widget _construirContenidoPrincipal() {
    return widget.orientacion == Orientation.portrait
        ? SingleChildScrollView(
            child: Column(
              children: [
                _construirReproductor(16 / 9),
                _construirVideosRecomendados(),
              ],
            ),
          )
        : _construirReproductor(MediaQuery.of(context).size.aspectRatio);
  }

  Widget _construirReproductor(double relacionAspecto) {
    return AspectRatio(
      aspectRatio: relacionAspecto,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTapDown: (detalles) {
          final anchoPantalla = MediaQuery.of(context).size.width;
          final posicionToque = detalles.globalPosition.dx;
          
          posicionToque < anchoPantalla / 2
              ? _retroceder()
              : _avanzar();
        },
        child: YoutubePlayer(
          controller: _controlador,
          onReady: () {
            if (_posicionActual.inSeconds > 0) {
              _controlador.seekTo(_posicionActual);
            }
            setState(() => _controladorListo = true);
          },
        ),
      ),
    );
  }

  void _avanzar() {
    final nuevaPosicion = _controlador.value.position + const Duration(seconds: 10);
    _controlador.seekTo(nuevaPosicion);
  }

  void _retroceder() {
    final nuevaPosicion = _controlador.value.position - const Duration(seconds: 10);
    _controlador.seekTo(nuevaPosicion > Duration.zero 
        ? nuevaPosicion 
        : Duration.zero);
  }

  Widget _construirVideosRecomendados() {
    final recomendados = widget.todosVideos
        .where((v) => v['url'] != _controlador.metadata.videoId)
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
            itemCount: recomendados.length,
            itemBuilder: (context, indice) {
              final video = recomendados[indice];
              return Container(
                width: 250,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    onTap: () => widget.alSeleccionarVideo(video['url']),
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
    _controlador.dispose();
    super.dispose();
  }
}

// Buscador de videos
class BuscadorVideos extends SearchDelegate {
  final List<dynamic> videos;
  final Function(String) alSeleccionar;

  BuscadorVideos({required this.videos, required this.alSeleccionar});

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
      (video['titulo']?.toString().toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();

    return ListView.builder(
      itemCount: resultados.length,
      itemBuilder: (context, indice) {
        final video = resultados[indice];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(video['thumbnail'] ?? 'https://via.placeholder.com/150'),
          ),
          title: Text(video['titulo'] ?? 'Sin título'),
          subtitle: const Text('Haz clic para reproducir'),
          onTap: () {
            close(context, null); // Cerrar buscador primero
            alSeleccionar(video['url']); // Luego navegar
          },
        );
      },
    );
  }
}
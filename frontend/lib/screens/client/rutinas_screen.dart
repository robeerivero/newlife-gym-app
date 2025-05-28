import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:convert';
import '../../config.dart';

class RutinasScreen extends StatefulWidget {
  const RutinasScreen({super.key});

  @override
  State<RutinasScreen> createState() => _RutinasScreenState();
}

class _RutinasScreenState extends State<RutinasScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool isLoading = true;
  String errorMessage = '';
  List<dynamic> rutinas = [];

  @override
  void initState() {
    super.initState();
    fetchRutinas();
  }

  Future<void> fetchRutinas() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        setState(() {
          errorMessage = 'Token no encontrado. Por favor, inicia sesión.';
          rutinas = [];
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/rutinas/usuario'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          rutinas = json.decode(response.body);
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage = 'Error al cargar rutinas.';
          rutinas = [];
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error de conexión.';
        rutinas = [];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showVideoFullScreen(String videoUrl, {String? titulo}) {
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);

    if (videoId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(titulo ?? "Video", style: const TextStyle(color: Colors.white)),
            ),
            body: SafeArea(
              child: Center(
                child: YoutubePlayer(
                  controller: YoutubePlayerController(
                    initialVideoId: videoId,
                    flags: const YoutubePlayerFlags(
                      autoPlay: true,
                      mute: false,
                    ),
                  ),
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.blue,
                ),
              ),
            ),
          ),
          fullscreenDialog: true,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL de video inválida')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: const Text('Mis Rutinas', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Recargar rutinas",
            onPressed: fetchRutinas,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(errorMessage,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
                )
              : rutinas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.fitness_center, size: 72, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No tienes rutinas asignadas todavía.',
                              style: TextStyle(color: Colors.black54, fontSize: 17)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                      itemCount: rutinas.length,
                      itemBuilder: (context, index) {
                        final rutina = rutinas[index];
                        final diaSemana = rutina['diaSemana'];
                        final ejercicios = rutina['ejercicios'];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17)),
                          elevation: 5,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                              splashColor: Colors.blue[50],
                            ),
                            child: ExpansionTile(
                              leading: const Icon(Icons.today, color: Color(0xFF1E88E5)),
                              title: Text(
                                diaSemana ?? 'Día no especificado',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              children: ejercicios.map<Widget>((ejercicio) {
                                final datos = ejercicio['ejercicio'];
                                final videoUrl = datos?['video'] ?? '';
                                final descripcion = datos?['descripcion'] ?? 'Sin descripción';
                                final nombre = datos?['nombre']?.toUpperCase() ?? 'Sin nombre';

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                                  leading: const Icon(Icons.sports_gymnastics, color: Colors.deepPurple),
                                  title: Text(
                                    nombre,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Series: ${ejercicio['series']}   Reps: ${ejercicio['repeticiones']}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      if (descripcion.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 3),
                                          child: Text(descripcion,
                                              style: const TextStyle(
                                                  fontSize: 13, color: Colors.black54)),
                                        ),
                                    ],
                                  ),
                                  trailing: videoUrl.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.play_circle_fill,
                                              color: Colors.blue, size: 32),
                                          onPressed: () => showVideoFullScreen(videoUrl, titulo: nombre),
                                        )
                                      : null,
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text(nombre),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(descripcion),
                                            const SizedBox(height: 10),
                                            Text(
                                              "Series: ${ejercicio['series']} - Reps: ${ejercicio['repeticiones']}",
                                              style: const TextStyle(
                                                  color: Colors.black87),
                                            ),
                                            if (videoUrl.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 16),
                                                child: ElevatedButton.icon(
                                                  icon: const Icon(Icons.play_circle_fill),
                                                  label: const Text('Ver Video'),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    showVideoFullScreen(videoUrl, titulo: nombre);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.blue[700],
                                                    foregroundColor: Colors.white,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

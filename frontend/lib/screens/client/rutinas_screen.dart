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
  setState(() => isLoading = true);

  try {
    final token = await _storage.read(key: 'jwt_token');

    if (token == null ) {
      setState(() {
        errorMessage = 'Token no encontrado. Por favor, inicia sesión.';
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
      });
    } else {
      setState(() {
        errorMessage = 'Error al cargar rutinas.';
      });
    }
  } catch (e) {
    setState(() {
      errorMessage = 'Error de conexión.';
    });
  } finally {
    setState(() => isLoading = false);
  }
}


  void showVideo(String videoUrl) {
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);

    if (videoId != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          contentPadding: const EdgeInsets.all(0),
          content: YoutubePlayer(
            controller: YoutubePlayerController(
              initialVideoId: videoId,
              flags: const YoutubePlayerFlags(
                autoPlay: true,
                mute: false,
              ),
            ),
          ),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : ListView.builder(
                  itemCount: rutinas.length,
                  itemBuilder: (context, index) {
                    final rutina = rutinas[index];
                    final diaSemana = rutina['diaSemana'];
                    final ejercicios = rutina['ejercicios'];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ExpansionTile(
                        title: Text(
                          diaSemana ?? 'Día no especificado',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        children: ejercicios.map<Widget>((ejercicio) {
                          final videoUrl = ejercicio['ejercicio']['video'] ?? '';
                          final descripcion = ejercicio['ejercicio']['descripcion'] ?? 'Sin descripción';

                          return ListTile(
                            title: Text(ejercicio['ejercicio']['nombre']?.toUpperCase() ?? 'Sin nombre'),
                            subtitle: Text(
                              'Series: ${ejercicio['series']} - Repeticiones: ${ejercicio['repeticiones']}',
                            ),
                            trailing: videoUrl.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.play_circle_fill, color: Colors.blue),
                                    onPressed: () {
                                      showVideo(videoUrl);
                                    },
                                  )
                                : null,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(ejercicio['ejercicio']['nombre']?.toUpperCase() ?? 'Sin nombre'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(descripcion),
                                      const SizedBox(height: 10),
                                      if (videoUrl.isNotEmpty)
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            showVideo(videoUrl);
                                          },
                                          child: const Text('Ver Video'),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
    );
  }
}

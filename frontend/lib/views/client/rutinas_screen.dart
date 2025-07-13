import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../viewmodels/rutinas_viewmodel.dart';
import '../../models/rutina.dart';

class RutinasScreen extends StatelessWidget {
  const RutinasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RutinasViewModel()..fetchRutinas(),
      child: const _RutinasBody(),
    );
  }
}

class _RutinasBody extends StatelessWidget {
  const _RutinasBody({super.key});

  void showVideo(BuildContext context, String url, String nombre) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video inválido')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(nombre, style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: YoutubePlayerBuilder(
            player: YoutubePlayer(
              controller: YoutubePlayerController(
                initialVideoId: videoId,
                flags: const YoutubePlayerFlags(autoPlay: true),
              ),
              showVideoProgressIndicator: true,
            ),
            builder: (context, player) => Center(child: player),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RutinasViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.errorMessage.isNotEmpty) {
          return Center(
            child: Text(vm.errorMessage,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
          );
        }

        if (vm.rutinas.isEmpty) {
          return const Center(
            child: Text('No tienes rutinas asignadas.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: vm.rutinas.length,
          itemBuilder: (context, index) {
            final rutina = vm.rutinas[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rutina.diaSemana,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                    const Divider(height: 18, thickness: 1.2),
                    ...rutina.ejercicios.map((ej) {
                      final nombre = ej.ejercicio.nombre;
                      final series = ej.series;
                      final reps = ej.repeticiones;
                      final video = ej.ejercicio.video;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.fitness_center, color: Colors.deepPurple),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Series: $series   Reps: $reps', style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            if (video.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 28),
                                onPressed: () => showVideo(context, video, nombre),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

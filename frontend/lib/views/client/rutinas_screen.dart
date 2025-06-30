// ==========================
// lib/views/client/rutinas_screen.dart
// ==========================

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
  const _RutinasBody({Key? key}) : super(key: key);

  void showVideoFullScreen(BuildContext context, String videoUrl, {String? titulo}) {
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
    return Consumer<RutinasViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.errorMessage.isNotEmpty) {
          return Center(
            child: Text(
              vm.errorMessage,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          );
        }
        if (vm.rutinas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.fitness_center, size: 72, color: Colors.grey),
                SizedBox(height: 16),
                Text('No tienes rutinas asignadas todavía.',
                    style: TextStyle(color: Colors.black54, fontSize: 17)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          itemCount: vm.rutinas.length,
          itemBuilder: (context, index) {
            final rutina = vm.rutinas[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
              elevation: 5,
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: Colors.blue[50],
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.today, color: Color(0xFF1E88E5)),
                  title: Text(
                    rutina.diaSemana.isNotEmpty ? rutina.diaSemana : 'Día no especificado',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  children: rutina.ejercicios.map<Widget>((ejercicioRutina) {
                    final nombre = ejercicioRutina.ejercicio.nombre;
                    final series = ejercicioRutina.series;
                    final repeticiones = ejercicioRutina.repeticiones;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                      leading: const Icon(Icons.sports_gymnastics, color: Colors.deepPurple),
                      title: Text(
                        nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Series: $series   Reps: $repeticiones',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

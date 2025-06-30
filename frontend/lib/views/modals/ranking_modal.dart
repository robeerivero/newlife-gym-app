import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/ranking_viewmodel.dart';
import '../../models/usuario_ranking.dart';
import '../../fluttermoji/fluttermojiCircleAvatar.dart';

class RankingModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RankingViewModel()..fetchRanking(),
      child: Dialog(
        insetPadding: EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<RankingViewModel>(
            builder: (context, vm, _) {
              if (vm.loading) return const Center(child: CircularProgressIndicator());
              if (vm.error != null) return Center(child: Text('Error: ${vm.error}'));
              final ranking = vm.ranking;
              if (ranking == null || ranking.isEmpty) return const Text("Aún no hay asistencias este mes");

              final coloresPodio = [Colors.amber, Colors.grey, Colors.brown];
              final podio = List.generate(
                ranking.length < 3 ? ranking.length : 3,
                (i) {
                  final usuario = ranking[i];
                  return Column(
                    children: [
                      Text(['🥇', '🥈', '🥉'][i], style: TextStyle(fontSize: 32)),
                      SizedBox(height: 8),
                      FluttermojiCircleAvatar(
                        radius: i == 0 ? 40 : 32,
                        avatarJson: jsonEncode(usuario.avatar),
                        backgroundColor: coloresPodio[i][100],
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          usuario.nombre,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(fontWeight: FontWeight.bold, color: coloresPodio[i], fontSize: 14),
                        ),
                      ),
                      Text('Asistencias: ${usuario.asistenciasEsteMes}', style: TextStyle(fontSize: 12)),
                    ],
                  );
                },
              );

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'RANKING MENSUAL',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: podio,
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    height: 350,
                    child: ListView.builder(
                      itemCount: ranking.length,
                      itemBuilder: (context, index) {
                        if (index < 3) return SizedBox.shrink();
                        final usuario = ranking[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          color: Colors.blue[50], // mismo color que el encabezado
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '${index + 1}.',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                SizedBox(width: 12),
                                FluttermojiCircleAvatar(
                                  radius: 22,
                                  avatarJson: jsonEncode(usuario.avatar),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    usuario.nombre,
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '${usuario.asistenciasEsteMes} asist.',
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

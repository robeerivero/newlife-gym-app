import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/ranking_viewmodel.dart';
import '../../models/usuario_ranking.dart';
// Import local
import '../../fluttermoji/fluttermojiCircleAvatar.dart'; 

class RankingModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RankingViewModel()..fetchRanking(),
      child: Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Consumer<RankingViewModel>(
            builder: (context, vm, _) {
              final colorScheme = Theme.of(context).colorScheme;
              
              if (vm.loading) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              if (vm.error != null) return Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${vm.error}', style: TextStyle(color: colorScheme.error)));
              
              final ranking = vm.ranking;
              if (ranking == null || ranking.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("Aún no hay asistencias este mes"));

              // Podio
              final podio = List.generate(
                ranking.length < 3 ? ranking.length : 3,
                (i) {
                  final usuario = ranking[i];
                  final colorMedalla = [const Color(0xFFFFD700), const Color(0xFFC0C0C0), const Color(0xFFCD7F32)][i];
                  final size = i == 0 ? 90.0 : 70.0;
                  final fontSize = i == 0 ? 30.0 : 20.0;
                  
                  return Expanded(
                    child: Column(
                      children: [
                        Text(['🥇', '🥈', '🥉'][i], style: TextStyle(fontSize: fontSize)),
                        const SizedBox(height: 4),
                        Stack(
                           alignment: Alignment.bottomRight,
                           children: [
                             FluttermojiCircleAvatar(
                               radius: size / 2,
                               // Enviamos el avatar del usuario del ranking
                               avatarJson: jsonEncode(usuario.avatar),
                             ),
                             CircleAvatar(
                               radius: 12,
                               backgroundColor: colorMedalla,
                               child: Text('${i+1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                             )
                           ]
                        ),
                        const SizedBox(height: 8),
                        Text(usuario.nombre, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        Text('${usuario.asistenciasEsteMes}', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              );

              // Resto de la lista
              final resto = ranking.length > 3 ? ranking.sublist(3) : <UsuarioRanking>[];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🏆 Ranking del Mes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                        if (podio.length > 1) podio[1],
                        if (podio.isNotEmpty) podio[0],
                        if (podio.length > 2) podio[2],
                    ],
                  ),
                  if (resto.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: resto.length,
                        itemBuilder: (context, index) {
                          final usuario = resto[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                               width: 30, 
                               alignment: Alignment.center,
                               child: Text('${index + 4}.', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant))
                            ),
                            title: Row(
                              children: [
                                FluttermojiCircleAvatar(
                                  radius: 16,
                                  avatarJson: jsonEncode(usuario.avatar),
                                  backgroundColor: Colors.transparent, 
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(usuario.nombre)),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                              child: Text('${usuario.asistenciasEsteMes}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
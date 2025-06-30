import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/logros_viewmodel.dart';
import '../../models/logro_prenda.dart';
import '../../models/logro_progreso.dart';

class LogrosModal extends StatelessWidget {
  final String userId;
  const LogrosModal({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LogrosViewModel()..fetchLogrosYProgreso(userId),
      child: Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 400,
          child: Consumer<LogrosViewModel>(
            builder: (context, vm, _) {
              if (vm.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (vm.error != null) {
                return Center(child: Text('Error: ${vm.error}'));
              }
              final logros = vm.logros;
              if (logros.isEmpty) {
                return const Text("No hay logros definidos");
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Logros y recompensas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 450,
                    child: ListView.separated(
                      itemCount: logros.length,
                      separatorBuilder: (_, __) => const Divider(height: 10),
                      itemBuilder: (context, idx) {
                        final logro = logros[idx];
                        final progreso = vm.progresos[logro.key];
                        return ListTile(
                          leading: Text(logro.emoji, style: const TextStyle(fontSize: 28)),
                          title: Text(logro.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(logro.descripcion),
                              if (!logro.conseguido)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: ProgresoLogroWidget(logro: logro, progreso: progreso),
                                )
                            ],
                          ),
                          trailing: logro.conseguido
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.lock_outline, color: Colors.grey),
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

class ProgresoLogroWidget extends StatelessWidget {
  final LogroPrenda logro;
  final LogroProgreso? progreso;
  const ProgresoLogroWidget({required this.logro, required this.progreso, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (progreso == null) {
      return const SizedBox(height: 20, child: LinearProgressIndicator());
    }

    final tipo = logro.logro ?? '';
    if (tipo.contains("asistencia_") && tipo.contains("_total")) {
      final req = int.parse(RegExp(r'asistencia_(\d+)_total').firstMatch(tipo)!.group(1)!);
      return Text('Progreso: ${progreso!.totalAsistencias ?? 0} / $req asistencias');
    }
    if (tipo.contains("asistencia_") && tipo.contains("_seguidas")) {
      final req = int.parse(RegExp(r'asistencia_(\d+)_seguidas').firstMatch(tipo)!.group(1)!);
      return Text('Racha actual: ${progreso!.rachaActual ?? 0} / $req');
    }
    if (tipo.contains("racha_")) {
      final req = int.parse(RegExp(r'racha_(\d+)_seguidas').firstMatch(tipo)!.group(1)!);
      return Text('Racha actual: ${progreso!.rachaActual ?? 0} / $req');
    }
    if (tipo.contains("pasos_")) {
      final req = int.parse(RegExp(r'pasos_(\d+)_dia').firstMatch(tipo)!.group(1)!);
      return Text('Hoy: ${progreso!.pasosHoy ?? 0} / $req pasos');
    }
    if (tipo.contains("kcal_")) {
      final req = int.parse(RegExp(r'kcal_(\d+)_dia').firstMatch(tipo)!.group(1)!);
      return Text('Hoy: ${progreso!.kcalHoy ?? 0} / $req kcal');
    }
    return const SizedBox();
  }
}

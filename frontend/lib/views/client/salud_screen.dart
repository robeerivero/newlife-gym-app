import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/salud_viewmodel.dart';
import '../../models/salud.dart';

class SaludScreen extends StatelessWidget {
  const SaludScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SaludViewModel()..inicializarTodo(),
      child: const _SaludScreenBody(),
    );
  }
}

class _SaludScreenBody extends StatelessWidget {
  const _SaludScreenBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<SaludViewModel>(
      builder: (context, vm, _) {
        final colorScheme = Theme.of(context).colorScheme;

        if (vm.permisoDenegado) {
          return _buildPermisoDenegado(context);
        }

        if (vm.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // === CORRECCIÓN FECHA LOCAL ===
        final nowLocal = DateTime.now();
        final hoyStr = DateFormat('yyyy-MM-dd').format(nowLocal);

        // Calcular el lunes y hoy (LOCAL)
        final daysToMonday = nowLocal.weekday - DateTime.monday;
        final monday = DateTime(nowLocal.year, nowLocal.month, nowLocal.day)
            .subtract(Duration(days: daysToMonday));
        final mondayStr = DateFormat('yyyy-MM-dd').format(monday);

        // Semana filtrada por fecha local (corrige cualquier problema de zona)
        final semana = vm.historial.where((dia) {
          final fStr = DateFormat('yyyy-MM-dd').format(dia.fecha.toLocal());
          return fStr.compareTo(mondayStr) >= 0 && fStr.compareTo(hoyStr) <= 0;
        }).toList()
          ..sort((a, b) => a.fecha.compareTo(b.fecha));

        // Buscar datos de HOY correctamente
        final hoy = vm.historial.firstWhere(
          (d) => DateFormat('yyyy-MM-dd').format(d.fecha.toLocal()) == hoyStr,
          orElse: () => Salud(
            id: '',
            usuario: '',
            fecha: nowLocal,
            pasos: 0,
            kcalQuemadas: 0.0,
            kcalConsumidas: 0.0,
            kcalQuemadasManual: 0.0,
          ),
        );

        final pasosHoy = hoy.pasos;
        final kcalQuemadasHoy = hoy.kcalQuemadas;
        final kcalConsumidasHoy = hoy.kcalConsumidas;

        final int pasosSemana = semana.fold<int>(
          0,
          (sum, dia) => sum + dia.pasos,
        );
        final double progreso = (pasosSemana / (vm.objetivoSemanal > 0 ? vm.objetivoSemanal : 1)).clamp(0.0, 1.0);

        // Lógica visual del progreso adaptada al tema
        Color colorProgreso;
        if (progreso >= 1.0) {
          colorProgreso = Colors.green; // Éxito
        } else if (progreso > 0.7) {
          colorProgreso = Colors.lightGreen; // Casi
        } else if (progreso > 0.4) {
          colorProgreso = colorScheme.secondary; // Naranja (Progreso medio)
        } else {
          colorProgreso = colorScheme.error; // Rojo (Bajo)
        }

        return Scaffold(
          // backgroundColor eliminado (Theme default)
          appBar: AppBar(
            // backgroundColor eliminado (Theme default - Teal)
            elevation: 0,
            title: const Text('Salud'),
            actions: [
              IconButton(
                icon: const Icon(Icons.flag),
                onPressed: () async {
                  final ctrl = TextEditingController(text: vm.objetivoSemanal.toString());
                  final nuevo = await showDialog<int>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('¿Cuál es tu objetivo de pasos para esta semana?'),
                      content: TextField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Pasos objetivo"),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                        ElevatedButton(
                            onPressed: () {
                              int? val = int.tryParse(ctrl.text.trim());
                              if (val != null && val > 0) {
                                Navigator.pop(ctx, val);
                              }
                            },
                            child: const Text("Guardar")),
                      ],
                    ),
                  );
                  if (nuevo != null) {
                    await vm.cambiarObjetivo(nuevo);
                  }
                },
                tooltip: "Cambiar objetivo semanal",
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => vm.inicializarTodo(forzar: true),
                tooltip: "Sincronizar",
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 6),
                CircularPercentIndicator(
                  radius: 98,
                  lineWidth: 16,
                  percent: progreso,
                  animation: true,
                  animateFromLastPercent: true,
                  circularStrokeCap: CircularStrokeCap.round,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$pasosSemana",
                        style: TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold, color: colorProgreso),
                      ),
                      Text("de ${vm.objetivoSemanal}\npasos semanales",
                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(
                        progreso >= 1.0
                            ? "¡Objetivo semanal completado! 🎉"
                            : progreso > 0.7
                                ? "¡Ya casi lo tienes!"
                                : progreso > 0.4
                                    ? "¡Sigue sumando!"
                                    : "¡Ánimo, tú puedes!",
                        style: TextStyle(
                            color: colorProgreso,
                            fontWeight: FontWeight.w600,
                            fontSize: 16),
                      ),
                    ],
                  ),
                  progressColor: colorProgreso,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Pasos: Primary (Teal)
                    _infoCard(context, "👣", "Hoy", pasosHoy.toString(), colorScheme.primary),
                    // Kcal Quemadas: Secondary (Orange/Fuego)
                    _infoCard(context, "🔥", "Kcal quem.", kcalQuemadasHoy.toStringAsFixed(0), colorScheme.secondary),
                    // Kcal Consumidas: Green (Semántico comida/salud)
                    _infoCard(context, "🍽️", "Kcal cons.", kcalConsumidasHoy.toStringAsFixed(0), Colors.green),
                  ],
                ),
                const SizedBox(height: 26),
                ElevatedButton.icon(
                  icon: const Icon(Icons.fitness_center),
                  label: const Text("Añadir kcal de clase"),
                  // Estilo eliminado para heredar del Theme (Primary)
                  onPressed: vm.loading
                      ? null
                      : () async {
                          final kcalController = TextEditingController();
                          await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Registrar kcal quemadas en clase'),
                              content: TextField(
                                controller: kcalController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Kcal'),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Cancelar'),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                                TextButton(
                                  child: const Text('Guardar'),
                                  onPressed: () async {
                                    final kcal = double.tryParse(kcalController.text) ?? 0.0;
                                    if (kcal > 0) {
                                      Navigator.pop(ctx);
                                      // Aquí pasamos pasosHoy como segundo parámetro
                                      await vm.anadirKcalManual(kcal, pasosHoy);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                ),
                const SizedBox(height: 26),
                Text(
                  'Historial (semana actual)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary, // Azul -> Primary
                  ),
                ),
                const SizedBox(height: 13),
                _buildHistorial(context, semana),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermisoDenegado(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 70, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'El permiso de actividad es necesario\ny ha sido denegado.',
                style: TextStyle(fontSize: 17, color: colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
  }

  Widget _infoCard(BuildContext context, String emoji, String label, String value, Color color) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 22),
        child: Column(
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: 38, shadows: [
                Shadow(
                  blurRadius: 2,
                  color: color.withOpacity(0.4),
                  offset: const Offset(0, 2),
                )
              ]),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorial(BuildContext context, List<Salud> semana) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (semana.isEmpty) {
      return Column(
        children: const [
          Icon(Icons.history, size: 48, color: Colors.grey),
          Text('Sin historial por ahora.', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    return Column(
      children: semana.map((dia) {
        final fechaLocal = dia.fecha.toLocal();
        final fecha = DateFormat.EEEE('es_ES').format(fechaLocal).toUpperCase();
        final pasosDia = dia.pasos;
        final kcalDia = dia.kcalQuemadas.toStringAsFixed(0);
        final kcalCons = dia.kcalConsumidas.toStringAsFixed(0);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          elevation: 3,
          child: ListTile(
            leading: Text(
              "👣",
              style: TextStyle(
                  fontSize: 36, 
                  color: colorScheme.primary, // Azul -> Primary
                  fontWeight: FontWeight.bold
              ),
            ),
            title: Text(fecha,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('👣 $pasosDia pasos\n🔥 $kcalDia kcal\n🍽️ $kcalCons kcal consumidas',
                  style: const TextStyle(fontSize: 15)),
            ),
            isThreeLine: true,
          ),
        );
      }).toList(),
    );
  }
}
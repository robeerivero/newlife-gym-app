// ==========================
// lib/views/admin/rutinas/edit_rutina_screen.dart
// ==========================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/edit_rutina_viewmodel.dart';
import '../../../models/ejercicio.dart';
import '../../../models/usuario.dart';

class EditRutinaScreen extends StatelessWidget {
  final String rutinaId;
  const EditRutinaScreen({required this.rutinaId, super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditRutinaViewModel()..cargarTodo(rutinaId),
      child: const _EditRutinaBody(),
    );
  }
}

class _EditRutinaBody extends StatelessWidget {
  const _EditRutinaBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditRutinaViewModel>();

    if (vm.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Rutina'), backgroundColor: Colors.blueAccent),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: vm.error != null
            ? Text(vm.error!, style: const TextStyle(color: Colors.red))
            : Column(
                children: [
                  DropdownButtonFormField<Usuario>(
                    value: vm.selectedUsuario,
                    items: vm.usuarios.map((u) => DropdownMenuItem<Usuario>(
                      value: u,
                      child: Text(u.nombre),
                    )).toList(),
                    onChanged: vm.updateUsuario,
                    decoration: const InputDecoration(labelText: 'Usuario'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: vm.selectedDiaSemana,
                    items: const [
                      DropdownMenuItem(value: 'Lunes', child: Text('Lunes')),
                      DropdownMenuItem(value: 'Martes', child: Text('Martes')),
                      DropdownMenuItem(value: 'Miércoles', child: Text('Miércoles')),
                      DropdownMenuItem(value: 'Jueves', child: Text('Jueves')),
                      DropdownMenuItem(value: 'Viernes', child: Text('Viernes')),
                      DropdownMenuItem(value: 'Sábado', child: Text('Sábado')),
                      DropdownMenuItem(value: 'Domingo', child: Text('Domingo')),
                    ],
                    onChanged: vm.updateDiaSemana,
                    decoration: const InputDecoration(labelText: 'Día de la Semana'),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: vm.ejerciciosDisponibles.length,
                      itemBuilder: (context, idx) {
                        final ejercicio = vm.ejerciciosDisponibles[idx];
                        final isSelected = vm.isEjercicioSelected(ejercicio);

                        return Card(
                          child: ListTile(
                            title: Text(ejercicio.nombre),
                            subtitle: Row(
                              children: [
                                Flexible(
                                  child: TextFormField(
                                    initialValue: vm.getSeries(ejercicio).toString(),
                                    decoration: const InputDecoration(labelText: 'Series'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final v = int.tryParse(value);
                                      if (v != null && isSelected) {
                                        final i = vm.selectedEjercicios.indexWhere((e) => e.ejercicio.id == ejercicio.id);
                                        vm.updateEjercicio(i, series: v);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: TextFormField(
                                    initialValue: vm.getReps(ejercicio).toString(),
                                    decoration: const InputDecoration(labelText: 'Reps'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final v = int.tryParse(value);
                                      if (v != null && isSelected) {
                                        final i = vm.selectedEjercicios.indexWhere((e) => e.ejercicio.id == ejercicio.id);
                                        vm.updateEjercicio(i, repeticiones: v);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (val) => vm.toggleEjercicio(ejercicio),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final ok = await vm.guardarCambios();
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Rutina actualizada con éxito.')),
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Guardar Cambios'),
                  ),
                ],
              ),
      ),
    );
  }
}


// ==========================
// lib/views/admin/rutinas/add_rutina_screen.dart
// ==========================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/ejercicio.dart';
import '../../../models/usuario.dart';
import '../../../models/rutina.dart';
import '../../../models/ejercicio_ref.dart';
import '../../../viewmodels/add_rutina_viewmodel.dart';

class AddRutinaScreen extends StatelessWidget {
  const AddRutinaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddRutinaViewModel()
        ..fetchUsuarios()
        ..fetchEjercicios(),
      child: const _AddRutinaBody(),
    );
  }
}

class _AddRutinaBody extends StatefulWidget {
  const _AddRutinaBody();

  @override
  State<_AddRutinaBody> createState() => _AddRutinaBodyState();
}

class _AddRutinaBodyState extends State<_AddRutinaBody> {
  final _formKey = GlobalKey<FormState>();
  final _diaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddRutinaViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Rutina'), backgroundColor: Colors.blueAccent),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (vm.error != null)
                      Text(vm.error!, style: const TextStyle(color: Colors.red)),
                    DropdownButtonFormField<Usuario>(
                      value: vm.selectedUsuario,
                      decoration: const InputDecoration(labelText: 'Seleccionar Usuario'),
                      items: vm.usuarios.map<DropdownMenuItem<Usuario>>((usuario) {
                        return DropdownMenuItem<Usuario>(
                          value: usuario,
                          child: Text(usuario.nombre),
                        );
                      }).toList(),
                      onChanged: (u) => vm.selectedUsuario = u,
                      validator: (v) => v == null ? 'Selecciona un usuario.' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _diaController,
                      decoration: const InputDecoration(labelText: 'Día de la Semana'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Ingresa un día de la semana.' : null,
                      onChanged: (v) => vm.diaSemana = v,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => SelectExerciseDialog(
                            ejerciciosDisponibles: vm.ejerciciosDisponibles,
                            onAddExercise: (ej) => vm.addEjercicioSeleccionado(ej),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir Ejercicio'),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: vm.ejerciciosSeleccionados.length,
                        itemBuilder: (context, index) {
                          final ejercicio = vm.ejerciciosSeleccionados[index];
                          return Card(
                            child: ListTile(
                              title: Text(ejercicio.ejercicio.nombre),
                              subtitle: Text('Series: ${ejercicio.series} - Reps: ${ejercicio.repeticiones}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => vm.removeEjercicioSeleccionado(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          vm.crearRutina(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Agregar Rutina'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class SelectExerciseDialog extends StatefulWidget {
  final List<Ejercicio> ejerciciosDisponibles;
  final Function(Ejercicio) onAddExercise;

  const SelectExerciseDialog({
    Key? key,
    required this.ejerciciosDisponibles,
    required this.onAddExercise,
  }) : super(key: key);

  @override
  State<SelectExerciseDialog> createState() => _SelectExerciseDialogState();
}

class _SelectExerciseDialogState extends State<SelectExerciseDialog> {
  Ejercicio? selectedExercise;
  final TextEditingController seriesController = TextEditingController();
  final TextEditingController repsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Ejercicio'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Ejercicio>(
            decoration: const InputDecoration(labelText: 'Ejercicio'),
            items: widget.ejerciciosDisponibles.map<DropdownMenuItem<Ejercicio>>((ejercicio) {
              return DropdownMenuItem<Ejercicio>(
                value: ejercicio,
                child: Text(ejercicio.nombre),
              );
            }).toList(),
            onChanged: (value) => setState(() => selectedExercise = value),
          ),
          TextFormField(
            controller: seriesController,
            decoration: const InputDecoration(labelText: 'Series'),
            keyboardType: TextInputType.number,
          ),
          TextFormField(
            controller: repsController,
            decoration: const InputDecoration(labelText: 'Repeticiones'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (selectedExercise != null) {
              widget.onAddExercise(selectedExercise!);
              Navigator.pop(context);
            }
          },
          child: const Text('Añadir'),
        ),
      ],
    );
  }
}

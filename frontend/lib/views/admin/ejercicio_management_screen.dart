import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ejercicio.dart';
import '../../viewmodels/ejercicios_management_viewmodel.dart';

class EjerciciosManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EjerciciosManagementViewModel()..fetchEjercicios(),
      child: _EjerciciosManagementView(),
    );
  }
}

class _EjerciciosManagementView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EjerciciosManagementViewModel>(context);

    // Controllers para los formularios, inicializados dinámicamente
    final nombreController = TextEditingController();
    final videoController = TextEditingController();
    final descripcionController = TextEditingController();
    String dificultad = 'fácil';

    void showFormDialog({Ejercicio? ejercicio, required bool isEdit}) {
      if (ejercicio != null) {
        nombreController.text = ejercicio.nombre;
        videoController.text = ejercicio.video;
        descripcionController.text = ejercicio.descripcion;
        dificultad = ejercicio.dificultad;
      } else {
        nombreController.clear();
        videoController.clear();
        descripcionController.clear();
        dificultad = 'fácil';
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isEdit ? 'Editar Ejercicio' : 'Agregar Ejercicio'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: videoController,
                  decoration: const InputDecoration(labelText: 'Video URL'),
                ),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                DropdownButton<String>(
                  value: dificultad,
                  items: ['fácil', 'medio', 'difícil']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      dificultad = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                final ej = Ejercicio(
                  id: ejercicio?.id ?? '',
                  nombre: nombreController.text,
                  video: videoController.text,
                  descripcion: descripcionController.text,
                  dificultad: dificultad,
                );
                if (isEdit) {
                  await vm.editEjercicio(ej);
                } else {
                  await vm.addEjercicio(ej);
                }
                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Guardar' : 'Agregar'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Ejercicios'),
        backgroundColor: Colors.blueAccent,
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      vm.error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: vm.ejercicios.length,
                    itemBuilder: (context, index) {
                      final ejercicio = vm.ejercicios[index];
                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(
                            ejercicio.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dificultad: ${ejercicio.dificultad}'),
                              Text('Video: ${ejercicio.video}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.green),
                                onPressed: () => showFormDialog(ejercicio: ejercicio, isEdit: true),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await vm.deleteEjercicio(ejercicio.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    onPressed: () => showFormDialog(isEdit: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Agregar Ejercicio',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

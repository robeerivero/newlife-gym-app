import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/rutinas_management_viewmodel.dart';
import '../../models/rutina.dart';
import 'rutinas/add_rutina_screen.dart';
import 'rutinas/edit_rutina_screen.dart';
import 'ejercicio_management_screen.dart';

class RutinasManagementScreen extends StatelessWidget {
  const RutinasManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RutinasManagementViewModel()..fetchRutinas(),
      child: const _RutinasManagementView(),
    );
  }
}

class _RutinasManagementView extends StatelessWidget {
  const _RutinasManagementView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RutinasManagementViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Rutinas'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.fitness_center),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EjerciciosManagementScreen()),
              );
            },
          ),
        ],
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (vm.error != null && vm.error!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      vm.error!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: vm.rutinas.length,
                    itemBuilder: (context, index) {
                      final rutina = vm.rutinas[index];

                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(
                            rutina.diaSemana.isNotEmpty ? rutina.diaSemana : 'Día no especificado',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Usuario: ${rutina.usuario.nombre}'),
                              const SizedBox(height: 5),
                              const Text('Ejercicios:'),
                              ...rutina.ejercicios.map((ej) => Text(ej.ejercicio.nombre)).toList(),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.green),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditRutinaScreen(rutinaId: rutina.id),
                                    ),
                                  ).then((_) => vm.fetchRutinas());
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => vm.deleteRutina(rutina.id),
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddRutinaScreen()),
                      ).then((_) => vm.fetchRutinas());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Agregar Rutina',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

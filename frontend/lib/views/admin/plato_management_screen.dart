import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/plato.dart';
import '../../viewmodels/plato_management_viewmodel.dart';

class PlatoManagementScreen extends StatelessWidget {
  const PlatoManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlatoManagementViewModel()..fetchPlatos(),
      child: const _PlatoManagementBody(),
    );
  }
}

class _PlatoManagementBody extends StatelessWidget {
  const _PlatoManagementBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<PlatoManagementViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestión de Platos'),
            backgroundColor: const Color(0xFF42A5F5),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: vm.fetchPlatos,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showPlatoDialog(context, vm),
            child: const Icon(Icons.add),
          ),
          body: vm.loading
              ? const Center(child: CircularProgressIndicator())
              : vm.error != null
                  ? Center(child: Text(vm.error!))
                  : ListView.builder(
                      itemCount: vm.platos.length,
                      itemBuilder: (context, index) {
                        final plato = vm.platos[index];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(plato.nombre),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kcal: ${plato.kcal}'),
                                Text('Comida del Día: ${plato.comidaDelDia}'),
                                Text('Ingredientes: ${plato.ingredientes.join(', ')}'),
                                Text('Tiempo: ${plato.tiempoPreparacion} min'),
                                if ((plato.observaciones ?? '').isNotEmpty)
                                  Text('Obs: ${plato.observaciones}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showPlatoDialog(context, vm, plato: plato),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Eliminar plato'),
                                        content: Text('¿Eliminar "${plato.nombre}"?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await vm.deletePlato(plato.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}

void _showPlatoDialog(BuildContext context, PlatoManagementViewModel vm, {Plato? plato}) {
  final isEdit = plato != null;
  final nameController = TextEditingController(text: plato?.nombre ?? '');
  final kcalController = TextEditingController(text: plato?.kcal.toString() ?? '');
  final ingredientesController = TextEditingController(text: plato?.ingredientes.join(', ') ?? '');
  final instruccionesController = TextEditingController(text: plato?.instrucciones ?? '');
  final tiempoPreparacionController = TextEditingController(text: plato?.tiempoPreparacion.toString() ?? '');
  final observacionesController = TextEditingController(text: plato?.observaciones ?? '');
  String selectedComidaDelDia = plato?.comidaDelDia ?? 'Almuerzo';
  final comidasDelDia = ['Desayuno', 'Almuerzo', 'Cena', 'Snack'];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Editar Plato' : 'Nuevo Plato'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
                TextField(controller: kcalController, decoration: const InputDecoration(labelText: 'Calorías'), keyboardType: TextInputType.number),
                DropdownButtonFormField<String>(
                  value: selectedComidaDelDia,
                  items: comidasDelDia.map((comida) => DropdownMenuItem(value: comida, child: Text(comida))).toList(),
                  onChanged: (value) => setState(() => selectedComidaDelDia = value!),
                  decoration: const InputDecoration(labelText: 'Comida del Día'),
                ),
                TextField(controller: ingredientesController, decoration: const InputDecoration(labelText: 'Ingredientes (separados por coma)')),
                TextField(controller: instruccionesController, decoration: const InputDecoration(labelText: 'Instrucciones'), maxLines: 3),
                TextField(controller: tiempoPreparacionController, decoration: const InputDecoration(labelText: 'Tiempo de Preparación (min)'), keyboardType: TextInputType.number),
                TextField(controller: observacionesController, decoration: const InputDecoration(labelText: 'Observaciones (opcional)'), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    kcalController.text.isEmpty ||
                    ingredientesController.text.isEmpty ||
                    instruccionesController.text.isEmpty ||
                    tiempoPreparacionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Complete todos los campos requeridos')),
                  );
                  return;
                }
                final nuevoPlato = Plato(
                  id: plato?.id ?? '',
                  nombre: nameController.text,
                  kcal: int.parse(kcalController.text),
                  comidaDelDia: selectedComidaDelDia,
                  ingredientes: ingredientesController.text.split(',').map((e) => e.trim()).toList(),
                  instrucciones: instruccionesController.text,
                  tiempoPreparacion: int.parse(tiempoPreparacionController.text),
                  observaciones: observacionesController.text,
                );
                await vm.addOrUpdatePlato(nuevoPlato, id: isEdit ? plato!.id : null);
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
    },
  );
}

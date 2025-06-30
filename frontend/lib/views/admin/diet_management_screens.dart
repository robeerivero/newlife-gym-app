import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dieta.dart';
import '../../models/plato.dart';
import '../../models/usuario.dart';
import '../../viewmodels/dieta_management_viewmodel.dart';

class DietaManagementScreen extends StatelessWidget {
  const DietaManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DietaManagementViewModel(),
      child: const _DietaManagementView(),
    );
  }
}

class _DietaManagementView extends StatelessWidget {
  const _DietaManagementView();

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<DietaManagementViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Dietas'),
        backgroundColor: const Color(0xFF42A5F5),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: vm.dietas.isEmpty ? null : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Eliminar todas las dietas'),
                  content: const Text('¿Estás seguro de eliminar todas las dietas?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
                  ],
                ),
              );
              if (confirm == true) await vm.deleteAllDietas();
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDietaDialog(context, vm),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (vm.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(vm.error!, style: const TextStyle(color: Colors.red)),
                    ),
                  DropdownButtonFormField<Usuario>(
                    isExpanded: true,
                    value: vm.selectedUsuario,
                    items: vm.usuarios.map((u) {
                      return DropdownMenuItem<Usuario>(
                        value: u,
                        child: Text(
                          u.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (usuario) {
                      if (usuario != null) {
                        vm.selectedUsuario = usuario;
                        vm.fetchDietas(usuario.id);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Selecciona un usuario'),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: vm.dietas.isEmpty
                        ? const Center(child: Text('No hay dietas registradas'))
                        : ListView.builder(
                            itemCount: vm.dietas.length,
                            itemBuilder: (_, i) {
                              final dieta = vm.dietas[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fecha: ${dieta.fecha.day}/${dieta.fecha.month}/${dieta.fecha.year}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text('Platos:'),
                                      const SizedBox(height: 4),
                                      ...dieta.platos.map((plato) => Row(
                                            children: [
                                              Expanded(child: Text(plato.nombre)),
                                              Text('${plato.kcal} kcal'),
                                            ],
                                          )),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => vm.deleteDieta(dieta.id),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showAddDietaDialog(BuildContext context, DietaManagementViewModel vm) {
    DateTime? selectedDate;
    Usuario? selectedUsuario = vm.selectedUsuario;
    final Set<Plato> selectedPlatos = {};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Agregar Nueva Dieta'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<Usuario>(
                        value: selectedUsuario,
                        decoration: const InputDecoration(labelText: 'Usuario'),
                        items: vm.usuarios.map((usuario) {
                          return DropdownMenuItem<Usuario>(
                            value: usuario,
                            child: Text('${usuario.nombre}'),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => selectedUsuario = value),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        title: Text(
                          selectedDate == null
                              ? 'Selecciona una fecha'
                              : 'Fecha: ${selectedDate.toString().split(' ')[0]}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() => selectedDate = pickedDate);
                          }
                        },
                      ),
                      const Divider(),
                      const Text('Selecciona Platos:'),
                      const SizedBox(height: 5),
                      ...vm.platos.map((plato) {
                        final selected = selectedPlatos.contains(plato);
                        return CheckboxListTile(
                          title: Text('${plato.nombre} (${plato.kcal} kcal)'),
                          value: selected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedPlatos.add(plato);
                              } else {
                                selectedPlatos.remove(plato);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedUsuario == null ||
                        selectedDate == null ||
                        selectedPlatos.isEmpty) {
                      return;
                    }
                    await vm.addDieta(
                      usuario: selectedUsuario!,
                      fecha: selectedDate!,
                      platosSeleccionados: selectedPlatos.toList(),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

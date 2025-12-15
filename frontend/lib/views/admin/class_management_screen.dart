import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/class_management_viewmodel.dart';
import '../../models/clase.dart';

const _classTypes = ['funcional', 'pilates', 'zumba'];
const _daysOfWeek = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];

class ClassManagementScreen extends StatelessWidget {
  const ClassManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClassManagementViewModel()..fetchClasses(),
      child: const _ClassManagementView(),
    );
  }
}

class _ClassManagementView extends StatelessWidget {
  const _ClassManagementView();

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ClassManagementViewModel>(context);
    // Accedemos al tema actual
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clases'),
        // Eliminado backgroundColor: Colors.blueAccent -> Usa el del tema (Teal)
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: vm.selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                // El DatePicker usará automáticamente los colores del tema
              );
              if (pickedDate != null) {
                vm.selectedDate = pickedDate;
                await vm.fetchClasses(date: pickedDate);
              }
            },
            tooltip: 'Filtrar por fecha',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Eliminar todas las clases'),
                  content: const Text('¿Estás seguro de eliminar todas las clases?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), 
                      child: Text('Eliminar', style: TextStyle(color: theme.colorScheme.error))
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await vm.deleteAllClasses();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.fetchClasses,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditClassDialog(context, vm),
        // El color vendrá del theme (Secondary/Naranja)
        child: const Icon(Icons.add),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
              ? Center(child: Text(vm.error!))
              : ListView.builder(
                  itemCount: vm.clases.length,
                  itemBuilder: (context, index) {
                    final classItem = vm.clases[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      // El Card usa el estilo del tema
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.fitness_center, color: theme.colorScheme.primary),
                        ),
                        title: Text(classItem.nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Día: ${classItem.dia}'),
                            Text('Hora: ${classItem.horaInicio} - ${classItem.horaFin}'),
                            Text('Cupos: ${classItem.cuposDisponibles}/${classItem.maximoParticipantes}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              // Usamos el color secundario (Naranja) para editar
                              icon: Icon(Icons.edit, color: theme.colorScheme.secondary),
                              onPressed: () => _showAddEditClassDialog(context, vm, clase: classItem),
                            ),
                            IconButton(
                              // Usamos el color de error para borrar
                              icon: Icon(Icons.delete, color: theme.colorScheme.error),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar clase'),
                                    content: Text('¿Eliminar "${classItem.nombre}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true), 
                                        child: Text('Eliminar', style: TextStyle(color: theme.colorScheme.error))
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await vm.deleteClass(classItem.id);
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
  }

  void _showAddEditClassDialog(BuildContext context, ClassManagementViewModel vm, {Clase? clase}) {
    final _formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: clase?.nombre ?? '');
    String? selectedClassType = clase?.nombre;
    String? selectedDay = clase?.dia;
    TimeOfDay? startTime = clase != null ? _parseTime(clase.horaInicio) : null;
    TimeOfDay? endTime = clase != null ? _parseTime(clase.horaFin) : null;
    final maxParticipantsController = TextEditingController(text: clase?.maximoParticipantes.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(clase == null ? 'Nueva Clase' : 'Editar Clase'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedClassType,
                    items: _classTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (v) => setState(() => selectedClassType = v),
                    decoration: const InputDecoration(labelText: 'Tipo de Clase'),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    items: _daysOfWeek.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                    onChanged: (v) => setState(() => selectedDay = v),
                    decoration: const InputDecoration(labelText: 'Día'),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: startTime ?? TimeOfDay.now());
                      if (picked != null) setState(() => startTime = picked);
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: startTime == null
                              ? 'Seleccionar Hora de Inicio'
                              : 'Hora Inicio: ${_formatTime(startTime!)}',
                          // El InputDecoration del theme manejará el estilo
                        ),
                        validator: (v) => startTime == null ? 'Requerido' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: endTime ?? TimeOfDay.now());
                      if (picked != null) setState(() => endTime = picked);
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: endTime == null
                              ? 'Seleccionar Hora de Fin'
                              : 'Hora Fin: ${_formatTime(endTime!)}',
                        ),
                        validator: (v) => endTime == null ? 'Requerido' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: maxParticipantsController,
                    decoration: const InputDecoration(labelText: 'Máximo Participantes'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                final now = DateTime.now();
                final selectedDate = vm.selectedDate ?? now;
                final claseNueva = Clase(
                  id: clase?.id ?? '',
                  nombre: selectedClassType!,
                  dia: selectedDay!,
                  horaInicio: _formatTime(startTime!),
                  horaFin: _formatTime(endTime!),
                  fecha: DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
                  cuposDisponibles: clase?.cuposDisponibles ?? 0,
                  maximoParticipantes: int.tryParse(maxParticipantsController.text) ?? 0,
                  listaEspera: clase?.listaEspera ?? [],
                );
                if (clase == null) {
                  await vm.addClass(claseNueva);
                } else {
                  await vm.editClass(claseNueva.id, claseNueva);
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static TimeOfDay? _parseTime(String? time) {
    if (time == null || time.isEmpty) return null;
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
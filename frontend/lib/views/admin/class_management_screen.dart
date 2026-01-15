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
      child: const _ClassManagementMergedView(),
    );
  }
}

class _ClassManagementMergedView extends StatelessWidget {
  const _ClassManagementMergedView();

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ClassManagementViewModel>(context);
    final theme = Theme.of(context);

    // Usamos DefaultTabController para gestionar las pestañas
    return DefaultTabController(
      length: 2, // Dos pestañas: Lista y Generador
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Clases'),
          bottom: TabBar(
          // 1. Color del texto/icono SELECCIONADO (Usa el color principal, ej: Teal)
          labelColor: theme.colorScheme.primary,
          
          // 2. Color del texto/icono NO SELECCIONADO (Usa un gris visible)
          unselectedLabelColor: Colors.white,
          
          // 3. Color de la línea inferior indicadora
          indicatorColor: theme.colorScheme.primary,
          
          // 4. (Opcional) Hacer el texto seleccionado más grueso
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          
          tabs: const [
            Tab(icon: Icon(Icons.list), text: "Calendario"),
            Tab(icon: Icon(Icons.playlist_add), text: "Generador"),
          ],
        ),
          actions: [
            // Botón Filtro (Solo tiene sentido en la lista, pero lo dejamos global)
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: 'Filtrar por fecha',
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: vm.selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  await vm.fetchClasses(date: pickedDate);
                }
              },
            ),
            // Botón Borrar Todo
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Eliminar todas las clases',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('⚠️ Eliminar TODAS las clases'),
                    content: const Text('Esta acción borrará todas las clases y reservas. ¿Estás seguro?'),
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
              onPressed: () => vm.fetchClasses(date: vm.selectedDate),
            ),
          ],
        ),
        
        // Aquí definimos el contenido de cada pestaña
        body: TabBarView(
          children: [
            // PESTAÑA 1: LISTADO DE CLASES
            _buildClassesList(context, vm, theme),
            
            // PESTAÑA 2: GENERADOR MASIVO
            _buildMassCreationForm(context, vm, theme),
          ],
        ),
        
        // FAB solo para añadir clase suelta (visible siempre o condicional)
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddEditClassDialog(context, vm),
          child: const Icon(Icons.add),
          tooltip: 'Añadir clase suelta',
        ),
      ),
    );
  }

  // --- WIDGET: PESTAÑA 1 (LISTA) ---
  Widget _buildClassesList(BuildContext context, ClassManagementViewModel vm, ThemeData theme) {
    if (vm.loading) return const Center(child: CircularProgressIndicator());
    if (vm.error != null) return Center(child: Text(vm.error!, style: TextStyle(color: theme.colorScheme.error)));
    if (vm.clases.isEmpty) return const Center(child: Text("No hay clases para la fecha seleccionada."));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
      itemCount: vm.clases.length,
      itemBuilder: (context, index) {
        final classItem = vm.clases[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(Icons.fitness_center, color: theme.colorScheme.primary),
            ),
            title: Text(classItem.nombre.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${classItem.dia} - ${classItem.fecha.toString().split(" ")[0]}'),
                Text('${classItem.horaInicio} - ${classItem.horaFin}'),
                Text('Cupos: ${classItem.cuposDisponibles}/${classItem.maximoParticipantes}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: theme.colorScheme.secondary),
                  onPressed: () => _showAddEditClassDialog(context, vm, clase: classItem),
                ),
                IconButton(
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
    );
  }

  // --- WIDGET: PESTAÑA 2 (FORMULARIO MASIVO) ---
  Widget _buildMassCreationForm(BuildContext context, ClassManagementViewModel vm, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey),
                SizedBox(width: 10),
                Expanded(child: Text("Selecciona patrones para generar el calendario de clases de todo el año.", style: TextStyle(fontSize: 13))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // 1. TIPO
          Text("1. Actividad", style: theme.textTheme.titleMedium),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            value: vm.newClassType,
            items: vm.availableTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
            onChanged: vm.setClassType,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
          ),
          const SizedBox(height: 20),

          // 2. CUPO
          Text("2. Cupo por clase", style: theme.textTheme.titleMedium),
          const SizedBox(height: 5),
          TextField(
            controller: vm.maxParticipantsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
          ),
          const SizedBox(height: 20),

          // 3. DÍAS
          Text("3. Días (Repetición semanal)", style: theme.textTheme.titleMedium),
          const SizedBox(height: 5),
          Wrap(
            spacing: 8.0,
            children: vm.availableDays.map((day) {
              final isSelected = vm.isDaySelected(day);
              return FilterChip(
                label: Text(day),
                selected: isSelected,
                selectedColor: theme.colorScheme.secondaryContainer,
                onSelected: (_) => vm.toggleDay(day),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 4. HORAS
          Text("4. Horarios", style: theme.textTheme.titleMedium),
          const SizedBox(height: 5),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: vm.availableHours.map((hour) {
              final isSelected = vm.isHourSelected(hour);
              return FilterChip(
                label: Text(hour),
                selected: isSelected,
                selectedColor: theme.colorScheme.primary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                onSelected: (_) => vm.toggleHour(hour),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),

          // BOTÓN
          vm.loading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('GENERAR CALENDARIO ANUAL'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    onPressed: () async {
                      final error = await vm.createMassiveClasses();
                      if (error == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Clases generadas correctamente'), backgroundColor: Colors.green),
                          );
                          vm.clearMassCreationForm();
                          // Cambiamos a la pestaña de lista automáticamente
                          DefaultTabController.of(context).animateTo(0);
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: theme.colorScheme.error));
                        }
                      }
                    },
                  ),
                ),
           const SizedBox(height: 80), // Espacio final
        ],
      ),
    );
  }

  // DIÁLOGO PARA CLASE SUELTA (Reutilizado)
  void _showAddEditClassDialog(BuildContext context, ClassManagementViewModel vm, {Clase? clase}) {
    final _formKey = GlobalKey<FormState>();
    String? selectedClassType = clase?.nombre;
    String? selectedDay = clase?.dia;
    TimeOfDay? startTime = clase != null ? _parseTime(clase.horaInicio) : null;
    TimeOfDay? endTime = clase != null ? _parseTime(clase.horaFin) : null;
    final maxParticipantsController = TextEditingController(text: clase?.maximoParticipantes.toString() ?? '14');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(clase == null ? 'Clase Individual' : 'Editar Clase'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedClassType,
                    items: _classTypes.map((type) => DropdownMenuItem(value: type, child: Text(type.toUpperCase()))).toList(),
                    onChanged: (v) => setState(() => selectedClassType = v),
                    decoration: const InputDecoration(labelText: 'Actividad'),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    items: _daysOfWeek.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                    onChanged: (v) => setState(() => selectedDay = v),
                    decoration: const InputDecoration(labelText: 'Día'),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    title: Text(startTime == null ? 'Hora Inicio' : 'Inicio: ${_formatTime(startTime!)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: startTime ?? TimeOfDay.now());
                      if (picked != null) setState(() => startTime = picked);
                    },
                  ),
                  ListTile(
                    title: Text(endTime == null ? 'Hora Fin' : 'Fin: ${_formatTime(endTime!)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: endTime ?? TimeOfDay.now());
                      if (picked != null) setState(() => endTime = picked);
                    },
                  ),
                  TextFormField(
                    controller: maxParticipantsController,
                    decoration: const InputDecoration(labelText: 'Cupo'),
                    keyboardType: TextInputType.number,
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
                if (!_formKey.currentState!.validate() || startTime == null || endTime == null) return;
                
                final now = DateTime.now();
                final selectedDate = vm.selectedDate ?? now;
                final claseNueva = Clase(
                  id: clase?.id ?? '',
                  nombre: selectedClassType!,
                  dia: selectedDay!,
                  horaInicio: _formatTime(startTime!),
                  horaFin: _formatTime(endTime!),
                  fecha: DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
                  cuposDisponibles: int.tryParse(maxParticipantsController.text) ?? 14,
                  maximoParticipantes: int.tryParse(maxParticipantsController.text) ?? 14,
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
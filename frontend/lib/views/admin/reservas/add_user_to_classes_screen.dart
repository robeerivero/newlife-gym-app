// screens/admin/reservas/add_user_to_classes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/add_user_to_classes_viewmodel.dart';

class AddUserToClassesScreen extends StatelessWidget {
  const AddUserToClassesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddUserToClassesViewModel()..fetchUsuarios(),
      child: const _AddUserToClassesView(),
    );
  }
}

class _AddUserToClassesView extends StatelessWidget {
  const _AddUserToClassesView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddUserToClassesViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // backgroundColor eliminado (Theme default)
      appBar: AppBar(
        title: const Text('Añadir Usuario a Clases'),
        // backgroundColor eliminado (Theme default - Teal)
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (vm.error != null && vm.error!.isNotEmpty)
              Text(
                vm.error!,
                style: TextStyle(color: colorScheme.error),
              ),
            const SizedBox(height: 10),
            // Dropdown para seleccionar usuario
            DropdownButtonFormField<String>(
              value: vm.selectedUsuarioId,
              items: vm.usuarios.map<DropdownMenuItem<String>>((user) {
                return DropdownMenuItem<String>(
                  value: user.id,
                  child: Text(user.nombre),
                );
              }).toList(),
              onChanged: vm.setUsuario,
              decoration: const InputDecoration(labelText: 'Seleccionar Usuario'),
            ),
            const SizedBox(height: 10),
            // Dropdown para seleccionar día
            DropdownButtonFormField<String>(
              value: vm.selectedDay,
              items: vm.days.map<DropdownMenuItem<String>>((day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: vm.setDay,
              decoration: const InputDecoration(labelText: 'Seleccionar Día'),
            ),
            const SizedBox(height: 10),
            // Selector para la hora
            GestureDetector(
              onTap: () async {
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: vm.selectedTime ?? TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  vm.setTime(pickedTime);
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: vm.selectedTime == null
                        ? 'Seleccionar Hora de Inicio'
                        : 'Hora: ${vm.selectedTime!.hour.toString().padLeft(2, '0')}:${vm.selectedTime!.minute.toString().padLeft(2, '0')}',
                    // Icono añadido para mejor UX
                    suffixIcon: Icon(Icons.access_time, color: colorScheme.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            vm.loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final error = await vm.addUserToClasses();
                        if (error == null) {
                          // Éxito
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Usuario añadido a las clases con éxito.'), backgroundColor: Colors.green),
                            );
                            Navigator.pop(context, true);
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error), backgroundColor: colorScheme.error),
                            );
                          }
                        }
                      },
                      // Estilo eliminado para heredar del Theme (Primary)
                      child: const Text('Añadir Usuario a Clases'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
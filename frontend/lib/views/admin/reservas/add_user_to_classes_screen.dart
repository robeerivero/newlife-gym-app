import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Asegúrate de que esta ruta sea correcta
import '../../../../viewmodels/add_user_to_classes_viewmodel.dart'; 

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
      appBar: AppBar(
        title: const Text('Asignación Masiva'),
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vm.error != null && vm.error!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  vm.error!,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            
            // 1. SELECCIÓN DE USUARIO
            const Text("1. Seleccionar Usuario", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: vm.selectedUsuarioId,
              items: vm.usuarios.map<DropdownMenuItem<String>>((user) {
                return DropdownMenuItem<String>(
                  value: user.id,
                  child: Text(user.nombre),
                );
              }).toList(),
              onChanged: vm.setUsuario,
              decoration: const InputDecoration(
                hintText: 'Buscar usuario...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)
              ),
            ),
            
            const SizedBox(height: 20),

            // 2. SELECCIÓN DE DÍAS (Chips)
            const Text("2. Días de la semana", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Wrap(
              spacing: 8.0,
              children: vm.days.map((day) {
                final isSelected = vm.isDaySelected(day);
                return FilterChip(
                  label: Text(day),
                  selected: isSelected,
                  selectedColor: colorScheme.primaryContainer,
                  checkmarkColor: colorScheme.onPrimaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                  ),
                  onSelected: (_) => vm.toggleDay(day),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 3. SELECCIÓN DE HORAS (Chips)
            const Text("3. Horas de clase", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: vm.availableHours.map((hour) {
                final isSelected = vm.isHourSelected(hour);
                return FilterChip(
                  label: Text(hour),
                  selected: isSelected,
                  selectedColor: colorScheme.primary, // Color sólido para horas
                  checkmarkColor: colorScheme.onPrimary,
                  labelStyle: TextStyle(
                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => vm.toggleHour(hour),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // BOTÓN DE ACCIÓN
            vm.loading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final error = await vm.addUserToClasses();
                        
                        if (error == null) {
                          // --- ÉXITO ---
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Asignación completada. Puedes seguir añadiendo.'), 
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            // 👇 Aquí está la clave: Limpiamos y NO cerramos
                            vm.clearSelection(); 
                          }
                        } else {
                          // --- ERROR ---
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error), backgroundColor: colorScheme.error),
                            );
                          }
                        }
                      },
                      child: const Text('ASIGNAR A TODAS LAS CLASES'),
                    ),
                  ),
             
             const SizedBox(height: 10),
             Center(
               child: Text(
                 "Esto inscribirá al usuario en todas las clases futuras que coincidan.",
                 style: TextStyle(color: Colors.grey[600], fontSize: 12),
                 textAlign: TextAlign.center,
               ),
             )
          ],
        ),
      ),
    );
  }
}
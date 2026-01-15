import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/reservation_management_viewmodel.dart';
import '../../models/clase.dart';
import 'qr_generator_screen.dart';
import 'reservas/reservations_list_screen.dart';
import 'reservas/add_user_to_classes_screen.dart';

class ReservationManagementScreen extends StatelessWidget {
  const ReservationManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReservationManagementViewModel()..fetchClasses(date: DateTime.now()),
      child: const _ReservationManagementView(),
    );
  }
}

class _ReservationManagementView extends StatelessWidget {
  const _ReservationManagementView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservationManagementViewModel>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // El backgroundColor lo maneja el tema por defecto
      appBar: AppBar(
        title: const Text('Gestión de Reservas'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (vm.error != null)
              Text(
                vm.error!,
                style: TextStyle(color: colorScheme.error, fontSize: 16),
              ),
            ElevatedButton.icon(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: vm.selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  vm.fetchClasses(date: pickedDate);
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Seleccionar Fecha'),
              // Estilo eliminado para heredar del Theme (Primary/Teal)
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                // Navegamos a la pantalla
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddUserToClassesScreen(),
                  ),
                ).then((_) {                
                  vm.fetchClasses(date: vm.selectedDate ?? DateTime.now());
                });
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Añadir Usuario a Clases'),
            ),
            const SizedBox(height: 10),
            vm.loading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: vm.clases.length,
                      itemBuilder: (context, index) {
                        final classItem = vm.clases[index];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.event_available, color: colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${classItem.dia.toUpperCase()} - ${classItem.horaInicio.toUpperCase()}',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.people, color: colorScheme.primary),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ReservationsListScreen(
                                              classId: classItem.id,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '📅 Fecha: ${classItem.fecha.toLocal().toString().split(" ")[0]}',
                                  style: textTheme.bodyMedium,
                                ),
                                Text(
                                  '🏷️ Tipo: ${(classItem.nombre.isNotEmpty ? classItem.nombre : 'Sin nombre').toUpperCase()}',
                                  style: textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Row(
                                      children: [
                                        // Mantenemos verde semántico para cupos/éxito
                                        const Icon(Icons.group, size: 16, color: Colors.green),
                                        const SizedBox(width: 6),
                                        Text('Cupos: ${classItem.cuposDisponibles}', style: textTheme.bodyMedium),
                                      ],
                                    ),
                                    const SizedBox(width: 20),
                                    Row(
                                      children: [
                                        // Mantenemos rojo semántico para alertas/lleno
                                        const Icon(Icons.people_alt, size: 16, color: Colors.red),
                                        const SizedBox(width: 6),
                                        Text('Asistentes: ${classItem.maximoParticipantes - classItem.cuposDisponibles}', style: textTheme.bodyMedium),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => QRGeneratorScreen(claseId: classItem.id),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.qr_code),
                                    label: const Text("Generar QR"),
                                    // Estilo eliminado para heredar del Theme
                                  ),
                                ),
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
}
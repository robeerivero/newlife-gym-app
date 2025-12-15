// screens/admin/reservas/reservations_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/reservations_list_viewmodel.dart';
import '../../../models/usuario.dart';
import '../../../models/usuario_reserva.dart'; 

class ReservationsListScreen extends StatelessWidget {
  final String classId;

  const ReservationsListScreen({Key? key, required this.classId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReservationsListViewModel()
        ..fetchUsers(classId)
        ..fetchAllUsuarios(),
      child: _ReservationsListView(classId: classId),
    );
  }
}

class _ReservationsListView extends StatefulWidget {
  final String classId;
  const _ReservationsListView({required this.classId});

  @override
  State<_ReservationsListView> createState() => _ReservationsListViewState();
}

class _ReservationsListViewState extends State<_ReservationsListView> {
  Usuario? selectedUsuario;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservationsListViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // backgroundColor eliminado (Theme default)
      appBar: AppBar(
        title: const Text('Participantes de la Clase'),
        // backgroundColor eliminado (Theme default - Teal)
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Asignar usuario manualmente',
            onPressed: vm.usuariosDisponibles.isEmpty
                ? null
                : () => _mostrarDialogoAsignarUsuario(context, vm),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : vm.error != null
                ? Center(child: Text(vm.error!, style: TextStyle(color: colorScheme.error)))
                : vm.users.isEmpty
                    ? const Center(child: Text('No hay usuarios registrados en esta clase.'))
                    : ListView.builder(
                        itemCount: vm.users.length,
                        itemBuilder: (context, index) {
                          final UsuarioReserva user = vm.users[index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: Icon(
                                user.asistio ? Icons.check_circle : Icons.cancel,
                                // Semántico: Asistencia (verde) vs Falta (error/rojo)
                                color: user.asistio ? Colors.green : colorScheme.error,
                              ),
                              title: Text(user.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(user.correo),
                              trailing: IconButton(
                                icon: Icon(Icons.remove_circle, color: colorScheme.error),
                                tooltip: 'Desasignar usuario',
                                onPressed: () async {
                                  try {
                                    await vm.desasignarUsuarioDeClase(widget.classId, user.id);
                                    vm.fetchUsers(widget.classId);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error al desasignar: $e'), backgroundColor: colorScheme.error),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  void _mostrarDialogoAsignarUsuario(BuildContext context, ReservationsListViewModel vm) {
    Usuario? selectedUsuarioDialog;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Asignar usuario a clase'),
              content: DropdownButtonFormField<Usuario>(
                isExpanded: true,
                value: selectedUsuarioDialog,
                items: vm.usuariosDisponibles
                    .map((u) => DropdownMenuItem<Usuario>(
                          value: u,
                          child: Text('${u.nombre} (${u.correo})', overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (u) => setState(() => selectedUsuarioDialog = u),
                decoration: const InputDecoration(labelText: 'Selecciona un usuario'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selectedUsuarioDialog == null
                      ? null
                      : () async {
                          try {
                            await vm.asignarUsuarioAClase(widget.classId, selectedUsuarioDialog!.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                              vm.fetchUsers(widget.classId);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: colorScheme.error),
                              );
                            }
                          }
                        },
                  // Estilo del botón heredado del tema
                  child: const Text('Asignar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
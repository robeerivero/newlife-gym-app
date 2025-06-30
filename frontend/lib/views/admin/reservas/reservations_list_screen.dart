import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/reservations_list_viewmodel.dart';
import '../../../models/usuario.dart';
import '../../../models/usuario_reserva.dart'; // ← Importar modelo con asistio

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Participantes de la Clase'),
        backgroundColor: const Color(0xFF42A5F5),
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
                ? Center(child: Text(vm.error!))
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
                                color: user.asistio ? Colors.green : Colors.red,
                              ),
                              title: Text(user.nombre),
                              subtitle: Text(user.correo),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                tooltip: 'Desasignar usuario',
                                onPressed: () async {
                                  try {
                                    await vm.desasignarUsuarioDeClase(widget.classId, user.id);
                                    vm.fetchUsers(widget.classId);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error al desasignar: $e')),
                                    );
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
                          child: Text('${u.nombre} (${u.correo})'),
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
                            Navigator.pop(context);
                            vm.fetchUsers(widget.classId);
                          } catch (e) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
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

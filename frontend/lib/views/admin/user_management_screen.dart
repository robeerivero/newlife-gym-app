import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/user_management_viewmodel.dart';
import '../../models/usuario.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserManagementViewModel(),
      child: _UserManagementBody(),
    );
  }
}

class _UserManagementBody extends StatelessWidget {
  final List<String> _classTypes = ['funcional', 'pilates', 'zumba'];
  final List<String> _roles = ['admin', 'cliente', 'online'];

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<UserManagementViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: const Color(0xFF42A5F5),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.fetchUsuarios,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context, vm),
        child: const Icon(Icons.add),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
              ? Center(child: Text(vm.error!))
              : ListView.builder(
                  itemCount: vm.usuarios.length,
                  itemBuilder: (context, index) {
                    final user = vm.usuarios[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(user.nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.correo),
                            Text('Rol: ${user.rol}'),
                            Text('Clases: ${user.tiposDeClases.join(', ')}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _showEditUserDialog(context, vm, user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar usuario'),
                                    content:
                                        Text('¿Eliminar a ${user.nombre}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await vm.deleteUsuario(user.id);
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

  void _showAddUserDialog(BuildContext context, UserManagementViewModel vm) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'cliente';
    List<String> selectedClassTypes = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                ),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: _roles
                      .map((role) => DropdownMenuItem(
                          value: role, child: Text(role.toUpperCase())))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedRole = value!),
                  decoration: const InputDecoration(labelText: 'Rol'),
                ),
                const SizedBox(height: 10),
                const Text('Tipos de Clases:'),
                Wrap(
                  spacing: 8,
                  children: _classTypes
                      .map((type) => FilterChip(
                            label: Text(type),
                            selected: selectedClassTypes.contains(type),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedClassTypes.add(type);
                                } else {
                                  selectedClassTypes.remove(type);
                                }
                              });
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    passwordController.text.isEmpty ||
                    selectedClassTypes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Todos los campos son requeridos')),
                  );
                  return;
                }
                final ok = await vm.addUsuario(
                  nombre: nameController.text,
                  correo: emailController.text,
                  contrasena: passwordController.text,
                  rol: selectedRole,
                  tiposDeClases: selectedClassTypes,
                );
                if (ok) Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(
      BuildContext context, UserManagementViewModel vm, Usuario user) {
    final nameController = TextEditingController(text: user.nombre);
    final emailController = TextEditingController(text: user.correo);
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    String selectedRole = user.rol;
    List<String> selectedClassTypes = [...user.tiposDeClases];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: _roles
                      .map((role) => DropdownMenuItem(
                          value: role, child: Text(role.toUpperCase())))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedRole = value!),
                  decoration: const InputDecoration(labelText: 'Rol'),
                ),
                const SizedBox(height: 10),
                const Text('Tipos de Clases:'),
                Wrap(
                  spacing: 8,
                  children: _classTypes
                      .map((type) => FilterChip(
                            label: Text(type),
                            selected: selectedClassTypes.contains(type),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedClassTypes.add(type);
                                } else {
                                  selectedClassTypes.remove(type);
                                }
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: currentPasswordController,
                  decoration: const InputDecoration(
                      labelText: 'Contraseña Actual',
                      hintText: 'Opcional para cambiar contraseña'),
                  obscureText: true,
                ),
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                      labelText: 'Nueva Contraseña',
                      hintText: 'Opcional para cambiar contraseña'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    selectedClassTypes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Campos obligatorios faltantes')),
                  );
                  return;
                }

                final ok = await vm.updateUsuario(
                  usuario: user,
                  nombre: nameController.text,
                  correo: emailController.text,
                  rol: selectedRole,
                  tiposDeClases: selectedClassTypes,
                  contrasenaActual: currentPasswordController.text.isNotEmpty
                      ? currentPasswordController.text
                      : null,
                  nuevaContrasena: newPasswordController.text.isNotEmpty
                      ? newPasswordController.text
                      : null,
                );
                if (ok) Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

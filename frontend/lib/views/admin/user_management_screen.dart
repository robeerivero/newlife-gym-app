// screens/admin/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/user_management_viewmodel.dart'; 
import '../../models/usuario.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserManagementViewModel(),
      child: _UserManagementBody(),
    );
  }
}

class _UserManagementBody extends StatelessWidget {
  final List<String> _roles = ['admin', 'cliente', 'online'];
  // Opciones para el diálogo de añadir (simplificado)
  final List<String> _tiposDeClasesDefault = ['funcional', 'pilates', 'zumba'];

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<UserManagementViewModel>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        // backgroundColor eliminado, lo maneja el tema (Teal/Primary)
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: vm.loading ? null : vm.fetchUsuarios,
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: vm.grupoSeleccionado,
                // Usamos onPrimary para asegurar que se vea bien sobre el color del AppBar
                icon: Icon(Icons.filter_list, color: colorScheme.onPrimary),
                dropdownColor: colorScheme.primaryContainer, // O el color que prefieras del tema
                style: TextStyle(color: colorScheme.onPrimaryContainer, fontSize: 16),
                items: vm.gruposDisponibles.map((String grupo) {
                  return DropdownMenuItem<String>(
                    value: grupo,
                    child: Text(grupo, style: TextStyle(color: colorScheme.onSurface)),
                  );
                }).toList(),
                onChanged: vm.loading ? null : (String? nuevoGrupo) {
                    vm.setGrupoSeleccionado(nuevoGrupo); // Actualiza el filtro
                },
              ),
            ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context, vm),
        // backgroundColor eliminado, usa el color Secondary/Accent del tema por defecto
        child: const Icon(Icons.add),
      ),
      body: _buildUserList(context, vm),
    );
  }

  Widget _buildUserList(BuildContext context, UserManagementViewModel vm) {
    if (vm.loading && vm.usuarios.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null) {
      return Center(child: Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)));
    }
    if (vm.usuarios.isEmpty) {
      return const Center(child: Text('No se encontraron usuarios.'));
    }

    return ListView.builder(
      itemCount: vm.usuarios.length,
      itemBuilder: (context, index) {
        final user = vm.usuarios[index];
        return _buildUserCard(context, vm, user);
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context, UserManagementViewModel vm, Usuario user) {
    final TextEditingController passwordController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cambiar Contraseña'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Usuario: ${user.nombre}'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña',
                    // Bordes eliminados, el tema se encarga
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El campo no puede estar vacío';
                    }
                    if (value.length < 6) {
                      return 'Debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final newPassword = passwordController.text;
                  
                  final success = await vm.cambiarContrasena(user.id, newPassword);
                  
                  Navigator.of(dialogContext).pop();
                  
                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Contraseña de ${user.nombre} actualizada.'), backgroundColor: Colors.green),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${vm.error}'), backgroundColor: Theme.of(context).colorScheme.error),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserCard(BuildContext context, UserManagementViewModel vm, Usuario user) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2, // Puedes dejar que el tema maneje la elevación si prefieres quitar esto
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      // Mantenemos la lógica visual del borde por estado de pago, pero adaptamos colores
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: user.haPagado ? Colors.green.shade300 : (user.rol == 'admin' ? Colors.transparent : colorScheme.error),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8), // O usa el default del tema eliminando esta línea
      ),
      child: ListTile(
        leading: Icon(
          Icons.circle,
          size: 18,
          // Indigo reemplazado por Primary (Teal)
          color: user.rol == 'admin' ? colorScheme.primary : (user.haPagado ? Colors.green : colorScheme.error),
        ),
        title: Text(user.nombre, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${user.nombreGrupo ?? 'Sin Grupo'}  •  ${user.rol}',
          style: textTheme.bodyMedium?.copyWith(color: user.nombreGrupo == null ? textTheme.bodySmall?.color : null),
        ),
        
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit), // El color lo maneja el tema (normalmente gris o primary)
              tooltip: 'Editar Datos',
              onPressed: () => _showEditUserDialog(context, vm, user),
            ),
            IconButton(
              // Usamos Secondary (Orange) para acciones destacadas
              icon: Icon(Icons.key, color: colorScheme.secondary),
              tooltip: 'Cambiar Contraseña',
              onPressed: () => _showChangePasswordDialog(context, vm, user),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: colorScheme.error),
              tooltip: 'Eliminar',
              onPressed: () => _confirmDeleteUser(context, vm, user),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, UserManagementViewModel vm) {
    final _formKey = GlobalKey<FormState>();
    final _nombreController = TextEditingController();
    final _correoController = TextEditingController();
    final _contrasenaController = TextEditingController();
    final _grupoController = TextEditingController();
    String _selectedRol = 'cliente';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Añadir Usuario'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                  ),
                  TextFormField(
                    controller: _correoController,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => (value == null || !value.contains('@')) ? 'Correo inválido' : null,
                  ),
                  TextFormField(
                    controller: _contrasenaController,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                    validator: (value) => (value == null || value.length < 6) ? 'Mínimo 6 caracteres' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedRol,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: _roles.map((String rol) {
                      return DropdownMenuItem<String>(value: rol, child: Text(rol));
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) _selectedRol = newValue;
                    },
                  ),
                  TextFormField(
                    controller: _grupoController,
                    decoration: const InputDecoration(labelText: 'Nombre de Grupo (Opcional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final success = await vm.addUsuario(
                    nombre: _nombreController.text,
                    correo: _correoController.text,
                    contrasena: _contrasenaController.text,
                    rol: _selectedRol,
                    tiposDeClases: _tiposDeClasesDefault,
                    nombreGrupo: _grupoController.text.isEmpty ? null : _grupoController.text,
                  );
                  
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        if (!success && vm.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al crear: ${vm.error!}"), backgroundColor: Theme.of(context).colorScheme.error));
                        } else if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario creado"), backgroundColor: Colors.green));
                        }
                      }
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
  }

  void _showEditUserDialog(BuildContext context, UserManagementViewModel vm, Usuario user) {
    final _formKey = GlobalKey<FormState>();
    final _nombreController = TextEditingController(text: user.nombre);
    final _correoController = TextEditingController(text: user.correo);
    
    final _grupoController = TextEditingController(text: user.nombreGrupo);
    bool _haPagado = user.haPagado;
    
    String _selectedRol = user.rol;
    bool _esPremium = user.esPremium;
    bool _incluyeDieta = user.incluyePlanDieta;
    bool _incluyeEntreno = user.incluyePlanEntrenamiento;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Editar ${user.nombre}'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SwitchListTile(
                        title: Text(
                          _haPagado ? 'Pagado' : 'Pendiente de Pago',
                          style: TextStyle(
                            color: _haPagado ? Colors.green : colorScheme.error, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        value: _haPagado,
                        onChanged: (bool value) {
                          setDialogState(() {
                            _haPagado = value;
                          });
                        },
                      ),
                      TextFormField(
                        controller: _grupoController,
                        decoration: const InputDecoration(labelText: 'Nombre de Grupo (Opcional)'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                      ),
                      TextFormField(
                        controller: _correoController,
                        decoration: const InputDecoration(labelText: 'Correo'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => (value == null || !value.contains('@')) ? 'Correo inválido' : null,
                      ),

                      DropdownButtonFormField<String>(
                        value: _selectedRol,
                        decoration: const InputDecoration(labelText: 'Rol'),
                        items: _roles.map((String rol) {
                          return DropdownMenuItem<String>(value: rol, child: Text(rol));
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              _selectedRol = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Es Premium'),
                        value: _esPremium,
                        onChanged: (bool value) {
                          setDialogState(() {
                            _esPremium = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Incluye Dieta'),
                        value: _incluyeDieta,
                        onChanged: (bool value) {
                          setDialogState(() {
                            _incluyeDieta = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Incluye Entrenamiento'),
                        value: _incluyeEntreno,
                        onChanged: (bool value) {
                          setDialogState(() {
                            _incluyeEntreno = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final success = await vm.updateUsuario(
                        id: user.id,
                        nombre: _nombreController.text,
                        correo: _correoController.text,
                        rol: _selectedRol,
                        nuevaContrasena: null,
                        esPremium: _esPremium,
                        incluyePlanDieta: _incluyeDieta,
                        incluyePlanEntrenamiento: _incluyeEntreno,
                        haPagado: _haPagado,
                        nombreGrupo: _grupoController.text.isEmpty ? null : _grupoController.text,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        if (!success && vm.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error!), backgroundColor: Theme.of(context).colorScheme.error));
                        }
                      }
                    }
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

  void _confirmDeleteUser(BuildContext context, UserManagementViewModel vm, Usuario user) {
     showDialog(
       context: context,
       builder: (BuildContext dialogContext) {
         return AlertDialog(
           title: const Text('Eliminar Usuario'),
           content: Text('¿Estás seguro de eliminar a ${user.nombre}? Esta acción no se puede deshacer y borrará todos sus datos.'),
           actions: <Widget>[
             TextButton(
               child: const Text('Cancelar'),
               onPressed: () => Navigator.of(dialogContext).pop(),
             ),
             TextButton(
               child: Text('Eliminar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
               onPressed: () async {
                 Navigator.of(dialogContext).pop(); 
                 await vm.deleteUsuario(user.id); 
                 if (context.mounted && vm.error != null) { 
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error!), backgroundColor: Theme.of(context).colorScheme.error));
                 }
               },
             ),
           ],
         );
       },
     );
  }
}
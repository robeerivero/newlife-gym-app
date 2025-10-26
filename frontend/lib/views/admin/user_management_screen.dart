// screens/admin/user_management_screen.dart
// ¡ACTUALIZADO CON FILTROS, ORDEN, INDICADOR DE PAGO Y DIÁLOGO DE EDICIÓN!

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Colors.indigo,
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
                icon: const Icon(Icons.filter_list, color: Colors.white),
                dropdownColor: Colors.indigo[700],
                style: const TextStyle(color: Colors.white, fontSize: 16),
                // Usar vm.gruposDisponibles que se actualiza desde el ViewModel
                items: vm.gruposDisponibles.map((String grupo) {
                  return DropdownMenuItem<String>(
                    value: grupo,
                    child: Text(grupo, style: const TextStyle(color: Colors.white)),
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
        backgroundColor: Colors.indigo,
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
      return Center(child: Text(vm.error!, style: const TextStyle(color: Colors.red)));
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

  /// Construye la tarjeta para un usuario en la lista
  Widget _buildUserCard(BuildContext context, UserManagementViewModel vm, Usuario user) {
    // --- ¡TAMAÑO DE FUENTE AUMENTADO! ---
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold); // Más grande
    final subtitleStyle = Theme.of(context).textTheme.bodyLarge; // Un poco más grande

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: user.haPagado ? Colors.green.shade300 : (user.rol == 'admin' ? Colors.transparent : Colors.red.shade300),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          Icons.circle,
          size: 18, // Ligeramente más grande
          color: user.rol == 'admin' ? Colors.indigo : (user.haPagado ? Colors.green : Colors.red),
        ),
        // Aplicamos los nuevos estilos de texto
        title: Text(user.nombre, style: titleStyle),
        subtitle: Text(
          '${user.nombreGrupo ?? 'Sin Grupo'}  •  ${user.rol}',
          style: subtitleStyle?.copyWith(color: user.nombreGrupo == null ? Colors.grey[600] : Colors.black87),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blueGrey[600]),
              tooltip: 'Editar',
              onPressed: () => _showEditUserDialog(context, vm, user),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[700]),
              tooltip: 'Eliminar',
              onPressed: () => _confirmDeleteUser(context, vm, user),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra el diálogo para AÑADIR un nuevo usuario
  /// Muestra el diálogo para AÑADIR un nuevo usuario (¡CON CAMPO GRUPO!)
  void _showAddUserDialog(BuildContext context, UserManagementViewModel vm) {
    final _formKey = GlobalKey<FormState>();
    final _nombreController = TextEditingController();
    final _correoController = TextEditingController();
    final _contrasenaController = TextEditingController();
    final _grupoController = TextEditingController(); // <-- ¡NUEVO!
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
                  // --- ¡NUEVO CAMPO! ---
                  TextFormField(
                    controller: _grupoController,
                    decoration: const InputDecoration(labelText: 'Nombre de Grupo (Opcional)'),
                    // Sin validador, es opcional
                  ),
                  // --- FIN NUEVO CAMPO ---
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
                    contrasena: _contrasenaController.text, // <-- SIN HASHEAR
                    rol: _selectedRol,
                    tiposDeClases: _tiposDeClasesDefault,
                    nombreGrupo: _grupoController.text.isEmpty ? null : _grupoController.text,
                  );
                  // ... (manejo del resultado)
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        if (!success && vm.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al crear: ${vm.error!}"), backgroundColor: Colors.red));
                        } else if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Usuario creado"), backgroundColor: Colors.green));
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

  /// Muestra el diálogo para EDITAR un usuario (¡MODIFICADO!)
  void _showEditUserDialog(BuildContext context, UserManagementViewModel vm, Usuario user) {
    final _formKey = GlobalKey<FormState>();
    final _nombreController = TextEditingController(text: user.nombre);
    final _correoController = TextEditingController(text: user.correo);
    final _contrasenaController = TextEditingController(); // Vacía por defecto
    // --- ¡NUEVO! ---
    final _grupoController = TextEditingController(text: user.nombreGrupo);
    bool _haPagado = user.haPagado;
    // --- FIN NUEVO ---
    
    String _selectedRol = user.rol;
    bool _esPremium = user.esPremium;
    bool _incluyeDieta = user.incluyePlanDieta;
    bool _incluyeEntreno = user.incluyePlanEntrenamiento;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Usamos StatefulBuilder para que el estado del Switch se actualice
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
                      // --- ¡NUEVO! Switch de Pago ---
                      SwitchListTile(
                        title: Text(
                          _haPagado ? 'Pagado' : 'Pendiente de Pago',
                          style: TextStyle(color: _haPagado ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                        ),
                        value: _haPagado,
                        onChanged: (bool value) {
                          setDialogState(() {
                            _haPagado = value;
                          });
                        },
                      ),
                      // --- ¡NUEVO! Campo de Grupo ---
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
                      TextFormField(
                        controller: _contrasenaController,
                        decoration: const InputDecoration(labelText: 'Nueva Contraseña (Opcional)'),
                        obscureText: true,
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
                      // Checkboxes de servicios
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
                        nuevaContrasena: _contrasenaController.text.isEmpty ? null : _contrasenaController.text,
                        esPremium: _esPremium,
                        incluyePlanDieta: _incluyeDieta,
                        incluyePlanEntrenamiento: _incluyeEntreno,
                        // --- ¡NUEVOS CAMPOS! ---
                        haPagado: _haPagado,
                        nombreGrupo: _grupoController.text.isEmpty ? null : _grupoController.text,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        if (!success && vm.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error!), backgroundColor: Colors.red));
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

   /// Muestra diálogo de confirmación antes de eliminar.
  void _confirmDeleteUser(BuildContext context, UserManagementViewModel vm, Usuario user) {
     // (Tu función original sin cambios)
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
               child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
               onPressed: () async {
                 Navigator.of(dialogContext).pop(); 
                 await vm.deleteUsuario(user.id); 
                 if (context.mounted && vm.error != null) { 
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error!), backgroundColor: Colors.red));
                 }
               },
             ),
           ],
         );
       },
     );
  }
}
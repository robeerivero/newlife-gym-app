// screens/admin/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Necesario para formatear fechas
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
  final List<String> _tiposDeClasesDefault = ['funcional', 'pilates', 'zumba'];

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<UserManagementViewModel>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
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
                icon: Icon(Icons.filter_list, color: colorScheme.onPrimary),
                dropdownColor: colorScheme.primaryContainer,
                style: TextStyle(color: colorScheme.onPrimaryContainer, fontSize: 16),
                items: vm.gruposDisponibles.map((String grupo) {
                  return DropdownMenuItem<String>(
                    value: grupo,
                    child: Text(grupo),
                  );
                }).toList(),
                onChanged: vm.loading ? null : (String? nuevoGrupo) {
                    vm.setGrupoSeleccionado(nuevoGrupo);
                },
              ),
            ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context, vm),
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

  // --- TARJETA DE USUARIO MEJORADA ---
  Widget _buildUserCard(BuildContext context, UserManagementViewModel vm, Usuario user) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final bool tieneSolicitud = user.solicitudPremium != null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: tieneSolicitud ? Colors.amber.shade50 : null,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: tieneSolicitud 
              ? Colors.amber 
              : (user.haPagado ? Colors.green.shade300 : (user.rol == 'admin' ? Colors.transparent : colorScheme.error)),
          width: tieneSolicitud ? 2.0 : 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Reducimos padding para ganar espacio
        leading: Icon(
          tieneSolicitud ? Icons.rocket_launch : Icons.circle,
          size: tieneSolicitud ? 24 : 14, // Icono un poco más pequeño
          color: tieneSolicitud 
              ? Colors.amber 
              : (user.rol == 'admin' ? colorScheme.primary : (user.haPagado ? Colors.green : colorScheme.error)),
        ),
        title: Row(
          children: [
            // Usamos Flexible para que el texto se corte si es muy largo y no empuje los botones fuera
            Flexible(
              child: Text(
                user.nombre, 
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis, // Pone "..." si no cabe
              ),
            ),
            if (tieneSolicitud) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                child: const Text('SOLICITUD', style: TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold)),
              )
            ]
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${user.nombreGrupo ?? 'Sin Grupo'}  •  ${user.rol}',
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 12, 
                color: user.nombreGrupo == null ? textTheme.bodySmall?.color : null
              ),
            ),
            if (tieneSolicitud)
              Text(
                'Solicitado: ${DateFormat('dd/MM HH:mm').format(user.solicitudPremium!.toLocal())}',
                style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontStyle: FontStyle.italic),
              )
          ],
        ),
        
        // 👇 AQUÍ ESTÁ EL CAMBIO CLAVE PARA EVITAR EL OVERFLOW 👇
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Botón Atender (Solo si hay solicitud) - Prioridad alta
            if (tieneSolicitud)
              IconButton(
                visualDensity: VisualDensity.compact, // Ocupa menos espacio
                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                tooltip: 'Atender/Limpiar Solicitud',
                onPressed: () => _confirmarAtencionSolicitud(context, vm, user),
              ),

            // 2. Botón Editar - Prioridad alta
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit), 
              tooltip: 'Editar Datos',
              onPressed: () => _showEditUserDialog(context, vm, user),
            ),

            // 3. Menú "Más opciones" (3 puntitos) para lo que no cabe
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Más acciones',
              onSelected: (value) {
                if (value == 'password') _showChangePasswordDialog(context, vm, user);
                if (value == 'delete') _confirmDeleteUser(context, vm, user);
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'password',
                  child: ListTile(
                    leading: Icon(Icons.key),
                    title: Text('Cambiar Contraseña'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Eliminar Usuario', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- DIÁLOGO PARA ATENDER SOLICITUD ---
  void _confirmarAtencionSolicitud(BuildContext context, UserManagementViewModel vm, Usuario user) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Gestionar Solicitud Premium'),
          content: Text('El usuario ${user.nombre} ha solicitado información sobre Premium.\n\n¿Has contactado con él? Al confirmar, se borrará la marca de solicitud.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Sí, Limpiar', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); 
                final success = await vm.limpiarSolicitud(user.id);
                if (context.mounted) {
                   if (success) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitud gestionada.'), backgroundColor: Colors.green));
                   } else {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error ?? 'Error'), backgroundColor: Colors.red));
                   }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- EL RESTO DE MÉTODOS SE MANTIENEN IGUAL (Dialogs de Edit, Add, Password, Delete) ---
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
                  decoration: const InputDecoration(labelText: 'Nueva Contraseña'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'El campo no puede estar vacío';
                    if (value.length < 6) return 'Debe tener al menos 6 caracteres';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(dialogContext).pop()),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final success = await vm.cambiarContrasena(user.id, passwordController.text);
                  Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Contraseña actualizada.' : 'Error: ${vm.error}'), backgroundColor: success ? Colors.green : Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
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
                    items: _roles.map((String rol) => DropdownMenuItem<String>(value: rol, child: Text(rol))).toList(),
                    onChanged: (newValue) { if (newValue != null) _selectedRol = newValue; },
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
            TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
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
                    if (!success) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${vm.error}"), backgroundColor: Colors.red));
                    else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario creado"), backgroundColor: Colors.green));
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
                        title: Text(_haPagado ? 'Pagado' : 'Pendiente de Pago', style: TextStyle(color: _haPagado ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                        value: _haPagado,
                        onChanged: (val) => setDialogState(() => _haPagado = val),
                      ),
                      TextFormField(controller: _grupoController, decoration: const InputDecoration(labelText: 'Grupo')),
                      const SizedBox(height: 10),
                      TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                      TextFormField(controller: _correoController, decoration: const InputDecoration(labelText: 'Correo'), keyboardType: TextInputType.emailAddress),
                      DropdownButtonFormField<String>(
                        value: _selectedRol,
                        decoration: const InputDecoration(labelText: 'Rol'),
                        items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedRol = val!),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(title: const Text('Es Premium'), value: _esPremium, onChanged: (val) => setDialogState(() => _esPremium = val)),
                      SwitchListTile(title: const Text('Incluye Dieta'), value: _incluyeDieta, onChanged: (val) => setDialogState(() => _incluyeDieta = val)),
                      SwitchListTile(title: const Text('Incluye Entrenamiento'), value: _incluyeEntreno, onChanged: (val) => setDialogState(() => _incluyeEntreno = val)),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
                ElevatedButton(
                  child: const Text('Guardar'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final success = await vm.updateUsuario(
                        id: user.id, nombre: _nombreController.text, correo: _correoController.text,
                        rol: _selectedRol, nuevaContrasena: null, esPremium: _esPremium,
                        incluyePlanDieta: _incluyeDieta, incluyePlanEntrenamiento: _incluyeEntreno,
                        haPagado: _haPagado, nombreGrupo: _grupoController.text.isEmpty ? null : _grupoController.text,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        if (!success) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error!), backgroundColor: Colors.red));
                      }
                    }
                  },
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
       builder: (ctx) => AlertDialog(
         title: const Text('Eliminar Usuario'),
         content: Text('¿Seguro que quieres eliminar a ${user.nombre}?'),
         actions: [
           TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop()),
           TextButton(
             child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
             onPressed: () async {
               Navigator.of(ctx).pop();
               await vm.deleteUsuario(user.id);
               if (context.mounted && vm.error != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error!), backgroundColor: Colors.red));
             },
           ),
         ],
       ),
     );
  }
}
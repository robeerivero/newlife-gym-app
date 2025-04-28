import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  String _selectedRole = 'cliente';
  List<String> _selectedClassTypes = [];

  final List<String> _classTypes = ['funcional', 'pilates', 'zumba'];
  final List<String> _roles = ['admin', 'cliente', 'online'];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/admin/usuarios'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => _users = json.decode(response.body));
      } else {
        setState(() => _errorMessage = 'Error cargando usuarios: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error de conexión: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(String id) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/api/admin/usuarios/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado correctamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar el usuario')),
      );
    }
  }

  void _showAddUserDialog() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _selectedRole = 'cliente';
    _selectedClassTypes = [];

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
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: _roles.map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedRole = value!),
                  decoration: const InputDecoration(labelText: 'Rol'),
                ),
                const SizedBox(height: 10),
                const Text('Tipos de Clases:'),
                Wrap(
                  spacing: 8,
                  children: _classTypes.map((type) => FilterChip(
                    label: Text(type),
                    selected: _selectedClassTypes.contains(type),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _selectedClassTypes.add(type);
                      } else {
                        _selectedClassTypes.remove(type);
                      }
                    }),
                  )).toList(),
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
                if (_validateForm()) {
                  try {
                    final token = await _storage.read(key: 'jwt_token');
                    final response = await http.post(
                      Uri.parse('${AppConstants.baseUrl}/api/admin/usuarios'),
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Content-Type': 'application/json',
                      },
                      body: json.encode({
                        'nombre': _nameController.text,
                        'correo': _emailController.text,
                        'contrasena': _passwordController.text,
                        'rol': _selectedRole,
                        'tiposDeClases': _selectedClassTypes,
                      }),
                    );

                    if (response.statusCode == 201) {
                      _fetchUsers();
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al crear usuario')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateForm() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedClassTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos son requeridos')),
      );
      return false;
    }
    return true;
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    _nameController.text = user['nombre'];
    _emailController.text = user['correo'];
    _selectedRole = user['rol'];
    _selectedClassTypes = List<String>.from(user['tiposDeClases']);
    _currentPasswordController.clear(); // Limpiar campos de contraseña
    _newPasswordController.clear();

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
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: _roles.map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedRole = value!),
                  decoration: const InputDecoration(labelText: 'Rol'),
                ),
                const SizedBox(height: 10),
                const Text('Tipos de Clases:'),
                Wrap(
                  spacing: 8,
                  children: _classTypes.map((type) => FilterChip(
                    label: Text(type),
                    selected: _selectedClassTypes.contains(type),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _selectedClassTypes.add(type);
                      } else {
                        _selectedClassTypes.remove(type);
                      }
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña Actual',
                    hintText: 'Opcional para cambiar contraseña'
                  ),
                  obscureText: true,
                ),
                TextField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña',
                    hintText: 'Opcional para cambiar contraseña'
                  ),
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
                if (_validateEditForm(user)) {
                  try {
                    final token = await _storage.read(key: 'jwt_token');
                    final body = {
                      'nombre': _nameController.text,
                      'correo': _emailController.text,
                      'rol': _selectedRole,
                      'tiposDeClases': _selectedClassTypes,
                    };

                    // Añadir campos de contraseña si están completos
                    if (_currentPasswordController.text.isNotEmpty && 
                        _newPasswordController.text.isNotEmpty) {
                      body['contrasenaActual'] = _currentPasswordController.text;
                      body['nuevaContrasena'] = _newPasswordController.text;
                    }

                    final response = await http.put(
                      Uri.parse('${AppConstants.baseUrl}/api/admin/usuarios/${user['_id']}'),
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Content-Type': 'application/json',
                      },
                      body: json.encode(body),
                    );

                    if (response.statusCode == 200) {
                      _fetchUsers();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Usuario actualizado correctamente')),
                      );
                    } else {
                      final errorData = json.decode(response.body);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorData['mensaje'] ?? 'Error al actualizar')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // Añade este método de validación
  bool _validateEditForm(Map<String, dynamic> user) {
    final passwordFieldsFilled = 
      _currentPasswordController.text.isNotEmpty || 
      _newPasswordController.text.isNotEmpty;

    if (passwordFieldsFilled) {
      if (_currentPasswordController.text.isEmpty || 
          _newPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ambos campos de contraseña son requeridos')),
        );
        return false;
      }
      
      if (_newPasswordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La nueva contraseña debe tener al menos 6 caracteres')),
        );
        return false;
      }
    }

    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _selectedClassTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campos obligatorios faltantes')),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: const Color(0xFF42A5F5),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(user['nombre']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['correo']),
                            Text('Rol: ${user['rol']}'),
                            Text('Clases: ${user['tiposDeClases'].join(', ')}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditUserDialog(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar usuario'),
                                    content: Text('¿Eliminar a ${user['nombre']}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteUser(user['_id']);
                                        },
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );
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
}
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class DietaManagementScreen extends StatefulWidget {
  const DietaManagementScreen({super.key});

  @override
  State<DietaManagementScreen> createState() => _DietaManagementScreenState();
}

class _DietaManagementScreenState extends State<DietaManagementScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<dynamic> _usuarios = [];
  List<dynamic> _dietas = [];
  String? _selectedUsuarioId;
  List<Map<String, dynamic>> _platos = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUsuarios();
    _fetchPlatos();
  }

  Future<void> _fetchUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      final res = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/usuarios'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _usuarios = data;
          _selectedUsuarioId = data.isNotEmpty ? data[0]['_id'] : null;
        });
        if (_selectedUsuarioId != null) _fetchDietas(_selectedUsuarioId!);
      } else {
        setState(() => _errorMessage = 'Error al cargar usuarios');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error de conexión');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDietas(String userId) async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      final res = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/dietas/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        setState(() => _dietas = json.decode(res.body));
      } else {
        setState(() => _errorMessage = 'Error al cargar dietas');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error de conexión');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPlatos() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) return;

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/platos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _platos = data.map((p) => {
            '_id': p['_id'],
            'nombre': p['nombre'],
            'kcal': p['kcal'],
          }).toList();
        });
      } else {
        setState(() => _errorMessage = 'Error al cargar los platos.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error de conexión al cargar platos.');
    }
  }


  Future<void> _deleteDieta(String id) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final res = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/api/dietas/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        _fetchDietas(_selectedUsuarioId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dieta eliminada')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar dieta')),
      );
    }
  }

  Future<void> _deleteAllDietas() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar todas las dietas'),
        content: const Text('¿Estás seguro de eliminar todas las dietas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final token = await _storage.read(key: 'jwt_token');
        final res = await http.delete(
          Uri.parse('${AppConstants.baseUrl}/api/dietas'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (res.statusCode == 200) {
          _fetchDietas(_selectedUsuarioId!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todas las dietas eliminadas')),
          );
        }
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar dietas')),
        );
      }
    }
  }

  String _formatDate(String date) {
    final d = DateTime.parse(date);
    return '${d.day}/${d.month}/${d.year}';
  }
  void _showAddDietaDialog() {
    DateTime? selectedDate;
    String? selectedUsuarioId;
    List<String> selectedPlatos = [];
    bool isLoading = false;
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Agregar Nueva Dieta'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (errorMessage.isNotEmpty)
                        Text(errorMessage, style: const TextStyle(color: Colors.red)),
                      DropdownButtonFormField<String>(
                        value: selectedUsuarioId,
                        decoration: const InputDecoration(labelText: 'Usuario'),
                        items: _usuarios.map((usuario) {
                          return DropdownMenuItem<String>(
                            value: usuario['_id'],
                            child: Text('${usuario['nombre']} (${usuario['correo']})'),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => selectedUsuarioId = value),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        title: Text(
                          selectedDate == null
                              ? 'Selecciona una fecha'
                              : 'Fecha: ${selectedDate.toString().split(' ')[0]}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() => selectedDate = pickedDate);
                          }
                        },
                      ),
                      const Divider(),
                      const Text('Selecciona Platos:'),
                      const SizedBox(height: 5),
                      ..._platos.map((plato) {
                        return CheckboxListTile(
                          title: Text('${plato['nombre']} (${plato['kcal']} kcal)'),
                          value: selectedPlatos.contains(plato['_id']),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedPlatos.add(plato['_id']);
                              } else {
                                selectedPlatos.remove(plato['_id']);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedUsuarioId == null ||
                        selectedDate == null ||
                        selectedPlatos.isEmpty) {
                      setState(() => errorMessage = 'Todos los campos son obligatorios.');
                      return;
                    }

                    setState(() => isLoading = true);

                    try {
                      final token = await _storage.read(key: 'jwt_token');
                      final response = await http.post(
                        Uri.parse('${AppConstants.baseUrl}/api/dietas'),
                        headers: {
                          'Authorization': 'Bearer $token',
                          'Content-Type': 'application/json',
                        },
                        body: json.encode({
                          'usuario': selectedUsuarioId,
                          'fecha': selectedDate!.toIso8601String().split('T')[0],
                          'platos': selectedPlatos,
                        }),
                      );

                      if (response.statusCode == 201) {
                        Navigator.pop(context);
                        _fetchDietas(selectedUsuarioId!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dieta agregada con éxito')),
                        );
                      } else {
                        setState(() => errorMessage = 'Error al agregar la dieta.');
                      }
                    } catch (_) {
                      setState(() => errorMessage = 'Error de conexión.');
                    } finally {
                      setState(() => isLoading = false);
                    }
                  },
                  child: isLoading
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Dietas'),
        backgroundColor: const Color(0xFF42A5F5),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _deleteAllDietas,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDietaDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                    ),
                  DropdownButtonFormField<String>(
                    value: _selectedUsuarioId,
                    items: _usuarios
                        .map<DropdownMenuItem<String>>((u) => DropdownMenuItem(
                              value: u['_id'],
                              child: Text(u['nombre']),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedUsuarioId = value);
                      if (value != null) _fetchDietas(value);
                    },
                    decoration: const InputDecoration(labelText: 'Selecciona un usuario'),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _dietas.isEmpty
                        ? const Center(child: Text('No hay dietas registradas'))
                        : ListView.builder(
                            itemCount: _dietas.length,
                            itemBuilder: (_, i) {
                              final dieta = _dietas[i];
                              return Card(
                                child: ListTile(
                                  title: Text('Fecha: ${_formatDate(dieta['fecha'])}'),
                                  subtitle: Text(
                                    'Platos: ${(dieta['platos'] as List).map((e) => e['nombre']).join(', ')}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteDieta(dieta['_id']),
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

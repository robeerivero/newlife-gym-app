import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class PlatoManagementScreen extends StatefulWidget {
  const PlatoManagementScreen({Key? key}) : super(key: key);

  @override
  State<PlatoManagementScreen> createState() => _PlatoManagementScreenState();
}

class _PlatoManagementScreenState extends State<PlatoManagementScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<dynamic> _platos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _kcalController = TextEditingController();
  final TextEditingController _ingredientesController = TextEditingController();
  final TextEditingController _instruccionesController = TextEditingController();
  final TextEditingController _tiempoPreparacionController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();

  String _selectedComidaDelDia = 'Almuerzo';
  final List<String> _comidasDelDia = ['Desayuno', 'Almuerzo', 'Cena', 'Snack'];

  @override
  void initState() {
    super.initState();
    _fetchPlatos();
  }

  Future<void> _fetchPlatos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/platos'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => _platos = json.decode(response.body));
      } else {
        setState(() => _errorMessage = 'Error cargando platos: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error de conexión: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePlato(String id) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/api/platos/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchPlatos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plato eliminado correctamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar el plato')),
      );
    }
  }

  void _showPlatoDialog({Map<String, dynamic>? plato}) {
    final isEdit = plato != null;
    _nameController.text = isEdit ? plato['nombre'] : '';
    _kcalController.text = isEdit ? plato['kcal'].toString() : '';
    _ingredientesController.text = isEdit ? (plato['ingredientes'] as List).join(', ') : '';
    _instruccionesController.text = isEdit ? plato['instrucciones'] : '';
    _tiempoPreparacionController.text = isEdit ? plato['tiempoPreparacion'].toString() : '';
    _observacionesController.text = isEdit ? (plato['observaciones'] ?? '') : '';
    _selectedComidaDelDia = isEdit ? plato['comidaDelDia'] : 'Almuerzo';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Editar Plato' : 'Nuevo Plato'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre')),
                TextField(controller: _kcalController, decoration: const InputDecoration(labelText: 'Calorías'), keyboardType: TextInputType.number),
                DropdownButtonFormField<String>(
                  value: _selectedComidaDelDia,
                  items: _comidasDelDia.map((comida) => DropdownMenuItem(value: comida, child: Text(comida))).toList(),
                  onChanged: (value) => setState(() => _selectedComidaDelDia = value!),
                  decoration: const InputDecoration(labelText: 'Comida del Día'),
                ),
                TextField(controller: _ingredientesController, decoration: const InputDecoration(labelText: 'Ingredientes (separados por coma)')),
                TextField(controller: _instruccionesController, decoration: const InputDecoration(labelText: 'Instrucciones'), maxLines: 3),
                TextField(controller: _tiempoPreparacionController, decoration: const InputDecoration(labelText: 'Tiempo de Preparación (min)'), keyboardType: TextInputType.number),
                TextField(controller: _observacionesController, decoration: const InputDecoration(labelText: 'Observaciones (opcional)'), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                if (_validateForm()) {
                  try {
                    final token = await _storage.read(key: 'jwt_token');
                    final platoData = {
                      'nombre': _nameController.text,
                      'kcal': int.parse(_kcalController.text),
                      'comidaDelDia': _selectedComidaDelDia,
                      'ingredientes': _ingredientesController.text.split(',').map((e) => e.trim()).toList(),
                      'instrucciones': _instruccionesController.text,
                      'tiempoPreparacion': int.parse(_tiempoPreparacionController.text),
                      'observaciones': _observacionesController.text,
                    };

                    final url = isEdit
                        ? Uri.parse('${AppConstants.baseUrl}/api/platos/${plato!['_id']}')
                        : Uri.parse('${AppConstants.baseUrl}/api/platos');

                    final response = isEdit
                        ? await http.put(url, headers: _headers(token), body: json.encode(platoData))
                        : await http.post(url, headers: _headers(token), body: json.encode(platoData));

                    if (response.statusCode == 201 || response.statusCode == 200) {
                      _fetchPlatos();
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: ${response.body}')));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión')));
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

  Map<String, String> _headers(String? token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  bool _validateForm() {
    if (_nameController.text.isEmpty ||
        _kcalController.text.isEmpty ||
        _ingredientesController.text.isEmpty ||
        _instruccionesController.text.isEmpty ||
        _tiempoPreparacionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete todos los campos requeridos')),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Platos'),
        backgroundColor: const Color(0xFF42A5F5),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPlatos),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlatoDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView.builder(
                  itemCount: _platos.length,
                  itemBuilder: (context, index) {
                    final plato = _platos[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(plato['nombre']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kcal: ${plato['kcal']}'),
                            Text('Comida del Día: ${plato['comidaDelDia']}'),
                            Text('Ingredientes: ${(plato['ingredientes'] as List).join(', ')}'),
                            Text('Tiempo: ${plato['tiempoPreparacion']} min'),
                            if (plato['observaciones'] != null && plato['observaciones'].toString().isNotEmpty)
                              Text('Obs: ${plato['observaciones']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showPlatoDialog(plato: plato),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar plato'),
                                    content: Text('¿Eliminar "${plato['nombre']}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deletePlato(plato['_id']);
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

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../../config.dart';

class AddDietaScreen extends StatefulWidget {
  const AddDietaScreen({Key? key}) : super(key: key);

  @override
  _AddDietaScreenState createState() => _AddDietaScreenState();
}

class _AddDietaScreenState extends State<AddDietaScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  DateTime? _selectedDate;
  String? _selectedUsuarioId;
  List<String> _selectedPlatos = [];
  List<Map<String, dynamic>> _usuariosDisponibles = [];
  List<Map<String, dynamic>> _platosDisponibles = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUsuarios();
    _fetchPlatos();
  }

  Future<void> _fetchUsuarios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Token no encontrado. Por favor, inicia sesión nuevamente.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/usuarios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> usuarios = json.decode(response.body);
        setState(() {
          _usuariosDisponibles = usuarios.map((usuario) => {
                '_id': usuario['_id'],
                'nombre': usuario['nombre'],
                'correo': usuario['correo'],
              }).toList();
          _selectedUsuarioId = _usuariosDisponibles.isNotEmpty ? _usuariosDisponibles.first['_id'] : null;
        });
      } else {
        setState(() {
          _errorMessage = 'Error al cargar los usuarios.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión al cargar usuarios.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPlatos() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Token no encontrado. Por favor, inicia sesión nuevamente.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/platos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> platos = json.decode(response.body);
        setState(() {
          _platosDisponibles = platos.map((plato) => {
                '_id': plato['_id'],
                'nombre': plato['nombre'],
                'kcal': plato['kcal'],
              }).toList();
        });
      } else {
        setState(() {
          _errorMessage = 'Error al cargar los platos.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión al cargar platos.';
      });
    }
  }

  Future<void> _addDieta() async {
    if (_selectedPlatos.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, selecciona al menos un plato.';
      });
      return;
    }

    if (_selectedUsuarioId == null) {
      setState(() {
        _errorMessage = 'Por favor, selecciona un usuario.';
      });
      return;
    }

    if (_selectedDate == null) {
      setState(() {
        _errorMessage = 'Por favor, selecciona una fecha.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Token no encontrado. Por favor, inicia sesión nuevamente.';
        });
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/dietas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'usuario': _selectedUsuarioId,
          'fecha': _selectedDate!.toIso8601String().split('T')[0],
          'platos': _selectedPlatos,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dieta creada con éxito.')),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = 'Error al crear la dieta.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Dieta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            DropdownButtonFormField<String>(
              value: _selectedUsuarioId,
              items: _usuariosDisponibles.map((usuario) {
                return DropdownMenuItem<String>(
                  value: usuario['_id'],
                  child: Text('${usuario['nombre']} (${usuario['correo']})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUsuarioId = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Selecciona un Usuario'),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text(
                _selectedDate == null
                    ? 'Selecciona una fecha'
                    : 'Fecha: ${_selectedDate!.toIso8601String().split('T')[0]}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (selectedDate != null) {
                    setState(() {
                      _selectedDate = selectedDate;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _platosDisponibles.length,
                itemBuilder: (context, index) {
                  final plato = _platosDisponibles[index];
                  return CheckboxListTile(
                    title: Text('${plato['nombre']} (${plato['kcal']} kcal)'),
                    value: _selectedPlatos.contains(plato['_id']),
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedPlatos.add(plato['_id']);
                        } else {
                          _selectedPlatos.remove(plato['_id']);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _addDieta,
                    child: const Text('Guardar Dieta'),
                  ),
          ],
        ),
      ),
    );
  }
}

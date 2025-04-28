import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../config.dart';

class AddPlatoScreen extends StatefulWidget {
  const AddPlatoScreen({Key? key}) : super(key: key);

  @override
  _AddPlatoScreenState createState() => _AddPlatoScreenState();
}

class _AddPlatoScreenState extends State<AddPlatoScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final _nombreController = TextEditingController();
  final _kcalController = TextEditingController();
  final _ingredientesController = TextEditingController();
  final _instruccionesController = TextEditingController();
  final _tiempoPreparacionController = TextEditingController();
  final _observacionesController = TextEditingController();
  String? _selectedComidaDelDia; // Para el selector
  bool _isLoading = false;
  String _errorMessage = '';

  final List<String> _comidaDelDiaOptions = [
    'Desayuno',
    'Almuerzo',
    'Cena',
    'Snack'
  ];

  Future<void> _addPlato() async {
    if (_nombreController.text.trim().isEmpty ||
        _kcalController.text.trim().isEmpty ||
        _selectedComidaDelDia == null ||
        _ingredientesController.text.trim().isEmpty ||
        _instruccionesController.text.trim().isEmpty ||
        _tiempoPreparacionController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Todos los campos obligatorios deben estar completos.';
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
        Uri.parse('${AppConstants.baseUrl}/api/platos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'nombre': _nombreController.text.trim(),
          'kcal': int.parse(_kcalController.text.trim()),
          'comidaDelDia': _selectedComidaDelDia,
          'ingredientes': _ingredientesController.text.trim().split(','),
          'instrucciones': _instruccionesController.text.trim(),
          'tiempoPreparacion': int.parse(_tiempoPreparacionController.text.trim()),
          'observaciones': _observacionesController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plato agregado con éxito.')),
        );
        Navigator.pop(context, true); // Regresar con éxito
      } else {
        final data = json.decode(response.body);
        setState(() {
          _errorMessage = data['mensaje'] ?? 'Error desconocido.';
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
      appBar: AppBar(title: const Text('Agregar Plato')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del Plato'),
              ),
              TextField(
                controller: _kcalController,
                decoration: const InputDecoration(labelText: 'Kcal'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedComidaDelDia,
                items: _comidaDelDiaOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedComidaDelDia = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Comida del Día'),
              ),
              TextField(
                controller: _ingredientesController,
                decoration: const InputDecoration(
                  labelText: 'Ingredientes (separados por comas)',
                ),
              ),
              TextField(
                controller: _instruccionesController,
                decoration: const InputDecoration(labelText: 'Instrucciones'),
                maxLines: 3,
              ),
              TextField(
                controller: _tiempoPreparacionController,
                decoration: const InputDecoration(labelText: 'Tiempo de Preparación (minutos)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _observacionesController,
                decoration: const InputDecoration(labelText: 'Observaciones (opcional)'),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _addPlato,
                      child: const Text('Guardar Plato'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

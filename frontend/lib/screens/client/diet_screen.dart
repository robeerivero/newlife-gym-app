import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../config.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({Key? key}) : super(key: key);

  @override
  _DietScreenState createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  DateTime _selectedFecha= DateTime.now();
  List<dynamic> _platos = [];
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _fetchPlatosPorFecha(DateTime fecha) async {
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
        Uri.parse('${AppConstants.baseUrl}/api/dietas?fecha=${fecha.toIso8601String().split('T')[0]}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _platos = data.expand((dieta) => dieta['platos']).toList();
        });
      } else {
        setState(() {
          _errorMessage = 'Error al obtener los platos para esta fecha.';
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

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedFecha ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() {
        _selectedFecha = selectedDate;
      });
      _fetchPlatosPorFecha(selectedDate);
    }
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _fetchPlatosPorFecha(_selectedFecha); 
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: Column(
        children: [
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ListTile(
            title: Text(
              'Fecha seleccionada: ${formatDate(_selectedFecha)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _selectDate,
            ),
          ),
          const SizedBox(height: 10),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _platos.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text(
                          'No hay platos para esta fecha.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _platos.length,
                        itemBuilder: (context, index) {
                          final plato = _platos[index];
                          return Card(
                            color: const Color(0xFFF5F5F5),
                            elevation: 10,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plato['nombre']?.toUpperCase() ?? 'NOMBRE NO DISPONIBLE',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF42A5F5),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Calorías: ${plato['kcal'] ?? 'N/A'} kcal'),
                                  Text('Comida del Día: ${plato['comidaDelDia'] ?? 'N/A'}'),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Ingredientes:',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    (plato['ingredientes'] as List<dynamic>?)?.join(', ') ?? 'No especificado',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Instrucciones:',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(plato['instrucciones'] ?? 'N/A'),
                                  const SizedBox(height: 8),
                                  Text('Tiempo de Preparación: ${plato['tiempoPreparacion'] ?? 'N/A'} minutos'),
                                  if (plato['observaciones'] != null)
                                    Text('Observaciones: ${plato['observaciones']}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}

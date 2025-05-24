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
  DateTime _selectedFecha = DateTime.now();
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
      initialDate: _selectedFecha,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF42A5F5),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('📅 ${formatDate(_selectedFecha)}'),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _selectDate,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _platos.isEmpty
              ? const Center(
                  child: Text(
                    'No hay platos para esta fecha.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.builder(
                  itemCount: _platos.length,
                  itemBuilder: (context, index) {
                    final plato = _platos[index];
                    return Card(
                      margin: const EdgeInsets.all(16),
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🍽 Comida del Día: ${plato['comidaDelDia'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5)),
                            ),
                            const SizedBox(height: 12),
                            Text('🍽 Plato: ${plato['nombre']?.toUpperCase()}', style: TextStyle(fontSize: 18)),
                            Text('🔥 Calorías: ${plato['kcal'] ?? 'N/A'} kcal', style: TextStyle(fontSize: 18)),
                            Text('🕒 Tiempo de Preparación: ${plato['tiempoPreparacion'] ?? 'N/A'} min', style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 12),
                            const Text('🧂 Ingredientes:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                              (plato['ingredientes'] as List<dynamic>?)?.join(', ') ?? 'No especificado',
                              style: const TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            const Text('📋 Instrucciones:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(plato['instrucciones'] ?? 'N/A', style: TextStyle(fontSize: 16)),
                            if (plato['observaciones'] != null) ...[
                              const SizedBox(height: 12),
                              const Text('📝 Observaciones:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(plato['observaciones'], style: TextStyle(fontSize: 16)),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

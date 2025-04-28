import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';


class AssignPlatoScreen extends StatefulWidget {
  final String dietaId;

  const AssignPlatoScreen({Key? key, required this.dietaId}) : super(key: key);

  @override
  _AssignPlatoScreenState createState() => _AssignPlatoScreenState();
}

class _AssignPlatoScreenState extends State<AssignPlatoScreen> {
  List<Map<String, dynamic>> _platosDisponibles = [];
  List<String> _selectedPlatos = [];
  bool _isLoading = false;
  String _errorMessage = '';

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
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/api/platos'));
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
          _errorMessage = 'Error al cargar los platos disponibles.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión al cargar platos.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _assignPlatos() async {
    if (_selectedPlatos.isEmpty) {
      setState(() {
        _errorMessage = 'Selecciona al menos un plato para asignar.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/dietas/${widget.dietaId}/platos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'platos': _selectedPlatos}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Platos asignados con éxito.')),
        );
        Navigator.pop(context, true); // Retorna al menú anterior
      } else {
        setState(() {
          _errorMessage = 'Error al asignar los platos.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión al asignar platos.';
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
      appBar: AppBar(title: const Text('Asignar Plato a Dieta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: const TextStyle(color: Colors.red)),
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
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _assignPlatos,
                    child: const Text('Asignar Platos'),
                  ),
          ],
        ),
      ),
    );
  }
}

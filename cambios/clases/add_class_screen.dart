import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../../config.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({Key? key}) : super(key: key);

  @override
  _AddClassScreenState createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  String? _selectedClassType;
  String? _selectedDay; // Día seleccionado (Lunes, Martes, etc.)
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _maxParticipants = 0; // Valor por defecto de máximo de participantes
  bool _isLoading = false;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  final List<String> _classTypes = ['funcional', 'pilates', 'zumba'];


  final List<String> _daysOfWeek = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
  ];

  Future<void> _addClass() async {
    if (_maxParticipants <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingrese un número válido de participantes.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/admin/clases'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'nombre': _selectedClassType,
          'dia': _selectedDay,
          'horaInicio': _startTime != null ? _formatTime(_startTime!) : null,
          'horaFin': _endTime != null ? _formatTime(_endTime!) : null,
          'maximoParticipantes': _maxParticipants,
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al agregar la clase.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Clase')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedClassType,
              items: _classTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedClassType = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Tipo de Clase'),
            ),
            const SizedBox(height: 16),

            // Dropdown para seleccionar el día
            DropdownButtonFormField<String>(
              value: _selectedDay,
              items: _daysOfWeek.map((day) {
                return DropdownMenuItem(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDay = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Seleccionar Día'),
            ),
            const SizedBox(height: 16),

            // Selección de hora de inicio
            GestureDetector(
              onTap: () => _selectTime(true),
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: _startTime == null
                        ? 'Seleccionar Hora de Inicio'
                        : 'Hora de Inicio: ${_formatTime(_startTime!)}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selección de hora de fin
            GestureDetector(
              onTap: () => _selectTime(false),
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: _endTime == null
                        ? 'Seleccionar Hora de Fin'
                        : 'Hora de Fin: ${_formatTime(_endTime!)}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Campo para ingresar el máximo de participantes
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _maxParticipants = int.tryParse(value) ?? 0;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Máximo de Participantes',
              ),
            ),
            const SizedBox(height: 20),

            // Botón para guardar la clase
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _addClass,
                    child: const Text('Guardar Clase'),
                  ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';

class EditClassScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const EditClassScreen({Key? key, required this.classData}) : super(key: key);

  @override
  _EditClassScreenState createState() => _EditClassScreenState();
}

class _EditClassScreenState extends State<EditClassScreen> {
  final _nameController = TextEditingController();
  String? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _maxParticipants = 0;
  bool _isLoading = false;

  final List<String> _daysOfWeek = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    // Inicializa el formulario con los datos recibidos
    final classData = widget.classData;
    _nameController.text = classData['nombre'] ?? '';
    _selectedDay = classData['dia'];
    _startTime = _parseTime(classData['horaInicio']);
    _endTime = _parseTime(classData['horaFin']);
    _maxParticipants = classData['maximoParticipantes'] ?? 0;
  }

  // Método para convertir el tiempo del formato string a TimeOfDay
  TimeOfDay? _parseTime(String? time) {
    if (time == null || time.isEmpty) return null;
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Método para guardar los cambios en la clase
  Future<void> _saveClass() async {
    if (_maxParticipants <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingrese un número válido de participantes.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final body = json.encode({
      'nombre': _nameController.text,
      'dia': _selectedDay,
      'horaInicio': _startTime != null ? _formatTime(_startTime!) : null,
      'horaFin': _endTime != null ? _formatTime(_endTime!) : null,
      'maximoParticipantes': _maxParticipants,
    });

    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/admin/clases/${widget.classData['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar la clase.')),
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

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(bool isStartTime) async {
    final pickedTime = await showTimePicker(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Clase')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 16),
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
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _maxParticipants = int.tryParse(value) ?? 0;
                });
              },
              decoration: const InputDecoration(labelText: 'Máximo de Participantes'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveClass,
                    child: const Text('Guardar Cambios'),
                  ),
          ],
        ),
      ),
    );
  }
}

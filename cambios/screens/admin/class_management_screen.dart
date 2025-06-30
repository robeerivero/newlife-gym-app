import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<dynamic> _classes = [];
  bool _isLoading = true;
  String _errorMessage = '';
  DateTime? _selectedDate;
  String? _selectedClassType;
  String? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _maxParticipantsController = TextEditingController();
  final List<String> _classTypes = ['funcional', 'pilates', 'zumba'];
  final List<String> _daysOfWeek = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
  ];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay? _parseTime(String? time) {
    if (time == null || time.isEmpty) return null;
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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

  Future<void> _fetchClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final dateQuery = _selectedDate != null 
          ? '?fecha=${_selectedDate!.toIso8601String().split('T')[0]}'
          : '';

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/clases$dateQuery'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => _classes = json.decode(response.body));
      } else {
        setState(() => _errorMessage = 'Error cargando clases: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error de conexión: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteClass(String id) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/api/clases/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchClasses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clase eliminada correctamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar la clase')),
      );
    }
  }

  Future<void> _deleteAllClasses() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/api/clases'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchClasses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todas las clases eliminadas')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar las clases')),
      );
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
      _fetchClasses();
    }
  }

  void _showAddClassDialog() {
    _selectedClassType = null;
    _selectedDay = null;
    _startTime = null;
    _endTime = null;
    _maxParticipantsController.clear();

    _maxParticipantsController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Clase'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    _selectedClassType = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Tipo de Clase'),
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
                    _selectedDay = value!;
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
              TextField(
                controller: _maxParticipantsController,
                decoration: const InputDecoration(labelText: 'Máximo participantes'),
                keyboardType: TextInputType.number,
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
              if (_selectedClassType == null || _selectedDay == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selecciona el tipo de clase y el día')),
                );
                return;
              }

              try {
                final token = await _storage.read(key: 'jwt_token');
                final response = await http.post(
                  Uri.parse('${AppConstants.baseUrl}/api/clases'),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                  body: json.encode({
                    'nombre': _selectedClassType,
                    'dia': _selectedDay,
                    'horaInicio': _startTime != null ? _formatTime(_startTime!) : null,
                    'horaFin': _endTime != null ? _formatTime(_endTime!) : null,
                    'maximoParticipantes': _maxParticipantsController.text,
                  }),
                );

                if (response.statusCode == 201) {
                  _fetchClasses();
                  Navigator.pop(context);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al crear clase')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }


  void _showEditClassDialog(Map<String, dynamic> classData) {
    _selectedClassType = classData['nombre'];
    _selectedDay = classData['dia'];
    _startTime = _parseTime(classData['horaInicio']);
    _endTime = _parseTime(classData['horaFin']);
    _maxParticipantsController.text = classData['maximoParticipantes'].toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Clase'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  _selectedClassType = value!;
                });
              },
              decoration: const InputDecoration(labelText: 'Tipo de Clase'),
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
                    _selectedDay = value!;
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
              TextField(
                controller: _maxParticipantsController,
                decoration: const InputDecoration(labelText: 'Máximo participantes'),
                keyboardType: TextInputType.number,
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
              try {
                final token = await _storage.read(key: 'jwt_token');
                final response = await http.put(
                  Uri.parse('${AppConstants.baseUrl}/api/clases/${classData['_id']}'),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                  body: json.encode({
                    'nombre': _selectedClassType,
                    'dia': _selectedDay,
                    'horaInicio': _startTime != null ? _formatTime(_startTime!) : null,
                    'horaFin': _endTime != null ? _formatTime(_endTime!) : null,
                    'maximoParticipantes': _maxParticipantsController.text,
                  }),
                );

                if (response.statusCode == 200) {
                  _fetchClasses();
                  Navigator.pop(context);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al actualizar clase')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clases'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Filtrar por fecha',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Eliminar todas las clases'),
                  content: const Text('¿Estás seguro de eliminar todas las clases?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteAllClasses();
                      },
                      child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchClasses,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView.builder(
                  itemCount: _classes.length,
                  itemBuilder: (context, index) {
                    final classItem = _classes[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(classItem['nombre'] ?? 'Sin nombre'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Día: ${classItem['dia']}'),
                            Text('Hora: ${classItem['horaInicio']} - ${classItem['horaFin']}'),
                            Text('Cupos: ${classItem['cuposDisponibles']}/${classItem['maximoParticipantes']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditClassDialog(classItem),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar clase'),
                                    content: Text('¿Eliminar "${classItem['nombre']}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteClass(classItem['_id']);
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
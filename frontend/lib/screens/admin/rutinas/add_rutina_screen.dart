import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';
class AddRutinaScreen extends StatefulWidget {
  const AddRutinaScreen({Key? key}) : super(key: key);

  @override
  State<AddRutinaScreen> createState() => _AddRutinaScreenState();
}

class _AddRutinaScreenState extends State<AddRutinaScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _diaSemanaController = TextEditingController();

  List<dynamic> usuarios = [];
  List<dynamic> ejerciciosDisponibles = [];
  List<Map<String, dynamic>> ejerciciosSeleccionados = [];

  String? selectedUsuario;
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchUsuarios();
    fetchEjercicios();
  }

  Future<void> fetchUsuarios() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        setState(() => errorMessage = 'Token no encontrado. Por favor, inicia sesión nuevamente.');
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/usuarios'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => usuarios = json.decode(response.body));
      } else {
        setState(() => errorMessage = 'Error al cargar usuarios.');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error de conexión. Por favor, intenta nuevamente.');
    }
  }

  Future<void> fetchEjercicios() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        setState(() => errorMessage = 'Token no encontrado. Por favor, inicia sesión nuevamente.');
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/ejercicios'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => ejerciciosDisponibles = json.decode(response.body));
      } else {
        setState(() => errorMessage = 'Error al cargar ejercicios.');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error de conexión. Por favor, intenta nuevamente.');
    }
  }

  Future<void> addRutina() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        setState(() => errorMessage = 'Token no encontrado. Por favor, inicia sesión nuevamente.');
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/rutinas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'usuario': selectedUsuario,
          'diaSemana': _diaSemanaController.text.trim(),
          'ejercicios': ejerciciosSeleccionados,
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rutina agregada exitosamente.')),
        );
      } else {
        setState(() => errorMessage = 'Error al agregar la rutina.');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error de conexión. Por favor, intenta nuevamente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Rutina'), backgroundColor: Colors.blueAccent),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (errorMessage.isNotEmpty)
                      Text(errorMessage, style: const TextStyle(color: Colors.red)),
                    DropdownButtonFormField<String>(
                      value: selectedUsuario,
                      decoration: const InputDecoration(labelText: 'Seleccionar Usuario'),
                      items: usuarios.map<DropdownMenuItem<String>>((usuario) {
                        return DropdownMenuItem<String>(
                          value: usuario['_id'],
                          child: Text(usuario['nombre']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => selectedUsuario = value),
                      validator: (value) =>
                          value == null ? 'Selecciona un usuario.' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _diaSemanaController,
                      decoration: const InputDecoration(labelText: 'Día de la Semana'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Ingresa un día de la semana.' : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => SelectExerciseDialog(
                            ejerciciosDisponibles: ejerciciosDisponibles,
                            onAddExercise: (ejercicio) {
                              setState(() => ejerciciosSeleccionados.add(ejercicio));
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir Ejercicio'),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: ejerciciosSeleccionados.length,
                        itemBuilder: (context, index) {
                          final ejercicio = ejerciciosSeleccionados[index];
                          return Card(
                            child: ListTile(
                              title: Text(ejercicio['nombre'] ?? 'Ejercicio'),
                              subtitle: Text(
                                  'Series: ${ejercicio['series']} - Repeticiones: ${ejercicio['repeticiones']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() => ejerciciosSeleccionados.removeAt(index));
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: addRutina,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Agregar Rutina'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class SelectExerciseDialog extends StatelessWidget {
  final List<dynamic> ejerciciosDisponibles;
  final Function(Map<String, dynamic>) onAddExercise;

  const SelectExerciseDialog({
    Key? key,
    required this.ejerciciosDisponibles,
    required this.onAddExercise,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? selectedExercise;
    TextEditingController seriesController = TextEditingController();
    TextEditingController repsController = TextEditingController();

    return AlertDialog(
      title: const Text('Seleccionar Ejercicio'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Ejercicio'),
            items: ejerciciosDisponibles.map<DropdownMenuItem<String>>((ejercicio) {
              return DropdownMenuItem<String>(
                value: ejercicio['_id'],
                child: Text(ejercicio['nombre']),
              );
            }).toList(),
            onChanged: (value) => selectedExercise = value,
          ),
          TextFormField(
            controller: seriesController,
            decoration: const InputDecoration(labelText: 'Series'),
            keyboardType: TextInputType.number,
          ),
          TextFormField(
            controller: repsController,
            decoration: const InputDecoration(labelText: 'Repeticiones'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (selectedExercise != null) {
              onAddExercise({
                'ejercicio': selectedExercise,
                'series': int.tryParse(seriesController.text) ?? 3,
                'repeticiones': int.tryParse(repsController.text) ?? 10,
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Añadir'),
        ),
      ],
    );
  }
}

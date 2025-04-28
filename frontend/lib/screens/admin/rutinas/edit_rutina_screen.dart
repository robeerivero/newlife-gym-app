import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';
class EditRutinaScreen extends StatefulWidget {
  final String rutinaId;

  const EditRutinaScreen({required this.rutinaId, super.key});

  @override
  State<EditRutinaScreen> createState() => _EditRutinaScreenState();
}

class _EditRutinaScreenState extends State<EditRutinaScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();

  String? selectedDay;
  String? selectedUsuario;
  List<Map<String, dynamic>> selectedEjercicios = [];
  List<dynamic> ejerciciosDisponibles = [];
  List<dynamic> usuarios = [];
  bool isLoading = false;
  String errorMessage = '';

  Future<void> fetchRutinaDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        setState(() {
          errorMessage = 'Token no encontrado. Por favor, inicia sesión nuevamente.';
        });
        return;
      }

      // Obtener detalles de la rutina
      final rutinaResponse = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/rutinas/${widget.rutinaId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (rutinaResponse.statusCode == 200) {
        final rutinaData = json.decode(rutinaResponse.body);

        setState(() {
          selectedDay = rutinaData['diaSemana'];
          selectedUsuario = rutinaData['usuario']?['_id'];
          selectedEjercicios = List<Map<String, dynamic>>.from(
            rutinaData['ejercicios'].map(
              (e) => {
                'ejercicio': e['ejercicio']['_id'],
                'series': e['series'],
                'repeticiones': e['repeticiones'],
              },
            ),
          );
        });

        final ejerciciosResponse = await http.get(
          Uri.parse('${AppConstants.baseUrl}/api/ejercicios'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (ejerciciosResponse.statusCode == 200) {
          setState(() => ejerciciosDisponibles = json.decode(ejerciciosResponse.body));
        }

        final usuariosResponse = await http.get(
          Uri.parse('${AppConstants.baseUrl}/api/usuarios'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (usuariosResponse.statusCode == 200) {
          setState(() => usuarios = json.decode(usuariosResponse.body));
        }
      } else {
        setState(() {
          errorMessage = 'Error al obtener los detalles de la rutina.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error de conexión. Por favor, intenta nuevamente.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateRutina() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        setState(() {
          errorMessage = 'Token no encontrado. Por favor, inicia sesión nuevamente.';
        });
        return;
      }

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/rutinas/${widget.rutinaId}'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          'usuario': selectedUsuario,
          'diaSemana': selectedDay,
          'ejercicios': selectedEjercicios,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rutina actualizada con éxito.')),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          errorMessage = 'Error al actualizar la rutina.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error de conexión. Por favor, intenta nuevamente.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRutinaDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Rutina'), backgroundColor: Colors.blueAccent),
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
                      validator: (value) => value == null ? 'Selecciona un usuario.' : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedDay,
                      decoration: const InputDecoration(labelText: 'Día de la Semana'),
                      items: const [
                        DropdownMenuItem(value: 'Lunes', child: Text('Lunes')),
                        DropdownMenuItem(value: 'Martes', child: Text('Martes')),
                        DropdownMenuItem(value: 'Miércoles', child: Text('Miércoles')),
                        DropdownMenuItem(value: 'Jueves', child: Text('Jueves')),
                        DropdownMenuItem(value: 'Viernes', child: Text('Viernes')),
                        DropdownMenuItem(value: 'Sábado', child: Text('Sábado')),
                        DropdownMenuItem(value: 'Domingo', child: Text('Domingo')),
                      ],
                      onChanged: (value) => setState(() => selectedDay = value),
                      validator: (value) => value == null ? 'Selecciona un día.' : null,
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: ejerciciosDisponibles.length,
                        itemBuilder: (context, index) {
                          final ejercicio = ejerciciosDisponibles[index];
                          final selected = selectedEjercicios.firstWhere(
                            (e) => e['ejercicio'] == ejercicio['_id'],
                            orElse: () => {},
                          );

                          return Card(
                            child: ListTile(
                              title: Text(ejercicio['nombre']),
                              subtitle: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: 
                                          selected['series'].toString(),
                                      decoration: const InputDecoration(labelText: 'Series'),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        selected['series'] = int.tryParse(value) ?? 3;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue:  selected['repeticiones'].toString(),
                                      decoration: const InputDecoration(labelText: 'Repeticiones'),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        selected['repeticiones'] = int.tryParse(value) ?? 10;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Checkbox(
                                value: selected != null,
                                onChanged: (isChecked) {
                                  setState(() {
                                    if (isChecked ?? false) {
                                        selectedEjercicios.add({
                                          'ejercicio': ejercicio['_id'],
                                          'series': 3,
                                          'repeticiones': 10,
                                        });
                                    } else {
                                      selectedEjercicios.removeWhere(
                                          (e) => e['ejercicio'] == ejercicio['_id']);
                                    }
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: updateRutina,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Guardar Cambios'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

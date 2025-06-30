import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';
class AddUserToClassesScreen extends StatefulWidget {
  const AddUserToClassesScreen({Key? key}) : super(key: key);

  @override
  _AddUserToClassesScreenState createState() => _AddUserToClassesScreenState();
}

class _AddUserToClassesScreenState extends State<AddUserToClassesScreen> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  List<dynamic> users = [];
  String? selectedUserId;
  String? selectedDay;
  TimeOfDay? selectedTime;
  bool isLoading = false;
  String errorMessage = '';
  final List<String> days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];

  @override
  void initState() {
    super.initState();
    fetchUsers(); // Obtener usuarios al cargar la pantalla
  }

  // Método para obtener usuarios
  Future<void> fetchUsers() async {
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

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/usuarios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body);
        });
      } else {
        setState(() {
          errorMessage = json.decode(response.body)['mensaje'] ?? 'Error al obtener usuarios.';
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

  // Método para seleccionar la hora
  Future<void> selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  // Método para añadir el usuario a las clases
  Future<void> addUserToClasses() async {
    if (selectedUserId == null || selectedDay == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona todos los campos requeridos.')),
      );
      return;
    }

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

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/reservas/asignarPorDiaYHora'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'idUsuario': selectedUserId,
          'dia': selectedDay,
          'horaInicio': '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario añadido a las clases con éxito.')),
        );
        Navigator.pop(context, true); // Cerrar pantalla y notificar éxito
      } else {
        setState(() {
          errorMessage = json.decode(response.body)['mensaje'] ?? 'Error al añadir usuario a clases.';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Usuario a Clases'),
        backgroundColor: const Color(0xFF42A5F5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 10),
            // Dropdown para seleccionar usuario
            DropdownButtonFormField<String>(
              value: selectedUserId,
              items: users.map<DropdownMenuItem<String>>((user) {
                return DropdownMenuItem<String>(
                  value: user['_id'],
                  child: Text(user['nombre'] ?? 'Usuario sin nombre'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedUserId = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Seleccionar Usuario'),
            ),
            const SizedBox(height: 10),
            // Dropdown para seleccionar día
            DropdownButtonFormField<String>(
              value: selectedDay,
              items: days.map<DropdownMenuItem<String>>((day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDay = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Seleccionar Día'),
            ),
            const SizedBox(height: 10),
            // Selector para la hora
            GestureDetector(
              onTap: selectTime,
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: selectedTime == null
                        ? 'Seleccionar Hora de Inicio'
                        : 'Hora: ${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: addUserToClasses,
                    child: const Text('Añadir Usuario a Clases'),
                  ),
          ],
        ),
      ),
    );
  }
}

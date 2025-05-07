import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import '../../config.dart';
class ReserveClassScreen extends StatefulWidget {
  const ReserveClassScreen({Key? key}) : super(key: key);

  @override
  _ReserveClassScreenState createState() => _ReserveClassScreenState();
}

class _ReserveClassScreenState extends State<ReserveClassScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<dynamic> classes = [];
  List<String> userClassTypes = [];
  bool isLoading = false;
  String errorMessage = '';
  DateTime _selectedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  int _cancelaciones = -1;

  @override
  void initState() {
    super.initState();
    fetchUserClassTypes();
  }

  Future<void> fetchUserClassTypes() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        setState(() {
          errorMessage = 'No se encontró el token. Por favor, inicia sesión nuevamente.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/usuarios/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userClassTypes = List<String>.from(data['tiposDeClases'] ?? []);
          _cancelaciones = data['cancelaciones'] ?? 0;
          if (_cancelaciones == 0) {
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No puedes reservar debido a cancelaciones pendientes'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
            return;
          }
          fetchClassesForDate(_selectedDate);
        });
      } else {
        setState(() {
          errorMessage = 'Error al obtener los tipos de clase del usuario.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error de conexión.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchClassesForDate(DateTime date) async {
    setState(() {
      isLoading = true;
      classes = [];
      errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        setState(() {
          errorMessage = 'No se encontró el token. Por favor, inicia sesión nuevamente.';
        });
        return;
      }

      final dateQuery = '?fecha=${date.toIso8601String().split('T')[0]}';

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/clases/clases$dateQuery'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          classes = data
              .where((clase) => userClassTypes.contains(clase['nombre']))
              .toList();
        });
      } else {
        setState(() {
          errorMessage = 'Error al obtener clases.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error de conexión.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> reserveClass(String classId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        setState(() {
          errorMessage = 'No se encontró el token. Por favor, inicia sesión nuevamente.';
        });
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/reservas/reservar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'idClase': classId}),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clase reservada con éxito.')),
        );
        _cancelaciones--;
        if (_cancelaciones == 0) {
          if (mounted) {
            Navigator.pop(context);
          }
          return;
        }
        fetchClassesForDate(_selectedDate);
      } else {
        setState(() {
          errorMessage = 'Error al reservar la clase.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error de conexión.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reservar Clase',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 7)),
            focusedDay: _selectedDate,
            locale: 'es_ES', // Calendario en Español
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
              fetchClassesForDate(selectedDay);
            },
            selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
          ),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    )
                  : classes.isEmpty
                      ? const Expanded(
                          child: Center(
                            child: Text(
                              'No hay clases disponibles.',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: classes.length,
                            itemBuilder: (context, index) {
                              final classItem = classes[index];
                              return Card(
                                color: const Color(0xFFE3F2FD), // Fondo de tarjeta (celeste claro)
                                elevation: 5,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (classItem['nombre'] ?? 'Sin nombre')
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue),
                                      ),
                                      Text(
                                          'Fecha: ${formatDate(classItem['fecha'])}'),
                                      Text('Hora: ${classItem['horaInicio']}'),
                                      Text(
                                          'Cupos disponibles: ${classItem['cuposDisponibles']}'),
                                      Text(
                                          'Lista de espera: ${classItem['listaEspera'].length}'),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              reserveClass(classItem['_id']),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.blueAccent,
                                          ),
                                          child: const Text('Reservar'),
                                        ),
                                      ),
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

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';

class AddEjercicioScreen extends StatefulWidget {
  const AddEjercicioScreen({Key? key}) : super(key: key);

  @override
  _AddEjercicioScreenState createState() => _AddEjercicioScreenState();
}

class _AddEjercicioScreenState extends State<AddEjercicioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = FlutterSecureStorage();

  String nombre = '';
  String video = '';
  String descripcion = '';
  String dificultad = 'fácil';

  Future<void> addEjercicio() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token no encontrado. Por favor, inicia sesión nuevamente.')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/ejercicios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'nombre': nombre,
          'video': video,
          'descripcion': descripcion,
          'dificultad': dificultad,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ejercicio agregado exitosamente.')),
        );
        Navigator.pop(context); // Volver a la pantalla anterior
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${json.decode(response.body)['mensaje']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión. Por favor, intenta nuevamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Ejercicio'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
                onSaved: (value) => nombre = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'URL del Video'),
                validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
                onSaved: (value) => video = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
                onSaved: (value) => descripcion = value!,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Dificultad'),
                value: dificultad,
                items: const [
                  DropdownMenuItem(value: 'fácil', child: Text('Fácil')),
                  DropdownMenuItem(value: 'medio', child: Text('Medio')),
                  DropdownMenuItem(value: 'difícil', child: Text('Difícil')),
                ],
                onChanged: (value) => setState(() => dificultad = value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: addEjercicio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Agregar Ejercicio', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditGroupScreen extends StatefulWidget {
  final Map<String, dynamic> groupData;

  const EditGroupScreen({Key? key, required this.groupData}) : super(key: key);

  @override
  _EditGroupScreenState createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.groupData['nombre'] ?? '';
    _descriptionController.text = widget.groupData['descripcion'] ?? '';
  }

  Future<void> _editGroup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.put(
        Uri.parse('http://192.168.0.101:5000/api/admin/grupos/${widget.groupData['_id']}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nombre': _nameController.text,
          'descripcion': _descriptionController.text,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true); // Cerrar la pantalla al editar correctamente
      } else {
        final data = json.decode(response.body);
        setState(() {
          _errorMessage = data['mensaje'] ?? 'Error desconocido';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión. Por favor, intenta nuevamente.';
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
      appBar: AppBar(
        title: const Text('Editar Grupo'),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Grupo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _editGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: const Text('Guardar Cambios'),
                  ),
          ],
        ),
      ),
    );
  }
}

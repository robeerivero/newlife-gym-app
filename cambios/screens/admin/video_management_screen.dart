import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:convert';
import '../../config.dart';

class VideoManagementScreen extends StatefulWidget {
  const VideoManagementScreen({super.key});

  @override
  State<VideoManagementScreen> createState() => _VideoManagementScreenState();
}

class _VideoManagementScreenState extends State<VideoManagementScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<dynamic> _videos = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/videos'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => _videos = json.decode(response.body));
      } else {
        setState(() => _errorMessage = 'Error cargando videos');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error de conexión');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteVideo(String id) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/api/videos/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchVideos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video eliminado correctamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar el video')),
      );
    }
  }

  Future<void> _deleteAllVideos() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/api/videos'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchVideos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todos los videos eliminados')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar los videos')),
      );
    }
  }

  void _showAddVideoDialog() {
    _titleController.clear();
    _urlController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Nuevo Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'URL de YouTube'),
            ),
          ],
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
                final response = await http.post(
                  Uri.parse('${AppConstants.baseUrl}/api/videos'),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                  body: json.encode({
                    'titulo': _titleController.text,
                    'url': _urlController.text,
                  }),
                );

                if (response.statusCode == 201) {
                  _fetchVideos();
                  Navigator.pop(context);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al agregar video')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditVideoDialog(Map<String, dynamic> video) {
    _titleController.text = video['titulo'];
    _urlController.text = video['url'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'URL de YouTube'),
            ),
          ],
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
                  Uri.parse('${AppConstants.baseUrl}/api/videos/${video['_id']}'),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                  body: json.encode({
                    'titulo': _titleController.text,
                    'url': _urlController.text,
                  }),
                );

                if (response.statusCode == 200) {
                  _fetchVideos();
                  Navigator.pop(context);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al actualizar video')),
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
        title: const Text('Gestión de Videos'),
        backgroundColor: const Color(0xFF42A5F5),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Eliminar todos los videos'),
                  content: const Text('¿Estás seguro de eliminar todos los videos?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteAllVideos();
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVideoDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView.builder(
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: Image.network(
                          video['thumbnail'] ?? 
                          'https://via.placeholder.com/150',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                        title: Text(video['titulo'] ?? 'Sin título'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditVideoDialog(video),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar video'),
                                    content: Text('¿Eliminar "${video['titulo']}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteVideo(video['_id']);
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/video_management_viewmodel.dart';
import '../../models/video.dart';

class VideoManagementScreen extends StatelessWidget {
  const VideoManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VideoManagementViewModel()..fetchVideos(),
      child: const _VideoManagementView(),
    );
  }
}

class _VideoManagementView extends StatefulWidget {
  const _VideoManagementView();

  @override
  State<_VideoManagementView> createState() => _VideoManagementViewState();
}

class _VideoManagementViewState extends State<_VideoManagementView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  void _showAddOrEditDialog(BuildContext context, {Video? video}) {
    final isEdit = video != null;
    _titleController.text = video?.titulo ?? '';
    _urlController.text = video?.url ?? '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Editar Video' : 'Agregar Nuevo Video'),
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
              final titulo = _titleController.text.trim();
              final url = _urlController.text.trim();
              if (titulo.isEmpty || url.isEmpty) return;

              final vm = context.read<VideoManagementViewModel>();
              final v = Video(
                id: video?.id ?? '', // vacía para agregar, sino edita
                titulo: titulo,
                url: url,
                thumbnail: null!,
              );
              final ok = isEdit
                  ? await vm.editVideo(v)
                  : await vm.addVideo(v);

              if (ok) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoManagementViewModel>(
      builder: (context, vm, _) {
        if (vm.loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestión de Videos'),
            backgroundColor: const Color(0xFF42A5F5),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Eliminar todos los videos'),
                      content: const Text('¿Estás seguro de eliminar todos los videos?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
                      ],
                    ),
                  );
                  if (confirm == true) await vm.deleteAllVideos();
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddOrEditDialog(context),
            child: const Icon(Icons.add),
          ),
          body: vm.error != null
              ? Center(child: Text(vm.error!))
              : ListView.builder(
                  itemCount: vm.videos.length,
                  itemBuilder: (context, index) {
                    final video = vm.videos[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: video.thumbnail != null
                            ? Image.network(video.thumbnail!, width: 60, height: 60, fit: BoxFit.cover)
                            : const Icon(Icons.ondemand_video, size: 60, color: Colors.blue),
                        title: Text(video.titulo),
                        subtitle: Text(video.url),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddOrEditDialog(context, video: video),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Eliminar video'),
                                    content: Text('¿Eliminar "${video.titulo}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
                                    ],
                                  ),
                                );
                                if (confirm == true) await vm.deleteVideo(video.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

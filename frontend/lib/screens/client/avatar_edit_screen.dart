import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermoji.dart';

class AvatarEditScreen extends StatelessWidget {
  const AvatarEditScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personaliza tu Avatar')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FluttermojiCustomizer(
          autosave: false, // para que el usuario decida cuándo guardar
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("Guardar"),
        icon: const Icon(Icons.check),
        onPressed: () async {
          // Cuando el usuario pulsa guardar en AvatarEditScreen:
          final avatarJson = await FluttermojiFunctions().getFluttermojiOptions();
          Navigator.pop(context, avatarJson);

        },
      ),
    );
  }
}

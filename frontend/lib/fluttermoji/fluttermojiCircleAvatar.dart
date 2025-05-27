import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'fluttermojiController.dart';
import 'fluttermojiFunctions.dart'; // Asegúrate de que esta ruta sea correcta
class FluttermojiCircleAvatar extends StatelessWidget {
  final double radius;
  final Color? backgroundColor;
  final String? avatarJson;

  FluttermojiCircleAvatar({
    Key? key,
    this.radius = 75.0,
    this.backgroundColor,
    this.avatarJson,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si avatarJson está definido, renderiza ese avatar directamente (sin usar GetX)
    if (avatarJson != null && avatarJson!.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? Colors.transparent,
          child: SvgPicture.string(
            // Si avatarJson es un JSON Map, conviértelo a String si hace falta
            _decodeAvatarIfNeeded(avatarJson!),
            height: radius * 1.6,
            semanticsLabel: "Fluttermoji",
            placeholderBuilder: (context) => Center(
              child: CupertinoActivityIndicator(),
            ),
          ),
        );
      } catch (e) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? Colors.grey[200],
          child: Icon(Icons.person, size: radius),
        );
      }
    }

    // Si no, renderiza el avatar del usuario logueado usando GetX como antes
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.blueAccent,
      child: buildGetX(),
    );
  }

  // Helper: decodifica el avatar si viene como JSON (no SVG directamente)
  String _decodeAvatarIfNeeded(String jsonOrSvg) {
    // Si huele a JSON (tiene { y }), decodifica usando tus funciones
    if (jsonOrSvg.trim().startsWith("{")) {
      // Importa aquí tu función desde fluttermojiFunctions.dart
      // Debes importarla arriba:
      // import 'fluttermojiFunctions.dart';
      return FluttermojiFunctions().decodeFluttermojifromString(jsonOrSvg);
    }
    // Si ya es SVG directamente
    return jsonOrSvg;
  }

  GetX<FluttermojiController> buildGetX() {
    return GetX<FluttermojiController>(
        init: FluttermojiController(),
        autoRemove: false,
        builder: (snapshot) {
          if (snapshot.fluttermoji.value.isEmpty) {
            return CupertinoActivityIndicator();
          }
          return SvgPicture.string(
            snapshot.fluttermoji.value,
            height: radius * 1.6,
            semanticsLabel: "Your Fluttermoji",
            placeholderBuilder: (context) => Center(
              child: CupertinoActivityIndicator(),
            ),
          );
        });
  }
}

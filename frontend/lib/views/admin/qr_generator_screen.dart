import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRGeneratorScreen extends StatelessWidget {
  final String claseId;

  const QRGeneratorScreen({Key? key, required this.claseId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String qrData = "CLASE:$claseId";
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR para Asistencia'),
        // backgroundColor heredado del tema
      ),
      // backgroundColor heredado del tema
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Escanea este QR para registrar asistencia',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            
            // Contenedor blanco con sombra para resaltar el QR
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 260.0,
                // Estilo del QR adaptado al tema
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: theme.colorScheme.primary, // Píxeles Teal
                ),
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: theme.colorScheme.primary, // Ojos Teal
                ),
                backgroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3))
              ),
              child: SelectableText(
                'Código: $claseId',
                style: TextStyle(fontSize: 16, color: Colors.grey[700], fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
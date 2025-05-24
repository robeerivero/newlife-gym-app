import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRGeneratorScreen extends StatelessWidget {
  final String claseId;

  const QRGeneratorScreen({Key? key, required this.claseId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String qrData = "CLASE:$claseId";

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR para Asistencia'),
        backgroundColor: const Color(0xFF42A5F5),
      ),
      backgroundColor: const Color(0xFFE3F2FD),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Escanea este QR para registrar asistencia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              'Código: $claseId',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

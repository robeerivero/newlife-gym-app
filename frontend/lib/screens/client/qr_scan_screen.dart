import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../../config.dart';

class QRScanScreen extends StatefulWidget {
  final String codigoClase;

  const QRScanScreen({Key? key, required this.codigoClase}) : super(key: key);

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _alreadyScanned = false;
  String? _mensaje;

  void _onDetect(BarcodeCapture capture) {
    final Barcode barcode = capture.barcodes.first;
    final String? scannedData = barcode.rawValue;

    if (scannedData != null && !_alreadyScanned) {
      _alreadyScanned = true;
      _registrarAsistencia(scannedData);
    }
  }

  Future<void> _registrarAsistencia(String scannedData) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
        setState(() {
        _mensaje = 'Token no encontrado.';
        });
        return;
    }

    final claseId = scannedData.replaceFirst('CLASE:', '');

    try {
        final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/reservas/asistencia'),
        headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
        },
        body: json.encode({
            'codigoQR': scannedData, // <- este es el nombre que espera el backend
        }),
        );

        setState(() {
        if (response.statusCode == 200) {
            _mensaje = '✅ Asistencia registrada correctamente';
        } else {
            final data = json.decode(response.body);
            _mensaje = '❌ Error: ${data['mensaje'] ?? 'Desconocido'}';
        }
        });
    } catch (e) {
        setState(() {
        _mensaje = '❌ Error de conexión';
        });
    }
    }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: MobileScannerController(),
              onDetect: _onDetect,
            ),
          ),
          if (_mensaje != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _mensaje!,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

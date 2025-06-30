import 'package:flutter/material.dart';
import '../services/qr_service.dart';

class QRScanViewModel extends ChangeNotifier {
  final QRService _qrService = QRService();

  bool alreadyScanned = false;
  String? mensaje;

  Future<void> registrarAsistencia(String scannedData) async {
    mensaje = null;
    notifyListeners();

    final result = await _qrService.registrarAsistencia(scannedData);

    mensaje = result;
    notifyListeners();
  }

  void reset() {
    alreadyScanned = false;
    mensaje = null;
    notifyListeners();
  }
}

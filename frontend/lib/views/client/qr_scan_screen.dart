// screens/qr_scan_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../viewmodels/qr_scan_viewmodel.dart';

class QRScanScreen extends StatelessWidget {
  const QRScanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QRScanViewModel(),
      child: _QRScanBody(),
    );
  }
}

class _QRScanBody extends StatefulWidget {
  @override
  State<_QRScanBody> createState() => _QRScanBodyState();
}

class _QRScanBodyState extends State<_QRScanBody> {
  late MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BuildContext context, BarcodeCapture capture) {
    final vm = Provider.of<QRScanViewModel>(context, listen: false);
    final Barcode barcode = capture.barcodes.first;
    final String? scannedData = barcode.rawValue;

    if (scannedData != null && !vm.alreadyScanned) {
      vm.alreadyScanned = true;
      vm.registrarAsistencia(scannedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QRScanViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Escanear QR'),
            // backgroundColor eliminado, usa el tema por defecto (Primary/Teal)
            actions: [
              if (vm.mensaje != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Escanear otro QR',
                  onPressed: () {
                    vm.reset();
                    _scannerController.stop();
                    _scannerController.start();
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: IgnorePointer(
                  ignoring: vm.alreadyScanned,
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) => _onDetect(context, capture),
                  ),
                ),
              ),
              if (vm.mensaje != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    vm.mensaje!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
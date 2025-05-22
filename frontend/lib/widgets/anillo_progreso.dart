// Archivo: lib/widgets/anillo_progreso.dart

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class AnilloProgreso extends StatelessWidget {
  final double valor;
  final double meta;
  final String etiqueta;

  const AnilloProgreso({
    super.key,
    required this.valor,
    required this.meta,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    final porcentaje = (valor / meta).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: CircularPercentIndicator(
        radius: 80.0,
        lineWidth: 12.0,
        animation: true,
        percent: porcentaje,
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${(porcentaje * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(etiqueta, style: const TextStyle(fontSize: 14)),
          ],
        ),
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: Colors.green,
        backgroundColor: Colors.grey.shade300,
      ),
    );
  }
}

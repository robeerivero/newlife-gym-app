import 'package:flutter/material.dart';
import '../models/plato.dart';
import '../services/diet_service.dart';

class DietViewModel extends ChangeNotifier {
  final _dietService = DietService();

  DateTime selectedFecha = DateTime.now();
  List<Plato> platos = [];
  bool isLoading = false;
  String errorMessage = '';

  Future<void> fetchPlatosPorFecha(DateTime fecha) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    final data = await _dietService.fetchPlatosPorFecha(fecha);
    if (data != null) {
      platos = data;
    } else {
      errorMessage = 'Error al obtener los platos para esta fecha.';
    }
    isLoading = false;
    notifyListeners();
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> selectDate(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: selectedFecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      selectedFecha = selectedDate;
      await fetchPlatosPorFecha(selectedDate);
    }
  }
}

import 'package:flutter/material.dart';
import '../models/clase.dart';
import '../services/reservation_service.dart';

class ReservationManagementViewModel extends ChangeNotifier {
  final ReservationService _reservationService = ReservationService();

  List<Clase> clases = [];
  bool loading = false;
  String? error;
  DateTime? selectedDate;

  Future<void> fetchClasses({DateTime? date}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      clases = await _reservationService.fetchClassesByDate(date);
      selectedDate = date;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      clases = [];
    }
    loading = false;
    notifyListeners();
  }

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }
}

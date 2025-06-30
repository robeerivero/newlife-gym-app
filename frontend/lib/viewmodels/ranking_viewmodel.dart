import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/usuario_ranking.dart';

class RankingViewModel extends ChangeNotifier {
  final _userService = UserService();

  List<UsuarioRanking> ranking = [];
  bool loading = true;
  String? error;

  Future<void> fetchRanking() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final response = await _userService.getRanking(); // Añade este método a tu UserService
      if (response != null) {
        ranking = response;
      } else {
        error = 'No se pudo obtener el ranking.';
      }
    } catch (e) {
      error = 'Error al cargar el ranking';
    }
    loading = false;
    notifyListeners();
  }
}

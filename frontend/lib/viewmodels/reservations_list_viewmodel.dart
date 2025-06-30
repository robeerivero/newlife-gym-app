import 'package:flutter/material.dart';
import '../services/reservation_service.dart';
import '../services/user_service.dart';
import '../models/usuario.dart';
import '../models/usuario_reserva.dart';

class ReservationsListViewModel extends ChangeNotifier {
  final ReservationService _reservationService = ReservationService();
  final UserService _userService = UserService();

  List<UsuarioReserva> users = []; 
  List<Usuario> allUsuarios = [];  

  bool isLoading = false;
  String? error;

  Future<void> fetchUsers(String classId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      users = await _reservationService.fetchUsuariosDeClase(classId);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      users = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllUsuarios() async {
    try {
      final lista = await _userService.fetchAllUsuarios();
      if (lista != null) allUsuarios = lista;
    } catch (e) {
      error = 'Error al cargar usuarios disponibles';
    }
    notifyListeners();
  }

  Future<void> asignarUsuarioAClase(String classId, String userId) async {
    try {
      await _reservationService.asignarUsuarioAClase(classId, userId);
    } catch (e) {
      throw Exception('No se pudo asignar el usuario: $e');
    }
  }

  Future<void> desasignarUsuarioDeClase(String classId, String userId) async {
    try {
      await _reservationService.desasignarUsuarioDeClase(classId, userId);
    } catch (e) {
      throw Exception('No se pudo desasignar el usuario: $e');
    }
  }

  List<Usuario> get usuariosDisponibles {
    final idsAsignados = users.map((u) => u.id).toSet();
    return allUsuarios.where((u) => !idsAsignados.contains(u.id)).toList();
  }
}

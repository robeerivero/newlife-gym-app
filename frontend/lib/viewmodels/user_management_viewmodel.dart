// viewmodels/admin/user_management_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../../models/usuario.dart';
import '../../services/user_service.dart';

class UserManagementViewModel extends ChangeNotifier {
  final UserService _userService = UserService();

  List<Usuario> _usuarios = []; // Lista interna
  List<Usuario> get usuarios {
    // FILTRO LOCAL: Si seleccionamos "Solicitudes Pendientes", filtramos la lista en memoria
    if (_grupoSeleccionado == 'Solicitudes Pendientes') {
      return _usuarios.where((u) => u.solicitudPremium != null).toList();
    }
    return _usuarios;
  }

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  // Estado de Grupos
  // Añadimos la opción estática "Solicitudes Pendientes"
  List<String> _gruposDisponibles = ['Todos', 'Solicitudes Pendientes', 'Sin Grupo'];
  List<String> get gruposDisponibles => _gruposDisponibles;
  
  String _grupoSeleccionado = 'Todos';
  String get grupoSeleccionado => _grupoSeleccionado;

  UserManagementViewModel() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([
          fetchGrupos(notify: false), 
          fetchUsuarios(notify: false), 
      ]);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      print("[ViewModel] Error en loadInitialData: $_error");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchGrupos({bool notify = true}) async {
     List<String> nuevosGrupos = ['Todos', 'Solicitudes Pendientes', 'Sin Grupo']; 
     try {
       final gruposFromService = await _userService.fetchGrupos(); 
       final Set<String> uniqueGroups = {'Todos', 'Solicitudes Pendientes', 'Sin Grupo', ...gruposFromService};
       
       nuevosGrupos = uniqueGroups.toList()..sort((a,b) {
           // Orden personalizado para que las opciones fijas salgan primero
           if (a == 'Todos') return -1; if (b == 'Todos') return 1;
           if (a == 'Solicitudes Pendientes') return -1; if (b == 'Solicitudes Pendientes') return 1;
           if (a == 'Sin Grupo') return -1; if (b == 'Sin Grupo') return 1;
           return a.compareTo(b);
       });

     } catch (e) {
       print("[ViewModel] Error fetching groups: $e");
       _error = e.toString().replaceFirst('Exception: ', ''); 
     } finally {
        if (!listEquals(_gruposDisponibles, nuevosGrupos)) {
            _gruposDisponibles = nuevosGrupos;
            if (!_gruposDisponibles.contains(_grupoSeleccionado)) {
                _grupoSeleccionado = 'Todos'; 
            }
            if (notify) notifyListeners(); 
        } else if (notify && _error != null) {
             notifyListeners(); 
        }
     }
  }

  Future<void> fetchUsuarios({bool notify = true}) async {
    bool startedLoadingLocally = false;
    if (!_loading) { _loading = true; startedLoadingLocally = true; if (notify) notifyListeners(); }
    _error = null;

    try {
      // Si el filtro es "Solicitudes Pendientes", traemos "Todos" del backend y filtramos en el getter
      String filtroParaBackend = _grupoSeleccionado == 'Solicitudes Pendientes' ? 'Todos' : _grupoSeleccionado;
      
      final fetchedUsers = await _userService.fetchAllUsuarios(nombreGrupo: filtroParaBackend);
      
      // Comprobación de cambios
      if (!listEquals(_usuarios, fetchedUsers)) {
          _usuarios = fetchedUsers ?? [];
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
       if (_usuarios.isNotEmpty) {
           _usuarios = []; 
       }
    } finally {
      if (startedLoadingLocally) _loading = false;
      if (notify) notifyListeners();
    }
  }

  void setGrupoSeleccionado(String? grupo) {
    if (grupo == null || _grupoSeleccionado == grupo) return;
    _grupoSeleccionado = grupo;
    notifyListeners(); 
    fetchUsuarios(); 
  }

  // --- ADD USUARIO ---
  Future<bool> addUsuario({
    required String nombre, required String correo, required String contrasena,
    required String rol, required List<String> tiposDeClases, String? nombreGrupo,
  }) async {
    _loading = true; _error = null; notifyListeners();
    bool success = false;
    try {
      success = await _userService.addUsuario(
        nombre: nombre, correo: correo, contrasena: contrasena, 
        rol: rol, tiposDeClases: tiposDeClases, nombreGrupo: nombreGrupo,
      );
      if (success) await loadInitialData(); 
      else _error = "El servidor indicó un error al crear usuario.";
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', ''); 
    } finally {
      _loading = false; notifyListeners();
    }
    return success; 
  }

  // --- UPDATE USUARIO ---
   Future<bool> updateUsuario({
    required String id, required String nombre, required String correo,
    required String rol, String? nuevaContrasena, required bool esPremium,
    required bool incluyePlanDieta, required bool incluyePlanEntrenamiento,
    required bool haPagado, required String? nombreGrupo,
  }) async {
     _loading = true; _error = null; notifyListeners();
     bool success = false;
     Map<String, dynamic> datosActualizar = {
        'nombre': nombre, 'correo': correo, 'rol': rol, 'esPremium': esPremium,
        'incluyePlanDieta': incluyePlanDieta, 'incluyePlanEntrenamiento': incluyePlanEntrenamiento,
        'haPagado': haPagado, 'nombreGrupo': nombreGrupo,
        if (nuevaContrasena != null && nuevaContrasena.isNotEmpty) 'nuevaContrasena': nuevaContrasena,
      };
     try {
       success = await _userService.updateUsuario(id, datosActualizar);
       if (success) {
          await fetchUsuarios(); 
          await fetchGrupos(); 
       } else { _error = "El servidor rechazó la actualización."; }
     } catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
     finally { _loading = false; notifyListeners(); }
     return success;
  }

  // --- CAMBIAR CONTRASEÑA ---
  Future<bool> cambiarContrasena(String usuarioId, String nuevaContrasena) async {
    _loading = true; _error = null; notifyListeners();
    bool success = false;
    try {
      success = await _userService.cambiarContrasenaAdmin(usuarioId, nuevaContrasena);
      if (!success) _error = 'El servicio falló al cambiar la contraseña.';
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false; notifyListeners();
    }
    return success;
  }
 
  // --- DELETE USUARIO ---
  Future<bool> deleteUsuario(String id) async {
    _loading = true; _error = null; notifyListeners();
    bool success = false;
    try {
      success = await _userService.deleteUsuario(id);
      if (success) {
         _usuarios.removeWhere((u) => u.id == id);
         await fetchGrupos(); 
      } else { 
        _error = 'Error: El servicio reportó fallo.'; 
      }
    } catch (e) { 
      _error = e.toString().replaceFirst('Exception: ', ''); 
    }
    finally { _loading = false; notifyListeners(); }
    return success;
  }

  // --- 👇 NUEVO: LIMPIAR SOLICITUD ---
  Future<bool> limpiarSolicitud(String id) async {
    _loading = true; _error = null; notifyListeners();
    bool success = false;
    try {
      // Llamamos a la función que creaste en el paso 3
      success = await _userService.limpiarSolicitudPremium(id);
      if (success) {
        // Recargamos la lista para que desaparezca el icono/estado
        await fetchUsuarios(notify: false);
      } else {
        _error = "No se pudo limpiar la solicitud.";
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false; notifyListeners();
    }
    return success;
  }
}
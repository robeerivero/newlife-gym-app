// viewmodels/admin/user_management_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../../models/usuario.dart';
import '../../services/user_service.dart';

class UserManagementViewModel extends ChangeNotifier {
  final UserService _userService = UserService();

  List<Usuario> _usuarios = []; // Lista interna
  List<Usuario> get usuarios => _usuarios; // Getter público

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  // Estado de Grupos
  List<String> _gruposDisponibles = ['Todos', 'Sin Grupo'];
  List<String> get gruposDisponibles => _gruposDisponibles;
  String _grupoSeleccionado = 'Todos';
  String get grupoSeleccionado => _grupoSeleccionado;

  UserManagementViewModel() {
    // Carga inicial
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    // Notifica el inicio de la carga global AHORA
    notifyListeners();
    try {
      // Ejecuta en paralelo para más rapidez (opcional)
      await Future.wait([
          fetchGrupos(notify: false), // Carga grupos sin notificar aún
          fetchUsuarios(notify: false), // Carga usuarios sin notificar aún
      ]);
      // Si ambas tuvieron éxito (o una falló pero la otra no), _error será null o tendrá un mensaje
    } catch (e) {
       // Captura cualquier error de fetchGrupos o fetchUsuarios si lanzan excepciones
      _error = e.toString().replaceFirst('Exception: ', '');
      print("[ViewModel] Error en loadInitialData: $_error");
    } finally {
      _loading = false;
      // Notifica el final de la carga global, con los datos actualizados o el error
      notifyListeners();
    }
  }

  Future<void> fetchGrupos({bool notify = true}) async {
     // No usa loading individual
     List<String> nuevosGrupos = ['Todos', 'Sin Grupo']; // Lista temporal
     try {
       print("[ViewModel] Fetching groups...");
       final gruposFromService = await _userService.fetchGrupos(); // Devuelve lista o lanza excepción
       // Combina y ordena
       final Set<String> uniqueGroups = {'Todos', 'Sin Grupo', ...gruposFromService};
       nuevosGrupos = uniqueGroups.toList()..sort((a,b) {
           if (a == 'Todos') return -1; if (b == 'Todos') return 1;
           if (a == 'Sin Grupo') return -1; if (b == 'Sin Grupo') return 1;
           return a.compareTo(b);
       });
       print("[ViewModel] Groups fetched successfully: ${nuevosGrupos.join(', ')}");

     } catch (e) {
       print("[ViewModel] Error fetching groups: $e");
       _error = e.toString().replaceFirst('Exception: ', ''); // Guarda el error
       // Mantiene 'Todos' y 'Sin Grupo' en caso de error
       nuevosGrupos = ['Todos', 'Sin Grupo'];
     } finally {
        // --- ¡CORRECCIÓN CLAVE! ---
        // Compara si la lista realmente cambió antes de actualizar y notificar
        if (!listEquals(_gruposDisponibles, nuevosGrupos)) {
            _gruposDisponibles = nuevosGrupos;
            // Asegura que el grupo seleccionado siga siendo válido
            if (!_gruposDisponibles.contains(_grupoSeleccionado)) {
                _grupoSeleccionado = 'Todos'; // Resetea a 'Todos' si el grupo actual ya no existe
            }
            if (notify) notifyListeners(); // Notifica SOLO si la lista cambió y se pidió
        } else if (notify && _error != null) {
             notifyListeners(); // Notifica si hubo error aunque la lista no cambie
        }
        // --- FIN CORRECCIÓN ---
     }
  }

  Future<void> fetchUsuarios({bool notify = true}) async {
    // Manejo de loading local si no está en carga global
    bool startedLoadingLocally = false;
    if (!_loading) { _loading = true; startedLoadingLocally = true; if (notify) notifyListeners(); }
    _error = null;

    try {
      print("[ViewModel] Fetching users for group: $_grupoSeleccionado");
      // Llama al servicio que devuelve lista o lanza excepción
      final fetchedUsers = await _userService.fetchAllUsuarios(nombreGrupo: _grupoSeleccionado);
      // Compara si la lista cambió antes de notificar (opcional, bueno para performance)
       if (!listEquals(_usuarios, fetchedUsers)) {
          _usuarios = fetchedUsers ?? [];
       }
      print("[ViewModel] Users fetched: ${_usuarios.length}");
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      // Compara si la lista cambió antes de notificar (si ya estaba vacía, no notifica)
       if (_usuarios.isNotEmpty) {
           _usuarios = []; // Limpia en error solo si no estaba vacía
       }
      print("[ViewModel] Error fetching users: $_error");
    } finally {
      if (startedLoadingLocally) _loading = false;
      // Notifica siempre si se pidió, para reflejar datos o error
      if (notify) notifyListeners();
    }
  }

  // Cambiar grupo seleccionado y recargar
  void setGrupoSeleccionado(String? grupo) {
    if (grupo == null || _grupoSeleccionado == grupo) return;
    _grupoSeleccionado = grupo;
    print("[ViewModel] Group selected: $_grupoSeleccionado"); // Log
    notifyListeners(); // Actualiza el dropdown visualmente
    fetchUsuarios(); // Recarga la lista de usuarios con el nuevo filtro
  }

  // --- ADD USUARIO (Manejo de Error Mejorado) ---
  Future<bool> addUsuario({
    required String nombre, required String correo, required String contrasena,
    required String rol, required List<String> tiposDeClases, String? nombreGrupo,
  }) async {
    _loading = true; // Indica carga
    _error = null; // Limpia error previo
    notifyListeners();
    bool success = false;
    try {
      success = await _userService.addUsuario(
        nombre: nombre, correo: correo, contrasena: contrasena, // Sin hashear
        rol: rol, tiposDeClases: tiposDeClases, nombreGrupo: nombreGrupo,
      );
      if (success) {
         // Refresca todo si tiene éxito
         await loadInitialData(); // Esto recarga grupos y usuarios
      } else {
         // El servicio debería lanzar excepción si falla, pero por si acaso
         _error = "El servidor indicó un error al crear usuario.";
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', ''); // Captura error del servicio
      print("[ViewModel] Error adding user: $_error"); // Log
    } finally {
      _loading = false; // Termina carga
      notifyListeners();
    }
    return success; // Devuelve si la operación (llamada al servicio) fue exitosa
  }

  // --- UPDATE USUARIO (Manejo de Error Mejorado) ---
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
         // No recargamos todo aquí, solo actualizamos el usuario localmente (más eficiente)
         // O simplemente llamamos a fetchUsuarios() si preferimos recargar la lista actual
          await fetchUsuarios(); // Recarga la lista actual
          await fetchGrupos(); // Recarga grupos por si cambió/añadió uno
       } else { _error = "El servidor rechazó la actualización."; }
     } catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
     finally { _loading = false; notifyListeners(); }
     return success;
  }

  // --- DELETE USUARIO (Manejo de Error Mejorado) ---
  // --- DELETE USUARIO (Manejo de Error Mejorado) ---
  Future<bool> deleteUsuario(String id) async {
    _loading = true; _error = null; notifyListeners();
    bool success = false;

    // --- LOG AÑADIDO ---
    print("[VM] 2. deleteUsuario VM iniciado para ID: $id");
    // -------------------

    try {
      success = await _userService.deleteUsuario(id);
      
      // --- LOG AÑADIDO ---
      print("[VM] 3. Servicio respondió. Success: $success");
      // -------------------

      if (success) {
         _usuarios.removeWhere((u) => u.id == id);
         await fetchGrupos(); 
         
         // --- LOG AÑADIDO ---
         print("[VM] 4. Usuario eliminado localmente y grupos recargados.");
         // -------------------
         
      } else { 
        _error = 'Error: El servicio reportó fallo (success=false).'; 
        
        // --- LOG AÑADIDO ---
        print("[VM] 4. El servicio devolvió success=false.");
        // -------------------
      }
    } catch (e) { 
      _error = e.toString().replaceFirst('Exception: ', ''); 
      
      // --- LOG AÑADIDO ---
      print("[VM] 4. ¡ERROR! Capturado en VM: $_error");
      // -------------------
    }
    finally { _loading = false; notifyListeners(); }
    return success;
  }
}
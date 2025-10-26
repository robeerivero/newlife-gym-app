// viewmodels/plan_review_viewmodel.dart
import 'package:flutter/material.dart';
import '../models/plan_entrenamiento.dart';
import '../models/plan_dieta.dart';
import '../services/ia_entrenamiento_service.dart';
import '../services/ia_dieta_service.dart';

class PlanReviewViewModel extends ChangeNotifier {
  final IAEntrenamientoService _entrenamientoService = IAEntrenamientoService();
  final IADietaService _dietaService = IADietaService();

  List<PlanEntrenamiento> planesEntrenamientoPendientes = [];
  List<PlanDieta> planesDietaPendientes = [];
  bool isLoading = false;
  String? error;

  PlanReviewViewModel() {
    fetchPendientes();
  }

  /// Carga ambos tipos de planes pendientes.
  Future<void> fetchPendientes() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      // Carga en paralelo para más eficiencia
      final results = await Future.wait([
        _entrenamientoService.obtenerPlanesPendientes(),
        _dietaService.obtenerPlanesPendientes(),
      ]);
      planesEntrenamientoPendientes = results[0] as List<PlanEntrenamiento>;
      planesDietaPendientes = results[1] as List<PlanDieta>;
    } catch (e) {
      error = "Error al cargar planes pendientes: $e";
      planesEntrenamientoPendientes = [];
      planesDietaPendientes = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- ¡MÉTODO MODIFICADO! ---
  /// Aprueba un plan de entrenamiento (flujo manual).
  Future<bool> aprobarPlanEntrenamientoManual({
    required String idPlan,
    required String jsonString, // Recibe el JSON como string
    required List<String> diasAsignados,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    bool success = false;
    try {
      // Llama al nuevo método del servicio
      success = await _entrenamientoService.aprobarPlanManual(idPlan, jsonString, diasAsignados);
      if (success) {
        planesEntrenamientoPendientes.removeWhere((p) => p.id == idPlan);
      } else {
        // El servicio ahora lanza excepciones, el error vendrá del catch
        // error = "Error al aprobar el plan de entrenamiento.";
      }
    } catch (e) {
      error = "Error al aprobar: ${e.toString()}"; // Captura el mensaje de la excepción
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return success;
  }


  // --- ¡MÉTODO MODIFICADO! ---
  /// Aprueba un plan de dieta (flujo manual).
  Future<bool> aprobarPlanDietaManual({
    required String idPlan,
    required String jsonString, // Recibe el JSON como string
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    bool success = false;
    try {
       // Llama al nuevo método del servicio
      success = await _dietaService.aprobarPlanManual(idPlan, jsonString);
      if (success) {
        planesDietaPendientes.removeWhere((p) => p.id == idPlan);
      } else {
        // error = "Error al aprobar el plan de dieta.";
      }
    } catch (e) {
      error = "Error al aprobar: ${e.toString()}";
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return success;
  }

   // --- ELIMINADO (O COMENTADO) ---
   // Ya no hay regeneración automática
   /*
   Future<bool> regenerarIA(String idPlan, String tipo) async {
     // ...
   }
   */
}
// viewmodels/plan_review_viewmodel.dart
// ¡ACTUALIZADO! Carga aprobados (Dieta y Entreno) y añade lógica de Entreno.

import 'package:flutter/material.dart';
import '../models/plan_entrenamiento.dart';
import '../models/plan_dieta.dart';
import '../services/ia_entrenamiento_service.dart';
import '../services/ia_dieta_service.dart';
import 'dart:async'; // Para el Debouncer

class PlanReviewViewModel extends ChangeNotifier {
  final IAEntrenamientoService _entrenamientoService = IAEntrenamientoService();
  final IADietaService _dietaService = IADietaService();

  // --- Listas maestras (privadas) ---
  List<PlanEntrenamiento> _allPlanesEntrenamientoPendientes = [];
  List<PlanDieta> _allPlanesDietaPendientes = [];
  List<PlanEntrenamiento> _allPlanesEntrenamientoAprobados = [];
  List<PlanDieta> _allPlanesDietaAprobados = [];

  // --- Listas filtradas (públicas) ---
  List<PlanEntrenamiento> planesEntrenamientoPendientes = [];
  List<PlanDieta> planesDietaPendientes = [];
  List<PlanEntrenamiento> planesEntrenamientoAprobados = [];
  List<PlanDieta> planesDietaAprobados = [];

  bool isLoading = false;
  String? error;
  String _searchTerm = '';

  PlanReviewViewModel() {
    fetchPlans();
  }

  /// Carga TODOS los tipos de planes (pendientes y aprobados).
  Future<void> fetchPlans() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        // Pendientes
        _entrenamientoService.obtenerPlanesPendientes(),
        _dietaService.obtenerPlanesPendientes(),
        
        // ¡NUEVO! Aprobados
        _entrenamientoService.obtenerPlanesAprobados(), 
        _dietaService.obtenerPlanesAprobados(),
      ]);
      
      // Asignamos Pendientes
      _allPlanesEntrenamientoPendientes = results[0] as List<PlanEntrenamiento>;
      _allPlanesDietaPendientes = results[1] as List<PlanDieta>;
      
      // ¡NUEVO! Asignamos Aprobados
      _allPlanesEntrenamientoAprobados = results[2] as List<PlanEntrenamiento>; 
      _allPlanesDietaAprobados = results[3] as List<PlanDieta>;

    } catch (e) {
      error = "Error al cargar planes: $e";
      _allPlanesEntrenamientoPendientes = [];
      _allPlanesDietaPendientes = [];
      _allPlanesEntrenamientoAprobados = [];
      _allPlanesDietaAprobados = [];
    } finally {
      _applyFilter();
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Lógica de Búsqueda ---
  
  void search(String term) {
    _searchTerm = term.toLowerCase();
    _applyFilter();
  }
  
  void _applyFilter() {
    planesDietaPendientes = _filterList(_allPlanesDietaPendientes, _searchTerm);
    planesDietaAprobados = _filterList(_allPlanesDietaAprobados, _searchTerm);
    planesEntrenamientoPendientes = _filterList(_allPlanesEntrenamientoPendientes, _searchTerm);
    planesEntrenamientoAprobados = _filterList(_allPlanesEntrenamientoAprobados, _searchTerm);
    notifyListeners();
  }

  List<T> _filterList<T>(List<T> list, String term) {
    if (term.isEmpty) {
      return List.from(list);
    }
    return list.where((plan) {
      String nombre = '';
      String? grupo = '';
      if (plan is PlanDieta) {
        nombre = plan.usuarioNombre.toLowerCase();
        grupo = plan.usuarioGrupo?.toLowerCase();
      } else if (plan is PlanEntrenamiento) {
        nombre = plan.usuarioNombre.toLowerCase();
        grupo = plan.usuarioGrupo?.toLowerCase();
      }
      return nombre.contains(term) || (grupo != null && grupo.contains(term));
    }).toList();
  }

  // --- Métodos de Acción (Entrenamiento) ---

  // ¡NUEVO!
  Future<Map<String, dynamic>> getPromptEntrenamiento(String idPlan) async {
     return await _entrenamientoService.obtenerPromptParaRevision(idPlan);
  }

  // ¡MODIFICADO!
  Future<bool> aprobarPlanEntrenamientoManual({
    required String idPlan,
    required String jsonString, // <-- Solo el jsonString
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    bool success = false;
    try {
      // Llama al método del servicio modificado
      success = await _entrenamientoService.aprobarPlanManual(idPlan, jsonString);
    } catch (e) {
      error = "Error al aprobar: ${e.toString()}";
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return success;
  }
  
  // ¡NUEVO!
  Future<bool> eliminarPlanEntrenamiento(String idPlan) async {
    isLoading = true;
    error = null;
    notifyListeners();
    bool success = false;
    try {
      success = await _entrenamientoService.eliminarPlan(idPlan);
    } catch (e) {
      error = "Error al eliminar: ${e.toString()}";
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return success;
  }

  // --- Métodos de Acción (Dieta) ---
  // (Estos ya estaban bien en tu archivo)

  Future<Map<String, dynamic>> getPromptDieta(String idPlan) async {
     return await _dietaService.obtenerPromptParaRevision(idPlan);
  }
  
  Future<bool> aprobarPlanDietaManual({
    required String idPlan,
    required String jsonString,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    bool success = false;
    try {
      success = await _dietaService.aprobarPlanManual(idPlan, jsonString);
    } catch (e) {
      error = "Error al aprobar: ${e.toString()}";
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> eliminarPlanDieta(String idPlan) async {
    isLoading = true;
    error = null;
    notifyListeners();
    bool success = false;
    try {
      success = await _dietaService.eliminarPlan(idPlan);
    } catch (e) {
      error = "Error al eliminar: ${e.toString()}";
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return success;
  }
}
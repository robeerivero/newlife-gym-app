// screens/admin/plan_review_list_screen.dart
// ¡ACTUALIZADO! Con buscador y listas de Aprobados.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Para el Debouncer
import '../../viewmodels/plan_review_viewmodel.dart';
import '../../models/plan_entrenamiento.dart';
import '../../models/plan_dieta.dart';
import 'plan_entrenamiento_edit_screen.dart'; // (Asumo que existe)
import 'plan_dieta_edit_screen.dart';

class PlanReviewListScreen extends StatefulWidget {
  const PlanReviewListScreen({super.key});

  @override
  State<PlanReviewListScreen> createState() => _PlanReviewListScreenState();
}

class _PlanReviewListScreenState extends State<PlanReviewListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debouncer;
  late PlanReviewViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Obtenemos el VM (sin escuchar) para añadir el listener
    _viewModel = Provider.of<PlanReviewViewModel>(context, listen: false);
    
    _searchController.addListener(() {
      if (_debouncer?.isActive ?? false) _debouncer!.cancel();
      _debouncer = Timer(const Duration(milliseconds: 500), () {
        _viewModel.search(_searchController.text);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer?.cancel();
    super.dispose();
  }

  /// Navega a la pantalla de edición de DIETA
  void _navigateToDietaDetail(BuildContext context, PlanReviewViewModel vm, PlanDieta plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanDietaEditScreen(
          planInicial: plan,
          viewModel: vm,
        ),
      ),
    ).then((didChange) {
      if (didChange == true) {
        vm.fetchPlans(); // Refresca todas las listas
      }
    });
  }
  
  /// Navega a la pantalla de edición de ENTRENAMIENTO
  void _navigateToEntrenamientoDetail(BuildContext context, PlanReviewViewModel vm, PlanEntrenamiento plan) {
     Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanEntrenamientoEditScreen(
          planInicial: plan,
          viewModel: vm, 
        ),
      ),
    ).then((didChange) {
      if (didChange == true) {
        vm.fetchPlans(); // Refresca todas las listas
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final Color appBarColor = const Color(0xFF1E88E5);
    final Color scaffoldBgColor = const Color(0xFFE3F2FD);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: scaffoldBgColor,
        appBar: AppBar(
          title: const Text('Gestión de Planes Premium', style: TextStyle(color: Colors.white)),
          backgroundColor: appBarColor,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Entrenamiento', icon: Icon(Icons.fitness_center)),
              Tab(text: 'Dieta', icon: Icon(Icons.restaurant_menu)),
            ],
          ),
        ),
        body: Consumer<PlanReviewViewModel>(
          builder: (context, vm, child) {
            
            return Column(
              children: [
                // --- Barra de Búsqueda ---
                _buildSearchBar(context, vm),
                
                // --- Contenido ---
                Expanded(
                  child: vm.isLoading && vm.planesDietaPendientes.isEmpty && vm.planesDietaAprobados.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : vm.error != null
                          ? Center(child: Text('Error: ${vm.error}'))
                          : TabBarView(
                              children: [
                                // --- Pestaña Entrenamiento ---
                                _buildPlanList(
                                  context: context,
                                  vm: vm,
                                  pendientes: vm.planesEntrenamientoPendientes,
                                  aprobados: vm.planesEntrenamientoAprobados,
                                  onTap: (plan) => _navigateToEntrenamientoDetail(context, vm, plan as PlanEntrenamiento),
                                  searchTerm: _searchController.text,
                                ),
                                
                                // --- Pestaña Dieta ---
                                _buildPlanList(
                                  context: context,
                                  vm: vm,
                                  pendientes: vm.planesDietaPendientes,
                                  aprobados: vm.planesDietaAprobados,
                                  onTap: (plan) => _navigateToDietaDetail(context, vm, plan as PlanDieta),
                                  searchTerm: _searchController.text,
                                ),
                              ],
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Widget de Búsqueda
  Widget _buildSearchBar(BuildContext context, PlanReviewViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o grupo...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    vm.search('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// Widget genérico para construir las listas de planes
  Widget _buildPlanList({
    required BuildContext context,
    required PlanReviewViewModel vm,
    required List<dynamic> pendientes,
    required List<dynamic> aprobados,
    required Function(dynamic) onTap,
    required String searchTerm,
  }) {
    if (pendientes.isEmpty && aprobados.isEmpty) {
      return Center(
        child: Text(
          searchTerm.isEmpty 
            ? 'No hay planes para mostrar.' 
            : 'No se encontraron planes.', 
          style: const TextStyle(fontSize: 16, color: Colors.grey)
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SECCIÓN PENDIENTES ---
          _buildSectionTitle('Pendientes de Revisión', pendientes.length),
          if (pendientes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No hay planes pendientes.', style: TextStyle(color: Colors.grey))),
            )
          else
            ListView.builder(
              itemCount: pendientes.length,
              shrinkWrap: true, 
              physics: const NeverScrollableScrollPhysics(), 
              itemBuilder: (context, index) {
                return _buildPlanItem(
                  plan: pendientes[index],
                  onTap: onTap,
                );
              },
            ),

          const SizedBox(height: 20),
          const Divider(),

          // --- SECCIÓN APROBADOS ---
          _buildSectionTitle('Planes Aprobados (Editar)', aprobados.length),
           if (aprobados.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No hay planes aprobados.', style: TextStyle(color: Colors.grey))),
            )
          else
            ListView.builder(
              itemCount: aprobados.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildPlanItem(
                  plan: aprobados[index],
                  onTap: onTap,
                  isApproved: true, 
                );
              },
            ),
        ],
      ),
    );
  }
  
  /// Título de sección
  Widget _buildSectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), 
      child: Text(
        '$title ($count)',
        style: const TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.bold, 
          color: Colors.indigo
        ),
      ),
    );
  }

  /// Widget para un item de plan (Dieta o Entrenamiento)
  Widget _buildPlanItem({
    required dynamic plan,
    required Function(dynamic) onTap,
    bool isApproved = false,
  }) {
    String nombreUsuario = '';
    String? nombreGrupo = '';
    String tipoPlan = '';
    String mes = '';
    IconData icon = Icons.help_outline; // Icono por defecto

    if (plan is PlanDieta) {
      nombreUsuario = plan.usuarioNombre;
      nombreGrupo = plan.usuarioGrupo;
      mes = plan.mes;
      tipoPlan = 'Dieta';
      icon = Icons.restaurant_menu;
    } else if (plan is PlanEntrenamiento) {
      nombreUsuario = plan.usuarioNombre;
      nombreGrupo = plan.usuarioGrupo;
      mes = plan.mes;
      tipoPlan = 'Entrenamiento';
      icon = Icons.fitness_center;
    }

    final String textoGrupo = (nombreGrupo != null && nombreGrupo.isNotEmpty)
        ? ' ($nombreGrupo)'
        : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(
          icon,
          color: isApproved ? Colors.green[700] : Colors.blue[700],
        ),
        title: Text(
          '$nombreUsuario$textoGrupo',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Plan $tipoPlan - $mes',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
        ),
        trailing: Icon(
          isApproved ? Icons.edit_note : Icons.chevron_right, 
          color: Colors.grey[600]
        ),
        onTap: () => onTap(plan),
      ),
    );
  }
}
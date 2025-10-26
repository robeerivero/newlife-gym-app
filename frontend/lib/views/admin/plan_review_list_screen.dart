// screens/admin/plan_review_list_screen.dart
// ¡ACTUALIZADO CON COLORES RESTAURADOS Y CORRECCIÓN DE PROVIDER!
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/plan_review_viewmodel.dart';
import '../../models/plan_entrenamiento.dart';
import '../../models/plan_dieta.dart';
import 'plan_entrenamiento_edit_screen.dart';
import 'plan_dieta_edit_screen.dart';

class PlanReviewListScreen extends StatelessWidget {
  const PlanReviewListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- COLORES RESTAURADOS ---
    final Color appBarColor = const Color(0xFF1E88E5);
    final Color scaffoldBgColor = const Color(0xFFE3F2FD);
    // ---------------------------

    return ChangeNotifierProvider(
      create: (_) => PlanReviewViewModel(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: scaffoldBgColor, // <-- Aplicado
          appBar: AppBar(
            title: const Text('Planes Premium Pendientes', style: TextStyle(color: Colors.white)),
            backgroundColor: appBarColor, // <-- Aplicado
            iconTheme: const IconThemeData(color: Colors.white), // <-- Aplicado (aunque ya estaba)
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(icon: Icon(Icons.fitness_center), text: 'Entrenamiento'),
                Tab(icon: Icon(Icons.restaurant_menu), text: 'Dieta'),
              ],
            ),
            actions: [
              Consumer<PlanReviewViewModel>(
                builder: (context, vm, _) => IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white), // <-- Aplicado (aunque ya estaba)
                  tooltip: 'Recargar',
                  onPressed: vm.isLoading ? null : vm.fetchPendientes,
                ),
              ),
            ],
          ),
          body: Consumer<PlanReviewViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading && vm.planesDietaPendientes.isEmpty && vm.planesEntrenamientoPendientes.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (vm.error != null) {
                return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${vm.error}', style: const TextStyle(color: Colors.red))));
              }

              return TabBarView(
                children: [
                  // Tab Entrenamiento (con corrección Provider)
                  _buildPlanList<PlanEntrenamiento>(
                    context: context,
                    planes: vm.planesEntrenamientoPendientes,
                    onTap: (plan) async {
                      final vmInstance = Provider.of<PlanReviewViewModel>(context, listen: false);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlanEntrenamientoEditScreen(
                            planInicial: plan,
                            viewModel: vmInstance, // Pasa la instancia
                          ),
                        ),
                      );
                      if (result == true) vmInstance.fetchPendientes();
                    },
                  ),
                  // Tab Dieta (con corrección Provider)
                  _buildPlanList<PlanDieta>(
                    context: context,
                    planes: vm.planesDietaPendientes,
                    onTap: (plan) async {
                      final vmInstance = Provider.of<PlanReviewViewModel>(context, listen: false);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlanDietaEditScreen(
                            planInicial: plan,
                            viewModel: vmInstance, // Pasa la instancia
                          ),
                        ),
                      );
                      if (result == true) vmInstance.fetchPendientes();
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }



  /// Construye la lista de planes para un tipo específico (Dieta o Entrenamiento)
  Widget _buildPlanList<T>({
    required BuildContext context,
    required List<T> planes,
    required Function(T) onTap,
  }) {
    if (planes.isEmpty) {
      return const Center(child: Text('No hay planes pendientes de revisión.'));
    }

    return ListView.separated(
      itemCount: planes.length,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16, color: Colors.blue[100]),
      itemBuilder: (context, index) {
        final plan = planes[index];
        
        // --- ¡LÓGICA ACTUALIZADA! ---
        String nombreUsuario = 'Usuario Desconocido';
        String? nombreGrupo; // Ahora es nulable
        String mes = 'Mes Desconocido';
        String tipoPlan = ''; // Para el subtítulo

        if (plan is PlanDieta) {
          // Leemos los campos nuevos y limpios del modelo
          nombreUsuario = plan.usuarioNombre; 
          nombreGrupo = plan.usuarioGrupo;
          mes = plan.mes;
          tipoPlan = 'Dieta';
        } else if (plan is PlanEntrenamiento) {
          // Leemos los campos nuevos y limpios del modelo
          nombreUsuario = plan.usuarioNombre;
          nombreGrupo = plan.usuarioGrupo;
          mes = plan.mes;
          tipoPlan = 'Entrenamiento';
        }

        // Formateamos el grupo: (Grupo 18:30) o "" si es nulo/vacío
        final String textoGrupo = (nombreGrupo != null && nombreGrupo.isNotEmpty)
            ? ' ($nombreGrupo)'
            : '';
        // -----------------------------

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: Icon(
              (tipoPlan == 'Dieta') ? Icons.restaurant_menu : Icons.fitness_center,
              color: Colors.blue[700],
            ),
            
            // --- TÍTULO ACTUALIZADO ---
            title: Text(
              '$nombreUsuario$textoGrupo', // Ej: "Roberto (Grupo 18:30)"
              style: const TextStyle(fontWeight: FontWeight.w500)
            ),
            
            // --- SUBTÍTULO ACTUALIZADO ---
            subtitle: Text(
              'Plan $tipoPlan - $mes', // Ej: "Plan Dieta - 2025-10"
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
            onTap: () => onTap(plan),
          ),
        );
      },
    );
  }
}

// Nota: Los placeholders para las pantallas de edición ya no son necesarios aquí
// si ya tienes los archivos creados.
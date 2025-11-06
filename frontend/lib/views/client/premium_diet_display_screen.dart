// screens/client/premium_diet_display_screen.dart
// ¡¡VERSIÓN SIMPLIFICADA!!
// Ahora es un StatelessWidget y depende SÓLO de PremiumDietDisplayViewModel

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../viewmodels/premium_diet_display_viewmodel.dart';
import '../../models/plan_dieta.dart';
import '../../models/usuario.dart';
import 'premium_dieta_setup_screen.dart';
// ¡¡Ya no se necesita ProfileViewModel!!
// import '../../viewmodels/profile_viewmodel.dart'; 

// Helper isSameDay (importante para TableCalendar)
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

// --- 1. VUELVE A SER STATELESSWIDGET ---
class PremiumDietDisplayScreen extends StatelessWidget {
  const PremiumDietDisplayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // 2. Crea el VM autónomo. El constructor llamará a _initialize()
      create: (_) => PremiumDietDisplayViewModel(),
      child: Consumer<PremiumDietDisplayViewModel>(
        builder: (context, vm, _) {
          
          return Scaffold(
            backgroundColor: const Color(0xFFE3F2FD),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1E88E5),
              title: Text(
                'Dieta - ${DateFormat('EEEE d', 'es_ES').format(vm.fechaSeleccionada)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
            ),
            
            // 3. Ya no hay Consumer<ProfileViewModel>
            body: Column(
              children: [
                // 4. Lógica de UI simple basada en el VM
                
                // Muestra el calendario SOLO si el VM cargó el usuario Y tiene el plan
                if (vm.currentUser != null && vm.incluyePlanDieta)
                  _buildTableCalendar(context, vm),

                // Contenido
                Expanded(
                  child: vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : vm.error != null
                          ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${vm.error}', style: const TextStyle(color: Colors.red))))
                          
                          // Si no hay dieta (ya sea por día de descanso o porque no tiene plan)
                          : vm.dietaDelDia == null
                              // Pasa el usuario del VM al _buildEmptyState
                              ? _buildEmptyState(context, vm.fechaSeleccionada, vm.currentUser) 
                              
                              // Si hay dieta, la muestra
                              : _buildDietDay(context, vm.dietaDelDia!),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // --- EL RESTO DE WIDGETS (Sin cambios) ---

  // --- WIDGET DE CALENDARIO ---
  Widget _buildTableCalendar(BuildContext context, PremiumDietDisplayViewModel vm) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: TableCalendar(
        locale: 'es_ES',
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: vm.focusedDay,
        calendarFormat: CalendarFormat.week,
        selectedDayPredicate: (day) => isSameDay(vm.fechaSeleccionada, day),
        
        onDaySelected: (selectedDay, focusedDay) {
          // Llama al VM (que ya sabe si tiene permiso)
          vm.cambiarDia(selectedDay);
        },
        onPageChanged: (focusedDay) {
          vm.setFocusedDay(focusedDay);
        },
        
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.blue[200],
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
        ),
      ),
    );
  }

  /// Muestra el contenido de la dieta para el día.
  Widget _buildDietDay(BuildContext context, DiaDieta diaDieta) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
          child: Text(
            '${diaDieta.nombreDia} (~${diaDieta.kcalDiaAprox} Kcal)',
             style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue[800]),
            textAlign: TextAlign.center,
          ),
        ),
        ...diaDieta.comidas.map((comida) => _buildMealCard(context, comida)),
      ],
    );
  }

  /// Construye una Card para cada comida.
  Widget _buildMealCard(BuildContext context, ComidaDia comida) {
     return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comida.nombreComida,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: Colors.blue[700]),
            ),
            const Divider(height: 15),
            if (comida.opciones.isEmpty)
              const Text('No hay opciones sugeridas.', style: TextStyle(fontStyle: FontStyle.italic))
            else
              ...comida.opciones.map((plato) => _buildDishDetails(context, plato)),
          ],
        ),
      ),
    );
  }

  /// Construye los detalles de un plato.
  Widget _buildDishDetails(BuildContext context, PlatoGenerado plato) {
     return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Text(
                    plato.nombrePlato,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                  ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('${plato.kcalAprox} Kcal'),
                backgroundColor: Colors.orange[100],
                labelStyle: TextStyle(fontSize: 12, color: Colors.orange[800]),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildDetailRow(Icons.list_alt_outlined, 'Ingredientes:', plato.ingredientes),
          _buildDetailRow(Icons.menu_book_outlined, 'Receta:', plato.receta),
        ],
      ),
    );
  }

  /// Helper para fila de detalle.
  Widget _buildDetailRow(IconData icon, String label, String value){
     return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Icon(icon, size: 18, color: Colors.grey[700]),
           const SizedBox(width: 8),
           Text('$label ', style: const TextStyle(fontWeight: FontWeight.w600)),
           Expanded(child: Text(value.isNotEmpty ? value : 'N/A', style: TextStyle(color: Colors.grey[800]))),
         ],
      ),
    );
  }

  /// --- Función de estado vacío (Tu lógica original) ---
  /// Ahora usa el 'usuario' que viene del VM
  Widget _buildEmptyState(BuildContext context, DateTime fecha, Usuario? usuario) {
    
    // 1. Si NO es premium (o el usuario es nulo)
    if (usuario == null || !usuario.esPremium) {
      return const _PremiumUpsellWidget();
    }
    
    // 2. Si ES premium pero NO incluye dieta
    if (usuario.esPremium && !usuario.incluyePlanDieta) {
       return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Plan No Incluido',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Este servicio no está incluido en tu plan premium actual. Contacta con tu entrenador para más información.',
                 style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // 3. Si ES premium y SÍ incluye dieta (pero no hay plan o es día de descanso)
    if (usuario.esPremium && usuario.incluyePlanDieta) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.no_food_outlined, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Sin Plan de Dieta',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Puede ser un día de descanso, aún no has configurado tus preferencias o tu plan no está aprobado.',
                 style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
               TextButton.icon(
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Configurar mis preferencias'),
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => PremiumDietaSetupScreen(usuario: usuario)))
                         .then((result) {
                            if (result == true) {
                              // Al volver, le decimos al VM que refresque
                              Provider.of<PremiumDietDisplayViewModel>(context, listen: false).fetchDietaParaDia(fecha);
                              
                              // NOTA: Si al guardar preferencias cambia el perfil, 
                              // el VM debería recargar su propio perfil.
                              // Por ahora, solo recargamos la dieta.
                            }
                          });
                  },
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
               ),
            ],
          ),
        ),
      );
    }
    return const Center(child: Text('Error al cargar estado.'));
  }
}

// --- WIDGET DE UPSELL (Tu widget original sin cambios) ---
class _PremiumUpsellWidget extends StatelessWidget {
  const _PremiumUpsellWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!, width: 2)
      ),
      margin: const EdgeInsets.all(16.0),
      child: SingleChildScrollView( 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border_purple500_sharp, color: Colors.amber[800], size: 50),
            const SizedBox(height: 16),
            Text(
              '✨ Desbloquea tu Plan de Dieta ✨',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                     fontWeight: FontWeight.bold, color: Colors.amber[900], fontSize: 22
                   ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Consigue dietas generadas por tu nutricionista, adaptadas 100% a tus calorías y objetivos.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.star, color: Colors.white),
              label: const Text('Hazte Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: () {
                // TODO: Navegar a la pantalla de suscripción premium
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
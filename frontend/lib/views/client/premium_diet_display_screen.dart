// screens/client/premium_diet_display_screen.dart
// ¡¡VERSIÓN CORREGIDA!! Tu UI original + Botón Lista de Compra + Lógica de Estado

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../viewmodels/premium_diet_display_viewmodel.dart';
import '../../models/plan_dieta.dart';
import '../../models/usuario.dart';
import 'premium_dieta_setup_screen.dart';

// Helper isSameDay (importante para TableCalendar)
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class PremiumDietDisplayScreen extends StatelessWidget {
  const PremiumDietDisplayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
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
              
              // --- ¡NUEVO! Botón Lista de Compra ---
              actions: [
                if (vm.estadoPlan == 'aprobado' && vm.tieneListaCompra)
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    tooltip: 'Lista de la Compra',
                    onPressed: () {
                      _mostrarListaCompra(context, vm.listaCompra);
                    },
                  ),
              ],
              // -----------------------------------
            ),
            
            body: Column(
              children: [
                // Muestra el calendario SOLO si el VM cargó el usuario Y tiene el plan
                if (vm.currentUser != null && vm.incluyePlanDieta)
                  _buildTableCalendar(context, vm),

                // Contenido
                Expanded(
                  child: vm.isLoading // Loading inicial
                      ? const Center(child: CircularProgressIndicator())
                      : vm.error != null // Error
                          ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${vm.error}', style: const TextStyle(color: Colors.red))))
                          
                          // ¡LÓGICA DE ESTADO MEJORADA!
                          : _buildBodyContent(context, vm), 
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // --- ¡NUEVO! Widget para decidir qué mostrar ---
  /// Decide qué mostrar basado en el estado del plan
  Widget _buildBodyContent(BuildContext context, PremiumDietDisplayViewModel vm) {
    // Si el usuario no tiene el plan (porque no es premium o no lo incluye)
    // _buildEmptyState se encargará de mostrar el banner de "Hazte Premium"
    if (vm.currentUser == null || !vm.incluyePlanDieta) {
      return _buildEmptyState(context, vm.fechaSeleccionada, vm.currentUser);
    }

    // Si tiene el plan, comprobamos el estado
    switch (vm.estadoPlan) {
      case 'aprobado':
        // Si está aprobado, mostramos la dieta o el día de descanso
        return vm.dietaDelDia == null
            ? _buildEmptyState(context, vm.fechaSeleccionada, vm.currentUser) // (mostrará "Día de descanso" o "Configurar")
            : _buildDietDay(context, vm.dietaDelDia!); // Muestra la dieta
            
      case 'pendiente_revision':
        // Si está pendiente, mostramos un banner específico
        return _buildStatusBanner(
          context: context,
          icon: Icons.pending_actions,
          color: Colors.orange,
          titulo: 'Tu dieta está en revisión',
          subtitulo: 'Tu plan está siendo preparado por el nutricionista. ¡Vuelve pronto!',
        );

      case 'pendiente_solicitud':
      default:
        // Si no ha solicitado (o estado desconocido), mostramos el EmptyState
        // que contiene el botón de "Configurar"
        return _buildEmptyState(context, vm.fechaSeleccionada, vm.currentUser);
    }
  }

  // --- WIDGET DE CALENDARIO (Tu código original) ---
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

  /// Muestra el contenido de la dieta para el día. (Tu código original)
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

  /// Construye una Card para cada comida. (Tu código original)
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

  /// Construye los detalles de un plato. (Tu código original)
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

  /// Helper para fila de detalle. (Tu código original)
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
                             // --- ¡¡LÍNEA CORREGIDA!! ---
                             // Al volver, le decimos al VM que refresque
                             Provider.of<PremiumDietDisplayViewModel>(context, listen: false).refreshData();
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

  // --- ¡NUEVO! Banner de Estado Específico ---
  /// Muestra un banner para estados como "pendiente_revision"
  Widget _buildStatusBanner({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String titulo,
    required String subtitulo,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 16),
            Text(titulo, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitulo, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
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

// --- ¡NUEVA FUNCIÓN! ---
// (Movida fuera de la clase para que sea un helper global o estático)
/// Muestra la lista de la compra en un Modal Deslizable
void _mostrarListaCompra(BuildContext context, Map<String, dynamic> listaCompra) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Permite que el modal sea más alto
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7, // Empieza al 70% de la altura
        maxChildSize: 0.9,     // Puede llegar al 90%
        minChildSize: 0.4,     // Mínimo 40%
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Lista de la Compra',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: ListView.builder(
                    controller: scrollController, // ¡Importante para el drag!
                    itemCount: listaCompra.keys.length,
                    itemBuilder: (context, index) {
                      String categoria = listaCompra.keys.elementAt(index);
                      List<dynamic> items = listaCompra[categoria] ?? [];
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoria, // Ej: "Frutas y Verduras"
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                            ),
                            const Divider(thickness: 1.5),
                            
                            ...items.map((item) => Padding(
                              padding: const EdgeInsets.only(left: 8.0, top: 6.0, bottom: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_box_outline_blank, size: 20, color: Colors.grey[700]),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(item.toString(), style: const TextStyle(fontSize: 16))),
                                ],
                              ),
                            )).toList(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
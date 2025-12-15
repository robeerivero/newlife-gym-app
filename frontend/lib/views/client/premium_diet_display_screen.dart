// screens/client/premium_diet_display_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../viewmodels/premium_diet_display_viewmodel.dart';
import '../../models/plan_dieta.dart';
import '../../models/usuario.dart';
import 'premium_dieta_setup_screen.dart';

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
          final colorScheme = Theme.of(context).colorScheme;
          
          return Scaffold(
            // backgroundColor: eliminado (Theme default)
            appBar: AppBar(
              // backgroundColor: eliminado (Theme default)
              title: Text(
                'Dieta - ${DateFormat('EEEE d', 'es_ES').format(vm.fechaSeleccionada)}',
                style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              elevation: 0,
              
              // --- Botón Lista de Compra ---
              actions: [
                if (vm.estadoPlan == 'aprobado' && vm.tieneListaCompra)
                  IconButton(
                    icon: Icon(Icons.shopping_cart_outlined, color: colorScheme.onPrimary),
                    tooltip: 'Lista de la Compra',
                    onPressed: () {
                      _mostrarListaCompra(context, vm.listaCompra);
                    },
                  ),
              ],
            ),
            
            body: Column(
              children: [
                if (vm.currentUser != null && vm.incluyePlanDieta)
                  _buildTableCalendar(context, vm),

                Expanded(
                  child: vm.isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : vm.error != null 
                          ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${vm.error}', style: TextStyle(color: colorScheme.error))))
                          : _buildBodyContent(context, vm), 
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildBodyContent(BuildContext context, PremiumDietDisplayViewModel vm) {
    if (vm.currentUser == null || !vm.incluyePlanDieta) {
      return _buildEmptyState(context, vm.fechaSeleccionada, vm.currentUser);
    }

    switch (vm.estadoPlan) {
      case 'aprobado':
        return vm.dietaDelDia == null
            ? _buildEmptyState(context, vm.fechaSeleccionada, vm.currentUser) 
            : _buildDietDay(context, vm.dietaDelDia!); 
            
      case 'pendiente_revision':
        return _buildStatusBanner(
          context: context,
          icon: Icons.pending_actions,
          color: Colors.orange, // Semántico: Pendiente = Naranja
          titulo: 'Tu dieta está en revisión',
          subtitulo: 'Tu plan está siendo preparado por el nutricionista. ¡Vuelve pronto!',
        );

      case 'pendiente_solicitud':
      default:
        return _buildEmptyState(context, vm.fechaSeleccionada, vm.currentUser);
    }
  }

  Widget _buildTableCalendar(BuildContext context, PremiumDietDisplayViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: TableCalendar(
        locale: 'es_ES',
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        
        focusedDay: vm.focusedDay,
        selectedDayPredicate: (day) => isSameDay(vm.fechaSeleccionada, day),
        
        // --- CAMBIO CLAVE 1: Usar variable del ViewModel ---
        calendarFormat: vm.calendarFormat, 
        
        // --- CAMBIO CLAVE 2: Configurar formatos disponibles ---
        availableCalendarFormats: const {
          CalendarFormat.month: 'Mes',    // Muestra "Mes"
          CalendarFormat.week: 'Semana',  // Muestra "Semana"
        },

        // --- CAMBIO CLAVE 3: Manejar el cambio ---
        onFormatChanged: (format) {
          vm.onFormatChanged(format);
        },

        onDaySelected: (selectedDay, focusedDay) {
          vm.cambiarDia(selectedDay);
        },
        onPageChanged: (focusedDay) {
          vm.setFocusedDay(focusedDay);
        },
        
        headerStyle: HeaderStyle( // Quitamos 'const' porque colorScheme.onPrimary no es constante
          titleCentered: true,
          // Habilitamos el botón de formato (antes estaba false)
          formatButtonVisible: true, 
          titleTextStyle: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          
          // Estilo del botón "Mes/Semana" (copiado de class_screen para consistencia)
          formatButtonTextStyle: TextStyle(color: colorScheme.onPrimary, fontSize: 14),
          formatButtonDecoration: BoxDecoration(
            color: colorScheme.primary, 
            borderRadius: const BorderRadius.all(Radius.circular(12.0))
          ),
          leftChevronIcon: const Icon(Icons.chevron_left),
          rightChevronIcon: const Icon(Icons.chevron_right),
        ),
        
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
        ),
      ),
    );
  }

  Widget _buildDietDay(BuildContext context, DiaDieta diaDieta) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
          child: Text(
            '${diaDieta.nombreDia} (~${diaDieta.kcalDiaAprox} Kcal)',
             style: Theme.of(context).textTheme.headlineMedium?.copyWith(
               fontWeight: FontWeight.bold, 
               color: colorScheme.primary // Azul reemplazado por Primary
             ),
            textAlign: TextAlign.center,
          ),
        ),
        ...diaDieta.comidas.map((comida) => _buildMealCard(context, comida)),
      ],
    );
  }

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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600, 
                color: Theme.of(context).colorScheme.primary // Azul reemplazado por Primary
              ),
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

  Widget _buildDishDetails(BuildContext context, PlatoGenerado plato) {
    final colorScheme = Theme.of(context).colorScheme;
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
                // Naranja/Amber adaptado al theme Secondary
                backgroundColor: colorScheme.secondaryContainer,
                labelStyle: TextStyle(fontSize: 12, color: colorScheme.onSecondaryContainer),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildDetailRow(context, Icons.list_alt_outlined, 'Ingredientes:', plato.ingredientes),
          _buildDetailRow(context, Icons.menu_book_outlined, 'Receta:', plato.receta),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value){
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
           const SizedBox(width: 8),
           Text('$label ', style: const TextStyle(fontWeight: FontWeight.w600)),
           Expanded(child: Text(value.isNotEmpty ? value : 'N/A', style: TextStyle(color: colorScheme.onSurface))),
         ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DateTime fecha, Usuario? usuario) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // 1. Si NO es premium
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
                             Provider.of<PremiumDietDisplayViewModel>(context, listen: false).refreshData();
                           }
                         });
                  },
                  style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
                ),
            ],
          ),
        ),
      );
    }
    return const Center(child: Text('Error al cargar estado.'));
  }

  Widget _buildStatusBanner({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String titulo,
    required String subtitulo,
  }) {
    // Nota: Mantenemos el color específico pasado por argumento (ej: Naranja de alerta)
    // para estados semánticos, pero el texto usa el theme.
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
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

class _PremiumUpsellWidget extends StatelessWidget {
  const _PremiumUpsellWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Adaptamos el estilo "Amber" al estilo "Secondary" (Naranja) del tema
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withOpacity(0.5), width: 2)
      ),
      margin: const EdgeInsets.all(16.0),
      child: SingleChildScrollView( 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border_purple500_sharp, color: colorScheme.secondary, size: 50),
            const SizedBox(height: 16),
            Text(
              '✨ Desbloquea tu Plan de Dieta ✨',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                       fontWeight: FontWeight.bold, color: colorScheme.secondary, fontSize: 22
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
              icon: Icon(Icons.star, color: colorScheme.onSecondary),
              label: Text('Hazte Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSecondary)),
              onPressed: () {
                // TODO: Navegar a la pantalla de suscripción premium
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
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

void _mostrarListaCompra(BuildContext context, Map<String, dynamic> listaCompra) {
  final colorScheme = Theme.of(context).colorScheme;
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, 
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7, 
        maxChildSize: 0.9,     
        minChildSize: 0.4,     
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
                    controller: scrollController, 
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
                              categoria,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary, // Indigo -> Primary
                                  ),
                            ),
                            const Divider(thickness: 1.5),
                            
                            ...items.map((item) => Padding(
                              padding: const EdgeInsets.only(left: 8.0, top: 6.0, bottom: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_box_outline_blank, size: 20, color: colorScheme.onSurfaceVariant),
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
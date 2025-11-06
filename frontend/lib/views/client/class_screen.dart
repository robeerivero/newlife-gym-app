// screens/client/class_screen.dart
// ¡VERSIÓN FINAL CON BOTÓN QR EN LA TARJETA!

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Para formatear fecha
// ViewModels y Modelos
import '../../viewmodels/class_viewmodel.dart'; 
import '../../models/reserva.dart';
import '../../models/clase.dart'; // Es necesario
import '../../models/plan_entrenamiento.dart';
// Otras Pantallas
import 'qr_scan_screen.dart';
import 'reserve_class_screen.dart';
// Pantallas de Setup Premium
import 'premium_entrenamiento_setup_screen.dart';

// Helper isSameDay (importante para TableCalendar)
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class ClassScreen extends StatelessWidget {
  const ClassScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClassViewModel(),
      child: Consumer<ClassViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFE3F2FD), 
            appBar: AppBar(
              backgroundColor: const Color(0xFF1E88E5), 
              title: const Text('Mi Calendario', style: TextStyle(color: Colors.white)),
              elevation: 0,
              actions: [
                // --- ¡¡CAMBIO!! Botón QR eliminado de aquí ---
                IconButton(icon: const Icon(Icons.exit_to_app, color: Colors.white), tooltip: 'Cerrar Sesión', onPressed: () => vm.logout(context)),
              ],
            ),
            floatingActionButton: vm.cancelaciones > 0 // Botón Reservar
                ? FloatingActionButton.extended(
                    onPressed: () => _navigateToReserveScreen(context, vm),
                    label: Text('Reservar (${vm.cancelaciones})'),
                    icon: const Icon(Icons.add),
                    backgroundColor: Colors.green,
                  )
                : null,
            body: vm.isLoading && vm.getReservasParaDia(vm.selectedDay).isEmpty 
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _buildTableCalendar(vm),
                      const Divider(height: 1, thickness: 1),
                      if (vm.error != null && !vm.isRutinaLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(vm.error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                      Expanded(
                        child: _buildInfoPanel(context, vm),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  // --- Navegaciones ---

  void _navigateToReserveScreen(BuildContext context, ClassViewModel vm, {bool replace = false}) {
    // (Tu función original sin cambios)
    final route = MaterialPageRoute(builder: (context) => const ReserveClassScreen());
    final navigator = Navigator.of(context);
    final classViewModel = Provider.of<ClassViewModel>(context, listen: false);

    Future.delayed(const Duration(milliseconds: 100), () {
        if (replace) {
          navigator.pushReplacement(route).then((_) => classViewModel.fetchProfile());
        } else {
          navigator.push(route).then((_) {
            classViewModel.fetchReservasParaMes(classViewModel.focusedDay);
            classViewModel.fetchProfile();
            classViewModel.onDaySelected(classViewModel.selectedDay, classViewModel.focusedDay);
          });
        }
    });
  }

  /// Navega a la pantalla de escanear QR.
  /// Esta función es genérica; el VM se encarga de validar el QR.
  void _escanearQR(BuildContext context, ClassViewModel vm) async {
    // (Tu lógica original sin cambios)
    final String? qrCode = await Navigator.push<String>(context, MaterialPageRoute(builder: (context) => const QRScanScreen()));
    if (qrCode != null && qrCode.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Procesando QR...')));
      final mensaje = await vm.registrarAsistencia(qrCode);
      if (context.mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
      }
    }
  }

  // --- Widgets de UI ---

  Widget _buildTableCalendar(ClassViewModel vm) {
    // (Tu versión final y correcta del calendario, sin cambios)
    final DateTime firstDay = vm.firstCalendarDay; 
    final DateTime now = DateTime.now();
    final DateTime lastDay = DateTime.utc(now.year, now.month + 1, 0); 

    return TableCalendar<Reserva>(
      locale: 'es_ES',
      firstDay: firstDay,
      lastDay: lastDay, 
      focusedDay: vm.focusedDay.isBefore(firstDay) ? firstDay : vm.focusedDay,
      selectedDayPredicate: (day) => isSameDay(vm.selectedDay, day),
      onDaySelected: vm.onDaySelected, 
      onPageChanged: vm.onPageChanged,
      eventLoader: vm.getReservasParaDia,
      calendarFormat: vm.calendarFormat,
      onFormatChanged: vm.onFormatChanged,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Mes',
        CalendarFormat.week: 'Semana',
      },
      enabledDayPredicate: (day) {
        final dayUtc = DateTime.utc(day.year, day.month, day.day);
        return !dayUtc.isBefore(firstDay);
      },
      calendarStyle: CalendarStyle(
        markerDecoration: BoxDecoration(color: Colors.deepOrangeAccent, shape: BoxShape.circle),
        todayDecoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), shape: BoxShape.circle),
        selectedDecoration: BoxDecoration(color: Colors.blue[700], shape: BoxShape.circle),
        disabledTextStyle: TextStyle(color: Colors.grey[400]),
        outsideDaysVisible: false, 
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: true, titleCentered: true,
        titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black54),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black54),
        formatButtonTextStyle: TextStyle(color: Colors.white, fontSize: 14),
          formatButtonDecoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.all(Radius.circular(12.0))),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
            final reservas = events as List<Reserva>? ?? [];
              if (reservas.isNotEmpty) {
                return Positioned( right: 1, bottom: 1,
                  child: Container( padding: const EdgeInsets.all(1.0),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.deepOrangeAccent),
                      child: const Icon(Icons.fitness_center, size: 10.0, color: Colors.white),
                  ),
                );
              } return null;
           },
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context, ClassViewModel vm) {
    // (Lógica sin cambios)
    final reservasDelDia = vm.getReservasParaDia(vm.selectedDay);
    if (reservasDelDia.isNotEmpty) {
      return _buildListaClases(context, vm, reservasDelDia);
    } else if (vm.incluyePlanEntrenamiento) {
      return _buildRutinaPremiumIA(context, vm, vm.selectedDay); 
    } else if (vm.esPremium) {
      return _buildMensajeServicioNoIncluido(context, 'entrenamiento');
    } else {
      return _buildBannerPremium(context);
    }
  }

  // --- ¡¡FUNCIÓN MODIFICADA!! ---
  /// Muestra la lista de tarjetas de clases presenciales reservadas.
  Widget _buildListaClases(BuildContext context, ClassViewModel vm, List<Reserva> reservas) {
    return ListView.builder(
      itemCount: reservas.length,
      padding: const EdgeInsets.only(bottom: 80.0, top: 8.0), 
      itemBuilder: (context, index) {
        final reserva = reservas[index];

        return _MyBookingCard(
          reserva: reserva,
          isCancelLoading: vm.isLoading, 
          onCancel: () {
            _confirmarCancelacion(context, vm, reserva);
          },
          // --- ¡¡CAMBIO!! Se pasa la función de escanear QR ---
          onScanQR: () {
             // Llama a la función genérica de escaneo
            _escanearQR(context, vm);
          },
        );
      },
    );
  }

  /// Muestra diálogo de confirmación y maneja la navegación post-cancelación.
  void _confirmarCancelacion(BuildContext context, ClassViewModel vm, Reserva reserva) {
    // (Tu función original sin cambios)
    if (vm.isLoading) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cancelar Clase'),
          content: Text('¿Seguro que quieres cancelar ${reserva.clase.nombre} a las ${reserva.clase.horaInicio}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Sí, Cancelar', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); 
                final bool exito = await vm.cancelarClase(reserva.clase.id);

                if (exito && context.mounted) {
                    if (vm.cancelSuccessCreditGranted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Clase cancelada. Crédito devuelto. Elige tu nueva clase.'), backgroundColor: Colors.green, duration: Duration(seconds: 3)),
                      );
                      _navigateToReserveScreen(context, vm, replace: true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Clase cancelada (sin devolución de crédito por poca antelación).'), backgroundColor: Colors.orange, duration: Duration(seconds: 3)),
                      );
                    }
                } else if (!exito && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(vm.error ?? 'Error al cancelar'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }


  /// Construye el widget que muestra la rutina de IA
  Widget _buildRutinaPremiumIA(BuildContext context, ClassViewModel vm, DateTime fecha) {
    // (Tu función original sin cambios)
    if (vm.isRutinaLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final rutinaDia = vm.rutinaDelDia;
    if (rutinaDia == null || rutinaDia.ejercicios.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(Icons.calendar_month_outlined, size: 50, color: Colors.grey[600]),
               const SizedBox(height: 16),
               Text(
                "Día de Descanso o Sin Plan",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
               ),
               const SizedBox(height: 8),
               Text( 
                "No tienes rutina de entrenamiento extra asignada para hoy (${DateFormat('EEEE', 'es_ES').format(fecha)}).\nPuede ser un día de descanso o tu plan aún no está configurado/aprobado.",
                 style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
               ),
               const SizedBox(height: 20),
               if (vm.currentUser != null && vm.currentUser!.incluyePlanEntrenamiento)
                 TextButton.icon(
                   icon: const Icon(Icons.settings_outlined),
                   label: const Text('Configurar mis preferencias'),
                   onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => PremiumEntrenamientoSetupScreen(usuario: vm.currentUser!)))
                       .then((_) => vm.onDaySelected(vm.selectedDay, vm.focusedDay));
                   },
                   style: TextButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
                 ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        Padding( 
          padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
          child: Text('💪 ${rutinaDia.nombreDia}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue[800])),
        ),
        ...rutinaDia.ejercicios.map((ej) => Card( 
          margin: const EdgeInsets.only(bottom: 12), elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding( padding: const EdgeInsets.all(14.0),
            child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ej.nombre, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap( spacing: 12.0, runSpacing: 4.0,
                      children: [
                        _buildDetailChip(Icons.repeat, 'Series: ${ej.series}'),
                        _buildDetailChip(Icons.fitness_center, 'Reps: ${ej.repeticiones}'),
                        _buildDetailChip(Icons.timer_outlined, 'Descanso Series: ${ej.descansoSeries}'),
                        _buildDetailChip(Icons.hourglass_bottom, 'Descanso Ejercicio: ${ej.descansoEjercicios}'),
                      ],
                  ),
                  if (ej.descripcion.isNotEmpty) ...[
                    const Divider(height: 20),
                    Text(ej.descripcion, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                  ]
                ],
            ),
          ),
        )),
      ],
    );
  }
  
  /// Helper para crear los chips de detalles del ejercicio.
  Widget _buildDetailChip(IconData icon, String text) {
    // (Tu función original sin cambios)
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.blue[800]),
      label: Text(text),
      backgroundColor: Colors.blue[50],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      labelStyle: TextStyle(fontSize: 13, color: Colors.blue[900]),
      visualDensity: VisualDensity.compact,
    );
  }

  /// Muestra un mensaje indicando que el servicio específico no está incluido.
  Widget _buildMensajeServicioNoIncluido(BuildContext context, String tipoServicio) {
    // (Tu función original sin cambios)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tipoServicio == 'entrenamiento' ? Icons.fitness_center : Icons.restaurant_menu, size: 50, color: Colors.orangeAccent),
            const SizedBox(height: 16),
            Text(
              'Plan de $tipoServicio no incluido',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Este servicio premium no está activo en tu cuenta. Habla con tu entrenador para añadirlo.',
               style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra el banner para que los usuarios gratuitos se hagan premium.
  Widget _buildBannerPremium(BuildContext context) {
    // (Tu función original sin cambios)
    return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.star_border_purple500_sharp, color: Colors.amber[800], size: 50),
          const SizedBox(height: 16),
          Text(
            '✨ Desbloquea tu Plan Personalizado ✨',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.amber[900]
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Consigue rutinas de entrenamiento y dietas generadas por tu entrenador, adaptadas a tus objetivos.',
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
              backgroundColor: Colors.amber[700], // Botón naranja
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

// --- ¡¡WIDGET MODIFICADO!! ---
// Acepta 'onScanQR' y muestra ambos botones

class _MyBookingCard extends StatelessWidget {
  final Reserva reserva;
  final bool isCancelLoading;
  final VoidCallback onCancel;
  final VoidCallback onScanQR; // <-- ¡CAMBIO! Añadido callback para QR

  const _MyBookingCard({
    Key? key,
    required this.reserva,
    required this.isCancelLoading,
    required this.onCancel,
    required this.onScanQR, // <-- ¡CAMBIO! Añadido al constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E88E5); 
    const Color cancelColor = Color(0xFFD32F2F); 
    const Color qrColor = Color(0xFF303F9F); // Color Indigo para QR
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String horaInicio = reserva.clase.horaInicio;
    final String horaFin = reserva.clase.horaFin;
    final String nombre = reserva.clase.nombre;
 
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, const Color(0xFFF0F4F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(
            left: BorderSide(color: primaryColor, width: 6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                nombre.toUpperCase(),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12), 

              // Fila de Información (Hora)
              Row(
                children: [
                  Icon(Icons.access_time_filled_rounded, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Hora: ',
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$horaInicio - $horaFin',
                    style: textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- ¡¡CAMBIO!! Botones en Fila ---
              Row(
                children: [
                  // Botón de Cancelar
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.white, size: 18),
                      label: Text(
                        isCancelLoading ? '...' : 'Cancelar', // Texto más corto
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      onPressed: isCancelLoading ? null : onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCancelLoading ? Colors.grey : cancelColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12), // Espacio entre botones
                  // Botón Canjear QR
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
                      label: const Text(
                        'Canjear QR',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      // Deshabilitado si hay una cancelación en curso
                      onPressed: isCancelLoading ? null : onScanQR, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCancelLoading ? Colors.grey : qrColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
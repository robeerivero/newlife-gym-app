import 'dart:convert'; // Necesario para jsonEncode
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; 
import '../../viewmodels/class_viewmodel.dart'; 
import '../../models/reserva.dart';
import '../../models/usuario.dart'; // Importar modelo Usuario
import '../../services/class_service.dart'; // Importar servicio
import '../../fluttermoji/fluttermojiCircleAvatar.dart'; // Tu avatar local

// 👇 IMPORTANTE: Importamos el widget del botón
import '../../widgets/boton_solicitud_premium.dart';

import 'qr_scan_screen.dart';
import 'reserve_class_screen.dart';
import 'premium_entrenamiento_setup_screen.dart';

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
            appBar: AppBar(
              title: const Text('Mi Calendario'),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  tooltip: 'Cerrar Sesión',
                  onPressed: () => vm.logout(context),
                ),
              ],
            ),
            floatingActionButton: vm.cancelaciones > 0
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
                      _buildTableCalendar(vm, context),
                      const Divider(height: 1, thickness: 1),
                      if (vm.error != null && !vm.isRutinaLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            vm.error!, 
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold), 
                            textAlign: TextAlign.center
                          ),
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

  void _navigateToReserveScreen(BuildContext context, ClassViewModel vm, {bool replace = false}) {
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

  void _escanearQR(BuildContext context, ClassViewModel vm) async {
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

  Widget _buildTableCalendar(ClassViewModel vm, BuildContext context) {
    final DateTime firstDay = vm.firstCalendarDay; 
    final DateTime now = DateTime.now();
    final DateTime lastDay = DateTime.utc(now.year, now.month + 1, 0);
    final colorScheme = Theme.of(context).colorScheme;

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
        CalendarFormat.week: 'Semana',
        CalendarFormat.month: 'Mes',
      },
      enabledDayPredicate: (day) {
        final dayUtc = DateTime.utc(day.year, day.month, day.day);
        return !dayUtc.isBefore(firstDay);
      },
      calendarStyle: CalendarStyle(
        markerDecoration: BoxDecoration(color: colorScheme.secondary, shape: BoxShape.circle),
        todayDecoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.5), shape: BoxShape.circle),
        selectedDecoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
        disabledTextStyle: TextStyle(color: Colors.grey[400]),
        outsideDaysVisible: false, 
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: true, titleCentered: true,
        titleTextStyle: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        leftChevronIcon: const Icon(Icons.chevron_left),
        rightChevronIcon: const Icon(Icons.chevron_right),
        formatButtonTextStyle: TextStyle(color: colorScheme.onPrimary, fontSize: 14),
        formatButtonDecoration: BoxDecoration(color: colorScheme.primary, borderRadius: const BorderRadius.all(Radius.circular(12.0))),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
            final reservas = events as List<Reserva>? ?? [];
              if (reservas.isNotEmpty) {
                return Positioned( right: 1, bottom: 1,
                  child: Container( padding: const EdgeInsets.all(1.0),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.secondary),
                      child: Icon(Icons.fitness_center, size: 10.0, color: colorScheme.onSecondary),
                  ),
                );
              } return null;
           },
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context, ClassViewModel vm) {
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
          onScanQR: () {
            _escanearQR(context, vm);
          },
        );
      },
    );
  }

  void _confirmarCancelacion(BuildContext context, ClassViewModel vm, Reserva reserva) {
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
              child: Text('Sí, Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); 
                final bool exito = await vm.cancelarClase(reserva.clase.id);
                if (exito && context.mounted) {
                  if (vm.cancelSuccessCreditGranted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Clase cancelada. Crédito devuelto.'), backgroundColor: Colors.green, duration: Duration(seconds: 3)),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Clase cancelada (sin devolución de crédito por poca antelación).'), backgroundColor: Colors.orange, duration: Duration(seconds: 3)),
                    );
                  }
                } else if (!exito && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(vm.error ?? 'Error al cancelar'), backgroundColor: Theme.of(context).colorScheme.error),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRutinaPremiumIA(BuildContext context, ClassViewModel vm, DateTime fecha) {
    if (vm.isRutinaLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final rutinaDia = vm.rutinaDelDia;
    final colorScheme = Theme.of(context).colorScheme;

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
                   style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
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
          child: Text('💪 ${rutinaDia.nombreDia}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
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
                        _buildDetailChip(context, Icons.repeat, 'Series: ${ej.series}'),
                        _buildDetailChip(context, Icons.fitness_center, 'Reps: ${ej.repeticiones}'),
                        _buildDetailChip(context, Icons.timer_outlined, 'Descanso Series: ${ej.descansoSeries}'),
                        _buildDetailChip(context, Icons.hourglass_bottom, 'Descanso Ejercicio: ${ej.descansoEjercicios}'),
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
  
  Widget _buildDetailChip(BuildContext context, IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
      label: Text(text),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      labelStyle: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildMensajeServicioNoIncluido(BuildContext context, String tipoServicio) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tipoServicio == 'entrenamiento' ? Icons.fitness_center : Icons.restaurant_menu, size: 50, color: Theme.of(context).colorScheme.secondary),
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

  Widget _buildBannerPremium(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.star_border_purple500_sharp, color: colorScheme.secondary, size: 50),
          const SizedBox(height: 16),
          Text(
            '✨ Desbloquea tu Plan Personalizado ✨',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: colorScheme.secondary
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
          
          // 🔥 AQUÍ ESTÁ EL CAMBIO: Usamos el BotonSolicitudPremium en lugar del botón dummy
          const BotonSolicitudPremium(),
        ],
      ),
    ),
  );
  }
}

class _MyBookingCard extends StatelessWidget {
  final Reserva reserva;
  final bool isCancelLoading;
  final VoidCallback onCancel;
  final VoidCallback onScanQR; 

  const _MyBookingCard({
    Key? key,
    required this.reserva,
    required this.isCancelLoading,
    required this.onCancel,
    required this.onScanQR, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          color: Theme.of(context).cardColor,
          border: Border(
            left: BorderSide(color: colorScheme.primary, width: 6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre.toUpperCase(),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12), 

              Row(
                children: [
                  Icon(Icons.access_time_filled_rounded, color: colorScheme.primary, size: 20),
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
              
              // --- INTEGRACIÓN VISUAL DE AVATARES ---
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                "Compañeros de clase:",
                style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              
              // Aquí incrustamos el widget que carga los avatares
              _ParticipantesClase(classId: reserva.clase.id),
              // -------------------------------------

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(
                        isCancelLoading ? '...' : 'Cancelar',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: isCancelLoading ? null : onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCancelLoading ? Colors.grey : colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12), 
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.qr_code_scanner, color: colorScheme.onPrimary, size: 18),
                      label: Text(
                        'Canjear QR',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onPrimary),
                      ),
                      onPressed: isCancelLoading ? null : onScanQR, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCancelLoading ? Colors.grey : colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
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

// --- WIDGET PARA CARGAR Y MOSTRAR LOS AVATARES DE LA CLASE ---
// --- WIDGET PARA CARGAR Y MOSTRAR LOS AVATARES DE LA CLASE ---
class _ParticipantesClase extends StatefulWidget {
  final String classId;
  const _ParticipantesClase({Key? key, required this.classId}) : super(key: key);

  @override
  State<_ParticipantesClase> createState() => _ParticipantesClaseState();
}

class _ParticipantesClaseState extends State<_ParticipantesClase> {
  late Future<List<Usuario>> _participantesFuture;

  @override
  void initState() {
    super.initState();
    _participantesFuture = ClassService().fetchUsuariosPorClase(widget.classId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Usuario>>(
      future: _participantesFuture,
      builder: (context, snapshot) {
        // --- ESTADO DE CARGA ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 60, 
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 100, 
                child: LinearProgressIndicator(minHeight: 2),
              ),
            ),
          );
        }
        
        // --- ESTADO SIN DATOS O VACÍO ---
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Sé el primero en llegar", 
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13),
            ),
          );
        }

        final participantes = snapshot.data!;
        
        // --- ESTADO CON DATOS (LISTA DE AVATARES + NOMBRE) ---
        // Aumentamos la altura a 85 para que quepa el avatar y el texto debajo
        return SizedBox(
          height: 85, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: participantes.length,
            itemBuilder: (context, index) {
              final user = participantes[index];
              
              // Truco estético: Usar solo el primer nombre para que no ocupe mucho
              final String primerNombre = user.nombre.contains(' ') 
                  ? user.nombre.split(' ')[0] 
                  : user.nombre;

              // Capitalizar primera letra (por si acaso viene en minúscula)
              final nombreBonito = primerNombre.isNotEmpty
                  ? "${primerNombre[0].toUpperCase()}${primerNombre.substring(1).toLowerCase()}"
                  : "";

              return Padding(
                padding: const EdgeInsets.only(right: 12.0), // Un poco más de espacio entre usuarios
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Borde decorativo opcional para que resalte
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: FluttermojiCircleAvatar(
                        radius: 26, // Avatar ligeramente más grande
                        backgroundColor: Colors.grey[100],
                        avatarJson: jsonEncode(user.avatar), 
                      ),
                    ),
                    const SizedBox(height: 6), // Espacio entre avatar y nombre
                    
                    // Nombre limitado en ancho
                    SizedBox(
                      width: 60, // Ancho máximo para el texto
                      child: Text(
                        nombreBonito,
                        style: TextStyle(
                          fontSize: 11, 
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // Si es muy largo pone "..."
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
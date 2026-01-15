// screens/client/reserve_class_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../viewmodels/reserve_class_viewmodel.dart';

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class ReserveClassScreen extends StatelessWidget {
  const ReserveClassScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReserveClassViewModel()..initialize(),
      child: const _ReserveClassView(),
    );
  }
}

class _ReserveClassView extends StatefulWidget {
  const _ReserveClassView({Key? key}) : super(key: key);

  @override
  State<_ReserveClassView> createState() => _ReserveClassViewState();
}

class _ReserveClassViewState extends State<_ReserveClassView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return Consumer<ReserveClassViewModel>(
      builder: (context, vm, _) {
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              vm.cancelaciones > 0
                ? 'Reservar Clase (${vm.cancelaciones} créditos)'
                : 'Reservar Clase', 
            ),
          ),
          body: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 7)),
                focusedDay: vm.selectedDate,
                locale: 'es_ES',
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() { _calendarFormat = format; });
                },
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Mes',
                  CalendarFormat.week: 'Semana',
                },
                onDaySelected: (selectedDay, focusedDay) {
                  final today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                  final futureLimit = today.add(const Duration(days: 7));
                  final selectedUtc = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);

                  if (selectedUtc.isBefore(today) || selectedUtc.isAfter(futureLimit)) {
                    return; 
                  }
                  vm.fetchClassesForDate(selectedDay);
                },
                selectedDayPredicate: (day) => isSameDay(vm.selectedDate, day),
                enabledDayPredicate: (day) { 
                  final today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                  final futureLimit = today.add(const Duration(days: 7));
                  final dayUtc = DateTime.utc(day.year, day.month, day.day);
                  return !dayUtc.isBefore(today) && !dayUtc.isAfter(futureLimit);
                },
                
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                  ),
                  formatButtonTextStyle: TextStyle(color: colorScheme.onPrimary),
                  titleTextStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  leftChevronIcon: const Icon(Icons.chevron_left),
                  rightChevronIcon: const Icon(Icons.chevron_right),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  disabledTextStyle: TextStyle(color: Colors.grey[400]),
                  outsideDaysVisible: false,
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: vm.isLoading && vm.classes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : vm.errorMessage.isNotEmpty && vm.classes.isEmpty
                    ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(vm.errorMessage, textAlign: TextAlign.center, style: TextStyle(color: colorScheme.error, fontSize: 16))))
                    : vm.classes.isEmpty
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No hay clases disponibles para este día.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ))
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
                          itemCount: vm.classes.length,
                          itemBuilder: (context, index) {
                            final clase = vm.classes[index];
                            
                            return _NewClassCard(
                              clase: clase,
                              isLoading: vm.isLoading,
                              // Pasamos la función asíncrona para manejar la respuesta exacta del backend
                              onPressed: () async {
                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                
                                // 1. Llamamos al ViewModel (que devuelve un Map con el resultado completo)
                                final result = await vm.reserveClass(clase['_id']);
                                
                                // 2. Verificamos si el widget sigue montado antes de usar el contexto
                                if (!mounted) return;

                                if (result['success'] == true) {
                                  // ÉXITO: Mostramos mensaje según si es reserva o espera
                                  final bool esEspera = result['estado'] == 'en_espera';
                                  
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(result['mensaje']), // Mensaje directo del backend
                                      backgroundColor: esEspera ? Colors.orange : Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );

                                  // Si se ha completado con éxito, cerramos la pantalla tras un momento
                                  Future.delayed(const Duration(milliseconds: 1500), () {
                                    if (mounted) Navigator.pop(context);
                                  });

                                } else {
                                  // ERROR: Mostramos el error del backend
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(result['mensaje'] ?? 'Error desconocido'), 
                                      backgroundColor: colorScheme.error
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NewClassCard extends StatelessWidget {
  final Map<String, dynamic> clase;
  final bool isLoading; 
  // Cambiamos a Function para que quede claro que es un callback de acción
  final Function() onPressed;

  const _NewClassCard({
    Key? key,
    required this.clase,
    required this.isLoading,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final int maximo = (clase['maximoParticipantes'] as int?) ?? 0;
    final int cuposDisponibles = (clase['cuposDisponibles'] as int?) ?? 0;
    final int asistentes = maximo - cuposDisponibles;
    
    final List<dynamic> listaDeEspera = (clase['listaEspera'] as List<dynamic>?) ?? [];
    final int enEspera = listaDeEspera.length;

    final String horaInicio = clase['horaInicio'] ?? 'HH:MM';
    final String horaFin = clase['horaFin'] ?? 'HH:MM';
    final String nombre = clase['nombre'] ?? 'Nombre de Clase';

    final bool hayCupos = cuposDisponibles > 0;
    final bool sePuedeApuntarEnEspera = !hayCupos; 
    
    // Colores semánticos
    final Color statusColor = hayCupos ? Colors.green[600]! : (sePuedeApuntarEnEspera ? colorScheme.secondary : colorScheme.error);

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
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoIcon(
                    context,
                    icon: Icons.access_time_filled_rounded,
                    color: colorScheme.primary,
                    label: 'Hora',
                    value: '$horaInicio - $horaFin',
                  ),
                  _buildInfoIcon(
                    context,
                    icon: Icons.groups_rounded,
                    color: colorScheme.primary,
                    label: 'Asistentes',
                    value: '$asistentes / $maximo',
                  ),
                  _buildInfoIcon(
                    context,
                    icon: Icons.hourglass_top_rounded,
                    color: colorScheme.secondary,
                    label: 'En Espera',
                    value: '$enEspera',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(
                    hayCupos ? Icons.check_circle_outline : Icons.pending_actions_outlined,
                    color: Colors.white, // Forzamos blanco para contraste sobre color fuerte
                  ),
                  label: Text(
                    isLoading ? 'Procesando...' : (hayCupos ? 'Reservar Plaza' : 'Apuntarse en Espera'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  onPressed: isLoading ? null : onPressed, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLoading ? Colors.grey : statusColor,
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
        ),
      ),
    );
  }

  Widget _buildInfoIcon(BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
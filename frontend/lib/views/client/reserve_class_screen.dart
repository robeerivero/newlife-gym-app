// screens/client/reserve_class_screen.dart
// ¡VERSIÓN FINAL CORREGIDA! (Icono de calendario eliminado y lógica de navegación revertida)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../viewmodels/reserve_class_viewmodel.dart';

// Helper isSameDay (importante para TableCalendar)
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
        return Scaffold(
          // Fondo celeste
          backgroundColor: const Color(0xFFE3F2FD), 
          appBar: AppBar(
            title: Text(
              vm.cancelaciones > 0
                ? 'Reservar Clase (${vm.cancelaciones} créditos)'
                : 'Reservar Clase', 
              style: const TextStyle(color: Colors.white)
            ),
            backgroundColor: const Color(0xFF1E88E5), // Azul primario
            iconTheme: const IconThemeData(color: Colors.white), // Flecha back blanca
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
                
                // --- ¡FIX! eventLoader y calendarBuilders ELIMINADOS ---

                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                  ),
                  formatButtonTextStyle: const TextStyle(color: Colors.white),
                  titleTextStyle: const TextStyle(fontSize: 16.0),
                  leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.black54),
                  rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.black54),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue[700],
                    shape: BoxShape.circle,
                  ),
                  disabledTextStyle: TextStyle(color: Colors.grey[400]),
                  outsideDaysVisible: false,
                ),
              ),
              const Divider(height: 1),

              // Lista de clases
              Expanded(
                child: vm.isLoading && vm.classes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : vm.errorMessage.isNotEmpty && vm.classes.isEmpty
                    ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(vm.errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16))))
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
                              onPressed: () async {
                                // Lógica de 0 cupos (navegar atrás)
                                final int cuposDisponibles = (clase['cuposDisponibles'] as int?) ?? 0;
                                if (cuposDisponibles == 0) {
                                  if (mounted) {
                                    Navigator.pop(context);
                                  }
                                  return; 
                                }

                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                final success = await vm.reserveClass(clase['_id']);
                                
                                if (success && mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('¡Clase reservada con éxito!'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );

                                  // --- ¡FIX DE NAVEGACIÓN! ---
                                  // Revertido a la lógica original.
                                  // Comprueba los créditos DESPUÉS de que el VM se haya actualizado.
                                  if (vm.cancelaciones == 0) {
                                    Future.delayed(const Duration(milliseconds: 1200), () {
                                      if (mounted) { Navigator.pop(context); } // Cierra si 0 créditos
                                    });
                                  }
                                  // --- FIN FIX ---

                                } else if (vm.errorMessage.isNotEmpty && mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar( content: Text(vm.errorMessage), backgroundColor: Colors.red),
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

// --- WIDGET _NewClassCard ---
// (Este widget no ha cambiado, es el mismo de la vez anterior)

class _NewClassCard extends StatelessWidget {
  final Map<String, dynamic> clase;
  final bool isLoading; 
  final VoidCallback onPressed;

  const _NewClassCard({
    Key? key,
    required this.clase,
    required this.isLoading,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E88E5); 
    const Color accentColor = Color(0xFFFFAB00); 
    final TextTheme textTheme = Theme.of(context).textTheme;

    final int maximo = (clase['maximoParticipantes'] as int?) ?? 0;
    final int cuposDisponibles = (clase['cuposDisponibles'] as int?) ?? 0;
    final int asistentes = maximo - cuposDisponibles;
    
    final List<dynamic> listaDeEspera = (clase['listaDeEspera'] as List<dynamic>?) ?? [];
    final int enEspera = listaDeEspera.length;

    final String horaInicio = clase['horaInicio'] ?? 'HH:MM';
    final String horaFin = clase['horaFin'] ?? 'HH:MM';
    final String nombre = clase['nombre'] ?? 'Nombre de Clase';

    final bool hayCupos = cuposDisponibles > 0;
    final bool sePuedeApuntarEnEspera = !hayCupos; 
    
    Color statusColor = hayCupos ? Colors.green[600]! : (sePuedeApuntarEnEspera ? accentColor : Colors.red[700]!);

    return Card(
      elevation: 5,
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
              Text(
                nombre.toUpperCase(),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoIcon(
                    icon: Icons.access_time_filled_rounded,
                    color: primaryColor,
                    label: 'Hora',
                    value: '$horaInicio - $horaFin',
                  ),
                  _buildInfoIcon(
                    icon: Icons.groups_rounded,
                    color: primaryColor,
                    label: 'Asistentes',
                    value: '$asistentes / $maximo',
                  ),
                  _buildInfoIcon(
                    icon: Icons.hourglass_top_rounded,
                    color: accentColor,
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
                    color: Colors.white,
                  ),
                  label: Text(
                    isLoading ? 'Procesando...' : (hayCupos ? 'Reservar Plaza' : 'Apuntarse en Espera'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  onPressed: isLoading ? null : onPressed, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLoading ? Colors.grey : statusColor,
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

  Widget _buildInfoIcon({
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
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
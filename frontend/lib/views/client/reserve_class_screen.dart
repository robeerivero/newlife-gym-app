import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../viewmodels/reserve_class_viewmodel.dart';

class ReserveClassScreen extends StatelessWidget {
  const ReserveClassScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReserveClassViewModel()..initialize(),
      child: _ReserveClassView(),
    );
  }
}

class _ReserveClassView extends StatefulWidget {
  @override
  State<_ReserveClassView> createState() => _ReserveClassViewState();
}

class _ReserveClassViewState extends State<_ReserveClassView> {
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  Widget build(BuildContext context) {
    return Consumer<ReserveClassViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Reservar Clase', style: TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF1E88E5),
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
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onDaySelected: (selectedDay, focusedDay) {
                  vm.fetchClassesForDate(selectedDay);
                },
                selectedDayPredicate: (day) => isSameDay(day, vm.selectedDate),
              ),
              vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : vm.errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            vm.errorMessage,
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        )
                      : vm.classes.isEmpty
                          ? const Expanded(
                              child: Center(
                                child: Text(
                                  'No hay clases disponibles.',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            )
                          : Expanded(
                              child: ListView.builder(
                                itemCount: vm.classes.length,
                                itemBuilder: (context, index) {
                                  final classItem = vm.classes[index];
                                  return Card(
                                    color: const Color(0xFFE3F2FD),
                                    elevation: 5,
                                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (classItem['nombre'] ?? 'Sin nombre').toUpperCase(),
                                            style: const TextStyle(
                                                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                                          ),
                                          Text('Fecha: ${vm.formatDate(classItem['fecha'])}'),
                                          Text('Hora: ${classItem['horaInicio']}'),
                                          Text('Cupos disponibles: ${classItem['cuposDisponibles']}'),
                                          Text('Lista de espera: ${classItem['listaEspera'].length}'),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: ElevatedButton(
                                              onPressed: vm.isLoading
                                                  ? null
                                                  : () async {
                                                      final success = await vm.reserveClass(classItem['_id']);
                                                      if (success) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Clase reservada con éxito.')),
                                                        );
                                                        if (vm.cancelaciones == 0 && mounted) {
                                                          Navigator.pop(context);
                                                        }
                                                      } else if (vm.errorMessage.isNotEmpty) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text(vm.errorMessage)),
                                                        );
                                                      }
                                                    },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blueAccent,
                                              ),
                                              child: const Text('Reservar'),
                                            ),
                                          ),
                                        ],
                                      ),
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
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/class_viewmodel.dart';
import 'reserve_class_screen.dart';
import 'qr_scan_screen.dart';
import '../../models/clase.dart';

class ClassScreen extends StatefulWidget {
  const ClassScreen({Key? key}) : super(key: key);

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClassViewModel()..fetchNextClasses()..fetchProfile(),
      child: Consumer<ClassViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFE3F2FD),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1E88E5),
              title: const Text('Mis Clases', style: TextStyle(color: Colors.white)),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.white),
                  onPressed: () => vm.logout(context),
                ),
              ],
            ),
            body: Column(
              children: [
                if (vm.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      vm.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                Expanded(
                  child: vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : vm.nextClasses.isEmpty
                          ? const Center(
                              child: Text(
                                'No tienes clases próximas.',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              itemCount: vm.nextClasses.length,
                              itemBuilder: (context, index) {
                                final classItem = vm.nextClasses[index];
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.event_available, color: Color(0xFF42A5F5)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${classItem.dia.toUpperCase()} - ${classItem.horaInicio.toUpperCase()}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1E88E5),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '📅 Fecha: ${vm.formatDate(classItem.fecha)}',
                                          style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                                        ),
                                        Text(
                                          '🏷️ Tipo: ${(classItem.nombre.isNotEmpty ? classItem.nombre : 'Sin nombre').toUpperCase()}',
                                          style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.group, size: 16, color: Colors.green),
                                                const SizedBox(width: 6),
                                                Text('Cupos: ${classItem.cuposDisponibles}'),
                                              ],
                                            ),
                                            const SizedBox(width: 20),
                                            Row(
                                              children: [
                                                const Icon(Icons.people_alt, size: 16, color: Colors.red),
                                                const SizedBox(width: 6),
                                                Text('Asistentes: ${classItem.maximoParticipantes - classItem.cuposDisponibles}'),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () => vm.cancelClass(classItem.id, context),
                                              icon: const Icon(Icons.cancel),
                                              label: const Text('Cancelar'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.redAccent,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              ),
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => QRScanScreen(codigoClase: classItem.id),
                                                  ),
                                                ).then((_) => vm.fetchNextClasses());
                                              },
                                              icon: const Icon(Icons.qr_code_scanner, size: 20),
                                              label: const Text(
                                                'Canjear QR',
                                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.indigoAccent,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(18),
                                                ),
                                                elevation: 3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                if (vm.cancelaciones > 0)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReserveClassScreen(),
                          ),
                        ).then((_) {
                          vm.fetchNextClasses();
                          vm.fetchProfile();
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Reservar una clase'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

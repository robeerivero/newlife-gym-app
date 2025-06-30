import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/diet_viewmodel.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({Key? key}) : super(key: key);

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
      Provider.of<DietViewModel>(context, listen: false)
          .fetchPlatosPorFecha(DateTime.now())
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DietViewModel(),
      child: Consumer<DietViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFE3F2FD),
            appBar: AppBar(
              backgroundColor: const Color(0xFF42A5F5),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('📅 ${vm.formatDate(vm.selectedFecha)}'),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => vm.selectDate(context),
                  ),
                ],
              ),
            ),
            body: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.platos.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay platos para esta fecha.',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      )
                    : ListView.builder(
                        itemCount: vm.platos.length,
                        itemBuilder: (context, index) {
                          final plato = vm.platos[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.restaurant_menu, color: Color(0xFF1E88E5), size: 32),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          plato.comidaDelDia.isNotEmpty
                                              ? plato.comidaDelDia
                                              : 'Sin especificar',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E88E5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      const Icon(Icons.local_dining, color: Colors.deepOrange),
                                      const SizedBox(width: 6),
                                      Text(
                                        plato.nombre.toUpperCase(),
                                        style: const TextStyle(
                                            fontSize: 18, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      const Icon(Icons.whatshot, color: Colors.redAccent, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Calorías: ${plato.kcal > 0 ? plato.kcal : "N/A"} kcal',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 18),
                                      const Icon(Icons.timer, color: Colors.blueGrey, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Prep: ${plato.tiempoPreparacion > 0 ? plato.tiempoPreparacion : "N/A"} min',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20, thickness: 1.2),

                                  const Text('🧂 Ingredientes:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0, top: 2, bottom: 8),
                                    child: Text(
                                      plato.ingredientes.isNotEmpty
                                          ? plato.ingredientes.join(', ')
                                          : 'No especificado',
                                      style: const TextStyle(color: Colors.black87, fontSize: 15),
                                    ),
                                  ),

                                  const Text('📋 Instrucciones:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0, top: 2, bottom: 8),
                                    child: Text(
                                      plato.instrucciones.isNotEmpty
                                          ? plato.instrucciones
                                          : 'N/A',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),

                                  if (plato.observaciones != null && plato.observaciones!.trim().isNotEmpty) ...[
                                    const Text('📝 Observaciones:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0, top: 2),
                                      child: Text(
                                        plato.observaciones!,
                                        style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.grey),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          );
        },
      ),
    );
  }
}

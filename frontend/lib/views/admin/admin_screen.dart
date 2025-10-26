// screens/admin/admin_screen.dart
// ¡ACTUALIZADO!
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
// import '../login/login_screen.dart'; // Ya no es necesario si logout navega
import 'user_management_screen.dart';
import 'class_management_screen.dart';
import 'reservation_management_screen.dart';
// Importa la nueva pantalla de revisión
import 'plan_review_list_screen.dart';
import 'video_management_screen.dart'; // Mantenemos gestión de videos

class AdminScreen extends StatelessWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminViewModel(),
      child: Consumer<AdminViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFE3F2FD),
            appBar: AppBar(
              title: const Text('Panel de Administrador',
                  style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,
                    letterSpacing: 1.2,
                  )),
              backgroundColor: Colors.indigo, // Color Admin
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout), // Icono más estándar para logout
                  tooltip: 'Cerrar Sesión',
                  onPressed: () => vm.logout(context),
                ),
              ],
            ),
            body: ListView( // Usamos ListView directamente
              padding: const EdgeInsets.all(16),
              children: [
                // --- Tarjeta NUEVA: Revisión de Planes ---
                _buildManagementCard(
                  icon: Icons.assignment_turned_in,
                  title: 'Revisar Planes Premium',
                  subtitle: 'Aprobar o editar planes de IA.',
                  color: Colors.deepPurpleAccent, // Color distintivo
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PlanReviewListScreen()),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Tarjetas Existentes que Mantenemos ---
                _buildManagementCard(
                  icon: Icons.people,
                  title: 'Gestionar Usuarios',
                  subtitle: 'Editar usuarios y activar servicios premium.',
                  color: const Color(0xFF42A5F5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                _buildManagementCard(
                  icon: Icons.class_,
                  title: 'Gestionar Clases',
                  subtitle: 'Agregar, editar o eliminar clases presenciales.',
                  color: const Color(0xFF42A5F5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ClassManagementScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                 _buildManagementCard(
                   icon: Icons.book_online,
                   title: 'Gestionar Reservas',
                   subtitle: 'Ver y gestionar reservas de clases.',
                   color: const Color(0xFF42A5F5),
                   onTap: () => Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => const ReservationManagementScreen()),
                   ),
                 ),
                 const SizedBox(height: 20),
                 _buildManagementCard(
                   icon: Icons.video_library,
                   title: 'Gestionar Videos', // Si aún usas videos
                   subtitle: 'Agregar, editar o eliminar Videos.',
                   color: const Color(0xFF42A5F5),
                   onTap: () => Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => const VideoManagementScreen()),
                   ),
                 ),

                // --- Tarjetas ANTIGUAS Eliminadas ---
                // Ya no necesitamos gestionar Rutinas, Platos, Dietas manualmente.
              ],
            ),
          );
        },
      ),
    );
  }

  /// Widget reutilizable para las tarjetas del dashboard.
  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    // (Tu diseño de tarjeta es bueno, lo mantenemos)
    return Card(
      elevation: 4, // Un poco menos de sombra
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Bordes menos pronunciados
      ),
      child: InkWell( // InkWell para efecto ripple al pulsar
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row( // Usamos Row para mejor alineación
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16, // Ligeramente más pequeño
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14, // Ligeramente más pequeño
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16), // Flecha indicadora
            ],
          ),
        ),
      ),
    );
  }
}
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
import '../../viewmodels/plan_review_viewmodel.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Acceso al tema global
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return ChangeNotifierProvider(
      create: (_) => AdminViewModel(),
      child: Consumer<AdminViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            // Eliminado backgroundColor hardcoded -> usa el del tema
            appBar: AppBar(
              title: const Text('Panel de Administrador',
                  style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,
                    letterSpacing: 1.2,
                  )),
              // Eliminado backgroundColor manual -> usa theme.primary
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout), 
                  tooltip: 'Cerrar Sesión',
                  // Mantenemos tu lógica exacta
                  onPressed: () => vm.logout(context),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- Tarjeta: Revisión de Planes ---
                _buildManagementCard(
                  icon: Icons.assignment_turned_in,
                  title: 'Revisar Planes Premium',
                  subtitle: 'Aprobar o editar planes de IA.',
                  color: primary, // Usa color Primario (Teal)
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChangeNotifierProvider(
                      create: (_) => PlanReviewViewModel(),
                      child: const PlanReviewListScreen(),
                    ),
                  ),
                )),
                const SizedBox(height: 12),

                // --- Tarjetas de Gestión ---
                _buildManagementCard(
                  icon: Icons.people,
                  title: 'Gestionar Usuarios',
                  subtitle: 'Editar usuarios y activar servicios premium.',
                  color: secondary, // Usa color Secundario (Naranja)
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _buildManagementCard(
                  icon: Icons.class_,
                  title: 'Gestionar Clases',
                  subtitle: 'Agregar, editar o eliminar clases presenciales.',
                  color: primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ClassManagementScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                 _buildManagementCard(
                   icon: Icons.book_online,
                   title: 'Gestionar Reservas',
                   subtitle: 'Ver y gestionar reservas de clases.',
                   color: secondary,
                   onTap: () => Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => const ReservationManagementScreen()),
                   ),
                 ),
                 const SizedBox(height: 12),
                 _buildManagementCard(
                   icon: Icons.video_library,
                   title: 'Gestionar Videos',
                   subtitle: 'Agregar, editar o eliminar Videos.',
                   color: primary,
                   onTap: () => Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => const VideoManagementScreen()),
                   ),
                 ),
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
    // Usamos el diseño de tarjeta que tenías, pero con los nuevos colores
    return Card(
      elevation: 4, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row( 
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), // Fondo suave
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14, 
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
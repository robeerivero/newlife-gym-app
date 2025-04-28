import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart';
import 'admin/user_management_screen.dart';
import 'admin/class_management_screen.dart';
import 'admin/reservation_management_screen.dart';
import 'admin/plato_management_screen.dart';
import 'admin/diet_management_screens.dart';
import 'admin/rutinas_management_screen.dart';
import 'admin/video_management_screen.dart';

class AdminScreen extends StatelessWidget {
  final _storage = FlutterSecureStorage();

  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'jwt_token');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text('Panel de Administrador',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            )),
        backgroundColor: const Color(0xFF42A5F5),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildManagementCard(
                  icon: Icons.people,
                  title: 'Gestionar Usuarios',
                  subtitle: 'Agregar, editar o eliminar usuarios.',
                  color: const Color(0xFF42A5F5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserManagementScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                _buildManagementCard(
                  icon: Icons.fitness_center,
                  title: 'Gestionar Rutinas',
                  subtitle: 'Crear, editar o eliminar rutinas.',
                  color: const Color(0xFF42A5F5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RutinasManagementScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                _buildManagementCard(
                  icon: Icons.restaurant,
                  title: 'Gestionar Platos',
                  subtitle: 'Agregar, editar o eliminar platos.',
                  color: const Color(0xFF42A5F5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlatoManagementScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                _buildManagementCard(
                  icon: Icons.restaurant_menu, // Icono corregido
                  title: 'Gestionar Dietas',
                  subtitle: 'Agregar, editar o eliminar dietas.',
                  color: const Color(0xFF42A5F5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DietaManagementScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                _buildManagementCard(
                  icon: Icons.book_online,
                  title: 'Gestionar Reservas',
                  subtitle: 'Crear, ver o eliminar reservas.',
                  color: const Color(0xFF42A5F5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReservationManagementScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                _buildManagementCard(
                  icon: Icons.class_,
                  title: 'Gestionar Clases',
                  subtitle: 'Agregar, editar o eliminar clases.',
                  color: const Color(0xFF42A5F5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClassManagementScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                _buildManagementCard(
                  icon: Icons.video_library,
                  title: 'Gestionar Videos',
                  subtitle: 'Agregar, editar o eliminar Videos.',
                  color: const Color(0xFF42A5F5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoManagementScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 30,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 40, color: color),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 55),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Acceder',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
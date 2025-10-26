import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../fluttermoji/fluttermojiCircleAvatar.dart';
import '../../fluttermoji/fluttermojiCustomizer.dart';
import '../../fluttermoji/fluttermojiFunctions.dart';
import 'edit_profile_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../modals/ranking_modal.dart';
import '../modals/logros_modal.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, vm, child) {
        final usuario = vm.usuario;
        return Scaffold(
          backgroundColor: const Color(0xFFE3F2FD),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E88E5),
            title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => _showSettingsDialog(context, vm),
              ),
            ],
          ),
          body: vm.loading
              ? const Center(child: CircularProgressIndicator())
              : usuario == null
                  ? Center(child: Text(vm.error ?? 'Error'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                      child: Center(
                        child: Card(
                          elevation: 12,
                          margin: const EdgeInsets.only(top: 20, bottom: 28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (vm.error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Text(vm.error!,
                                        style: const TextStyle(color: Colors.red, fontSize: 16)),
                                  ),
                                // AVATAR
                                FluttermojiCircleAvatar(
                                  backgroundColor: Colors.blue[50],
                                  radius: 70,
                                  avatarJson: vm.avatarJson,
                                ),
                                const SizedBox(height: 18),
                                // NOMBRE
                                Text(
                                  usuario.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: Color(0xFF1E88E5),
                                  ),
                                ),
                                // EMAIL
                                Text(
                                  usuario.correo,
                                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                                ),                                  
                                const SizedBox(height: 14),
                                // BOTÓN EDITAR AVATAR
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.face, size: 22),
                                  label: const Text("Editar avatar"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF42A5F5),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  onPressed: () async {
                                    // Consulta prendas desbloqueadas
                                    Map<String, Set<int>> prendasDesbloqueadas = {};
                                    try {
                                      prendasDesbloqueadas = await vm.fetchPrendasDesbloqueadas();
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Error al cargar tus prendas desbloqueadas')),
                                        );
                                      }
                                      return;
                                    }
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FluttermojiCustomizer(
                                          prendasDesbloqueadasPorAtributo: prendasDesbloqueadas,
                                        ),
                                      ),
                                    );
                                    final avatarJsonNew = await FluttermojiFunctions().encodeMySVGtoString();
                                    final success = await vm.guardarAvatar(avatarJsonNew);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(success ? 'Avatar actualizado' : 'Error al guardar el avatar'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 18),
                                // BOTÓN RANKING
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => RankingModal(),
                                    );
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 5,
                                    child: ListTile(
                                      leading: Icon(Icons.emoji_events, color: Colors.amber, size: 40),
                                      title: Text('Ranking mensual'),
                                      subtitle: Text('¿Quién va primero en la liga este mes?'),
                                      trailing: Icon(Icons.arrow_forward_ios),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // BOTÓN LOGROS
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => LogrosModal(userId: usuario.id),
                                    );
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 5,
                                    child: ListTile(
                                      leading: Icon(Icons.stars, color: Colors.blue, size: 40),
                                      title: Text('Logros y recompensas'),
                                      subtitle: Text('¡Descubre qué has desbloqueado!'),
                                      trailing: Icon(Icons.arrow_forward_ios),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext context, ProfileViewModel vm) {
    final usuario = vm.usuario;
    if (usuario == null) return;

    final tipoPrincipal = usuario.tiposDeClases.isNotEmpty
        ? usuario.tiposDeClases.first
        : 'General';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: Colors.deepPurple),
                title: const Text('Hablar con el asistente'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatBotScreen(section: tipoPrincipal),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF1E88E5)),
                title: const Text('Editar perfil'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        initialName: usuario.nombre,
                        initialEmail: usuario.correo,
                        initialTiposDeClases: usuario.tiposDeClases,
                      ),
                    ),
                  );
                  if (result == true) vm.fetchProfile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Cerrar sesión'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await vm.logout(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

}

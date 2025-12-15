import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Necesario para obtener el JSON real

import '../../viewmodels/profile_viewmodel.dart';
// Imports de tu implementación local
import '../../fluttermoji/fluttermojiCircleAvatar.dart';
import '../../fluttermoji/fluttermojiCustomizer.dart';
import '../../fluttermoji/fluttermojiFunctions.dart'; // Importamos esto por si acaso queremos usar el encoder explícitamente, aunque usamos prefs

import 'edit_profile_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../modals/ranking_modal.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtenemos los colores del tema actual (definidos en AppTheme)
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<ProfileViewModel>(
      builder: (context, vm, child) {
        final usuario = vm.usuario;
        
        return Scaffold(
          // No definimos backgroundColor fijo, usamos el del tema (gris suave)
          appBar: AppBar(
            // El color se toma automáticamente del AppBarTheme (Teal Primary)
            title: const Text('Mi Perfil'), 
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
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
                          elevation: 8, // Un poco menos de elevación para que se vea más limpio
                          margin: const EdgeInsets.only(top: 20, bottom: 28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          // El color de la tarjeta viene del tema (Blanco)
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (vm.error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Text(vm.error!,
                                        style: TextStyle(color: colorScheme.error, fontSize: 16)),
                                  ),
                                
                                // --- AVATAR ---
                                FluttermojiCircleAvatar(
                                  // Usamos un tono muy suave del primario (Teal) de fondo
                                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                                  radius: 70,
                                  // Usamos el JSON del VM para que se actualice al volver de editar
                                  avatarJson: vm.avatarJson,
                                ),
                                
                                const SizedBox(height: 18),
                                
                                // --- NOMBRE ---
                                Text(
                                  usuario.nombre,
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontSize: 22,
                                    color: colorScheme.primary, // Teal Oscuro
                                  ),
                                ),
                                
                                // --- EMAIL ---
                                Text(
                                  usuario.correo,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                    fontSize: 16
                                  ),
                                ),                                  
                                const SizedBox(height: 14),
                                
                                // --- BOTÓN EDITAR AVATAR ---
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.face, size: 22),
                                  label: const Text("Editar avatar"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary, // Teal
                                    foregroundColor: colorScheme.onPrimary, // Blanco
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  onPressed: () async {
                                    // 1. Abrir el Editor (Sin lógica de prendas desbloqueadas)
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => Scaffold(
                                          appBar: AppBar(
                                            title: const Text("Personalizar"),
                                            // Hereda el tema, no hace falta forzar color
                                          ),
                                          body: FluttermojiCustomizer(
                                            autosave: true, 
                                          ),
                                        ),
                                      ),
                                    );
                                    
                                    // 2. RECUPERAR DATOS Y GUARDAR
                                    // Leemos lo que el editor guardó en las preferencias (JSON de opciones)
                                    final prefs = await SharedPreferences.getInstance();
                                    final String? avatarConfig = prefs.getString('fluttermojiSelectedOptions');

                                    if (avatarConfig != null) {
                                      // Enviamos esa configuración (JSON) al backend
                                      final success = await vm.guardarAvatar(avatarConfig);
                                      
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(success ? 'Avatar actualizado' : 'Error al guardar el avatar'),
                                            backgroundColor: success ? Colors.green : colorScheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                
                                const SizedBox(height: 18),
                                
                                // --- BOTÓN RANKING ---
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => RankingModal(),
                                    );
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 4,
                                    shadowColor: Colors.black26,
                                    child: ListTile(
                                      // Usamos el color secundario (Naranja) para destacar eventos/premios
                                      leading: Icon(Icons.emoji_events, color: colorScheme.secondary, size: 40),
                                      title: const Text('Ranking mensual'),
                                      subtitle: const Text('¿Quién va primero en la liga este mes?'),
                                      trailing: Icon(Icons.arrow_forward_ios, color: colorScheme.primary),
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
    final colorScheme = Theme.of(context).colorScheme;

    final tipoPrincipal = usuario.tiposDeClases.isNotEmpty
        ? usuario.tiposDeClases.first
        : 'General';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          // El color de fondo del sheet viene del tema, pero forzamos blanco si prefieres
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10), // Pequeño espacio superior
              ListTile(
                leading: Icon(Icons.chat_bubble_outline, color: colorScheme.primary),
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
                leading: Icon(Icons.person, color: colorScheme.primary),
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
                leading: Icon(Icons.logout, color: colorScheme.error),
                title: const Text('Cerrar sesión'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await vm.logout(context);
                },
              ),
              const SizedBox(height: 20), // Espacio inferior seguro
            ],
          ),
        );
      },
    );
  }
}
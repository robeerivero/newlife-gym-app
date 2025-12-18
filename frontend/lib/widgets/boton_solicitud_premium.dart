import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_viewmodel.dart';

class BotonSolicitudPremium extends StatelessWidget {
  const BotonSolicitudPremium({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Escuchamos el ProfileViewModel
    final profileVM = context.watch<ProfileViewModel>();
    final usuario = profileVM.usuario;

    if (usuario == null) return const SizedBox.shrink();

    // 1. CASO: Ya es Premium
    if (usuario.esPremium) {
      return _buildEstadoContainer(
        context, 
        icon: Icons.star, 
        color: Colors.amber, 
        text: "¡Eres miembro Premium!",
        bgColor: Colors.amber.withOpacity(0.1)
      );
    }

    // 2. CASO: Ya solicitó (Pendiente)
    if (usuario.solicitudPremium != null) {
      return _buildEstadoContainer(
        context, 
        icon: Icons.hourglass_top, 
        color: Colors.blueGrey, 
        text: "Solicitud en revisión...",
        bgColor: Colors.blueGrey.withOpacity(0.1)
      );
    }

    // 3. CASO: Solicitar (Botón activo)
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black, // Color primario
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: profileVM.isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : const Icon(Icons.rocket_launch),
        label: Text(profileVM.isLoading ? "Enviando..." : "SOLICITAR PLAN PREMIUM"),
        onPressed: profileVM.isLoading ? null : () async {
          final success = await context.read<ProfileViewModel>().solicitarPremium();

          if (context.mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Solicitud enviada!'), backgroundColor: Colors.green),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error al enviar solicitud.'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildEstadoContainer(BuildContext context, {required IconData icon, required Color color, required String text, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/edit_profile_viewmodel.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;

  const EditProfileScreen({
    Key? key,
    required this.initialName,
    required this.initialEmail,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditProfileViewModel(),
      child: Consumer<EditProfileViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFE3F2FD),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1E88E5),
              elevation: 0,
              title: const Text("Editar Perfil", style: TextStyle(color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    child: Center(
                      child: Card(
                        elevation: 10,
                        margin: const EdgeInsets.only(top: 18, bottom: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (vm.error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 14.0),
                                    child: Text(vm.error!,
                                        style: const TextStyle(color: Colors.red, fontSize: 15)),
                                  ),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Nombre',
                                    prefixIcon: Icon(Icons.person, color: Color(0xFF1E88E5)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    filled: true,
                                    fillColor: Colors.blue[50],
                                  ),
                                  validator: (v) =>
                                      v == null || v.isEmpty ? 'Campo obligatorio' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Correo electrónico',
                                    prefixIcon: Icon(Icons.email, color: Color(0xFF1E88E5)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    filled: true,
                                    fillColor: Colors.blue[50],
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Campo obligatorio';
                                    final emailRegex = RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$");
                                    if (!emailRegex.hasMatch(v)) return 'Formato de correo no válido';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Cambiar contraseña",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _currentPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña actual',
                                    prefixIcon: Icon(Icons.lock_outline, color: Colors.blueGrey),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                  ),
                                  obscureText: true,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _newPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Nueva contraseña',
                                    prefixIcon: Icon(Icons.vpn_key_rounded, color: Colors.blueGrey),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                  ),
                                  obscureText: true,
                                ),
                                const SizedBox(height: 26),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.save_alt_rounded, color: Colors.white),
                                    label: const Text("Guardar cambios", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E88E5),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      elevation: 5,
                                    ),
                                    onPressed: () async {
                                      if (!_formKey.currentState!.validate()) return;
                                      // 1. Editar nombre/email
                                      final success = await vm.editarPerfil(
                                        nombre: _nameController.text,
                                        correo: _emailController.text,
                                      );
                                      if (!success) return;
                                      // 2. Cambiar contraseña (si corresponde)
                                      if (_currentPasswordController.text.isNotEmpty &&
                                          _newPasswordController.text.isNotEmpty) {
                                        final passSuccess = await vm.cambiarContrasena(
                                          _currentPasswordController.text,
                                          _newPasswordController.text,
                                        );
                                        if (!passSuccess) return;
                                      }
                                      if (mounted) Navigator.of(context).pop(true);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

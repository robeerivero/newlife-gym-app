// screens/client/edit_profile_screen.dart
// ¡ACTUALIZADO! Pasa 'tiposDeClases' al ViewModel.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/edit_profile_viewmodel.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final List<String> initialTiposDeClases; // <-- ¡NUEVO!

  const EditProfileScreen({
    Key? key,
    required this.initialName,
    required this.initialEmail,
    required this.initialTiposDeClases, // <-- ¡NUEVO!
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
  final _confirmPasswordController = TextEditingController();

  // --- ¡NUEVO! ---
  // Guardamos los tipos de clase actuales (puede que no los edites aquí,
  // pero el servicio los necesita para la actualización)
  late List<String> _currentTiposDeClases;
  // --- FIN NUEVO ---


  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _currentTiposDeClases = List.from(widget.initialTiposDeClases); // Copia la lista inicial
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
              title: const Text('Editar Perfil', style: TextStyle(color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Sección Datos Básicos ---
                    Text('Datos Personales', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person)),
                      validator: (value) => value == null || value.isEmpty ? 'Ingresa tu nombre' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Correo Electrónico', prefixIcon: Icon(Icons.email)),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingresa tu correo';
                        if (!value.contains('@') || !value.contains('.')) return 'Correo inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // --- Sección Cambio de Contraseña (Opcional) ---
                     Text('Cambiar Contraseña (Opcional)', style: Theme.of(context).textTheme.headlineSmall),
                     const SizedBox(height: 15),
                    TextFormField(
                      controller: _currentPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña Actual',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                      obscureText: _obscureCurrent,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña',
                         prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      obscureText: _obscureNew,
                      validator: (value) {
                        if (_currentPasswordController.text.isNotEmpty && (value == null || value.length < 6)) {
                          return 'La nueva contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Nueva Contraseña',
                         prefixIcon: const Icon(Icons.lock_clock),
                         suffixIcon: IconButton(
                           icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                           onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                         ),
                      ),
                      obscureText: _obscureConfirm,
                      validator: (value) {
                        if (_newPasswordController.text.isNotEmpty && value != _newPasswordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                     const SizedBox(height: 30),

                    // --- Mensaje de Error ---
                    if (vm.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Text(vm.error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),

                    // --- Botón Guardar ---
                    ElevatedButton.icon(
                      icon: vm.loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Icon(Icons.save),
                      label: Text(vm.loading ? 'Guardando...' : 'Guardar Cambios'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: vm.loading ? null : () async {
                        if (!_formKey.currentState!.validate()) return; // No válido

                        bool profileSuccess = true; // Asume éxito si no hay cambios
                        bool passwordSuccess = true; // Asume éxito si no se intenta cambiar

                        // 1. Guarda perfil básico si cambió
                        if (_nameController.text != widget.initialName || _emailController.text != widget.initialEmail) {
                          profileSuccess = await vm.editarPerfilBasico(
                            nombre: _nameController.text,
                            correo: _emailController.text,
                            tiposDeClases: _currentTiposDeClases // <-- ¡AÑADIDO! Pasa la lista
                          );
                        }


                        // 2. Cambia contraseña si se rellenaron los campos
                        if (_currentPasswordController.text.isNotEmpty && _newPasswordController.text.isNotEmpty) {
                          passwordSuccess = await vm.cambiarContrasena(
                             _currentPasswordController.text,
                             _newPasswordController.text,
                           );
                        }

                        // 3. Muestra resultado y cierra si todo OK
                        if (profileSuccess && passwordSuccess && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Perfil actualizado con éxito.'), backgroundColor: Colors.green),
                          );
                          Navigator.of(context).pop(true); // Devuelve true para indicar que hubo cambios
                        } else if (!profileSuccess && mounted){
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text(vm.error ?? 'Error al guardar perfil.'), backgroundColor: Colors.red),
                           );
                        } else if (!passwordSuccess && mounted){
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text(vm.error ?? 'Error al cambiar contraseña.'), backgroundColor: Colors.red),
                           );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
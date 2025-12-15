// screens/client/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/edit_profile_viewmodel.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final List<String> initialTiposDeClases; 

  const EditProfileScreen({
    Key? key,
    required this.initialName,
    required this.initialEmail,
    required this.initialTiposDeClases,
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

  late List<String> _currentTiposDeClases;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _currentTiposDeClases = List.from(widget.initialTiposDeClases);
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
          final colorScheme = Theme.of(context).colorScheme;

          return Scaffold(
            // backgroundColor: eliminado (Theme default)
            appBar: AppBar(
              // backgroundColor: eliminado (Theme default)
              title: const Text('Editar Perfil'),
              // iconTheme: eliminado (Theme default)
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Sección Datos Básicos ---
                    Text('Datos Personales', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: colorScheme.primary)),
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
                     Text('Cambiar Contraseña (Opcional)', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: colorScheme.primary)),
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
                        child: Text(vm.error!, style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                      ),

                    // --- Botón Guardar ---
                    ElevatedButton.icon(
                      icon: vm.loading 
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 3)) 
                          : const Icon(Icons.save),
                      label: Text(vm.loading ? 'Guardando...' : 'Guardar Cambios'),
                      style: ElevatedButton.styleFrom(
                        // Eliminado backgroundColor fijo, hereda Primary del tema
                        // Eliminado foregroundColor fijo, hereda onPrimary del tema
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: vm.loading ? null : () async {
                        if (!_formKey.currentState!.validate()) return; 

                        bool profileSuccess = true; 
                        bool passwordSuccess = true; 

                        // 1. Guarda perfil básico si cambió
                        if (_nameController.text != widget.initialName || _emailController.text != widget.initialEmail) {
                          profileSuccess = await vm.editarPerfilBasico(
                            nombre: _nameController.text,
                            correo: _emailController.text,
                            tiposDeClases: _currentTiposDeClases 
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
                             SnackBar(content: Text(vm.error ?? 'Error al guardar perfil.'), backgroundColor: colorScheme.error),
                           );
                        } else if (!passwordSuccess && mounted){
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text(vm.error ?? 'Error al cambiar contraseña.'), backgroundColor: colorScheme.error),
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
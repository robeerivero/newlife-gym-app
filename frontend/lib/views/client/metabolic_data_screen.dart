// screens/client/metabolic_data_screen.dart
// ¡ACTUALIZADO!
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/usuario.dart';
import '../../viewmodels/metabolic_viewmodel.dart';

class MetabolicDataScreen extends StatefulWidget {
  final Usuario usuario; // Recibe el usuario completo
  const MetabolicDataScreen({Key? key, required this.usuario}) : super(key: key);

  @override
  State<MetabolicDataScreen> createState() => _MetabolicDataScreenState();
}

class _MetabolicDataScreenState extends State<MetabolicDataScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _pesoController;
  late TextEditingController _alturaController;
  late TextEditingController _edadController;
  String? _genero;
  String? _nivelActividad;
  String? _objetivo;

  // Opciones para los Dropdowns
  final List<DropdownMenuItem<String>> _generoItems = const [
    DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
    DropdownMenuItem(value: 'femenino', child: Text('Femenino')),
  ];
  final List<DropdownMenuItem<String>> _nivelActividadItems = const [
    DropdownMenuItem(value: 'sedentario', child: Text('Sedentario (poco o nada)')),
    DropdownMenuItem(value: 'ligero', child: Text('Ligero (1-3 días/sem)')),
    DropdownMenuItem(value: 'moderado', child: Text('Moderado (3-5 días/sem)')),
    DropdownMenuItem(value: 'activo', child: Text('Activo (6-7 días/sem)')),
    DropdownMenuItem(value: 'muy_activo', child: Text('Muy Activo (2 veces/día)')),
  ];
  final List<DropdownMenuItem<String>> _objetivoItems = const [
    DropdownMenuItem(value: 'perder', child: Text('Perder Peso')),
    DropdownMenuItem(value: 'mantener', child: Text('Mantener Peso')),
    DropdownMenuItem(value: 'ganar', child: Text('Ganar Masa Muscular')),
  ];

  late MetabolicViewModel _viewModel; // Guardamos referencia al VM

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _pesoController = TextEditingController(text: u.peso.toStringAsFixed(1));
    _alturaController = TextEditingController(text: u.altura.toStringAsFixed(0));
    _edadController = TextEditingController(text: u.edad.toString());
    _genero = u.genero;
    _nivelActividad = u.nivelActividad;
    _objetivo = u.objetivo;

    // Creamos el ViewModel aquí para pasarle el estado premium
    _viewModel = MetabolicViewModel();
    _viewModel.setIsPremium(u.esPremium);
  }

   @override
  void dispose() {
    _pesoController.dispose();
    _alturaController.dispose();
    _edadController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // Usamos ChangeNotifierProvider.value para pasar el VM ya creado
    return ChangeNotifierProvider.value(
       value: _viewModel,
      child: Consumer<MetabolicViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFE3F2FD),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1E88E5),
              title: const Text('Mis Datos Metabólicos', style: TextStyle(color: Colors.white)),
               iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Campos ---
                    _buildTextField(
                      controller: _pesoController,
                      label: 'Peso (kg)',
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))], // Permite un decimal
                      validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Peso inválido' : null,
                    ),
                    const SizedBox(height: 15),
                     _buildTextField(
                      controller: _alturaController,
                      label: 'Altura (cm)',
                      icon: Icons.height,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Altura inválida' : null,
                    ),
                    const SizedBox(height: 15),
                     _buildTextField(
                      controller: _edadController,
                      label: 'Edad',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                       validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Edad inválida' : null,
                    ),
                    const SizedBox(height: 15),
                     _buildDropdown(
                       label: 'Género',
                       value: _genero,
                       items: _generoItems,
                       onChanged: (val) => setState(() => _genero = val),
                       icon: Icons.wc,
                     ),
                    const SizedBox(height: 15),
                     _buildDropdown(
                       label: 'Nivel de Actividad Física',
                       value: _nivelActividad,
                       items: _nivelActividadItems,
                       onChanged: (val) => setState(() => _nivelActividad = val),
                       icon: Icons.directions_run,
                     ),
                    const SizedBox(height: 15),
                    _buildDropdown(
                       label: 'Objetivo Principal',
                       value: _objetivo,
                       items: _objetivoItems,
                       onChanged: (val) => setState(() => _objetivo = val),
                       icon: Icons.flag_outlined,
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
                      icon: vm.loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Icon(Icons.calculate),
                      label: Text(vm.loading ? 'Calculando...' : 'Calcular y Guardar Kcal'),
                       style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: vm.loading ? null : () => _submitForm(context, vm),
                    ),
                    const SizedBox(height: 15),

                     // --- Resultado Kcal ---
                    if (vm.kcalResult > 0)
                      Center(
                        child: Text(
                          'Tu objetivo calórico diario es: ${vm.kcalResult} Kcal',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green[800]),
                        ),
                      )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

   // --- Widgets Helper ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.blue[50],
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.blue[50],
      ),
      validator: (value) => value == null ? 'Selecciona una opción' : null,
    );
  }

  // --- Lógica de envío ---
  void _submitForm(BuildContext context, MetabolicViewModel vm) async {
    if (!_formKey.currentState!.validate()) {
      return; // No válido
    }

    final success = await vm.guardarDatos({
      "genero": _genero,
      "peso": _pesoController.text,
      "altura": _alturaController.text,
      "edad": _edadController.text,
      "nivelActividad": _nivelActividad,
      "objetivo": _objetivo,
    });

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.getSuccessMessage()), // Usa el mensaje del VM
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4), // Más tiempo para leer el mensaje extra
        ),
      );
      // Opcional: Cerrar la pantalla después de guardar
      Navigator.pop(context, true); // Devuelve true para indicar cambios
    } else if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.error ?? 'Error desconocido al guardar.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
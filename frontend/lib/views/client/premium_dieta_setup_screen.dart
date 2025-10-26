// screens/client/premium_dieta_setup_screen.dart
// ¡ESTILO DEFINITIVO + FIX DE OVERFLOW!

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/usuario.dart';
import '../../services/ia_dieta_service.dart';

class PremiumDietaSetupScreen extends StatefulWidget {
  final Usuario usuario;
  const PremiumDietaSetupScreen({Key? key, required this.usuario}) : super(key: key);

  @override
  State<PremiumDietaSetupScreen> createState() => _PremiumDietaSetupScreenState();
}

class _PremiumDietaSetupScreenState extends State<PremiumDietaSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Servicios ---
  final IADietaService _dietaService = IADietaService();

  // --- Controllers (Metabólicos) ---
  late TextEditingController _pesoController;
  late TextEditingController _alturaController;
  late TextEditingController _edadController;
  String? _genero;
  String? _nivelActividad;
  String? _objetivo;

  // --- Controllers (Preferencias Dieta) ---
  late TextEditingController _alergiasController;
  late TextEditingController _preferenciasController;
  int _numComidas = 4;

  // --- Estado de UI ---
  bool _isLoading = false;
  String? _error;
  String? _estadoPlan; 
  
  bool get puedeSolicitar => _estadoPlan == 'pendiente_solicitud' || _estadoPlan == null;

  @override
  void initState() {
    super.initState();
    _initializeState();
    _fetchPlanStatus(); 
  }

  void _initializeState() {
    // Datos Metabólicos
    _pesoController = TextEditingController(text: widget.usuario.peso.toStringAsFixed(1));
    _alturaController = TextEditingController(text: widget.usuario.altura.toStringAsFixed(0));
    _edadController = TextEditingController(text: widget.usuario.edad.toString());
    _genero = widget.usuario.genero;
    _nivelActividad = widget.usuario.nivelActividad;
    _objetivo = widget.usuario.objetivo;

    // Preferencias de Dieta
    _alergiasController = TextEditingController(text: widget.usuario.dietaAlergias);
    _preferenciasController = TextEditingController(text: widget.usuario.dietaPreferencias);
    _numComidas = widget.usuario.dietaComidas;
  }
  
  Future<void> _fetchPlanStatus() async {
    setState(() => _isLoading = true);
    try {
      final estado = await _dietaService.obtenerEstadoPlanDelMes();
      setState(() {
        _estadoPlan = estado;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar estado: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Map<String, dynamic> datosFormulario = {
        'peso': double.tryParse(_pesoController.text) ?? widget.usuario.peso,
        'altura': double.tryParse(_alturaController.text) ?? widget.usuario.altura,
        'edad': int.tryParse(_edadController.text) ?? widget.usuario.edad,
        'genero': _genero,
        'nivelActividad': _nivelActividad,
        'objetivo': _objetivo,
        'dietaAlergias': _alergiasController.text.trim(),
        'dietaPreferencias': _preferenciasController.text.trim(),
        'dietaComidas': _numComidas,
      };

      bool exito = await _dietaService.solicitarPlanDieta(datosFormulario);

      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferencias enviadas. Tu nutricionista las revisará.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isLoading = false;
          _estadoPlan = 'pendiente_revision'; 
        });
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Error en el servidor al enviar la solicitud.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Color principal del estilo
    const Color colorPrimario = Color(0xFF1E88E5);

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), 
      appBar: AppBar(
        title: const Text('Preferencias de Dieta', style: TextStyle(color: Colors.white)),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading && _estadoPlan == null
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Datos Metabólicos',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorPrimario),
                            textAlign: TextAlign.center,
                          ),
                          const Text('Se usan para calcular tus calorías base.', textAlign: TextAlign.center),
                          const SizedBox(height: 20),

                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14.0),
                              child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'Peso (kg)',
                                  controller: _pesoController,
                                  icon: Icons.monitor_weight_outlined,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTextField(
                                  label: 'Altura (cm)',
                                  controller: _alturaController,
                                  icon: Icons.height_outlined,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'Edad',
                                  controller: _edadController,
                                  icon: Icons.cake_outlined,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Género',
                                  value: _genero,
                                  items: const [
                                    DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
                                    DropdownMenuItem(value: 'femenino', child: Text('Femenino')),
                                  ],
                                  icon: Icons.wc_outlined,
                                  onChanged: (val) => setState(() => _genero = val),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildDropdownField(
                            label: 'Nivel de Actividad',
                            value: _nivelActividad,
                            items: const [
                              DropdownMenuItem(value: 'sedentario', child: Text('Sedentario (oficina)')),
                              DropdownMenuItem(value: 'ligero', child: Text('Ligero (1-3 días/sem)')),
                              DropdownMenuItem(value: 'moderado', child: Text('Moderado (3-5 días/sem)')),
                              DropdownMenuItem(value: 'activo', child: Text('Activo (6-7 días/sem)')),
                              DropdownMenuItem(value: 'muy_activo', child: Text('Muy Activo (trabajo físico)')),
                            ],
                            icon: Icons.directions_run_outlined,
                            onChanged: (val) => setState(() => _nivelActividad = val),
                          ),
                          const SizedBox(height: 16),

                          _buildDropdownField(
                            label: 'Objetivo Principal',
                            value: _objetivo,
                            items: const [
                              DropdownMenuItem(value: 'perder', child: Text('Perder peso')),
                              DropdownMenuItem(value: 'mantener', child: Text('Mantener peso')),
                              DropdownMenuItem(value: 'ganar', child: Text('Ganar masa muscular')),
                            ],
                            icon: Icons.flag_outlined,
                            onChanged: (val) => setState(() => _objetivo = val),
                          ),

                          const Divider(height: 32),

                          Text(
                            'Preferencias de Dieta',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorPrimario),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            label: 'Alergias o Restricciones',
                            hintText: 'Ej: Lactosa, gluten, "no como pescado"',
                            controller: _alergiasController,
                            icon: Icons.no_food_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            label: 'Preferencias Generales',
                            hintText: 'Ej: "Me gusta la comida simple", "vegetariano"',
                            controller: _preferenciasController,
                            icon: Icons.restaurant_menu_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          
                          Text('Comidas por día: $_numComidas', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,),
                          Slider(
                            value: _numComidas.toDouble(),
                            min: 2, max: 6, divisions: 4,
                            label: '$_numComidas comidas',
                            activeColor: colorPrimario,
                            onChanged: puedeSolicitar ? (val) => setState(() => _numComidas = val.round()) : null,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          ElevatedButton.icon(
                            icon: Icon(_isLoading ? Icons.sync : Icons.save_alt_rounded, color: Colors.white),
                            label: Text(
                              _isLoading 
                                ? 'Procesando...' 
                                : (puedeSolicitar ? 'Enviar Preferencias' : 'Tu plan está en revisión'),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorPrimario,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 5,
                            ),
                            onPressed: _isLoading || !puedeSolicitar ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // --- Helpers de Widgets (ESTILO ACTUALIZADO) ---

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: puedeSolicitar,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.blue[50],
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Requerido';
        }
        if (keyboardType.toString().contains('number')) {
           if (double.tryParse(value) == null || double.parse(value) <= 0) {
             return 'Valor > 0';
           }
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: puedeSolicitar ? onChanged : null,
      
      // --- ¡¡FIX DE OVERFLOW AÑADIDO!! ---
      isExpanded: true, 
      // ---------------------------------

      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.blue[50],
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
    );
  }
}
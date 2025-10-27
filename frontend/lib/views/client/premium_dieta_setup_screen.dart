// screens/client/premium_dieta_setup_screen.dart
// ¡¡VERSIÓN FINAL!! Lógica de _submit corregida + Estilo de diet_display

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/usuario.dart';
import '../../services/ia_dieta_service.dart';
import '../../services/user_service.dart'; // Importar UserService

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
  final UserService _userService = UserService(); // ¡Importante!

  // --- Controllers (Metabólicos) ---
  late TextEditingController _pesoController;
  late TextEditingController _alturaController;
  late TextEditingController _edadController;
  String? _genero;
  String? _ocupacion;
  String? _ejercicio;
  String? _objetivo;
  int _kcalObjetivo = 0; 

  // --- Controllers (Preferencias Dieta) ---
  late TextEditingController _alergiasController;
  late TextEditingController _preferenciasController;
  late TextEditingController _historialMedicoController; 
  late TextEditingController _horariosController;        
  late TextEditingController _platosFavoritosController; 
  int _numComidas = 4;

  // --- Estado de UI ---
  bool _isLoading = false;
  String? _error;
  String? _estadoPlan; 
  
  bool get puedeSolicitar => _estadoPlan == 'pendiente_solicitud' || _estadoPlan == null;

  // --- Colores del Tema ---
  static const Color _colorFondo = Color(0xFFE3F2FD); // Azul claro (de diet_display)
  static const Color _colorAppBar = Color(0xFF1E88E5); // Azul primario (de diet_display)
  static const Color _colorIconos = Color(0xFF1E88E5); // Iconos de campos
  static const Color _colorCampos = Colors.white;     // Fondo de campos

  @override
  void initState() {
    super.initState();
    _initializeState();
    _fetchPlanStatus(); 
  }

  void _initializeState() {
    // Metabólicos
    _pesoController = TextEditingController(text: widget.usuario.peso.toStringAsFixed(1));
    _alturaController = TextEditingController(text: widget.usuario.altura.toStringAsFixed(0));
    _edadController = TextEditingController(text: widget.usuario.edad.toString());
    _genero = widget.usuario.genero;
    _ocupacion = widget.usuario.ocupacion;
    _ejercicio = widget.usuario.ejercicio;
    _objetivo = widget.usuario.objetivo;
    _kcalObjetivo = widget.usuario.kcalObjetivo; 

    // Preferencias
    _alergiasController = TextEditingController(text: widget.usuario.dietaAlergias);
    _preferenciasController = TextEditingController(text: widget.usuario.dietaPreferencias);
    _numComidas = widget.usuario.dietaComidas;
    _historialMedicoController = TextEditingController(text: widget.usuario.historialMedico);
    _horariosController = TextEditingController(text: widget.usuario.horarios);
    _platosFavoritosController = TextEditingController(text: widget.usuario.platosFavoritos);
  }
  
  @override
  void dispose() {
    _pesoController.dispose();
    _alturaController.dispose();
    _edadController.dispose();
    _alergiasController.dispose();
    _preferenciasController.dispose();
    _historialMedicoController.dispose();
    _horariosController.dispose();
    _platosFavoritosController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchPlanStatus() async {
    setState(() => _isLoading = true);
    try {
      final estado = await _dietaService.obtenerEstadoPlanDelMes();
      setState(() { _estadoPlan = estado; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Error al cargar estado: $e'; _isLoading = false; });
    }
  }

  // =================================================================
  //                 FUNCIÓN _submit CORREGIDA
  // =================================================================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      // --- PASO 1: Actualizar Datos Metabólicos y recalcular Kcal ---
      final Map<String, dynamic> datosMetabolicos = {
        'peso': double.tryParse(_pesoController.text) ?? widget.usuario.peso,
        'altura': double.tryParse(_alturaController.text) ?? widget.usuario.altura,
        'edad': int.tryParse(_edadController.text) ?? widget.usuario.edad,
        'genero': _genero,
        'ocupacion': _ocupacion,
        'ejercicio': _ejercicio,
        'objetivo': _objetivo,
      };

      // --- ¡¡LÍNEAS RE-AÑADIDAS!! ---
      // Llamamos a UserService para actualizar y recalcular
      final respuestaKcal = await _userService.actualizarDatosMetabolicos(datosMetabolicos);
      if (respuestaKcal == null) {
        throw Exception('Error al actualizar datos metabólicos');
      }

      // Usamos las Kcal recién calculadas
      final int nuevasKcal = respuestaKcal['kcalObjetivo'] ?? _kcalObjetivo;
      setState(() => _kcalObjetivo = nuevasKcal); 
      // --- FIN DE LA CORRECCIÓN ---

      // --- PASO 2: Solicitar el Plan de Dieta con TODOS los datos ---
      final Map<String, dynamic> datosSolicitud = {
        ...datosMetabolicos, 
        'kcalObjetivo': nuevasKcal, // <-- Se usan las nuevas Kcal
        
        // Preferencias
        'dietaAlergias': _alergiasController.text.trim(),
        'dietaPreferencias': _preferenciasController.text.trim(),
        'dietaComidas': _numComidas,
        'historialMedico': _historialMedicoController.text.trim(),
        'horarios': _horariosController.text.trim(),
        'platosFavoritos': _platosFavoritosController.text.trim(),
      };

      final bool solicitado = await _dietaService.solicitarPlanDieta(datosSolicitud);

      if (solicitado) {
        setState(() { _isLoading = false; _estadoPlan = 'pendiente_revision'; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar( content: Text('¡Plan solicitado con éxito! Será revisado.'), backgroundColor: Colors.green, ),
          );
        }
      } else {
        throw Exception('Error al solicitar el plan de dieta');
      }

    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar( content: Text(_error ?? 'Error desconocido al enviar'), backgroundColor: Theme.of(context).colorScheme.error, ),
          );
      }
    }
  }
  // =================================================================
  //               FIN DE LA FUNCIÓN _submit
  // =================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFondo, 
      appBar: AppBar(
        title: const Text('Configurar Dieta Premium'),
        backgroundColor: _colorAppBar,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _estadoPlan == 'aprobado'
              ? _buildInfoCard(
                  'Plan Aprobado',
                  'Ya tienes un plan de dieta aprobado para este mes.',
                  Icons.check_circle, Colors.green,
                )
              : _estadoPlan == 'pendiente_revision'
                  ? _buildInfoCard(
                      'Plan Pendiente',
                      'Tu solicitud de dieta está siendo revisada.',
                      Icons.hourglass_top, Colors.orange,
                    )
                  : _buildFormulario(context),
    );
  }

  Widget _buildFormulario(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null && !_isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text( _error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16), textAlign: TextAlign.center, ),
              ),
            
            _buildSectionTitle('1. Datos Metabólicos'),
            const SizedBox(height: 16),
            _buildFormularioMetabolico(),
            const SizedBox(height: 24),
            
            _buildSectionTitle('2. Preferencias de Dieta'),
            const SizedBox(height: 16),
            _buildFormularioPreferencias(),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              icon: const Icon(Icons.send, size: 20, color: Colors.white),
              label: Text(
                puedeSolicitar ? 'Solicitar Plan' : 'Plan ya Solicitado',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorAppBar, // Azul primario
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              onPressed: (puedeSolicitar && !_isLoading) ? _submit : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Al solicitar, tus datos serán enviados a nuestro equipo de nutricionistas.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioMetabolico() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _pesoController, label: 'Peso (kg)', icon: Icons.monitor_weight,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _alturaController, label: 'Altura (cm)', icon: Icons.height,
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
                controller: _edadController, label: 'Edad', icon: Icons.cake,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Género', value: _genero, icon: Icons.person,
                items: const [
                  DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
                  DropdownMenuItem(value: 'femenino', child: Text('Femenino')),
                ],
                onChanged: (value) => setState(() => _genero = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Ocupación (Trabajo)', value: _ocupacion, icon: Icons.work,
          items: const [
            DropdownMenuItem(value: 'sedentaria', child: Text('Sedentaria (Oficina)')),
            DropdownMenuItem(value: 'ligera', child: Text('Ligera (De pie)')),
            DropdownMenuItem(value: 'activa', child: Text('Activa (Física)')),
          ],
          onChanged: (value) => setState(() => _ocupacion = value),
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Ejercicio Físico', value: _ejercicio, icon: Icons.fitness_center,
          items: const [
            DropdownMenuItem(value: '0', child: Text('0 días / semana')),
            DropdownMenuItem(value: '1-3', child: Text('1-3 días / semana')),
            DropdownMenuItem(value: '4-5', child: Text('4-5 días / semana')),
            DropdownMenuItem(value: '6-7', child: Text('6-7 días / semana')),
          ],
          onChanged: (value) => setState(() => _ejercicio = value),
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Objetivo', value: _objetivo, icon: Icons.flag,
          items: const [
            DropdownMenuItem(value: 'perder', child: Text('Perder peso')),
            DropdownMenuItem(value: 'mantener', child: Text('Mantener peso')),
            DropdownMenuItem(value: 'ganar', child: Text('Ganar masa muscular')),
          ],
          onChanged: (value) => setState(() => _objetivo = value),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _colorAppBar.withOpacity(0.05), // Fondo azul muy sutil
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _colorAppBar.withOpacity(0.2))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calculate, color: _colorAppBar),
              const SizedBox(width: 12),
              Text(
                'Kcal Objetivo: $_kcalObjetivo',
                style: TextStyle( fontSize: 18, fontWeight: FontWeight.bold, color: _colorAppBar, ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text( 'Tus kcal objetivo se recalcularán al enviar.', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center, ),
        ),
      ],
    );
  }

  Widget _buildFormularioPreferencias() {
    return Column(
      children: [
        _buildDropdownField(
          label: 'Número de Comidas', value: _numComidas.toString(), icon: Icons.restaurant,
          items: [2, 3, 4, 5, 6].map((num) {
            return DropdownMenuItem(value: num.toString(), child: Text('$num comidas'));
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _numComidas = int.parse(value));
          },
        ),
        const SizedBox(height: 16),
        _buildTextField( controller: _alergiasController, label: 'Alergias o Intolerancias', icon: Icons.no_food, maxLines: 2, isOptional: true, ),
        const SizedBox(height: 16),
        _buildTextField( controller: _preferenciasController, label: 'Alimentos que no te gustan', icon: Icons.thumb_down, maxLines: 2, isOptional: true, ),
        const SizedBox(height: 16),
        _buildTextField( controller: _historialMedicoController, label: 'Historial Médico (Opcional)', icon: Icons.medical_services, maxLines: 2, isOptional: true, ),
        const SizedBox(height: 16),
        _buildTextField( controller: _horariosController, label: 'Horarios de trabajo/sueño (Opcional)', icon: Icons.schedule, maxLines: 2, isOptional: true, ),
        const SizedBox(height: 16),
        _buildTextField( controller: _platosFavoritosController, label: 'Platos favoritos (Opcional)', icon: Icons.favorite, maxLines: 2, isOptional: true, ),
      ],
    );
  }
  
  Widget _buildInfoCard(String title, String message, IconData icon, Color color) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 20),
            Text( title, style: TextStyle( fontSize: 22, fontWeight: FontWeight.bold, color: color, ), textAlign: TextAlign.center, ),
            const SizedBox(height: 12),
            Text( message, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center, ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _colorAppBar, // Azul primario
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool isOptional = false, 
  }) {
    return TextFormField(
      controller: controller,
      readOnly: !puedeSolicitar, 
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _colorIconos),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: _colorCampos, // Fondo Blanco
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: (value) {
        if (isOptional) return null; 
        if (value == null || value.trim().isEmpty) return 'Requerido';
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
      isExpanded: true, 
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _colorIconos),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: _colorCampos, // Fondo Blanco
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Requerido';
        return null;
      },
    );
  }
}
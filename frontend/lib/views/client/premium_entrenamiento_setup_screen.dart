// screens/client/premium_entrenamiento_setup_screen.dart
// ¡MODIFICADO! Añadidos campos Nivel, Días y Lesiones.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para input formatters
import '../../models/usuario.dart';
import '../../services/ia_entrenamiento_service.dart';

class PremiumEntrenamientoSetupScreen extends StatefulWidget {
  final Usuario usuario;
  const PremiumEntrenamientoSetupScreen({Key? key, required this.usuario}) : super(key: key);

  @override
  State<PremiumEntrenamientoSetupScreen> createState() => _PremiumEntrenamientoSetupScreenState();
}

class _PremiumEntrenamientoSetupScreenState extends State<PremiumEntrenamientoSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // --- Controllers (MODIFICADOS) ---
  late TextEditingController _metaController;
  late TextEditingController _focoController;
  late TextEditingController _lesionesController; // <-- AÑADIDO
  String? _equipamiento;
  int _tiempo = 45;
  String? _nivel; // <-- AÑADIDO
  int _diasSemana = 4; // <-- AÑADIDO

  bool _isLoading = false;
  String? _error;
  String? _estadoPlan;

  final IAEntrenamientoService _service = IAEntrenamientoService();

  bool get puedeSolicitar => _estadoPlan == 'pendiente_solicitud' || _estadoPlan == null;

  @override
  void initState() {
    super.initState();
    _fetchPlanStatus(); // Cargar estado primero
    
    // Inicializar controllers con datos del usuario
    _metaController = TextEditingController(text: widget.usuario.premiumMeta);
    _focoController = TextEditingController(text: widget.usuario.premiumFoco);
    _equipamiento = widget.usuario.premiumEquipamiento;
    _tiempo = widget.usuario.premiumTiempo;
    
    // --- ¡NUEVOS CAMPOS! ---
    _nivel = widget.usuario.premiumNivel;
    _diasSemana = widget.usuario.premiumDiasSemana;
    _lesionesController = TextEditingController(text: widget.usuario.premiumLesiones);
  }
  
  @override
  void dispose() {
    _metaController.dispose();
    _focoController.dispose();
    _lesionesController.dispose(); // <-- AÑADIDO
    super.dispose();
  }

  Future<void> _fetchPlanStatus() async {
    setState(() => _isLoading = true);
    try {
      final estado = await _service.obtenerEstadoPlanDelMes();
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
    
    setState(() { _isLoading = true; _error = null; });

    try {
      // --- ¡MAPA DE DATOS ACTUALIZADO! ---
      final Map<String, dynamic> datosPreferencias = {
        'premiumMeta': _metaController.text.trim(),
        'premiumFoco': _focoController.text.trim(),
        'premiumEquipamiento': _equipamiento,
        'premiumTiempo': _tiempo,
        'premiumNivel': _nivel,
        'premiumDiasSemana': _diasSemana,
        'premiumLesiones': _lesionesController.text.trim(),
      };

      final bool solicitado = await _service.solicitarPlanEntrenamiento(datosPreferencias);

      if (solicitado) {
        setState(() {
          _isLoading = false;
          _estadoPlan = 'pendiente_revision'; // Actualiza el estado local
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Plan solicitado con éxito! Será revisado.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Error al solicitar el plan de entrenamiento');
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error ?? 'Error desconocido al enviar'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
      }
    }
  }

  // --- Helper para construir Dropdowns (reutilizado de dieta) ---
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
        prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.blue[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Requerido';
        return null;
      },
    );
  }

  // --- Helper para construir TextFields (reutilizado de dieta) ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: !puedeSolicitar,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.blue[50],
      ),
      maxLines: maxLines,
      validator: (value) {
        if (isOptional) return null;
        if (value == null || value.trim().isEmpty) return 'Requerido';
        return null;
      },
    );
  }
  
  // --- Helper para construir el Slider de Tiempo ---
  Widget _buildTimeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
          child: Text(
            'Tiempo por sesión: $_tiempo min',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E88E5), // Azul
            ),
          ),
        ),
        Slider(
          value: _tiempo.toDouble(),
          min: 30,
          max: 90,
          divisions: 12, // (90-30) / 5 = 12 divisiones
          label: '${_tiempo.round()} min',
          activeColor: const Color(0xFF1E88E5), // Azul
          inactiveColor: Colors.blue[100],
          onChanged: puedeSolicitar
              ? (double value) {
                  setState(() => _tiempo = value.round());
                }
              : null,
        ),
      ],
    );
  }
  
  // --- Helper para construir el Slider de Días ---
  Widget _buildDaysSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
          child: Text(
            'Días por semana: $_diasSemana días',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E88E5), // Azul
            ),
          ),
        ),
        Slider(
          value: _diasSemana.toDouble(),
          min: 2,
          max: 6,
          divisions: 4, // 2, 3, 4, 5, 6
          label: '${_diasSemana.round()} días',
          activeColor: const Color(0xFF1E88E5), // Azul
          inactiveColor: Colors.blue[100],
          onChanged: puedeSolicitar
              ? (double value) {
                  setState(() => _diasSemana = value.round());
                }
              : null,
        ),
      ],
    );
  }
  
  // --- BUILD WIDGET ---
  
  @override
  Widget build(BuildContext context) {
    // Usamos el mismo color primario que en la pantalla de dieta
    const colorPrimario = Color(0xFF1E88E5);

    return Scaffold(
      backgroundColor: colorPrimario.withOpacity(0.05), // Fondo muy claro
      appBar: AppBar(
        title: const Text('Configurar Entrenamiento'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorPrimario, // Texto y flecha azul
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _estadoPlan == 'aprobado'
              ? _buildInfoCard(
                  'Plan Aprobado',
                  'Ya tienes un plan de entrenamiento aprobado para este mes. Puedes consultarlo en la pestaña "Mi Rutina".',
                  Icons.check_circle,
                  Colors.green,
                )
              : _estadoPlan == 'pendiente_revision'
                  ? _buildInfoCard(
                      'Plan Pendiente',
                      'Tu solicitud de entrenamiento está siendo revisada. Recibirás una notificación cuando esté lista.',
                      Icons.hourglass_top,
                      Colors.orange,
                    )
                  : _buildFormulario(context, colorPrimario),
    );
  }
  
  // --- Widget del Formulario ---
  Widget _buildFormulario(BuildContext context, Color colorPrimario) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // --- ¡¡NUEVOS CAMPOS!! ---
              _buildDropdownField(
                label: 'Tu Nivel Actual',
                value: _nivel,
                icon: Icons.leaderboard,
                items: const [
                  DropdownMenuItem(value: 'principiante', child: Text('Principiante (0-6 meses)')),
                  DropdownMenuItem(value: 'intermedio', child: Text('Intermedio (6m - 2 años)')),
                  DropdownMenuItem(value: 'avanzado', child: Text('Avanzado (2+ años)')),
                ],
                onChanged: (value) => setState(() => _nivel = value),
              ),
              const SizedBox(height: 16),
              
              _buildDaysSlider(), // Slider para días
              const SizedBox(height: 16),

              // --- Campos Antiguos ---
              _buildTextField(
                controller: _metaController,
                label: 'Tu Meta Principal',
                icon: Icons.flag,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _focoController,
                label: 'Foco Muscular',
                icon: Icons.accessibility_new,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Equipamiento Disponible',
                value: _equipamiento,
                icon: Icons.fitness_center,
                items: const [
                  DropdownMenuItem(value: 'solo_cuerpo', child: Text('Solo Peso Corporal')),
                  DropdownMenuItem(value: 'mancuernas_basico', child: Text('Básico (Mancuernas/Bandas)')),
                  DropdownMenuItem(value: 'gym_completo', child: Text('Gimnasio Completo')),
                ],
                onChanged: (value) => setState(() => _equipamiento = value),
              ),
              const SizedBox(height: 16),
              
              _buildTimeSlider(), // Slider para tiempo
              const SizedBox(height: 16),

              // --- ¡¡NUEVO CAMPO DE TEXTO!! ---
              _buildTextField(
                controller: _lesionesController,
                label: 'Lesiones o Limitaciones (Opcional)',
                icon: Icons.warning_amber_rounded,
                maxLines: 2,
                isOptional: true,
              ),
              const SizedBox(height: 32),
              
              // --- Botón de Envío ---
              ElevatedButton.icon(
                icon: Icon(_isLoading ? Icons.sync : Icons.send, color: Colors.white),
                label: Text(
                  _isLoading 
                    ? 'Enviando...' 
                    : (puedeSolicitar ? 'Solicitar Plan' : 'Plan en Revisión'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                onPressed: _isLoading || !puedeSolicitar ? null : _submit, 
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget de Tarjeta de Información (Idéntico al de dieta) ---
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
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
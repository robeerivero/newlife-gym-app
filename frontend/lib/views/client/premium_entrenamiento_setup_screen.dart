// screens/client/premium_entrenamiento_setup_screen.dart
// ¡¡CORREGIDO!! La función _submit ahora envía los datos metabólicos existentes.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../../models/usuario.dart';
import '../../services/ia_entrenamiento_service.dart';
import '../../services/user_service.dart'; 

class PremiumEntrenamientoSetupScreen extends StatefulWidget {
  final Usuario usuario;
  const PremiumEntrenamientoSetupScreen({Key? key, required this.usuario}) : super(key: key);

  @override
  State<PremiumEntrenamientoSetupScreen> createState() => _PremiumEntrenamientoSetupScreenState();
}

class _PremiumEntrenamientoSetupScreenState extends State<PremiumEntrenamientoSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // --- Controladores (los que son de texto) ---
  late TextEditingController _focoController;
  late TextEditingController _lesionesController;
  late TextEditingController _tiempoController;
  late TextEditingController _diasSemanaController;
  late TextEditingController _ejerciciosOdiadosController;

  // --- Variables de Dropdown (los que son de selección) ---
  String? _meta;
  String? _nivel; 
  
  // --- Variable de Multiselect ---
  Set<String> _equipamientoSeleccionado = {};

  bool _isLoading = false;
  String? _estadoPlan; 

  // --- Servicios ---
  final IAEntrenamientoService _iaService = IAEntrenamientoService();
  final UserService _userService = UserService();

  bool get puedeSolicitar => _estadoPlan == 'pendiente_solicitud' || _estadoPlan == null;

  // --- Colores del Tema ---
  static const Color _colorPrimario = Color(0xFF1E88E5);
  static const Color _colorSecundario = Color(0xFF1565C0);
  static const Color _colorCampos = Colors.white;
  static const Color _colorIconos = Color(0xFF1565C0);
  final TextStyle _labelStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);

  // --- Opciones para los nuevos Dropdowns y Chips ---

  final Map<String, String> _metaOpciones = {
    'salud_general': 'Fitness y salud general',
    'perder_grasa': 'Perder grasa y definir',
    'hipertrofia': 'Aumentar masa muscular (Volumen)',
    'fuerza_pura': 'Ganar fuerza pura (Powerlifting)',
    'rendimiento_atletico': 'Atleta Híbrido (Fuerza + Velocidad)',
  };

  final Map<String, String> _nivelOpciones = {
    'principiante_nuevo': 'Principiante (0-6 meses)',
    'intermedio_consistente': 'Intermedio (6 meses - 2 años)',
    'avanzado_programado': 'Avanzado (2+ años)',
  };

  final Map<String, String> _equipamientoOpciones = {
    'solo_cuerpo': 'Solo Peso Corporal',
    'bandas_elasticas': 'Bandas Elásticas',
    'mancuernas_ligeras': 'Mancuernas Ligeras',
    'mancuernas_ajustables': 'Mancuernas (Set completo)',
    'kettlebell': 'Kettlebell',
    'barra_dominadas': 'Barra de Dominadas',
    'banco': 'Banco (Plano o Ajustable)',
    'gym_basico': 'Gimnasio Básico (Máquinas)',
    'gym_completo': 'Gimnasio Completo (Peso Libre)',
  };


  @override
  void initState() {
    super.initState();
    // Inicializa todos los campos desde el 'widget.usuario'
    _focoController = TextEditingController(text: widget.usuario.premiumFoco);
    _lesionesController = TextEditingController(text: widget.usuario.premiumLesiones);
    _ejerciciosOdiadosController = TextEditingController(text: widget.usuario.premiumEjerciciosOdiados);
    _tiempoController = TextEditingController(text: widget.usuario.premiumTiempo.toString());
    _diasSemanaController = TextEditingController(text: widget.usuario.premiumDiasSemana.toString());
    
    _meta = widget.usuario.premiumMeta;
    _nivel = widget.usuario.premiumNivel;
    _equipamientoSeleccionado = widget.usuario.premiumEquipamiento.toSet();
    
    _fetchEstadoPlan();
  }

  @override
  void dispose() {
    _focoController.dispose();
    _lesionesController.dispose();
    _tiempoController.dispose();
    _diasSemanaController.dispose();
    _ejerciciosOdiadosController.dispose();
    super.dispose();
  }

  Future<void> _fetchEstadoPlan() async {
    setState(() { _isLoading = true; });
    try {
      final estado = await _iaService.obtenerEstadoPlanDelMes();
      setState(() {
        _estadoPlan = estado;
      });
    } catch (e) {
      // Manejar error
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  /// --- ¡FUNCIÓN SUBMIT CORREGIDA! ---
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, revisa los campos en rojo.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 1. Construye el mapa de datos
      final Map<String, dynamic> datos = {
        // --- DATOS DE ENTRENAMIENTO (NUEVOS) ---
        'premiumMeta': _meta,
        'premiumNivel': _nivel,
        'premiumDiasSemana': int.tryParse(_diasSemanaController.text.trim()) ?? 3,
        'premiumTiempo': int.tryParse(_tiempoController.text.trim()) ?? 45,
        'premiumEquipamiento': _equipamientoSeleccionado.toList(), 
        'premiumFoco': _focoController.text.trim(),
        'premiumLesiones': _lesionesController.text.trim(),
        'premiumEjerciciosOdiados': _ejerciciosOdiadosController.text.trim(),
        
        // --- ¡¡CORRECCIÓN!! ---
        // Debemos reenviar los datos de Dieta/Metabólicos existentes
        // para que la validación del backend no falle.
        'genero': widget.usuario.genero,
        'edad': widget.usuario.edad,
        'altura': widget.usuario.altura,
        'peso': widget.usuario.peso,
        'ocupacion': widget.usuario.ocupacion,
        'ejercicio': widget.usuario.ejercicio,
        'objetivo': widget.usuario.objetivo,
        'kcalObjetivo': widget.usuario.kcalObjetivo, // <-- ¡LA CLAVE DEL ERROR!
        
        'dietaAlergias': widget.usuario.dietaAlergias,
        'dietaPreferencias': widget.usuario.dietaPreferencias,
        'dietaComidas': widget.usuario.dietaComidas,
        'historialMedico': widget.usuario.historialMedico,
        'horarios': widget.usuario.horarios,
        'platosFavoritos': widget.usuario.platosFavoritos,
        'dietaTiempoCocina': widget.usuario.dietaTiempoCocina,
        'dietaHabilidadCocina': widget.usuario.dietaHabilidadCocina,
        'dietaEquipamiento': widget.usuario.dietaEquipamiento,
        'dietaContextoComida': widget.usuario.dietaContextoComida,
        'dietaAlimentosOdiados': widget.usuario.dietaAlimentosOdiados,
        'dietaRetoPrincipal': widget.usuario.dietaRetoPrincipal,
        'dietaBebidas': widget.usuario.dietaBebidas,
      };

      // 2. Actualiza el perfil del usuario (como en Dieta)
      final Map<String, dynamic>? resultadoPerfil = await _userService.actualizarDatosMetabolicos(datos);
      
      if (resultadoPerfil == null) {
        throw Exception('No se pudo actualizar el perfil de usuario.');
      }

      // 3. Envía la solicitud del plan
      final bool solicitudEnviada = await _iaService.solicitarPlanEntrenamiento(datos);

      if (solicitudEnviada && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Solicitud de rutina enviada! Tu plan estará listo pronto.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Devuelve 'true' para refrescar
      } else {
        throw Exception('Error al enviar la solicitud del plan.');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }


  @override
  Widget build(BuildContext context) {
    // Items de los menús
    final _metaItems = _metaOpciones.entries
        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
        .toList();
    final _nivelItems = _nivelOpciones.entries
        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
        .toList();
        
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text('Configurar Rutina', style: TextStyle(color: Colors.white)),
        backgroundColor: _colorPrimario,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading && _estadoPlan == null // Loading inicial
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(context, _metaItems, _nivelItems),
    );
  }

  Widget _buildForm(BuildContext context, List<DropdownMenuItem<String>> metaItems, List<DropdownMenuItem<String>> nivelItems) {
    if (!puedeSolicitar && _estadoPlan == 'pendiente_revision') {
      return _buildInfoCard('Plan en Revisión', 'Tu entrenador ya está preparando tu rutina. Recibirás una notificación cuando esté lista.', Icons.pending_actions, Colors.orange);
    }
    if (!puedeSolicitar && _estadoPlan == 'aprobado') {
      return _buildInfoCard('Plan Aprobado', 'Tu rutina para este mes ya está aprobada. Puedes verla en la pantalla de "Clases".', Icons.check_circle_outline, Colors.green);
    }
    
    // Si puede solicitar (o es nulo), muestra el formulario
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Tu Objetivo', '¿Qué quieres conseguir?'),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Objetivo Principal',
              value: _meta,
              items: metaItems,
              icon: Icons.flag_outlined,
              onChanged: (val) => setState(() { _meta = val; }),
            ),
            const SizedBox(height: 16),
             _buildTextField(
              label: 'Foco Específico (Opcional)',
              hint: 'Ej: Híbrido (fuerza y pliometría), más pierna...',
              controller: _focoController,
              icon: Icons.filter_center_focus_outlined,
              isOptional: true,
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            _buildSectionTitle('Tu Nivel y Logística', '¿Cómo, cuándo y dónde?'),
            const SizedBox(height: 16),
            
            _buildDropdownField(
              label: 'Nivel de Experiencia',
              value: _nivel,
              items: nivelItems,
              icon: Icons.leaderboard_outlined,
              onChanged: (val) => setState(() { _nivel = val; }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(
                  label: 'Días por Semana',
                  controller: _diasSemanaController,
                  icon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(
                  label: 'Tiempo por Sesión (min)',
                  controller: _tiempoController,
                  icon: Icons.timer_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                )),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildEquipamientoCheckboxes(), // ¡NUEVO WIDGET!
            
            const SizedBox(height: 24),
            const Divider(),
            _buildSectionTitle('Limitaciones y Preferencias', 'Para una rutina segura y que disfrutes'),
            const SizedBox(height: 16),
            
            _buildTextField(
              label: 'Lesiones o Molestias (Opcional)',
              hint: 'Ej: Dolor lumbar en peso muerto...',
              controller: _lesionesController,
              icon: Icons.healing_outlined,
              maxLines: 3,
              isOptional: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Ejercicios Odiados (Opcional)',
              hint: 'Ej: Odio los burpees, no quiero correr...',
              controller: _ejerciciosOdiadosController,
              icon: Icons.thumb_down_outlined,
              maxLines: 3,
              isOptional: true,
            ),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (_isLoading) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Enviar Solicitud de Rutina',
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets constructores (Copiados de Dieta para consistencia) ---

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _colorPrimario),
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '$label ${isOptional ? '(Opcional)' : ''}',
        hintText: hint,
        prefixIcon: Icon(icon, color: _colorIconos),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: _colorCampos,
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
      onChanged: onChanged,
      isExpanded: true, 
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _colorIconos),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: _colorCampos,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Requerido';
        return null;
      },
    );
  }

  // --- Widget para los Checkboxes de Equipamiento ---
  Widget _buildEquipamientoCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Equipamiento Disponible (multiselección)', style: _labelStyle.copyWith(color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _colorCampos,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[400]!)
          ),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _equipamientoOpciones.entries.map((entry) {
              final key = entry.key;
              final label = entry.value;
              final isSelected = _equipamientoSeleccionado.contains(key);
              return FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _equipamientoSeleccionado.add(key);
                    } else {
                      _equipamientoSeleccionado.remove(key);
                    }
                  });
                },
                selectedColor: _colorSecundario.withOpacity(0.3),
                checkmarkColor: _colorSecundario,
                showCheckmark: true,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // (Tu widget _buildInfoCard original)
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
            Text( message, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center, ),
          ],
        ),
      ),
    );
  }
}
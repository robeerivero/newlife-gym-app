// screens/client/premium_entrenamiento_setup_screen.dart
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
  
  // --- Controladores ---
  late TextEditingController _focoController;
  late TextEditingController _lesionesController;
  late TextEditingController _tiempoController;
  late TextEditingController _diasSemanaController;
  late TextEditingController _ejerciciosOdiadosController;

  // --- Variables de selección ---
  String? _meta;
  String? _nivel; 
  
  // --- Multiselect ---
  Set<String> _equipamientoSeleccionado = {};

  bool _isLoading = false;
  String? _estadoPlan; 

  // --- Servicios ---
  final IAEntrenamientoService _iaService = IAEntrenamientoService();
  final UserService _userService = UserService();

  bool get puedeSolicitar => _estadoPlan == 'pendiente_solicitud' || _estadoPlan == null;

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
      // Manejar error silenciosamente o mostrar snackbar
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _submit() async {
    final colorScheme = Theme.of(context).colorScheme;
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Por favor, revisa los campos en rojo.'), backgroundColor: colorScheme.error),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final Map<String, dynamic> datos = {
        // --- DATOS DE ENTRENAMIENTO ---
        'premiumMeta': _meta,
        'premiumNivel': _nivel,
        'premiumDiasSemana': int.tryParse(_diasSemanaController.text.trim()) ?? 3,
        'premiumTiempo': int.tryParse(_tiempoController.text.trim()) ?? 45,
        'premiumEquipamiento': _equipamientoSeleccionado.toList(), 
        'premiumFoco': _focoController.text.trim(),
        'premiumLesiones': _lesionesController.text.trim(),
        'premiumEjerciciosOdiados': _ejerciciosOdiadosController.text.trim(),
        
        // --- DATOS METABÓLICOS EXISTENTES (PRESERVADOS) ---
        'genero': widget.usuario.genero,
        'edad': widget.usuario.edad,
        'altura': widget.usuario.altura,
        'peso': widget.usuario.peso,
        'ocupacion': widget.usuario.ocupacion,
        'ejercicio': widget.usuario.ejercicio,
        'objetivo': widget.usuario.objetivo,
        'kcalObjetivo': widget.usuario.kcalObjetivo,
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

      // 1. Guardar perfil
      final Map<String, dynamic>? resultadoPerfil = await _userService.actualizarDatosMetabolicos(datos);
      
      if (resultadoPerfil == null) throw Exception('Error al actualizar perfil.');

      // 2. Solicitar rutina
      bool solicitudEnviada = await _iaService.solicitarPlanEntrenamiento(datos);

      if (solicitudEnviada && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Solicitud enviada! Tu rutina estará lista pronto.'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      } else {
         throw Exception('Error al enviar solicitud.');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: colorScheme.error),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Entrenamiento'),
        // backgroundColor: eliminado (Theme default)
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!widget.usuario.esPremium || !widget.usuario.incluyePlanEntrenamiento) {
      return _buildInfoCard(
        context,
        'No Incluido', 
        'Este plan no está incluido en tu suscripción. Contacta con soporte o mejora tu plan.',
        Icons.lock_outline,
        Theme.of(context).disabledColor,
      );
    }

    if (!puedeSolicitar && _estadoPlan == 'pendiente_revision') {
      return _buildInfoCard(
        context,
        'En Revisión', 
        'Tu entrenador ya está preparando tu rutina. Recibirás una notificación cuando esté lista.',
        Icons.pending_actions,
        Colors.orange, // Semántico: Pendiente
      );
    }

    if (!puedeSolicitar && _estadoPlan == 'aprobado') {
      return _buildInfoCard(
        context,
        'Plan Aprobado', 
        'Tu rutina para este mes ya está aprobada. Puedes verla en la pantalla de "Clases".',
        Icons.check_circle_outline,
        Colors.green, // Semántico: Éxito
      );
    }

    // FORMULARIO ACTIVO
    final metaItems = _metaOpciones.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList();
    final nivelItems = _nivelOpciones.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList();
    final colorScheme = Theme.of(context).colorScheme;

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
                   icon: Icons.calendar_today,
                   keyboardType: TextInputType.number,
                   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                 )),
                 const SizedBox(width: 10),
                 Expanded(child: _buildTextField(
                   label: 'Minutos por Sesión',
                   controller: _tiempoController,
                   icon: Icons.timer,
                   keyboardType: TextInputType.number,
                   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                 )),
               ],
             ),
             const SizedBox(height: 16),
             Text('Equipamiento Disponible:', style: Theme.of(context).textTheme.titleMedium),
             const SizedBox(height: 8),
             Wrap(
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
                  // Colores del tema
                  selectedColor: colorScheme.secondaryContainer,
                  checkmarkColor: colorScheme.onSecondaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            const Divider(),

            _buildSectionTitle('Limitaciones', 'Para entrenar seguro'),
            const SizedBox(height: 16),
             _buildTextField(
              label: 'Lesiones / Molestias (Opcional)',
              hint: 'Ej: Dolor lumbar, rodilla izquierda...',
              controller: _lesionesController,
              icon: Icons.local_hospital_outlined,
              isOptional: true,
            ),
            const SizedBox(height: 16),
             _buildTextField(
              label: 'Ejercicios que odias (Opcional)',
              hint: 'Ej: Burpees, Dominadas...',
              controller: _ejerciciosOdiadosController,
              icon: Icons.thumb_down_alt_outlined,
              isOptional: true,
            ),

            const SizedBox(height: 40),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _submit,
                // Estilo por defecto del tema
                child: const Text('Solicitar Rutina', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      validator: (val) => val == null ? 'Requerido' : null,
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
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: (value) {
        if (isOptional) return null;
        if (value == null || value.trim().isEmpty) return 'Requerido';
        return null;
      },
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String message, IconData icon, Color color) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
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
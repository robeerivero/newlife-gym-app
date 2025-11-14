// screens/client/premium_dieta_setup_screen.dart
// ¡¡CORREGIDO!! Corregido el nombre del método en _submit()

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
  bool _calculoPersonalizado = false;

  // --- Controllers (Preferencias Dieta Base) ---
  late TextEditingController _alergiasController;
  late TextEditingController _preferenciasController;
  late TextEditingController _comidasController;
  late TextEditingController _historialController;
  late TextEditingController _horariosController;
  late TextEditingController _platosFavoritosController;

  // --- Controllers (Adherencia Dieta) ---
  late TextEditingController _alimentosOdiadosController;
  late TextEditingController _bebidasController;
  String? _tiempoCocina;
  String? _habilidadCocina;
  String? _contextoComida;
  String? _retoPrincipal;
  Set<String> _equipamientoSeleccionado = {};
  // ---------------------------------------------

  bool _isLoading = false;
  
  final Color _colorPrimario = const Color(0xFF1E88E5);
  final Color _colorSecundario = const Color(0xFF1565C0);
  final Color _colorCampos = Colors.white;
  final Color _colorIconos = const Color(0xFF1565C0);
  final TextStyle _labelStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);

  final Map<String, String> _tiempoCocinaOpciones = {
    'menos_15_min': 'Menos de 15 min (Rápido)',
    '15_30_min': '15-30 min (Estándar)',
    'mas_30_min': 'Más de 30 min (Me gusta cocinar)',
  };
  
  final Map<String, String> _habilidadCocinaOpciones = {
    'principiante': 'Principiante (Recetas muy simples)',
    'intermedio': 'Intermedio (Sigo recetas)',
    'avanzado': 'Avanzado (Soy creativo)',
  };
  
  final Map<String, String> _contextoComidaOpciones = {
    'casa': 'Como en casa',
    'oficina_tupper': 'En la oficina (Necesito tupper)',
    'restaurante': 'Como fuera (Restaurante/Delivery)',
  };
  
  final Map<String, String> _retoPrincipalOpciones = {
    'picoteo': 'El picoteo entre horas',
    'social': 'Las comidas sociales / Fines de semana',
    'organizacion': 'La falta de tiempo / Organización',
    'estres': 'Comer por estrés o aburrimiento',
    'raciones': 'Controlar las raciones',
  };
  
  final Map<String, String> _equipamientoOpciones = {
    'basico': 'Básico (Sartén, Microondas)',
    'horno': 'Horno',
    'airfryer': 'Airfryer',
    'batidora': 'Batidora (Smoothies/Cremas)',
    'robot': 'Robot de Cocina',
  };


  @override
  void initState() {
    super.initState();
    // Metabólicos
    _pesoController = TextEditingController(text: widget.usuario.peso.toStringAsFixed(1));
    _alturaController = TextEditingController(text: widget.usuario.altura.toStringAsFixed(0));
    _edadController = TextEditingController(text: widget.usuario.edad.toString());
    _genero = widget.usuario.genero;
    _ocupacion = widget.usuario.ocupacion;
    _ejercicio = widget.usuario.ejercicio;
    _objetivo = widget.usuario.objetivo;
    _kcalObjetivo = widget.usuario.kcalObjetivo;
    _calculoPersonalizado = _kcalObjetivo > 0 && _kcalObjetivo != 2000;

    // Preferencias Base
    _alergiasController = TextEditingController(text: widget.usuario.dietaAlergias);
    _preferenciasController = TextEditingController(text: widget.usuario.dietaPreferencias);
    _comidasController = TextEditingController(text: widget.usuario.dietaComidas.toString());
    _historialController = TextEditingController(text: widget.usuario.historialMedico);
    _horariosController = TextEditingController(text: widget.usuario.horarios);
    _platosFavoritosController = TextEditingController(text: widget.usuario.platosFavoritos);

    // Adherencia
    _alimentosOdiadosController = TextEditingController(text: widget.usuario.dietaAlimentosOdiados);
    _bebidasController = TextEditingController(text: widget.usuario.dietaBebidas);
    _tiempoCocina = widget.usuario.dietaTiempoCocina;
    _habilidadCocina = widget.usuario.dietaHabilidadCocina;
    _contextoComida = widget.usuario.dietaContextoComida;
    _retoPrincipal = widget.usuario.dietaRetoPrincipal;
    _equipamientoSeleccionado = widget.usuario.dietaEquipamiento.toSet();
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _alturaController.dispose();
    _edadController.dispose();
    _alergiasController.dispose();
    _preferenciasController.dispose();
    _comidasController.dispose();
    _historialController.dispose();
    _horariosController.dispose();
    _platosFavoritosController.dispose();
    _alimentosOdiadosController.dispose();
    _bebidasController.dispose();
    super.dispose();
  }

  void _calcularKcal() {
    if (!_formKey.currentState!.validate()) return;
    
    final double peso = double.tryParse(_pesoController.text.trim()) ?? 0;
    final double altura = double.tryParse(_alturaController.text.trim()) ?? 0;
    final int edad = int.tryParse(_edadController.text.trim()) ?? 0;

    if (peso == 0 || altura == 0 || edad == 0 || _genero == null || _ocupacion == null || _ejercicio == null || _objetivo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los datos metabólicos.'), backgroundColor: Colors.red),
      );
      return;
    }

    double tmb;
    if (_genero == 'masculino') {
      tmb = (10 * peso) + (6.25 * altura) - (5 * edad) + 5;
    } else { // femenino
      tmb = (10 * peso) + (6.25 * altura) - (5 * edad) - 161;
    }

    final factoresOcupacion = {'sedentaria': 1.2, 'ligera': 1.375, 'activa': 1.55};
    final caloriasEjercicio = {'0': 0, '1-3': 300, '4-5': 500, '6-7': 700};
    
    final tdee = (tmb * (factoresOcupacion[_ocupacion] ?? 1.2)) + (caloriasEjercicio[_ejercicio] ?? 0);

    double kcalFinal;
    switch (_objetivo) {
      case 'perder':
        kcalFinal = tdee - 500;
        kcalFinal = (kcalFinal < tmb + 100) ? tmb + 100 : kcalFinal;
        break;
      case 'ganar':
        kcalFinal = tdee + 300;
        break;
      case 'mantener':
      default:
        kcalFinal = tdee;
    }

    setState(() {
      _kcalObjetivo = kcalFinal.round();
      _calculoPersonalizado = true;
      FocusScope.of(context).unfocus();
    });
  }


  // --- SUBMIT (¡CORREGIDO!) ---
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, revisa los campos en rojo.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (_kcalObjetivo == 0 || !_calculoPersonalizado) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calcula tus calorías antes de enviar.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final Map<String, dynamic> datos = {
        // Metabólicos
        'genero': _genero,
        'edad': int.parse(_edadController.text.trim()),
        'altura': double.parse(_alturaController.text.trim()),
        'peso': double.parse(_pesoController.text.trim()),
        'ocupacion': _ocupacion,
        'ejercicio': _ejercicio,
        'objetivo': _objetivo,
        'kcalObjetivo': _kcalObjetivo,
        // Preferencias Base
        'dietaAlergias': _alergiasController.text.trim(),
        'dietaPreferencias': _preferenciasController.text.trim(),
        'dietaComidas': int.tryParse(_comidasController.text.trim()) ?? 4,
        'historialMedico': _historialController.text.trim(),
        'horarios': _horariosController.text.trim(),
        'platosFavoritos': _platosFavoritosController.text.trim(),
        
        // Campos de Adherencia
        'dietaTiempoCocina': _tiempoCocina,
        'dietaHabilidadCocina': _habilidadCocina,
        'dietaEquipamiento': _equipamientoSeleccionado.toList(),
        'dietaContextoComida': _contextoComida,
        'dietaAlimentosOdiados': _alimentosOdiadosController.text.trim(),
        'dietaRetoPrincipal': _retoPrincipal,
        'dietaBebidas': _bebidasController.text.trim(),
      };

      // 1. Actualizar el perfil del usuario con estos datos
      // ¡¡CORRECCIÓN!! 
      // 1. El método se llama 'actualizarDatosMetabolicos'
      // 2. Devuelve un Map?, no un bool
      final Map<String, dynamic>? resultadoPerfil = await _userService.actualizarDatosMetabolicos(datos);
      
      if (resultadoPerfil == null) { // Comprobamos si el resultado es nulo (error)
        throw Exception('No se pudo actualizar el perfil de usuario.');
      }

      // 2. Enviar la solicitud del plan
      final bool solicitudEnviada = await _dietaService.solicitarPlanDieta(datos);

      if (solicitudEnviada && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Solicitud enviada! Tu plan estará listo pronto.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
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
    final bool puedeSolicitar = widget.usuario.esPremium && widget.usuario.incluyePlanDieta;

    // --- Items de Menús ---
    final _generoItems = [
      const DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
      const DropdownMenuItem(value: 'femenino', child: Text('Femenino')),
    ];
    final _ocupacionItems = [
      const DropdownMenuItem(value: 'sedentaria', child: Text('Sedentaria (Oficina, mucho tiempo sentado)')),
      const DropdownMenuItem(value: 'ligera', child: Text('Ligera (Camina, dependiente, de pie)')),
      const DropdownMenuItem(value: 'activa', child: Text('Activa (Construcción, mucho movimiento)')),
    ];
    final _ejercicioItems = [
      const DropdownMenuItem(value: '0', child: Text('0 días / semana')),
      const DropdownMenuItem(value: '1-3', child: Text('1-3 días / semana')),
      const DropdownMenuItem(value: '4-5', child: Text('4-5 días / semana')),
      const DropdownMenuItem(value: '6-7', child: Text('6-7 días / semana')),
    ];
    final _objetivoItems = [
      const DropdownMenuItem(value: 'perder', child: Text('Perder Peso / Definir')),
      const DropdownMenuItem(value: 'mantener', child: Text('Mantener Peso')),
      const DropdownMenuItem(value: 'ganar', child: Text('Ganar Masa Muscular')),
    ];
    
    final _tiempoCocinaItems = _tiempoCocinaOpciones.entries
        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
        .toList();
        
    final _habilidadCocinaItems = _habilidadCocinaOpciones.entries
        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
        .toList();
        
    final _contextoComidaItems = _contextoComidaOpciones.entries
        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
        .toList();
        
    final _retoPrincipalItems = _retoPrincipalOpciones.entries
        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text('Configurar Dieta', style: TextStyle(color: Colors.white)),
        backgroundColor: _colorPrimario,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!puedeSolicitar)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(14)),
                  child: const Text(
                    'Este servicio no está incluido en tu plan. Habla con tu entrenador para activarlo.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              
              _buildSectionTitle('Datos Metabólicos', 'Para calcular tus calorías'),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Género',
                value: _genero,
                items: _generoItems,
                icon: Icons.person_outline,
                onChanged: (val) => setState(() { _genero = val; _calculoPersonalizado = false; }),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _buildTextField(
                  label: 'Peso (kg)',
                  controller: _pesoController,
                  icon: Icons.monitor_weight_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
                  onChanged: (_) => setState(() => _calculoPersonalizado = false),
                )),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(
                  label: 'Altura (cm)',
                  controller: _alturaController,
                  icon: Icons.height_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() => _calculoPersonalizado = false),
                )),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(
                  label: 'Edad',
                  controller: _edadController,
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() => _calculoPersonalizado = false),
                )),
              ]),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Ocupación Diaria',
                value: _ocupacion,
                items: _ocupacionItems,
                icon: Icons.work_outline,
                onChanged: (val) => setState(() { _ocupacion = val; _calculoPersonalizado = false; }),
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Ejercicio Físico (además de tu ocupación)',
                value: _ejercicio,
                items: _ejercicioItems,
                icon: Icons.fitness_center_outlined,
                onChanged: (val) => setState(() { _ejercicio = val; _calculoPersonalizado = false; }),
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Objetivo Principal',
                value: _objetivo,
                items: _objetivoItems,
                icon: Icons.flag_outlined,
                onChanged: (val) => setState(() { _objetivo = val; _calculoPersonalizado = false; }),
              ),
              const SizedBox(height: 20),
              
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calculate_outlined, color: Colors.white),
                  label: const Text('Calcular Calorías', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: _colorSecundario, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  onPressed: puedeSolicitar ? _calcularKcal : null,
                ),
              ),
              if (_kcalObjetivo > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(
                    child: Text(
                      'Kcal Objetivo: $_kcalObjetivo aprox.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _colorPrimario),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Divider(),
              
              _buildSectionTitle('Preferencias de Dieta', 'Ayúdanos a crear tu plan'),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Alergias o Intolerancias',
                hint: 'Ej: Ninguna, Lactosa, Frutos secos...',
                controller: _alergiasController,
                icon: Icons.no_food_outlined,
                isOptional: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Estilo de Dieta / Preferencias',
                hint: 'Ej: Omnívoro, Vegetariano, Vegano...',
                controller: _preferenciasController,
                icon: Icons.restaurant_menu_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Comidas por día',
                controller: _comidasController,
                icon: Icons.hourglass_bottom_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Historial Médico Relevante',
                hint: 'Ej: Diabetes tipo 2, Hipertensión...',
                controller: _historialController,
                icon: Icons.medical_services_outlined,
                maxLines: 2,
                isOptional: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Horarios (Opcional)',
                hint: 'Ej: Desayuno 8am, Almuerzo 2pm...',
                controller: _horariosController,
                icon: Icons.schedule_outlined,
                maxLines: 2,
                isOptional: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Platos Favoritos (Opcional)',
                hint: 'Ej: Lentejas, Pasta carbonara, Ensalada César...',
                controller: _platosFavoritosController,
                icon: Icons.favorite_border_outlined,
                maxLines: 2,
                isOptional: true,
              ),
              const SizedBox(height: 24),
              const Divider(),
              
              _buildSectionTitle('Logística y Adherencia', 'La clave para que puedas cumplir la dieta'),
              const SizedBox(height: 16),
              
              _buildDropdownField(
                label: 'Tiempo para cocinar (Comida/Cena)',
                value: _tiempoCocina,
                items: _tiempoCocinaItems,
                icon: Icons.timer_outlined,
                onChanged: (val) => setState(() { _tiempoCocina = val; }),
              ),
              const SizedBox(height: 16),
              
              _buildDropdownField(
                label: 'Habilidad en la cocina',
                value: _habilidadCocina,
                items: _habilidadCocinaItems,
                icon: Icons.soup_kitchen_outlined,
                onChanged: (val) => setState(() { _habilidadCocina = val; }),
              ),
              const SizedBox(height: 16),

              _buildDropdownField(
                label: '¿Dónde comes habitualmente?',
                value: _contextoComida,
                items: _contextoComidaItems,
                icon: Icons.place_outlined,
                onChanged: (val) => setState(() { _contextoComida = val; }),
              ),
              const SizedBox(height: 16),
              
              _buildDropdownField(
                label: 'Tu mayor reto o dificultad',
                value: _retoPrincipal,
                items: _retoPrincipalItems,
                icon: Icons.shield_outlined,
                onChanged: (val) => setState(() { _retoPrincipal = val; }),
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                label: 'Alimentos que NO te gustan',
                hint: 'Ej: Brócoli, pescado azul, lentejas...',
                controller: _alimentosOdiadosController,
                icon: Icons.thumb_down_outlined,
                maxLines: 2,
                isOptional: true,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                label: 'Bebidas habituales',
                hint: 'Ej: Agua, refrescos zero, cerveza...',
                controller: _bebidasController,
                icon: Icons.local_drink_outlined,
                maxLines: 2,
                isOptional: true,
              ),
              const SizedBox(height: 16),
              
              _buildEquipamientoCheckboxes(),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: (puedeSolicitar && !_isLoading) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Enviar Solicitud de Dieta',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets constructores ---

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
    Function(String)? onChanged,
  }) {
    // (Tu lógica de 'puedeSolicitar' se maneja en el onPressed/onChanged)
    final bool puedeSolicitar = widget.usuario.esPremium && widget.usuario.incluyePlanDieta;

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
      onChanged: onChanged,
      enabled: puedeSolicitar, // Desactiva el campo si no puede solicitar
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
    final bool puedeSolicitar = widget.usuario.esPremium && widget.usuario.incluyePlanDieta;
    
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
        fillColor: _colorCampos,
        disabledBorder: OutlineInputBorder( // Estilo cuando está desactivado
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!)
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Requerido';
        return null;
      },
    );
  }

  Widget _buildEquipamientoCheckboxes() {
    final bool puedeSolicitar = widget.usuario.esPremium && widget.usuario.incluyePlanDieta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Equipamiento Disponible (multiselección)', style: _labelStyle.copyWith(color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: puedeSolicitar ? _colorCampos : Colors.grey[200], // Fondo gris si está desactivado
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
                onSelected: puedeSolicitar ? (selected) { // Desactiva el chip si no puede solicitar
                  setState(() {
                    if (selected) {
                      _equipamientoSeleccionado.add(key);
                    } else {
                      _equipamientoSeleccionado.remove(key);
                    }
                  });
                } : null, // Fin de onSelected
                selectedColor: _colorSecundario.withOpacity(0.3),
                checkmarkColor: _colorSecundario,
                showCheckmark: true,
                disabledColor: _colorCampos.withOpacity(0.5), // Color cuando está desactivado
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
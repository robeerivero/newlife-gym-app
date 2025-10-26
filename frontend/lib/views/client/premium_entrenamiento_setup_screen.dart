// screens/client/premium_entrenamiento_setup_screen.dart
// ¡ESTILO DEFINITIVO APLICADO (Fondo azul + Tarjeta blanca)!

import 'package:flutter/material.dart';
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
  
  late TextEditingController _metaController;
  late TextEditingController _focoController;
  String? _equipamiento;
  int _tiempo = 45;

  bool _isLoading = false;
  String? _error;
  String? _estadoPlan;

  final IAEntrenamientoService _service = IAEntrenamientoService();

  bool get puedeSolicitar => _estadoPlan == 'pendiente_solicitud' || _estadoPlan == null;

  @override
  void initState() {
    super.initState();
    _metaController = TextEditingController(text: widget.usuario.premiumMeta);
    _focoController = TextEditingController(text: widget.usuario.premiumFoco);
    _equipamiento = widget.usuario.premiumEquipamiento.isNotEmpty ? widget.usuario.premiumEquipamiento : null;
    _tiempo = widget.usuario.premiumTiempo;
    _fetchPlanStatus();
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
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final datos = {
        'premiumMeta': _metaController.text,
        'premiumFoco': _focoController.text,
        'premiumEquipamiento': _equipamiento,
        'premiumTiempo': _tiempo,
      };

      bool exito = await _service.solicitarPlanEntrenamiento(datos);

      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferencias enviadas. Tu entrenador las revisará.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isLoading = false;
          _estadoPlan = 'pendiente_revision'; // Bloquea la UI
        });
        Navigator.of(context).pop(true); // Devuelve true para refrescar
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
      // --- ¡ESTILO AÑADIDO! ---
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        // --- ¡ESTILO AÑADIDO! ---
        title: const Text('Preferencias de Entrenamiento', style: TextStyle(color: Colors.white)),
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
                // --- ¡ESTRUCTURA DE TARJETA AÑADIDA! ---
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
                        mainAxisSize: MainAxisSize.min, // Para que la tarjeta se ajuste
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Define tu Entrenamiento',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorPrimario),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14.0),
                              child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                            ),

                          // --- 1. Meta (ESTILO APLICADO) ---
                          TextFormField(
                            controller: _metaController,
                            enabled: puedeSolicitar,
                            decoration: InputDecoration(
                              labelText: 'Meta Principal',
                              hintText: 'Ej: Hipertrofia, Fuerza, Perder Grasa',
                              prefixIcon: Icon(Icons.flag_outlined, color: colorPrimario),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              filled: true,
                              fillColor: Colors.blue[50],
                            ),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),

                          // --- 2. Foco (ESTILO APLICADO) ---
                          TextFormField(
                            controller: _focoController,
                            enabled: puedeSolicitar,
                            decoration: InputDecoration(
                              labelText: 'Foco (Opcional)',
                              hintText: 'Ej: "Mejorar pecho", "Piernas y glúteos"',
                              prefixIcon: Icon(Icons.center_focus_strong_outlined, color: colorPrimario),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              filled: true,
                              fillColor: Colors.blue[50],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // --- 3. Equipamiento (ESTILO APLICADO) ---
                          DropdownButtonFormField<String>(
                            value: _equipamiento,
                            items: const [
                              DropdownMenuItem(value: 'solo_cuerpo', child: Text('Solo Peso Corporal')),
                              DropdownMenuItem(value: 'mancuernas_basico', child: Text('Mancuernas/Básico')),
                              DropdownMenuItem(value: 'gym_completo', child: Text('Gimnasio Completo')),
                            ],
                            onChanged: puedeSolicitar ? (v) => setState(() => _equipamiento = v) : null,
                            decoration: InputDecoration(
                              labelText: 'Equipamiento Disponible',
                              prefixIcon: Icon(Icons.fitness_center_outlined, color: colorPrimario),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              filled: true,
                              fillColor: Colors.blue[50],
                            ),
                            validator: (v) => v == null ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 20),

                          // --- 4. Tiempo ---
                          Text(
                            'Tiempo por sesión: ${_tiempo.round()} min', 
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          Slider(
                            value: _tiempo.toDouble(),
                            min: 20, max: 90, divisions: 14,
                            label: '${_tiempo.round()} min',
                            activeColor: colorPrimario, // ¡Estilo añadido!
                            onChanged: puedeSolicitar ? (v) => setState(() => _tiempo = v.round()) : null,
                          ),
                          const SizedBox(height: 20),
                          
                          // --- 5. Botón de Envío ---
                          ElevatedButton.icon(
                            icon: Icon(_isLoading ? Icons.sync : Icons.save_alt_rounded, color: Colors.white),
                            label: Text(
                              _isLoading 
                                ? 'Procesando...' 
                                : (puedeSolicitar ? 'Enviar Preferencias' : 'Tu plan está en revisión'),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)
                            ),
                            // --- ¡ESTILO AÑADIDO! ---
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
}
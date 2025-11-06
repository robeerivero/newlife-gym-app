// screens/admin/plan_entrenamiento_edit_screen.dart
// ¡ACTUALIZADO CON ESTILO Y FLUJO MANUAL!
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../models/plan_entrenamiento.dart';
import '../../viewmodels/plan_review_viewmodel.dart';
import '../../services/ia_entrenamiento_service.dart'; // Para obtener prompt

class PlanEntrenamientoEditScreen extends StatefulWidget {
  final PlanEntrenamiento planInicial;
  final PlanReviewViewModel viewModel;
  const PlanEntrenamientoEditScreen({Key? key, required this.planInicial, required this.viewModel}) : super(key: key);

  @override
  State<PlanEntrenamientoEditScreen> createState() => _PlanEntrenamientoEditScreenState();
}

class _PlanEntrenamientoEditScreenState extends State<PlanEntrenamientoEditScreen> {
  // --- NUEVOS ESTADOS PARA FLUJO MANUAL ---
  String? _promptParaGenerar;
  bool _isLoadingPrompt = false;
  String? _errorPrompt;
  final TextEditingController _jsonPastedController = TextEditingController();
  bool _mostrarCamposEdicion = false;
  String? _parseJsonError;

  // --- Estados anteriores para edición detallada ---
  late List<List<Map<String, TextEditingController>>> _controllers; // [día][ejercicio][campo]
  late List<DiaEntrenamiento> _planEditado;
  late List<String> _diasSeleccionados; // Días para asignar el plan

  final List<String> _diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  // Servicio
  final IAEntrenamientoService _entrenamientoService = IAEntrenamientoService();


  @override
  void initState() {
    super.initState();
    _mostrarCamposEdicion = false;
    _controllers = [];
    _planEditado = [];
     // Inicializamos días seleccionados (puede venir vacío del backend)
    _diasSeleccionados = List<String>.from(widget.planInicial.diasAsignados);
    _fetchPrompt();
  }

 @override
  void dispose() {
    _jsonPastedController.dispose();
    for (var diaControllers in _controllers) {
      for (var ejercicioControllers in diaControllers) {
        ejercicioControllers.values.forEach((controller) => controller.dispose());
      }
    }
    super.dispose();
  }

  /// Carga el prompt desde el backend
  Future<void> _fetchPrompt() async {
    setState(() { _isLoadingPrompt = true; _errorPrompt = null; });
    try {
      final promptData = await _entrenamientoService.obtenerPromptParaRevision(widget.planInicial.id);
      setState(() => _promptParaGenerar = promptData['prompt']);
    } catch (e) {
      setState(() => _errorPrompt = "Error al cargar el prompt: $e");
    } finally {
      setState(() => _isLoadingPrompt = false);
    }
  }

  /// Intenta parsear el JSON pegado y prepara la UI de edición detallada
  void _parseAndPrepareEditUI() {
     setState(() { _parseJsonError = null; _mostrarCamposEdicion = false; _controllers = []; _planEditado = []; });
     final jsonString = _jsonPastedController.text.trim();
     if (jsonString.isEmpty) {
       setState(() => _parseJsonError = 'El campo JSON está vacío.');
       return;
     }

     try {
       final List<dynamic> jsonData = jsonDecode(jsonString);
       if (jsonData is! List) throw const FormatException("El JSON no es una lista.");

       final List<DiaEntrenamiento> parsedPlan = jsonData.map((diaJson) {
         if (diaJson is! Map<String, dynamic>) throw const FormatException("Elemento del array no es un objeto.");
         return DiaEntrenamiento.fromJson(diaJson);
       }).toList();

       _planEditado = parsedPlan;
       _initializeControllers();
       setState(() => _mostrarCamposEdicion = true);

     } on FormatException catch (e) {
       setState(() => _parseJsonError = 'Error al parsear JSON: ${e.message}');
     } catch (e) {
        setState(() => _parseJsonError = 'Error inesperado al procesar JSON: $e');
     }
  }

  /// Inicializa controllers para entrenamiento
  void _initializeControllers() {
    _controllers = _planEditado.map((dia) {
      return dia.ejercicios.map((ejercicio) {
        return {
          'nombre': TextEditingController(text: ejercicio.nombre),
          'series': TextEditingController(text: ejercicio.series),
          'repeticiones': TextEditingController(text: ejercicio.repeticiones),
          'descansoSeries': TextEditingController(text: ejercicio.descansoSeries),
          'descansoEjercicios': TextEditingController(text: ejercicio.descansoEjercicios),
          'descripcion': TextEditingController(text: ejercicio.descripcion),
        };
      }).toList();
    }).toList();
  }

  
  /// Muestra el prompt en un diálogo
  void _showPromptDialog() {
    if (_promptParaGenerar == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prompt para IA'),
        content: SingleChildScrollView(child: SelectableText(_promptParaGenerar!)),
        actions: [
          TextButton(
            child: const Text('Copiar'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _promptParaGenerar!));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prompt copiado'), backgroundColor: Colors.green),
              );
            },
          ),
          TextButton(child: const Text('Cerrar'), onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  /// Lógica para aprobar el plan (entrenamiento)
  void _aprobarPlan() async {
    final jsonString = _jsonPastedController.text.trim();
    if (jsonString.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Primero pega el JSON generado.'), backgroundColor: Colors.red),
       );
       return;
    }
     if (_diasSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar al menos un día de la semana.'), backgroundColor: Colors.red),
      );
      return;
    }

    final vm = widget.viewModel;
    final success = await vm.aprobarPlanEntrenamientoManual(
        idPlan: widget.planInicial.id,
        jsonString: jsonString, // Enviamos el JSON string crudo
        diasAsignados: _diasSeleccionados, // Enviamos los días seleccionados
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan aprobado con éxito.'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(vm.error ?? 'Error al aprobar el plan.'), backgroundColor: Colors.red),
       );
    }
  }


  @override
  Widget build(BuildContext context) {
    // Colores y estilo
    final Color appBarColor = const Color(0xFF1E88E5);
    final Color scaffoldBgColor = const Color(0xFFE3F2FD);
    final vm = widget.viewModel;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        title: Text('Revisar Plan Entren. (${widget.planInicial.mes})', style: const TextStyle(color: Colors.white)),
        backgroundColor: appBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
           IconButton(
             icon: const Icon(Icons.description_outlined, color: Colors.white),
             tooltip: 'Ver Prompt para IA',
             onPressed: _isLoadingPrompt ? null : _showPromptDialog,
           ),
        ],
      ),
      body: SingleChildScrollView(
         padding: const EdgeInsets.all(16.0),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             // --- 1. Info Usuario y Prompt ---
             _buildSectionTitle('Solicitud del Usuario'),
              _buildInfoRow('Usuario:', widget.planInicial.inputsUsuario['usuarioNombre'] ?? widget.planInicial.usuarioId),
              _buildInfoRow('Meta:', widget.planInicial.inputsUsuario['premiumMeta']?.toString() ?? 'N/A'),
              _buildInfoRow('Foco:', widget.planInicial.inputsUsuario['premiumFoco']?.toString() ?? 'N/A'),
              _buildInfoRow('Equipamiento:', widget.planInicial.inputsUsuario['premiumEquipamiento']?.toString() ?? 'N/A'),
              _buildInfoRow('Tiempo/sesión:', '${widget.planInicial.inputsUsuario['premiumTiempo']?.toString() ?? 'N/A'} min'),

             const SizedBox(height: 10),
             _isLoadingPrompt
                ? const Center(child: CircularProgressIndicator())
                : _errorPrompt != null
                   ? Text('Error prompt: $_errorPrompt', style: const TextStyle(color: Colors.red))
                   : ElevatedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Ver y Copiar Prompt para IA'),
                      onPressed: _showPromptDialog,
                     ),
             const SizedBox(height: 20),
             Divider(color: Colors.blue[200]),

            // --- 2. Campo para Pegar JSON ---
            _buildSectionTitle('Respuesta de la IA'),
             TextField(
               controller: _jsonPastedController,
               decoration: InputDecoration(
                 labelText: 'Pega aquí el JSON generado',
                 hintText: '[ { "nombreDia": ..., "ejercicios": [...] }, ... ]',
                 border: const OutlineInputBorder(),
                 filled: true, fillColor: Colors.white,
                 errorText: _parseJsonError,
               ),
               maxLines: 10,
               keyboardType: TextInputType.multiline,
             ),
             const SizedBox(height: 10),
             ElevatedButton(
               onPressed: _parseAndPrepareEditUI,
               child: const Text('Validar JSON y Previsualizar/Editar'),
             ),
             const SizedBox(height: 20),
             Divider(color: Colors.blue[200]),

             // --- 3. Selector de Días ---
             _buildSectionTitle('Asignar Días de la Semana'),
             _buildDiasSemanaSelector(),
             const SizedBox(height: 20),
             Divider(color: Colors.blue[200]),


             // --- 4. Edición Detallada (si aplica) ---
              if (_mostrarCamposEdicion)
               _buildSectionTitle('Edición Detallada del Plan'),
              if (_mostrarCamposEdicion)
                ..._buildPlanEditableUI(),

             const SizedBox(height: 30),

             // --- 5. Botón Aprobar ---
              ElevatedButton(
                onPressed: vm.isLoading ? null : _aprobarPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                   textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
                child: vm.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Aprobar Plan', style: TextStyle(color: Colors.white)),
              ),
           ],
         ),
      ),
    );
  }

 /// Construye el selector de días con ChoiceChips
  Widget _buildDiasSemanaSelector() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: _diasSemana.map((dia) {
        final isSelected = _diasSeleccionados.contains(dia);
        return ChoiceChip(
          label: Text(dia),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _diasSeleccionados.add(dia);
              } else {
                _diasSeleccionados.remove(dia);
              }
               // Opcional: Reordenar la lista si quieres que siempre estén en orden L-D
               // _diasSeleccionados.sort((a, b) => _diasSemana.indexOf(a).compareTo(_diasSemana.indexOf(b)));
            });
          },
          selectedColor: Colors.blue[400],
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
          backgroundColor: Colors.blue[50],
          shape: StadiumBorder(side: BorderSide(color: Colors.blue[100]!)),
        );
      }).toList(),
    );
  }

 /// Construye UI editable para entrenamiento
 List<Widget> _buildPlanEditableUI() {
    List<Widget> widgets = [];
    for (int iDia = 0; iDia < _planEditado.length; iDia++) {
      widgets.add(_buildSectionTitle(_planEditado[iDia].nombreDia));
      for (int iEjercicio = 0; iEjercicio < _planEditado[iDia].ejercicios.length; iEjercicio++) {
        widgets.add(_buildEjercicioEditableUI(iDia, iEjercicio));
        widgets.add(const SizedBox(height: 10));
      }
      widgets.add(const Divider(height: 20));
    }
    return widgets;
 }

 /// Construye UI para editar un ejercicio
 Widget _buildEjercicioEditableUI(int iDia, int iEjercicio) {
    final controllers = _controllers[iDia][iEjercicio];
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
         padding: const EdgeInsets.all(10.0),
         child: Column(
           children: [
             _buildEditableField('Nombre Ejercicio', controllers['nombre']!),
             const SizedBox(height: 8),
             Row(children: [ // Fila para Series y Reps
               Expanded(child: _buildEditableField('Series', controllers['series']!, keyboardType: TextInputType.text)), // A menudo es texto como "3-4"
               const SizedBox(width: 8),
               Expanded(child: _buildEditableField('Reps', controllers['repeticiones']!, keyboardType: TextInputType.text)),
             ]),
             const SizedBox(height: 8),
              Row(children: [ // Fila para Descansos
               Expanded(child: _buildEditableField('Desc. Series', controllers['descansoSeries']!)),
               const SizedBox(width: 8),
               Expanded(child: _buildEditableField('Desc. Ejer.', controllers['descansoEjercicios']!)),
             ]),
             const SizedBox(height: 8),
             _buildEditableField('Descripción/Notas', controllers['descripcion']!, maxLines: 3),
              // TODO: Botón para eliminar ejercicio
           ],
         ),
      ),
    );
 }

  // --- Helpers de UI (Estilo EditProfileScreen) ---
  Widget _buildEditableField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
        filled: true, fillColor: Colors.white,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildInfoRow(String label, String value) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

   Widget _buildSectionTitle(String title) {
     return Padding(
       padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
       child: Text(
         title,
         style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF1A237E)),
       ),
     );
   }
}
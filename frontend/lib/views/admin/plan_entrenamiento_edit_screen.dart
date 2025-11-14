// screens/admin/plan_entrenamiento_edit_screen.dart
// ¡VERSIÓN FINAL CORREGIDA!
// Parsea JSON flexible (Array o Objeto)
// Y usa ChoiceChip nativos (SIN LIBRERÍAS EXTERNAS)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
// ¡Ya no se necesita la librería multi_select_flutter!
// import 'package:multi_select_flutter/multi_select_flutter.dart'; 
import '../../models/plan_entrenamiento.dart';
import '../../viewmodels/plan_review_viewmodel.dart';
import '../../services/ia_entrenamiento_service.dart'; // Para obtener prompt

class PlanEntrenamientoEditScreen extends StatefulWidget {
  final PlanEntrenamiento planInicial;
  final PlanReviewViewModel viewModel;
  
  const PlanEntrenamientoEditScreen({
    super.key, 
    required this.planInicial, 
    required this.viewModel
  });

  @override
  State<PlanEntrenamientoEditScreen> createState() => _PlanEntrenamientoEditScreenState();
}

class _PlanEntrenamientoEditScreenState extends State<PlanEntrenamientoEditScreen> {
  // --- Estados para flujo manual ---
  String? _promptParaGenerar;
  bool _isLoadingData = true; // Un solo loading
  String? _errorData;
  final TextEditingController _jsonPastedController = TextEditingController();
  bool _mostrarCamposEdicion = false;
  String? _parseJsonError;

  // --- Estados para edición detallada ---
  late List<List<Map<String, TextEditingController>>> _controllers; // [día][ejercicio][campo]
  late List<DiaEntrenamiento> _planEditado;
  Set<String> _diasSeleccionados = {}; 
  final List<String> _todosLosDias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  // Servicio
  final IAEntrenamientoService _entrenamientoService = IAEntrenamientoService();
  late bool _esModoEdicion;

  @override
  void initState() {
    super.initState();
    _esModoEdicion = widget.planInicial.estado == 'aprobado';
    _controllers = [];
    _planEditado = [];
    _diasSeleccionados = widget.planInicial.diasAsignados.toSet(); // Carga inicial
    
    _loadDataForScreen();
  }

  @override
  void dispose() {
    _jsonPastedController.dispose();
    
    for (final diaControllers in _controllers) {
      for (final ejControllers in diaControllers) {
        for (final controller in ejControllers.values) {
          controller.dispose();
        }
      }
    }
    super.dispose();
  }

  /// Carga el prompt (pendiente) o el JSON (aprobado)
  Future<void> _loadDataForScreen() async {
    setState(() {
      _isLoadingData = true;
      _errorData = null;
    });
    try {
      if (_esModoEdicion) {
        // --- MODO EDICIÓN (Aprobado) ---
        final data = await _entrenamientoService.obtenerPlanParaEditar(widget.planInicial.id);
        _jsonPastedController.text = data['jsonStringParaEditar']; 
        
        // Llamamos a _parseAndPrepareUiFlexible
        _parseAndPrepareUiFlexible();

      } else {
        // --- MODO REVISIÓN (Pendiente) ---
        final data = await widget.viewModel.getPromptEntrenamiento(widget.planInicial.id);
        _promptParaGenerar = data['prompt'];
      }
    } catch (e) {
      _errorData = e.toString();
    } finally {
      setState(() { _isLoadingData = false; });
    }
  }

  /// ¡¡CORREGIDO Y FLEXIBLE!!
  /// Esta función ahora acepta AMBOS formatos:
  /// 1. El Objeto { "planGenerado": [...], "diasAsignados": [...] } (para modo Edición)
  /// 2. El Array [ ... ] (para modo Revisión, pegado manual)
  void _parseAndPrepareUiFlexible() {
    setState(() {
      _parseJsonError = null;
      _mostrarCamposEdicion = false;
      _controllers = [];
      _planEditado = [];
      // NO limpiamos los días seleccionados si es modo edición
      if (!_esModoEdicion) {
         _diasSeleccionados = {}; // Limpia días solo si es modo revisión
      }
    });

    final jsonString = _jsonPastedController.text.trim();
    if (jsonString.isEmpty) {
      setState(() => _parseJsonError = 'El campo JSON está vacío.');
      return;
    }

    try {
      final dynamic jsonData = jsonDecode(jsonString);
      
      List<dynamic> planGeneradoList;
      
      // --- LÓGICA DE FLEXIBILIDAD ---
      if (jsonData is Map<String, dynamic>) {
        // FORMATO OBJETO (Modo Edición o pegado completo)
        if (!jsonData.containsKey('planGenerado') || jsonData['planGenerado'] is! List) {
           throw const FormatException("El JSON (Objeto) no contiene 'planGenerado' (una lista).");
        }
        planGeneradoList = jsonData['planGenerado'];

        // Si el objeto tbn tiene días, los cargamos
        if (jsonData.containsKey('diasAsignados') && jsonData['diasAsignados'] is List) {
          _diasSeleccionados = (jsonData['diasAsignados'] as List<dynamic>).cast<String>().toSet();
        }
        
      } else if (jsonData is List<dynamic>) {
        // FORMATO ARRAY (Modo Revisión)
        planGeneradoList = jsonData;
        // No tocamos _diasSeleccionados, se deben elegir manualmente.

      } else {
        // FORMATO INCORRECTO
        throw const FormatException("El JSON no es ni un Objeto {..} ni un Array [..].");
      }
      // --- FIN LÓGICA ---

      // 2. Parseamos el plan (común para ambos)
      final List<DiaEntrenamiento> parsedPlan = planGeneradoList.map((diaJson) {
        if (diaJson is! Map<String, dynamic>) throw const FormatException("Elemento del array no es un objeto.");
        return DiaEntrenamiento.fromJson(diaJson);
      }).toList();

      // 3. Si todo va bien, inicializamos controllers y mostramos
      _planEditado = parsedPlan; 
      _initializeControllers(); 
      setState(() {
        _mostrarCamposEdicion = true; // Muestra la UI de edición detallada
      });

    } on FormatException catch (e) { // Captura el error de 'jsonDecode' o de formato
      setState(() => _parseJsonError = 'Error al parsear JSON: ${e.message}');
    } catch (e) { // Otros errores
      setState(() => _parseJsonError = 'Error inesperado al procesar JSON: $e');
    }
  }


  /// Inicializa los controllers
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

  /// Reconstruye el JSON a partir de los campos editados
  /// ¡¡IMPORTANTE!! Siempre reconstruye al formato Objeto { ... }
  String _reconstruirJsonString() {
    try {
      // 1. Reconstruye el array 'planGenerado' desde los controllers
      final List<Map<String, dynamic>> planGeneradoReconstruido = [];
      for (int iDia = 0; iDia < _planEditado.length; iDia++) {
        final diaOriginal = _planEditado[iDia];
        final List<Map<String, dynamic>> ejerciciosReconstruidos = [];
        
        for (int iEj = 0; iEj < diaOriginal.ejercicios.length; iEj++) {
          final controllers = _controllers[iDia][iEj];
          ejerciciosReconstruidos.add({
            'nombre': controllers['nombre']!.text,
            'series': controllers['series']!.text,
            'repeticiones': controllers['repeticiones']!.text,
            'descansoSeries': controllers['descansoSeries']!.text,
            'descansoEjercicios': controllers['descansoEjercicios']!.text,
            'descripcion': controllers['descripcion']!.text,
          });
        }
        planGeneradoReconstruido.add({
          'nombreDia': diaOriginal.nombreDia,
          'ejercicios': ejerciciosReconstruidos,
        }); // <-- ¡¡AQUÍ SE ELIMINÓ EL TEXTO BASURA!!
      }

      // 2. Crea el objeto final con los días asignados
      final Map<String, dynamic> jsonFinalObject = {
        "planGenerado": planGeneradoReconstruido,
        "diasAsignados": _diasSeleccionados.toList(),
      };
      
      return jsonEncode(jsonFinalObject);

    } catch (e) {
      // Si falla la reconstrucción, devolvemos un JSON de error
      return '{"error": "Fallo al reconstruir JSON", "planGenerado": [], "diasAsignados": []}';
    }
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
            },
          ),
          TextButton(
            child: const Text('Cerrar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Confirma y elimina
  Future<void> _confirmarEliminarPlan() async {
    final bool? confirmado = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar permanentemente el plan de ${widget.planInicial.usuarioNombre}?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      final success = await widget.viewModel.eliminarPlanEntrenamiento(widget.planInicial.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan eliminado'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.viewModel.error ?? 'Error al eliminar'), backgroundColor: Colors.red),
        );
      }
    }
  }


  /// Lógica para aprobar o guardar el plan
  void _aprobarOGuardarPlan() async {
    String jsonStringFinal;

    if (_mostrarCamposEdicion) {
      // Si hemos editado, reconstruimos SIEMPRE al formato Objeto { ... }
      jsonStringFinal = _reconstruirJsonString();
      _jsonPastedController.text = jsonStringFinal;
    } else {
      jsonStringFinal = _jsonPastedController.text.trim();
      // Si no hemos editado y pegamos solo [ ... ], fallará la validación.
      // Forzamos la validación interna para que el usuario vea la UI de edición.
      _parseAndPrepareUiFlexible();
      if (!_mostrarCamposEdicion) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, valida el JSON antes de guardar.'), backgroundColor: Colors.red),
        );
        return;
      }
      // Si la validación SÍ funcionó, reconstruimos
      jsonStringFinal = _reconstruirJsonString();
    }

    if (jsonStringFinal.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El JSON no puede estar vacío.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Validamos que el JSON parseado (que SIEMPRE será un Objeto) tenga los días correctos
    try {
      final data = jsonDecode(jsonStringFinal);

      if (data is! Map) {
         throw const FormatException("El JSON parseado no es un Objeto.");
      }
      // Validamos que los días seleccionados (en el Chip) coincidan con el plan (en los textfields)
      final int dias = _diasSeleccionados.length;
      final int rutinas = (data['planGenerado'] as List).length;

      if (rutinas == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: El plan no tiene rutinas. Valida el JSON.'), backgroundColor: Colors.red),
        );
        return;
      }

      if (dias != rutinas) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Has asignado $dias días pero has creado $rutinas rutinas.'), backgroundColor: Colors.red),
        );
        return;
      }
    } catch(e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: El JSON no es válido. ${e.toString()}'), backgroundColor: Colors.red),
      );
       return;
    }

    final vm = widget.viewModel;
    final success = await vm.aprobarPlanEntrenamientoManual(
        idPlan: widget.planInicial.id,
        jsonString: jsonStringFinal, // Siempre enviamos el Objeto { ... }
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_esModoEdicion ? 'Plan guardado' : 'Plan aprobado'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Error al guardar el plan.'), backgroundColor: Colors.red),
       );
    }
  }


  @override
  Widget build(BuildContext context) {
    final Color appBarColor = const Color(0xFF1E88E5);
    final Color scaffoldBgColor = const Color(0xFFE3F2FD);
    final vm = widget.viewModel;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        title: Text(
          _esModoEdicion ? 'Editar Plan (Entreno)' : 'Revisar Plan (Entreno)', 
          style: const TextStyle(color: Colors.white)
        ),
        backgroundColor: appBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
           if (!_esModoEdicion)
            IconButton(
              icon: const Icon(Icons.description_outlined, color: Colors.white),
              tooltip: 'Ver Prompt para IA',
              onPressed: _isLoadingData ? null : _showPromptDialog,
            ),
           if (_esModoEdicion)
             IconButton(
               icon: const Icon(Icons.delete_outline, color: Colors.white),
               tooltip: 'Eliminar Plan',
               onPressed: _confirmarEliminarPlan,
             ),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : _errorData != null
              ? Center(child: Text('Error al cargar datos: $_errorData'))
              : _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, PlanReviewViewModel vm) {
    final inputs = widget.planInicial.inputsUsuario;
    final String equipamientoStr = (inputs['premiumEquipamiento'] as List<dynamic>?)
        ?.cast<String>()
        .join(', ') ?? 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Solicitud del Usuario'),
          _buildInfoRow('Usuario:', widget.planInicial.usuarioNombre),
          _buildInfoRow('Grupo:', widget.planInicial.usuarioGrupo ?? 'N/A'),
          _buildInfoRow('Objetivo:', inputs['premiumMeta'] ?? 'N/A'),
          _buildInfoRow('Nivel:', inputs['premiumNivel'] ?? 'N/A'),
          _buildInfoRow('Días/Semana:', inputs['premiumDiasSemana']?.toString() ?? 'N/A'),
          _buildInfoRow('Tiempo/Sesión:', '${inputs['premiumTiempo'] ?? 'N/A'} min'),
          _buildInfoRow('Foco:', inputs['premiumFoco'] ?? 'N/A'),
          _buildInfoRow('Lesiones:', inputs['premiumLesiones'] ?? 'N/A'),
          _buildInfoRow('Odiados:', inputs['premiumEjerciciosOdiados'] ?? 'N/A'),
          _buildInfoRow('Equipamiento:', equipamientoStr),
          
          const SizedBox(height: 10),
          
          if (!_esModoEdicion && _promptParaGenerar != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Ver y Copiar Prompt para IA'),
              onPressed: _showPromptDialog,
            ),
          const SizedBox(height: 20),
          Divider(color: Colors.blue[200]),

          _buildSectionTitle(_esModoEdicion ? 'JSON del Plan' : 'Respuesta de la IA'),
          TextField(
            controller: _jsonPastedController,
            decoration: InputDecoration(
              labelText: _esModoEdicion ? 'JSON (Editar con precaución)' : 'Pega aquí el JSON generado',
              hintText: 'Formato: [ { "nombreDia": ... } ] o { "planGenerado": [...] }',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              errorText: _parseJsonError,
            ),
            maxLines: 10,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _parseAndPrepareUiFlexible, 
            child: Text(_esModoEdicion ? 'Validar y Cargar Campos' : 'Validar JSON y Previsualizar/Editar'),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.blue[200]),

          if (_mostrarCamposEdicion)
            _buildSectionTitle('Edición Detallada del Plan'),
            
          if (_mostrarCamposEdicion)
            _buildDaySelector(), // <-- Llama a la versión con ChoiceChip
            
          if (_mostrarCamposEdicion)
            ..._buildPlanEditableUI(),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: vm.isLoading ? null : _aprobarOGuardarPlan,
            style: ElevatedButton.styleFrom(
              backgroundColor: _esModoEdicion ? Colors.blue[600] : Colors.green[600],
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
            child: vm.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(_esModoEdicion ? 'Guardar Cambios' : 'Aprobar Plan', style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// ¡¡REEMPLAZADO!! Widget para seleccionar días (VERSIÓN CON CHOICECHIP NATIVO)
  Widget _buildDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Días Asignados (${_diasSeleccionados.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
         // ¡¡AQUÍ SE ELIMINÓ EL TEXTO BASURA!! (description: decoration: ...)
          decoration: BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.circular(8),
             border: Border.all(color: Colors.grey[400]!)
          ),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _todosLosDias.map((dia) { // <-- Ahora '_todosLosDias' SÍ se usa
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
                  });
                },
                selectedColor: Colors.blue[100],
                labelStyle: TextStyle(color: isSelected ? Colors.blue[800] : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                backgroundColor: Colors.grey[100],
                shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.blue[100]! : Colors.grey[300]!)),
              );
            }).toList(),
          ),
         ),
        const SizedBox(height: 16),
      ],
    ); // <-- ¡¡AQUÍ SE ELIMINÓ EL TEXTO BASURA!!
  }


  /// Construye la UI de edición detallada
  List<Widget> _buildPlanEditableUI() {
    List<Widget> widgets = [];
    for (int iDia = 0; iDia < _planEditado.length; iDia++) {
      widgets.add(_buildSectionTitle(_planEditado[iDia].nombreDia));
      for (int iEj = 0; iEj < _planEditado[iDia].ejercicios.length; iEj++) {
        widgets.add(_buildEjercicioEditableUI(iDia, iEj));
        widgets.add(const SizedBox(height: 10));
      }
      widgets.add(const Divider(height: 20));
    }
    return widgets;
  }

  /// Construye la UI para editar un ejercicio
  Widget _buildEjercicioEditableUI(int iDia, int iEj) {
    final controllers = _controllers[iDia][iEj];
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            _buildEditableField('Nombre Ejercicio', controllers['nombre']!),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _buildEditableField('Series', controllers['series']!)),
              const SizedBox(width: 8),
              Expanded(child: _buildEditableField('Repeticiones', controllers['repeticiones']!)),
            ]),
            const SizedBox(height: 8),
             Row(children: [
              Expanded(child: _buildEditableField('Desc. Series', controllers['descansoSeries']!)),
              const SizedBox(width: 8),
            // ¡¡AQUÍ SE ELIMINÓ EL TEXTO BASURA!!
              Expanded(child: _buildEditableField('Desc. Ejs', controllers['descansoEjercicios']!)),
            ]),
            const SizedBox(height: 8),
            _buildEditableField('Descripción', controllers['descripcion']!, maxLines: 3),
          ],
        ),
      ),
    );
  }


  // --- Helpers de UI ---
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
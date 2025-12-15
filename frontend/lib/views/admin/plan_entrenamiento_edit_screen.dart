import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../models/plan_entrenamiento.dart';
import '../../viewmodels/plan_review_viewmodel.dart';
import '../../services/ia_entrenamiento_service.dart';

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
  bool _isLoadingData = true;
  String? _errorData;
  final TextEditingController _jsonPastedController = TextEditingController();
  bool _mostrarCamposEdicion = false;
  String? _parseJsonError;

  // --- Estados para edición detallada ---
  // Estructura: [día][ejercicio][campo]
  late List<List<Map<String, TextEditingController>>> _controllers; 
  late List<DiaEntrenamiento> _planEditado;
  Set<String> _diasSeleccionados = {}; 
  final List<String> _todosLosDias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  final IAEntrenamientoService _entrenamientoService = IAEntrenamientoService();
  late bool _esModoEdicion;

  @override
  void initState() {
    super.initState();
    _esModoEdicion = widget.planInicial.estado == 'aprobado';
    _controllers = [];
    _planEditado = [];
    _diasSeleccionados = widget.planInicial.diasAsignados.toSet();
    
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

  Future<void> _loadDataForScreen() async {
    setState(() {
      _isLoadingData = true;
      _errorData = null;
    });
    try {
      if (_esModoEdicion) {
        final data = await _entrenamientoService.obtenerPlanParaEditar(widget.planInicial.id);
        _jsonPastedController.text = data['jsonStringParaEditar']; 
        _parseAndPrepareUiFlexible();
      } else {
        final data = await widget.viewModel.getPromptEntrenamiento(widget.planInicial.id);
        _promptParaGenerar = data['prompt'];
      }
    } catch (e) {
      _errorData = e.toString();
    } finally {
      setState(() { _isLoadingData = false; });
    }
  }

  void _parseAndPrepareUiFlexible() {
    setState(() {
      _parseJsonError = null;
      _mostrarCamposEdicion = false;
      _controllers = [];
      _planEditado = [];
      if (!_esModoEdicion) {
         _diasSeleccionados = {}; 
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
      
      if (jsonData is Map<String, dynamic>) {
        if (!jsonData.containsKey('planGenerado') || jsonData['planGenerado'] is! List) {
           throw const FormatException("El JSON (Objeto) no contiene 'planGenerado' (una lista).");
        }
        planGeneradoList = jsonData['planGenerado'];

        if (jsonData.containsKey('diasAsignados') && jsonData['diasAsignados'] is List) {
          _diasSeleccionados = (jsonData['diasAsignados'] as List<dynamic>).cast<String>().toSet();
        }
        
      } else if (jsonData is List<dynamic>) {
        planGeneradoList = jsonData;
      } else {
        throw const FormatException("El JSON no es ni un Objeto {..} ni un Array [..].");
      }

      final List<DiaEntrenamiento> parsedPlan = planGeneradoList.map((diaJson) {
        if (diaJson is! Map<String, dynamic>) throw const FormatException("Elemento del array no es un objeto.");
        return DiaEntrenamiento.fromJson(diaJson);
      }).toList();

      _planEditado = parsedPlan; 
      _initializeControllers(); 
      setState(() {
        _mostrarCamposEdicion = true;
      });

    } on FormatException catch (e) {
      setState(() => _parseJsonError = 'Error al parsear JSON: ${e.message}');
    } catch (e) {
      setState(() => _parseJsonError = 'Error inesperado al procesar JSON: $e');
    }
  }

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

  String _reconstruirJsonString() {
    try {
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
        });
      }

      final Map<String, dynamic> jsonFinalObject = {
        "planGenerado": planGeneradoReconstruido,
        "diasAsignados": _diasSeleccionados.toList(),
      };
      
      return jsonEncode(jsonFinalObject);

    } catch (e) {
      return '{"error": "Fallo al reconstruir JSON", "planGenerado": [], "diasAsignados": []}';
    }
  }

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
                const SnackBar(content: Text('Prompt copiado al portapapeles')),
              );
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
            // Usa el color de error del tema
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
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
          const SnackBar(content: Text('Plan eliminado')),
        );
        Navigator.of(context).pop(true);
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.viewModel.error ?? 'Error al eliminar'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  void _aprobarOGuardarPlan() async {
    String jsonStringFinal;

    if (_mostrarCamposEdicion) {
      jsonStringFinal = _reconstruirJsonString();
      _jsonPastedController.text = jsonStringFinal;
    } else {
      jsonStringFinal = _jsonPastedController.text.trim();
      _parseAndPrepareUiFlexible();
      if (!_mostrarCamposEdicion) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Por favor, valida el JSON antes de guardar.'), backgroundColor: Theme.of(context).colorScheme.error),
        );
        return;
      }
      jsonStringFinal = _reconstruirJsonString();
    }

    if (jsonStringFinal.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('El JSON no puede estar vacío.'), backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }
    
    try {
      final data = jsonDecode(jsonStringFinal);
      if (data is! Map) {
         throw const FormatException("El JSON parseado no es un Objeto.");
      }
      final int dias = _diasSeleccionados.length;
      final int rutinas = (data['planGenerado'] as List).length;

      if (rutinas == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Error: El plan no tiene rutinas. Valida el JSON.'), backgroundColor: Theme.of(context).colorScheme.error),
        );
        return;
      }

      if (dias != rutinas) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Has asignado $dias días pero has creado $rutinas rutinas.'), backgroundColor: Theme.of(context).colorScheme.error),
        );
        return;
      }
    } catch(e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: El JSON no es válido. ${e.toString()}'), backgroundColor: Theme.of(context).colorScheme.error),
      );
       return;
    }

    final vm = widget.viewModel;
    final success = await vm.aprobarPlanEntrenamientoManual(
        idPlan: widget.planInicial.id,
        jsonString: jsonStringFinal,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_esModoEdicion ? 'Plan guardado' : 'Plan aprobado')),
      );
      Navigator.of(context).pop(true);
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Error al guardar el plan.'), backgroundColor: Theme.of(context).colorScheme.error),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = widget.viewModel;

    return Scaffold(
      // backgroundColor heredado del tema
      appBar: AppBar(
        title: Text(_esModoEdicion ? 'Editar Entreno' : 'Revisar Entreno'),
        actions: [
           if (!_esModoEdicion)
            IconButton(
              icon: const Icon(Icons.description_outlined),
              tooltip: 'Ver Prompt',
              onPressed: _isLoadingData ? null : _showPromptDialog,
            ),
           if (_esModoEdicion)
             IconButton(
               icon: const Icon(Icons.delete_outline),
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
    final theme = Theme.of(context);
    // Recuperar datos con seguridad
    final inputs = widget.planInicial.inputsUsuario;
    final String equipamientoStr = (inputs['premiumEquipamiento'] is List)
        ? (inputs['premiumEquipamiento'] as List).join(', ') 
        : (inputs['premiumEquipamiento']?.toString() ?? 'N/A');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Solicitud del Usuario', context),
          _buildInfoRow('Usuario:', widget.planInicial.usuarioNombre, context),
          _buildInfoRow('Grupo:', widget.planInicial.usuarioGrupo ?? 'N/A', context),
          _buildInfoRow('Objetivo:', inputs['premiumMeta'] ?? 'N/A', context),
          _buildInfoRow('Nivel:', inputs['premiumNivel'] ?? 'N/A', context),
          _buildInfoRow('Días/Semana:', inputs['premiumDiasSemana']?.toString() ?? 'N/A', context),
          _buildInfoRow('Equipamiento:', equipamientoStr, context),
          
          const SizedBox(height: 10),
          
          if (!_esModoEdicion && _promptParaGenerar != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Ver Prompt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
              onPressed: _showPromptDialog,
            ),
          const SizedBox(height: 20),
          const Divider(),

          _buildSectionTitle(_esModoEdicion ? 'JSON del Plan' : 'Respuesta de la IA', context),
          TextField(
            controller: _jsonPastedController,
            decoration: InputDecoration(
              labelText: _esModoEdicion ? 'JSON (Editar con precaución)' : 'Pega aquí el JSON generado',
              hintText: 'Formato: [ { "nombreDia": ... } ] o { "planGenerado": [...] }',
              errorText: _parseJsonError,
              // Estilo limpio del tema por defecto
            ),
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _parseAndPrepareUiFlexible, 
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary),
            child: Text(
              _esModoEdicion ? 'Validar y Cargar Campos' : 'Validar JSON',
              style: const TextStyle(color: Colors.white)
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),

          if (_mostrarCamposEdicion)
            _buildSectionTitle('Edición Detallada del Plan', context),
            
          if (_mostrarCamposEdicion)
            _buildDaySelector(context), 
            
          if (_mostrarCamposEdicion)
            ..._buildPlanEditableUI(context),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: vm.isLoading ? null : _aprobarOGuardarPlan,
            style: ElevatedButton.styleFrom(
              // Usamos Primary (Teal) para la acción principal
              backgroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: vm.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _esModoEdicion ? 'Guardar Cambios' : 'Aprobar Plan', 
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Widget de selección de días con estilo del tema
  Widget _buildDaySelector(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Días Asignados (${_diasSeleccionados.length})',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
             color: theme.colorScheme.surface,
             borderRadius: BorderRadius.circular(8),
             border: Border.all(color: Colors.grey.withOpacity(0.3))
          ),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _todosLosDias.map((dia) {
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
                // Estilos de color usando el tema
                selectedColor: theme.colorScheme.primaryContainer,
                backgroundColor: theme.scaffoldBackgroundColor,
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected ? theme.colorScheme.primary : Colors.grey.withOpacity(0.3)
                  )
                ),
              );
            }).toList(),
          ),
         ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _buildPlanEditableUI(BuildContext context) {
    List<Widget> widgets = [];
    for (int iDia = 0; iDia < _planEditado.length; iDia++) {
      widgets.add(_buildSectionTitle(_planEditado[iDia].nombreDia, context));
      for (int iEj = 0; iEj < _planEditado[iDia].ejercicios.length; iEj++) {
        widgets.add(_buildEjercicioEditableUI(iDia, iEj));
        widgets.add(const SizedBox(height: 10));
      }
      widgets.add(const Divider(height: 20));
    }
    return widgets;
  }

  Widget _buildEjercicioEditableUI(int iDia, int iEj) {
    final controllers = _controllers[iDia][iEj];
    return Card(
      elevation: 1, // Sombra suave
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
              Expanded(child: _buildEditableField('Desc. Ejs', controllers['descansoEjercicios']!)),
            ]),
            const SizedBox(height: 8),
            _buildEditableField('Descripción', controllers['descripcion']!, maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        // Eliminado fillColor/filled manuales, el Theme lo gestiona
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

   Widget _buildSectionTitle(String title, BuildContext context) {
     return Padding(
       padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
       child: Text(
         title,
         style: Theme.of(context).textTheme.titleLarge?.copyWith(
           color: Theme.of(context).colorScheme.primary,
           fontWeight: FontWeight.bold
         ),
       ),
     );
   }
}
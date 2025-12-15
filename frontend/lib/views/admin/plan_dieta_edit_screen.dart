// screens/admin/plan_dieta_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../models/plan_dieta.dart';
import '../../viewmodels/plan_review_viewmodel.dart';
import '../../services/ia_dieta_service.dart';

class PlanDietaEditScreen extends StatefulWidget {
  final PlanDieta planInicial;
  final PlanReviewViewModel viewModel;

  const PlanDietaEditScreen({Key? key, required this.planInicial, required this.viewModel}) : super(key: key);

  @override
  State<PlanDietaEditScreen> createState() => _PlanDietaEditScreenState();
}

class _PlanDietaEditScreenState extends State<PlanDietaEditScreen> {
  // --- Estados para flujo manual ---
  String? _promptParaGenerar;
  bool _isLoadingData = true;
  String? _errorData;
  final TextEditingController _jsonPastedController = TextEditingController();
  bool _mostrarCamposEdicion = false;
  String? _parseJsonError;

  // --- Estados para edición detallada ---
  late List<List<List<Map<String, TextEditingController>>>> _controllers;
  late List<DiaDieta> _planEditado;
  Map<String, dynamic> _listaCompraEditada = {};

  final IADietaService _dietaService = IADietaService();
  late bool _esModoEdicion;

  @override
  void initState() {
    super.initState();
    _esModoEdicion = widget.planInicial.estado == 'aprobado';
    _controllers = [];
    _planEditado = [];
    _loadDataForScreen();
  }

  @override
  void dispose() {
    _jsonPastedController.dispose();
    for (var diaControllers in _controllers) {
      for (var comidaControllers in diaControllers) {
        for (var opcionControllers in comidaControllers) {
          opcionControllers.values.forEach((controller) => controller.dispose());
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
        final data = await _dietaService.obtenerPlanParaEditar(widget.planInicial.id);
        _jsonPastedController.text = data['jsonStringParaEditar'];
        _parseAndPrepareEditUI(); 
      } else {
        final data = await widget.viewModel.getPromptDieta(widget.planInicial.id);
        _promptParaGenerar = data['prompt'];
      }
    } catch (e) {
      _errorData = e.toString();
    } finally {
      setState(() { _isLoadingData = false; });
    }
  }

  void _parseAndPrepareEditUI() {
    setState(() {
      _parseJsonError = null;
      _mostrarCamposEdicion = false;
      _controllers = [];
      _planEditado = [];
      _listaCompraEditada = {};
    });

    final jsonString = _jsonPastedController.text.trim();
    if (jsonString.isEmpty) {
      setState(() => _parseJsonError = 'El campo JSON está vacío.');
      return;
    }

    try {
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      
      if (jsonData is! Map) throw const FormatException("El JSON no es un objeto.");
      if (!jsonData.containsKey('planSemanal') || jsonData['planSemanal'] is! List) {
         throw const FormatException("El JSON no contiene 'planSemanal' (una lista).");
      }
      
      final List<dynamic> planSemanalList = jsonData['planSemanal'];
      final List<DiaDieta> parsedPlan = planSemanalList.map((diaJson) {
         if (diaJson is! Map<String, dynamic>) throw const FormatException("Elemento del array no es un objeto.");
         return DiaDieta.fromJson(diaJson);
      }).toList();

      if (jsonData.containsKey('listaCompra')) {
         _listaCompraEditada = jsonData['listaCompra'] as Map<String, dynamic>;
      }

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
       return dia.comidas.map((comida) {
         return comida.opciones.map((opcion) {
           return {
             'nombrePlato': TextEditingController(text: opcion.nombrePlato),
             'kcalAprox': TextEditingController(text: opcion.kcalAprox.toString()),
             'ingredientes': TextEditingController(text: opcion.ingredientes),
             'receta': TextEditingController(text: opcion.receta),
           };
         }).toList();
       }).toList();
     }).toList();
  }

  String _reconstruirJsonString() {
    try {
      final List<Map<String, dynamic>> planSemanalReconstruido = [];
      for (int iDia = 0; iDia < _planEditado.length; iDia++) {
        final diaOriginal = _planEditado[iDia];
        final List<Map<String, dynamic>> comidasReconstruidas = [];
        
        for (int iComida = 0; iComida < diaOriginal.comidas.length; iComida++) {
          final comidaOriginal = diaOriginal.comidas[iComida];
          final List<Map<String, dynamic>> opcionesReconstruidas = [];
          
          for (int iOpcion = 0; iOpcion < comidaOriginal.opciones.length; iOpcion++) {
            final controllers = _controllers[iDia][iComida][iOpcion];
            opcionesReconstruidas.add({
              'nombrePlato': controllers['nombrePlato']!.text,
              'kcalAprox': int.tryParse(controllers['kcalAprox']!.text) ?? 0,
              'ingredientes': controllers['ingredientes']!.text,
              'receta': controllers['receta']!.text,
            });
          }
          comidasReconstruidas.add({
            'nombreComida': comidaOriginal.nombreComida,
            'opciones': opcionesReconstruidas,
          });
        }
        planSemanalReconstruido.add({
          'nombreDia': diaOriginal.nombreDia,
          'kcalDiaAprox': diaOriginal.kcalDiaAprox,
          'comidas': comidasReconstruidas,
        });
      }

      final Map<String, dynamic> jsonFinalObject = {
        "planSemanal": planSemanalReconstruido,
        "listaCompra": _listaCompraEditada,
      };
      
      return jsonEncode(jsonFinalObject);

    } catch (e) {
      return _jsonPastedController.text.trim();
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
                const SnackBar(content: Text('Copiado al portapapeles')),
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
        content: Text('¿Eliminar plan de ${widget.planInicial.usuarioNombre}?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Eliminar'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      final success = await widget.viewModel.eliminarPlanDieta(widget.planInicial.id);
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
    }

    if (jsonStringFinal.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('El JSON está vacío.'), backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }

    final vm = widget.viewModel;
    final success = await vm.aprobarPlanDietaManual(
        idPlan: widget.planInicial.id,
        jsonString: jsonStringFinal,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_esModoEdicion ? 'Guardado con éxito' : 'Aprobado con éxito.')),
      );
      Navigator.of(context).pop(true);
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Error al guardar.'), backgroundColor: Theme.of(context).colorScheme.error),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = widget.viewModel;

    return Scaffold(
      // backgroundColor lo maneja el tema
      appBar: AppBar(
        title: Text(
          _esModoEdicion ? 'Editar Dieta' : 'Revisar Dieta', 
        ),
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
               tooltip: 'Eliminar',
               onPressed: _confirmarEliminarPlan,
             ),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : _errorData != null
              ? Center(child: Text('Error: $_errorData'))
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final vm = widget.viewModel;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Datos del Usuario', context),
          _buildInfoRow('Usuario:', widget.planInicial.usuarioNombre, context),
           _buildInfoRow('Grupo:', widget.planInicial.usuarioGrupo ?? 'N/A', context),
          _buildInfoRow('Objetivo:', widget.planInicial.inputsUsuario['objetivo']?.toString() ?? 'N/A', context),
          _buildInfoRow('Kcal:', widget.planInicial.inputsUsuario['kcalObjetivo']?.toString() ?? 'N/A', context),
          _buildInfoRow('Odiados:', widget.planInicial.inputsUsuario['dietaAlimentosOdiados'] ?? 'N/A', context),

          const SizedBox(height: 10),
          
          if (!_esModoEdicion && _promptParaGenerar != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copiar Prompt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
              onPressed: _showPromptDialog,
            ),
          const SizedBox(height: 20),
          const Divider(),

          _buildSectionTitle(_esModoEdicion ? 'JSON del Plan' : 'Respuesta IA', context),
          TextField(
            controller: _jsonPastedController,
            decoration: InputDecoration(
              labelText: 'JSON',
              hintText: '{ "planSemanal": [...], "listaCompra": {...} }',
              errorText: _parseJsonError,
              // Estilo limpio del tema
            ),
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _parseAndPrepareEditUI,
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary),
            child: Text(
              _esModoEdicion ? 'Recargar Campos' : 'Validar JSON',
              style: const TextStyle(color: Colors.white)
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),

          if (_mostrarCamposEdicion)
            _buildSectionTitle('Edición Detallada', context),
          if (_mostrarCamposEdicion)
            ..._buildPlanEditableUI(),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: vm.isLoading ? null : _aprobarOGuardarPlan,
            style: ElevatedButton.styleFrom(
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

  List<Widget> _buildPlanEditableUI() {
    List<Widget> widgets = [];
    for (int iDia = 0; iDia < _planEditado.length; iDia++) {
      widgets.add(_buildSectionTitle(_planEditado[iDia].nombreDia, context));
      for (int iComida = 0; iComida < _planEditado[iDia].comidas.length; iComida++) {
        widgets.add(_buildComidaEditableUI(iDia, iComida));
        widgets.add(const SizedBox(height: 10));
      }
      widgets.add(const Divider(height: 20));
    }
    return widgets;
  }

  Widget _buildComidaEditableUI(int iDia, int iComida) {
    final nombreComida = _planEditado[iDia].comidas[iComida].nombreComida;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nombreComida, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
            const Divider(),
            ...List.generate(_planEditado[iDia].comidas[iComida].opciones.length, (iOpcion) {
              return _buildOpcionEditableUI(iDia, iComida, iOpcion);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionEditableUI(int iDia, int iComida, int iOpcion) {
    final controllers = _controllers[iDia][iComida][iOpcion];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        children: [
          Row(children: [
             Expanded(flex: 3, child: _buildEditableField('Plato', controllers['nombrePlato']!)),
             const SizedBox(width: 8),
             Expanded(flex: 1, child: _buildEditableField('Kcal', controllers['kcalAprox']!, keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 8),
          _buildEditableField('Ingredientes', controllers['ingredientes']!, maxLines: 2),
          const SizedBox(height: 8),
          _buildEditableField('Receta', controllers['receta']!, maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        // El tema maneja los bordes y el fill color
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
// screens/admin/plan_dieta_edit_screen.dart
// ¡VERSIÓN CORREGIDA!
// Combina tu UI de edición detallada + la lógica de "Modo Edición" y "Eliminar".

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para copiar al portapapeles
import 'dart:convert'; // Para jsonDecode
import '../../models/plan_dieta.dart';
import '../../viewmodels/plan_review_viewmodel.dart';
import '../../services/ia_dieta_service.dart'; // Necesario para llamar a obtenerPrompt

class PlanDietaEditScreen extends StatefulWidget {
  final PlanDieta planInicial;
  final PlanReviewViewModel viewModel;

  const PlanDietaEditScreen({Key? key, required this.planInicial, required this.viewModel}) : super(key: key);

  @override
  State<PlanDietaEditScreen> createState() => _PlanDietaEditScreenState();
}

class _PlanDietaEditScreenState extends State<PlanDietaEditScreen> {
  // --- ESTADOS PARA FLUJO MANUAL ---
  String? _promptParaGenerar;
  bool _isLoadingData = true; // Renombrado de _isLoadingPrompt
  String? _errorData; // Renombrado de _errorPrompt
  final TextEditingController _jsonPastedController = TextEditingController();
  bool _mostrarCamposEdicion = false; // Controla si mostramos el textfield o los campos detallados
  String? _parseJsonError; // Para mostrar errores si el JSON pegado es inválido

  // --- Estados para edición detallada ---
  late List<List<List<Map<String, TextEditingController>>>> _controllers;
  late List<DiaDieta> _planEditado; // Para reconstruir el plan
  // ¡NUEVO! Almacenamos la lista de la compra para re-serializarla
  Map<String, dynamic> _listaCompraEditada = {};

  // Servicio para obtener el prompt/plan
  final IADietaService _dietaService = IADietaService();
  
  // ¡NUEVO! Determina si la pantalla es para Editar o Revisar
  late bool _esModoEdicion;

  @override
  void initState() {
    super.initState();
    _esModoEdicion = widget.planInicial.estado == 'aprobado';
    _controllers = [];
    _planEditado = [];
    
    // Llamamos a la nueva función que carga o el prompt o el JSON
    _loadDataForScreen();
  }

  @override
  void dispose() {
    _jsonPastedController.dispose();
    // Dispose de los controllers anidados (si se crearon)
    for (var diaControllers in _controllers) {
      for (var comidaControllers in diaControllers) {
        for (var opcionControllers in comidaControllers) {
          opcionControllers.values.forEach((controller) => controller.dispose());
        }
      }
    }
    super.dispose();
  }

  /// ¡NUEVO! Carga datos diferentes según el estado del plan.
  Future<void> _loadDataForScreen() async {
    setState(() {
      _isLoadingData = true;
      _errorData = null;
    });
    try {
      if (_esModoEdicion) {
        // --- MODO EDICIÓN (Plan 'aprobado') ---
        // 1. Llamamos al nuevo endpoint para obtener el JSON actual
        final data = await _dietaService.obtenerPlanParaEditar(widget.planInicial.id);
        // 2. Rellenamos el controlador con el JSON existente
        _jsonPastedController.text = data['jsonStringParaEditar'];
        // 3. ¡Parseamos y mostramos la UI de edición automáticamente!
        _parseAndPrepareEditUI(); 
        
      } else {
        // --- MODO REVISIÓN (Plan 'pendiente_revision') ---
        // 1. Obtenemos el prompt (como antes)
        final data = await widget.viewModel.getPromptDieta(widget.planInicial.id);
        _promptParaGenerar = data['prompt'];
      }
    } catch (e) {
      _errorData = e.toString();
    } finally {
      setState(() { _isLoadingData = false; });
    }
  }


  /// ¡CORREGIDO! Intenta parsear el JSON (ahora un OBJETO) y prepara la UI de edición
  void _parseAndPrepareEditUI() {
    setState(() {
      _parseJsonError = null;
      _mostrarCamposEdicion = false;
      _controllers = [];
      _planEditado = [];
      _listaCompraEditada = {}; // Limpia la lista de la compra
    });

    final jsonString = _jsonPastedController.text.trim();
    if (jsonString.isEmpty) {
      setState(() => _parseJsonError = 'El campo JSON está vacío.');
      return;
    }

    try {
      // --- ¡MODIFICADO! El JSON raíz ahora es un Objeto (Map) ---
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      
      // Validamos la nueva estructura
      if (jsonData is! Map) throw const FormatException("El JSON no es un objeto.");
      if (!jsonData.containsKey('planSemanal') || jsonData['planSemanal'] is! List) {
         throw const FormatException("El JSON no contiene 'planSemanal' (una lista).");
      }
      if (!jsonData.containsKey('listaCompra') || jsonData['listaCompra'] is! Map) {
         throw const FormatException("El JSON no contiene 'listaCompra' (un objeto).");
      }

      // 1. Extraemos la lista del plan semanal
      final List<dynamic> planSemanalList = jsonData['planSemanal'];

      // 2. Parseamos el plan semanal (como antes)
      final List<DiaDieta> parsedPlan = planSemanalList.map((diaJson) {
         if (diaJson is! Map<String, dynamic>) throw const FormatException("Elemento del array no es un objeto.");
         return DiaDieta.fromJson(diaJson);
      }).toList();

      // 3. ¡NUEVO! Guardamos la lista de la compra
      _listaCompraEditada = jsonData['listaCompra'] as Map<String, dynamic>;

      // 4. Si todo va bien, inicializamos controllers y mostramos
      _planEditado = parsedPlan; 
      _initializeControllers(); 
      setState(() {
        _mostrarCamposEdicion = true; // Muestra la UI de edición detallada
      });

    } on FormatException catch (e) {
      setState(() => _parseJsonError = 'Error al parsear JSON: ${e.message}');
    } catch (e) { // Otros errores inesperados
       setState(() => _parseJsonError = 'Error inesperado al procesar JSON: $e');
    }
  }

  /// Inicializa los controllers (Sin cambios)
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

  // --- ¡NUEVO! Reconstruye el JSON a partir de los campos editados ---
  String _reconstruirJsonString() {
    try {
      // 1. Reconstruye el array 'planSemanal' desde los controllers
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
          'kcalDiaAprox': diaOriginal.kcalDiaAprox, // (Podríamos recalcular esto, pero por ahora lo dejamos)
          'comidas': comidasReconstruidas,
        });
      }

      // 2. Crea el objeto final con la lista de la compra (que no se editó)
      final Map<String, dynamic> jsonFinalObject = {
        "planSemanal": planSemanalReconstruido,
        "listaCompra": _listaCompraEditada, // Re-adjunta la lista de la compra original
      };
      
      return jsonEncode(jsonFinalObject);

    } catch (e) {
      print("Error al reconstruir JSON: $e");
      // Si falla la reconstrucción, devolvemos el JSON original pegado
      return _jsonPastedController.text.trim();
    }
  }


  /// Muestra el prompt en un diálogo (Sin cambios)
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
                const SnackBar(content: Text('Prompt copiado al portapapeles'), backgroundColor: Colors.green),
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

  // --- ¡NUEVO! Función para confirmar y eliminar ---
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
      final success = await widget.viewModel.eliminarPlanDieta(widget.planInicial.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan eliminado'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true); // Devuelve 'true' para refrescar la lista anterior
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.viewModel.error ?? 'Error al eliminar'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// ¡CORREGIDO! Lógica para aprobar o guardar el plan
  void _aprobarOGuardarPlan() async {
    String jsonStringFinal;

    if (_mostrarCamposEdicion) {
      // Si los campos detallados están visibles, reconstruimos el JSON desde ahí
      jsonStringFinal = _reconstruirJsonString();
      // Actualizamos el controller por si acaso
      _jsonPastedController.text = jsonStringFinal;
    } else {
      // Si no, usamos el JSON que está pegado en el campo de texto
      jsonStringFinal = _jsonPastedController.text.trim();
    }

    if (jsonStringFinal.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El JSON no puede estar vacío.'), backgroundColor: Colors.red),
      );
      return;
    }

    final vm = widget.viewModel;
    final success = await vm.aprobarPlanDietaManual(
        idPlan: widget.planInicial.id,
        jsonString: jsonStringFinal, // Enviamos el JSON (reconstruido o pegado)
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_esModoEdicion ? 'Plan guardado con éxito' : 'Plan aprobado con éxito.'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true); // Vuelve a la lista anterior indicando éxito
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Error al guardar el plan.'), backgroundColor: Colors.red),
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
        // ¡Título dinámico!
        title: Text(
          _esModoEdicion ? 'Editar Plan Dieta' : 'Revisar Plan Dieta', 
          style: const TextStyle(color: Colors.white)
        ),
        backgroundColor: appBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
           // Botón para mostrar el prompt (solo en modo revisión)
           if (!_esModoEdicion)
            IconButton(
              icon: const Icon(Icons.description_outlined, color: Colors.white),
              tooltip: 'Ver Prompt para IA',
              onPressed: _isLoadingData ? null : _showPromptDialog,
            ),
            
           // ¡NUEVO! Botón de Eliminar (solo en modo edición)
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
              : _buildBody(context), // Pasamos el 'vm'
    );
  }

  Widget _buildBody(BuildContext context) {
    final vm = widget.viewModel; // Para el estado de carga al aprobar
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- 1. Información del Usuario ---
          _buildSectionTitle('Solicitud del Usuario'),
          // (Usamos la info de 'planInicial' que ya tiene los inputs)
          _buildInfoRow('Usuario:', widget.planInicial.usuarioNombre),
           _buildInfoRow('Grupo:', widget.planInicial.usuarioGrupo ?? 'N/A'),
          _buildInfoRow('Objetivo:', widget.planInicial.inputsUsuario['objetivo']?.toString() ?? 'N/A'),
          _buildInfoRow('Kcal Aprox:', widget.planInicial.inputsUsuario['kcalObjetivo']?.toString() ?? 'N/A'),
          // ¡NUEVO! Mostramos los campos de adherencia
          _buildInfoRow('Tiempo Cocina:', widget.planInicial.inputsUsuario['dietaTiempoCocina'] ?? 'N/A'),
          _buildInfoRow('Odiados:', widget.planInicial.inputsUsuario['dietaAlimentosOdiados'] ?? 'N/A'),
          _buildInfoRow('Reto:', widget.planInicial.inputsUsuario['dietaRetoPrincipal'] ?? 'N/A'),

          const SizedBox(height: 10),
          
          // Botón de copiar prompt (solo en modo revisión)
          if (!_esModoEdicion && _promptParaGenerar != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Ver y Copiar Prompt para IA'),
              onPressed: _showPromptDialog,
            ),
          const SizedBox(height: 20),
          Divider(color: Colors.blue[200]),

          // --- 2. Campo para Pegar/Editar JSON ---
          _buildSectionTitle(_esModoEdicion ? 'JSON del Plan' : 'Respuesta de la IA'),
          TextField(
            controller: _jsonPastedController,
            decoration: InputDecoration(
              labelText: _esModoEdicion ? 'JSON (Editar con precaución)' : 'Pega aquí el JSON generado',
              hintText: 'Asegúrate de que sea un objeto JSON válido: { "planSemanal": [...], "listaCompra": {...} }',
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
            // ¡Botón dinámico!
            onPressed: _parseAndPrepareEditUI,
            child: Text(_esModoEdicion ? 'Validar y Cargar Campos' : 'Validar JSON y Previsualizar/Editar'),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.blue[200]),

          // --- 3. Edición Detallada (si el JSON es válido y se parseó) ---
          if (_mostrarCamposEdicion)
            _buildSectionTitle('Edición Detallada del Plan'),
          if (_mostrarCamposEdicion)
            ..._buildPlanEditableUI(), // Función que genera los campos editables

          const SizedBox(height: 30),

          // --- 4. Botón de Aprobar / Guardar ---
          ElevatedButton(
            onPressed: vm.isLoading ? null : _aprobarOGuardarPlan,
            style: ElevatedButton.styleFrom(
               // ¡Color dinámico!
              backgroundColor: _esModoEdicion ? Colors.blue[600] : Colors.green[600],
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
            child: vm.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                // ¡Texto dinámico!
                : Text(_esModoEdicion ? 'Guardar Cambios' : 'Aprobar Plan', style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Construye la UI de edición detallada (Sin cambios)
  List<Widget> _buildPlanEditableUI() {
    List<Widget> widgets = [];
    for (int iDia = 0; iDia < _planEditado.length; iDia++) {
      widgets.add(_buildSectionTitle(_planEditado[iDia].nombreDia)); // Título del día
      for (int iComida = 0; iComida < _planEditado[iDia].comidas.length; iComida++) {
        widgets.add(_buildComidaEditableUI(iDia, iComida)); // Construye cada comida
        widgets.add(const SizedBox(height: 10));
      }
      widgets.add(const Divider(height: 20));
    }
    return widgets;
  }

  /// Construye la UI para editar una comida (Sin cambios)
  Widget _buildComidaEditableUI(int iDia, int iComida) {
    final nombreComida = _planEditado[iDia].comidas[iComida].nombreComida;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nombreComida, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            ...List.generate(_planEditado[iDia].comidas[iComida].opciones.length, (iOpcion) {
              return _buildOpcionEditableUI(iDia, iComida, iOpcion);
            }),
            // TODO: Botón para añadir nueva opción
          ],
        ),
      ),
    );
  }

  /// Construye la UI para editar una opción de plato (Sin cambios)
  Widget _buildOpcionEditableUI(int iDia, int iComida, int iOpcion) {
    final controllers = _controllers[iDia][iComida][iOpcion];
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            _buildEditableField('Nombre Plato', controllers['nombrePlato']!),
            const SizedBox(height: 8),
            _buildEditableField('Kcal Aprox', controllers['kcalAprox']!, keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            _buildEditableField('Ingredientes', controllers['ingredientes']!, maxLines: 2),
            const SizedBox(height: 8),
            _buildEditableField('Receta', controllers['receta']!, maxLines: 3),
             // TODO: Botón para eliminar opción
          ],
        ),
      ),
    );
  }


  // --- Helpers de UI (Sin cambios) ---
  Widget _buildEditableField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
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
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))), // Azul oscuro
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
         style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF1A237E)), // Azul oscuro
       ),
     );
   }
}
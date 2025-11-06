// screens/admin/plan_dieta_edit_screen.dart
// ¡ACTUALIZADO CON ESTILO Y FLUJO MANUAL!
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
  // --- NUEVOS ESTADOS PARA FLUJO MANUAL ---
  String? _promptParaGenerar;
  bool _isLoadingPrompt = false;
  String? _errorPrompt;
  final TextEditingController _jsonPastedController = TextEditingController();
  bool _mostrarCamposEdicion = false; // Controla si mostramos el textfield o los campos detallados
  String? _parseJsonError; // Para mostrar errores si el JSON pegado es inválido

  // --- Estados anteriores para edición detallada ---
  // Estructura de Controllers: [día][comida][opción][campo]
  late List<List<List<Map<String, TextEditingController>>>> _controllers;
  late List<DiaDieta> _planEditado; // Para reconstruir el plan

  // Servicio para obtener el prompt
  final IADietaService _dietaService = IADietaService();

  @override
  void initState() {
    super.initState();
    // Inicialmente no mostramos la edición detallada
    _mostrarCamposEdicion = false;
    // Inicializamos las estructuras de controllers vacías (se llenarán al parsear)
    _controllers = [];
    _planEditado = [];
    // Cargamos el prompt al inicio
    _fetchPrompt();
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

  /// Carga el prompt desde el backend
  Future<void> _fetchPrompt() async {
    setState(() {
      _isLoadingPrompt = true;
      _errorPrompt = null;
    });
    try {
      final promptData = await _dietaService.obtenerPromptParaRevision(widget.planInicial.id);
      setState(() {
        _promptParaGenerar = promptData['prompt'];
      });
    } catch (e) {
      setState(() {
        _errorPrompt = "Error al cargar el prompt: $e";
      });
    } finally {
      setState(() {
        _isLoadingPrompt = false;
      });
    }
  }

  /// Intenta parsear el JSON pegado y prepara la UI de edición detallada
  void _parseAndPrepareEditUI() {
    setState(() {
      _parseJsonError = null; // Limpia error anterior
      _mostrarCamposEdicion = false; // Oculta edición por si falla el parseo
       // Limpia controllers anteriores por si re-parsea
      _controllers = [];
      _planEditado = [];
    });

    final jsonString = _jsonPastedController.text.trim();
    if (jsonString.isEmpty) {
      setState(() => _parseJsonError = 'El campo JSON está vacío.');
      return;
    }

    try {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      // Validamos que sea una lista
      if (jsonData is! List) throw const FormatException("El JSON no es una lista.");

      // Convertimos el JSON a objetos DiaDieta (validando la estructura)
      final List<DiaDieta> parsedPlan = jsonData.map((diaJson) {
         if (diaJson is! Map<String, dynamic>) throw const FormatException("Elemento del array no es un objeto.");
         return DiaDieta.fromJson(diaJson);
      }).toList();

      // Si todo va bien, inicializamos los controllers y mostramos la edición
      _planEditado = parsedPlan; // Guardamos el plan parseado
      _initializeControllers(); // Crea los controllers basados en _planEditado
      setState(() {
        _mostrarCamposEdicion = true; // Muestra la UI de edición detallada
      });

    } on FormatException catch (e) {
      setState(() => _parseJsonError = 'Error al parsear JSON: ${e.message}');
    } catch (e) { // Otros errores inesperados
       setState(() => _parseJsonError = 'Error inesperado al procesar JSON: $e');
    }
  }


  /// Inicializa la estructura anidada de TextEditingControllers basado en _planEditado
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

  /// Lógica para aprobar el plan
  void _aprobarPlan() async {
    final jsonString = _jsonPastedController.text.trim();
    if (jsonString.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Primero pega el JSON generado por la IA.'), backgroundColor: Colors.red),
       );
       return;
    }


    final vm = widget.viewModel;
    final success = await vm.aprobarPlanDietaManual(
        idPlan: widget.planInicial.id,
        jsonString: jsonString, // Enviamos el JSON string crudo como lo pidió el backend
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan aprobado con éxito.'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true); // Vuelve a la lista anterior indicando éxito
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(vm.error ?? 'Error al aprobar el plan.'), backgroundColor: Colors.red),
       );
    }
  }


  @override
  Widget build(BuildContext context) {
    // Colores y estilo de EditProfileScreen
    final Color appBarColor = const Color(0xFF1E88E5);
    final Color scaffoldBgColor = const Color(0xFFE3F2FD);
    final vm = widget.viewModel; // Para el estado de carga al aprobar

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        title: Text('Revisar Plan Dieta (${widget.planInicial.mes})', style: const TextStyle(color: Colors.white)),
        backgroundColor: appBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
           // Botón para mostrar el prompt
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
            // --- 1. Información del Usuario y Prompt ---
            _buildSectionTitle('Solicitud del Usuario'),
            _buildInfoRow('Usuario:', widget.planInicial.inputsUsuario['usuarioNombre'] ?? widget.planInicial.usuarioId),
             _buildInfoRow('Objetivo:', widget.planInicial.inputsUsuario['objetivo']?.toString() ?? 'N/A'),
             _buildInfoRow('Kcal Aprox:', widget.planInicial.inputsUsuario['kcalObjetivo']?.toString() ?? 'N/A'),
             _buildInfoRow('Alergias:', widget.planInicial.inputsUsuario['dietaAlergias']?.toString() ?? 'N/A'),
             _buildInfoRow('Preferencias:', widget.planInicial.inputsUsuario['dietaPreferencias']?.toString() ?? 'N/A'),
             _buildInfoRow('Comidas/día:', widget.planInicial.inputsUsuario['dietaComidas']?.toString() ?? 'N/A'),

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
                 hintText: 'Asegúrate de que sea un array JSON válido: [ { "nombreDia": ... }, ... ]',
                 border: const OutlineInputBorder(),
                 filled: true,
                 fillColor: Colors.white,
                 errorText: _parseJsonError, // Muestra error si el JSON es inválido
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

            // --- 3. Edición Detallada (si el JSON es válido y se parseó) ---
            if (_mostrarCamposEdicion)
               _buildSectionTitle('Edición Detallada del Plan'),
            if (_mostrarCamposEdicion)
              ..._buildPlanEditableUI(), // Función que genera los campos editables

            const SizedBox(height: 30),

            // --- 4. Botón de Aprobar ---
            ElevatedButton(
              onPressed: vm.isLoading ? null : _aprobarPlan,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600], // Verde para aprobar
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

  /// Construye la UI de edición detallada (similar a tu código anterior)
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

  /// Construye la UI para editar una comida
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

  /// Construye la UI para editar una opción de plato
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


  // --- Helpers de UI (Estilo EditProfileScreen) ---
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
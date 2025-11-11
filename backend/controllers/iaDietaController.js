// controllers/iaDietaController.js
// ¡¡VERSIÓN CORRECTA PARA FLUJO MANUAL!!

// const { GoogleGenerativeAI } = require('@google/generative-ai'); // No se usa
const PlanDieta = require('../models/PlanDieta');
const Usuario = require('../models/Usuario');
// const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY); // No se usa

const getMesActual = () => new Date().toISOString().slice(0, 7);

// --- Helper para calcular Kcal (sin cambios) ---
function calcularKcal(peso, altura, edad, genero, ocupacion, ejercicio, objetivo) {
  let tmb;
  if (genero === 'masculino') { tmb = (10 * peso) + (6.25 * altura) - (5 * edad) + 5; }
  else { tmb = (10 * peso) + (6.25 * altura) - (5 * edad) - 161; }
  
  const factoresOcupacion = { 'sedentaria': 1.2, 'ligera': 1.375, 'activa': 1.55 };
  const caloriasEjercicio = { '0': 0, '1-3': 300, '4-5': 500, '6-7': 700 };
  
  const tdee = (tmb * (factoresOcupacion[ocupacion] || 1.2)) + (caloriasEjercicio[ejercicio] || 0);

  let kcalObjetivo;
  switch (objetivo) {
    case 'perder':
      kcalObjetivo = tdee - 500;
      kcalObjetivo = Math.max(kcalObjetivo, tmb + 100); 
      break;
    case 'ganar': kcalObjetivo = tdee + 300; break;
    default: kcalObjetivo = tdee;
  }
  return Math.round(kcalObjetivo);
}

/**
 * [CLIENTE] Solicita un plan (Versión unificada, flujo manual)
 */
exports.solicitarPlanDieta = async (req, res) => {
  // --- LOG DE DEBUG ---
  console.log('--- [iaDietaController] DATOS RECIBIDOS (req.body) ---');
  console.log(req.body);
  console.log('----------------------------------------------------');

  try {
    const usuarioId = req.user.id;
    
    // El req.body ya viene completo desde Flutter
    // (Flutter ya llamó a /metabolicos, así que Usuario.js ya está actualizado)
    // Solo necesitamos guardar los inputs en el PlanDieta
    const datosParaPlan = req.body; 

    const usuario = await Usuario.findById(usuarioId);
    if (!usuario.esPremium || !usuario.incluyePlanDieta) {
      console.error('[iaDietaController] Error: Usuario no es premium o no incluye dieta.');
      return res.status(403).json({ mensaje: 'Servicio no incluido.' });
    }
    
    const mesActual = getMesActual();

    // 2. Crear/Actualizar el PlanDieta
    await PlanDieta.findOneAndUpdate(
      { usuario: usuarioId, mes: mesActual },
      {
        inputsUsuario: datosParaPlan, // <-- ¡Guardamos TODOS los datos del req.body!
        estado: 'pendiente_revision',
        planGenerado: [],
        listaCompraGenerada: {} // Reseteamos la lista de la compra
      },
      { upsert: true, new: true }
    );

    res.status(200).json({ mensaje: 'Solicitud de dieta enviada correctamente.' });

  } catch (error) {
    console.error('--- [iaDietaController] ¡ERROR EN EL CATCH! ---');
    console.error(error);
    console.error('---------------------------------------------');
    res.status(500).json({ mensaje: 'Error interno del servidor al solicitar el plan.', error: error.message });
  }
};

/**
 * [HELPER INTERNO] Genera el string del prompt basado en los inputs.
 * ¡MODIFICADO PARA LISTA DE LA COMPRA!
 */
function generarPromptParaPlan(inputsUsuario) {
  // Aseguramos valores por defecto para que el prompt no se rompa
  const kcal = inputsUsuario.kcalObjetivo || 2000;
  const comidas = inputsUsuario.dietaComidas || 4;
  
  const masterPrompt = `
      Eres un nutricionista experto de nivel élite. Genera un plan de comidas semanal detallado
      Y UNA LISTA DE LA COMPRA SEMANAL CONSOLIDADA.
      Responde SÓLO con un objeto JSON, sin explicaciones.

      --- DATOS DEL USUARIO ---
      - Sexo: ${inputsUsuario.genero || 'No especificado'}
      - Edad: ${inputsUsuario.edad || 'No especificado'} años
      - Peso: ${inputsUsuario.peso || 'No especificado'} kg
      - Altura: ${inputsUsuario.altura || 'No especificado'} cm
      - Ocupación: ${inputsUsuario.ocupacion || 'No especificado'}
      - Ejercicio: ${inputsUsuario.ejercicio || 'No especificado'} días/semana
      - Objetivo: ${inputsUsuario.objetivo || 'mantener'}
      - Kcal Objetivo: Aprox ${kcal} kcal/día
      - Comidas por día: ${comidas}
      - Alergias/Restricciones: "${inputsUsuario.dietaAlergias || 'Ninguna'}"
      - Preferencias: "${inputsUsuario.dietaPreferencias || 'Omnívoro'}"
      - Historial Médico: "${inputsUsuario.historialMedico || 'No especificado'}"
      
      --- LOGÍSTICA Y ESTILO DE VIDA (CLAVE PARA ADHERENCIA) ---
      - Tiempo para cocinar: ${inputsUsuario.dietaTiempoCocina || '15-30 min'} (Generar recetas acordes)
      - Habilidad en cocina: ${inputsUsuario.dietaHabilidadCocina || 'intermedio'} (Ajustar complejidad)
      - Equipamiento: ${ (inputsUsuario.dietaEquipamiento || ['basico']).join(', ') } (Usar solo esto)
      - Dónde come: ${inputsUsuario.dietaContextoComida || 'casa'} (Si 'oficina_tupper', priorizar recetas transportables)
      - Alimentos Odiados: "${inputsUsuario.dietaAlimentosOdiados || 'Ninguno'}" (¡EVITAR ESTOS ALIMENTOS!)
      - Mayor Reto: ${inputsUsuario.dietaRetoPrincipal || 'picoteo'} (Incluir snacks saludables)

      --- INSTRUCCIONES DE FORMATO JSON ---
      Responde SÓLO con un objeto JSON que tenga esta estructura exacta:
      {
        "planSemanal": [
          // ... (Array de 7 días, de "Lunes" a "Domingo") ...
        ],
        "listaCompra": {
          // ... (Objeto con la lista de la compra) ...
        }
      }

      --- ESTRUCTURA "planSemanal" (Array de 7 días) ---
      Cada objeto 'dia' debe seguir esta estructura:
      { 
        "nombreDia": "Lunes", 
        "kcalDiaAprox": ${kcal},
        "comidas": [
          { 
            "nombreComida": "Desayuno", 
            "opciones": [ 
              { 
                "nombrePlato": "...", 
                "kcalAprox": ..., 
                "ingredientes": "...", // EJ: "2 rebanadas pan (60g), 1/2 aguacate (70g), 2 huevos (100g)"
                "receta": "..." 
              } 
            ] 
          },
          // ... (resto de ${comidas} comidas)
        ]
      }

      --- ESTRUCTURA "listaCompra" (Objeto) ---
      Agrupa TODOS los ingredientes de los 7 días del "planSemanal".
      Suma las cantidades totales (ej. si se usan 100g de pollo 3 veces, son 300g).
      Organízala por categorías.
      {
        "Frutas y Verduras": [ "Aguacate (3.5 unidades)", "Espinacas (1 bolsa)", ... ],
        "Carnes y Pescados": [ "Pechuga de Pollo (700g)", "Salmón (300g)", ... ],
        "Lácteos y Huevos": [ "Huevos (1 docena)", "Yogur Griego (7 unidades)", ... ],
        "Despensa": [ "Pan Integral (1 paquete)", "Arroz Integral (500g)", "Avena (1kg)", ... ]
      }
  `;
  
  return masterPrompt;
}

/**
 * [ADMIN] Obtiene el prompt para un plan específico.
 */
exports.obtenerPromptParaRevision = async (req, res) => {
  try {
    const { idPlan } = req.params;
    const plan = await PlanDieta.findById(idPlan);
    if (!plan) { return res.status(404).json({ mensaje: 'Plan no encontrado' }); }
    if (!plan.inputsUsuario) { return res.status(400).json({ mensaje: 'Datos de entrada no disponibles.' }); }
    
    // Usamos la función helper actualizada
    const prompt = generarPromptParaPlan(plan.inputsUsuario);
    
    res.status(200).json({ prompt: prompt });
  } catch (error) { console.error('Error al obtener prompt para revisión (dieta):', error); res.status(500).json({ mensaje: 'Error interno del servidor.' }); }
};

/**
 * [ADMIN] Obtiene planes para revisar (SOLO 'pendiente_revision')
 */
exports.obtenerPlanesPendientes = async (req, res) => {
  try {
    const planes = await PlanDieta.find({ estado: 'pendiente_revision' })
                            .populate('usuario', 'nombre nombreGrupo')
                            .sort({ createdAt: -1 }); // Ordenar por más nuevos primero
    res.status(200).json(planes);
  } catch(error){ console.error('Error al obtener planes pendientes (dieta):', error); res.status(500).json({ mensaje: 'Error interno del servidor.' }); }
};

/**
 * [ADMIN] Aprueba un plan recibiendo el JSON como string.
 * ¡MODIFICADO PARA LISTA DE LA COMPRA!
 */
exports.aprobarPlan = async (req, res) => {
  console.log('--- APROBAR PLAN DIETA REQ.BODY ---');
  console.log(req.body);
  console.log('---------------------------------');

  const { idPlan } = req.params;
  const { jsonString } = req.body; // Espera jsonString

  if (!jsonString) { return res.status(400).json({ mensaje: 'Falta el JSON generado (jsonString).' }); }

  let planCompletoParseado;
  try {
    planCompletoParseado = JSON.parse(jsonString);
    
    // Verificamos la nueva estructura de Objeto
    if (typeof planCompletoParseado !== 'object' || planCompletoParseado === null || Array.isArray(planCompletoParseado)) {
      throw new Error('El JSON proporcionado no es un objeto válido.');
    }
    if (!planCompletoParseado.planSemanal || !Array.isArray(planCompletoParseado.planSemanal)) {
      throw new Error('El JSON debe contener la clave "planSemanal" (un array).');
    }
    if (!planCompletoParseado.listaCompra || typeof planCompletoParseado.listaCompra !== 'object') {
      throw new Error('El JSON debe contener la clave "listaCompra" (un objeto).');
    }

  } catch (error) { 
    console.error(`Error al parsear JSON para plan ${idPlan}:`, error.message); 
    return res.status(400).json({ mensaje: 'El JSON pegado no es válido o no tiene la estructura { planSemanal: [], listaCompra: {} }.', error: error.message }); 
  }

  try {
    const plan = await PlanDieta.findByIdAndUpdate( 
      idPlan, 
      { 
        // ¡Guardamos cada parte en su sitio!
        planGenerado: planCompletoParseado.planSemanal,
        listaCompraGenerada: planCompletoParseado.listaCompra,
        estado: 'aprobado' 
      }, 
      { new: true } 
    );
    
    if (!plan) return res.status(404).json({ mensaje: 'Plan no encontrado' });
    res.status(200).json({ mensaje: 'Plan de dieta aprobado (con lista de compra).', plan });
  } catch(error){ console.error(`Error al aprobar plan de dieta ${idPlan}:`, error); res.status(500).json({ mensaje: 'Error interno al guardar el plan.' }); }
};


// --- FUNCIONES CLIENTE (EXISTENTES) ---

exports.obtenerMiPlanDelMes = async (req, res) => {
   // Esta función solo revisa el estado, no devuelve el plan.
   const plan = await PlanDieta.findOne({ usuario: req.user.id, mes: getMesActual() });
   if (!plan) { return res.status(200).json({ estado: 'pendiente_solicitud' }); }
   res.status(200).json({ estado: plan.estado });
};

exports.obtenerMiDietaDelDia = async (req, res) => {
  const { fecha } = req.query;
  const fechaSeleccionada = fecha ? new Date(fecha) : new Date();
  
  const dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
  const diaSemanaSeleccionado = dias[fechaSeleccionada.getUTCDay()]; 
  
  const mesActual = fechaSeleccionada.toISOString().slice(0, 7);

  const planAprobado = await PlanDieta.findOne({
    usuario: req.user.id,
    mes: mesActual,
    estado: 'aprobado'
  });

  if (!planAprobado || !planAprobado.planGenerado || planAprobado.planGenerado.length === 0) {
    return res.status(404).json({ mensaje: `No tienes una dieta aprobada para ${mesActual}.` });
  }
  
  let dietaDelDia = planAprobado.planGenerado.find(
    d => d.nombreDia === diaSemanaSeleccionado
  );
  
  if (!dietaDelDia && planAprobado.planGenerado.length > 0) {
     console.warn(`Fallback: No se encontró el plan para '${diaSemanaSeleccionado}'. Usando el primer plan disponible.`);
     dietaDelDia = planAprobado.planGenerado[0];
  }

  if (!dietaDelDia) {
    return res.status(404).json({ mensaje: 'Error de plan de dieta.' });
  }
  
  res.status(200).json(dietaDelDia);
};


// --- ¡NUEVA FUNCIÓN PARA EL CLIENTE! ---

/**
 * [CLIENTE] Obtiene la lista de la compra del mes actual
 */
exports.obtenerMiListaCompra = async (req, res) => {
  try {
    const mesActual = getMesActual();
    const planAprobado = await PlanDieta.findOne({
      usuario: req.user.id,
      mes: mesActual,
      estado: 'aprobado'
    });

    if (!planAprobado || !planAprobado.listaCompraGenerada) {
      return res.status(404).json({ mensaje: 'No se encontró una lista de la compra aprobada para este mes.' });
    }

    res.status(200).json(planAprobado.listaCompraGenerada);

  } catch (error) {
    console.error('Error al obtener la lista de la compra:', error);
    res.status(500).json({ mensaje: 'Error interno del servidor.' });
  }
};

// controllers/iaDietaController.js

// ... (todas las funciones que ya tienes: solicitarPlanDieta, generarPromptParaPlan, aprobarPlan, etc.) ...


/**
 * [ADMIN] Obtiene los datos de un plan aprobado para poder editarlos.
 * (Devuelve el plan y la lista como un objeto para re-copiar)
 */
exports.obtenerPlanParaEditar = async (req, res) => {
  try {
    const { idPlan } = req.params;
    const plan = await PlanDieta.findById(idPlan);

    if (!plan) {
      return res.status(404).json({ mensaje: 'Plan no encontrado' });
    }

    // Devolvemos la estructura exacta que el admin debe pegar
    const jsonParaEditar = {
      planSemanal: plan.planGenerado || [],
      listaCompra: plan.listaCompraGenerada || {}
    };

    // Convertimos el objeto a un string JSON formateado (pretty-print)
    // para que sea fácil de copiar y pegar para el Admin.
    const jsonString = JSON.stringify(jsonParaEditar, null, 2); // 'null, 2' añade indentación

    res.status(200).json({ 
      jsonStringParaEditar: jsonString,
      // También devolvemos los inputs por si el admin quiere consultar el prompt
      inputsUsuario: plan.inputsUsuario 
    });

  } catch (error) {
    console.error('Error al obtener plan para editar:', error);
    res.status(500).json({ mensaje: 'Error interno del servidor.' });
  }
};

/**
 * [ADMIN] Elimina un plan de dieta permanentemente.
 */
exports.eliminarPlan = async (req, res) => {
  try {
    const { idPlan } = req.params;
    const planEliminado = await PlanDieta.findByIdAndDelete(idPlan);

    if (!planEliminado) {
      return res.status(404).json({ mensaje: 'Plan no encontrado.' });
    }

    res.status(200).json({ mensaje: 'Plan de dieta eliminado permanentemente.' });

  } catch (error) {
    console.error('Error al eliminar plan de dieta:', error);
    res.status(500).json({ mensaje: 'Error interno del servidor.' });
  }
};

/**
 * [ADMIN] Obtiene planes APROBADOS (para editar/eliminar)
 */
exports.obtenerPlanesAprobados = async (req, res) => {
  try {
    const planes = await PlanDieta.find({ estado: 'aprobado' })
                            .populate('usuario', 'nombre nombreGrupo')
                            .sort({ updatedAt: -1 }); // Ordenar por más recientemente modificados
    res.status(200).json(planes);
  } catch(error){ 
    console.error('Error al obtener planes aprobados (dieta):', error); 
    res.status(500).json({ mensaje: 'Error interno del servidor.' }); 
  }
};
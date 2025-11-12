// controllers/iaEntrenamientoController.js
// ¡¡ACTUALIZADO!! Con lógica de Atleta Híbrido y Admin (Editar/Borrar)

const PlanEntrenamiento = require('../models/PlanEntrenamiento');
const Usuario = require('../models/Usuario');
const mongoose = require('mongoose');

const getMesActual = () => new Date().toISOString().slice(0, 7);

/**
 * [CLIENTE] Solicita un plan (flujo manual)
 * ¡ACTUALIZADO!
 */
exports.solicitarPlanEntrenamiento = async (req, res) => {
  // --- ¡CAMBIO AQUÍ! Recogemos TODOS los datos del formulario ---
  const { 
    premiumMeta, premiumFoco, premiumEquipamiento, premiumTiempo,
    premiumNivel, premiumDiasSemana, premiumLesiones,
    premiumEjerciciosOdiados // <-- CAMPO NUEVO
  } = req.body;
  
  const usuarioId = req.user.id;
  
  // Objeto con todos los datos a guardar
  const datosEntrenamiento = {
    premiumMeta, premiumFoco, premiumEquipamiento, premiumTiempo,
    premiumNivel, premiumDiasSemana, premiumLesiones,
    premiumEjerciciosOdiados // <-- CAMPO NUEVO
  };

  try {
    // --- ¡CAMBIO AQUÍ! Actualizamos el Usuario con TODOS los datos ---
    const usuario = await Usuario.findByIdAndUpdate( 
      usuarioId, 
      datosEntrenamiento, // Guardamos los nuevos datos en el perfil del usuario
      { new: true } 
    );
    
    if (!usuario || !usuario.esPremium || !usuario.incluyePlanEntrenamiento) {
      return res.status(403).json({ mensaje: 'No tienes permiso para este servicio.' });
    }
    
    const mesActual = getMesActual();

    // Crear/Actualizar el Plan de Entrenamiento
    await PlanEntrenamiento.findOneAndUpdate(
      { usuario: usuarioId, mes: mesActual },
      {
        inputsUsuario: datosEntrenamiento, // Guardamos los datos en el plan
        estado: 'pendiente_revision',    // Pasa a revisión del Admin
        planGenerado: [],              // Limpia el plan anterior
        diasAsignados: []              // Limpia los días
      },
      { upsert: true, new: true }
    );

    res.status(200).json({ mensaje: 'Solicitud de entrenamiento enviada correctamente.' });

  } catch (error) {
    console.error('Error al solicitar plan de entrenamiento:', error);
    res.status(500).json({ mensaje: 'Error interno del servidor.', error: error.message });
  }
};

/**
 * [HELPER INTERNO] Genera el prompt para el Admin
 * ¡TOTALMENTE REEMPLAZADO!
 */
function generarPromptParaPlan(inputsUsuario) {
  
  // Convertimos el array de equipamiento en texto claro
  const equipamientoTexto = (inputsUsuario.premiumEquipamiento || ['solo_cuerpo']).join(', ');

  const masterPrompt = `
      Eres un entrenador personal certificado de nivel élite (NSCA-CPT). 
      Tu especialidad es el rendimiento deportivo y el entrenamiento concurrente.
      Genera un plan de entrenamiento semanal detallado en formato JSON
      para un usuario con los siguientes datos:

      --- OBJETIVO Y NIVEL ---
      - Objetivo Principal: ${inputsUsuario.premiumMeta || 'salud_general'} 
        (INSTRUCCIÓN: Adapta las series/reps a ESTE objetivo.
         'fuerza_pura' = reps bajas (3-6), descansos largos.
         'hipertrofia' = reps medias (8-12).
         'perder_grasa' = reps altas (10-15) + cardio.
         
         ¡IMPORTANTE! Si el objetivo es 'rendimiento_atletico':
         El plan DEBE ser híbrido. Combina rangos de fuerza (ej. 4x5) en ejercicios 
         principales con ejercicios de POTENCIA/VELOCIDAD (ej. pliometría, saltos, 
         sprints) y algo de acondicionamiento metabólico.)

      - Nivel de Experiencia: ${inputsUsuario.premiumNivel || 'principiante_nuevo'}
        (Ajusta la complejidad de los ejercicios pliométricos a este nivel)

      --- LOGÍSTICA DE ENTRENAMIENTO ---
      - Días por semana: ${inputsUsuario.premiumDiasSemana || 4}
      - Tiempo por sesión: ${inputsUsuario.premiumTiempo || 45} minutos
        (INSTRUCCIÓN: La rutina completa, calentamiento incluido, debe durar esto)
      
      - Enfoque (Detalles del Objetivo): "${inputsUsuario.premiumFoco || 'Cuerpo completo'}"
        (INSTRUCCIÓN: ¡VITAL! Si el objetivo es 'rendimiento_atletico', 
        lee este campo para ver los detalles. Si el usuario pide "pliometría" o "velocidad", 
        DEBES incluir ejercicios como "Saltos al Cajón (Box Jumps)", "Lanzamientos de Balón Medicinal" 
        o "Sprints cortos" en la rutina.)

      --- EQUIPAMIENTO Y LIMITACIONES (MUY IMPORTANTE) ---
      - Equipamiento Disponible: ${equipamientoTexto}
        (INSTRUCCIÓN: Diseña la rutina usando ÚNICAMENTE este material. 
        Si dice 'solo_cuerpo', usa solo calistenia. Si dice 'gym_completo', puedes usar de todo.)
      
      - Limitaciones/Lesiones: "${inputsUsuario.premiumLesiones || 'Ninguna'}"
        (INSTRUCCIÓN: ¡VITAL! Lee esto con atención. Si el usuario menciona dolor en un movimiento 
        (ej. 'dolor rodilla al agachar'), SUSTITÚYELO por una alternativa segura 
        (ej. 'Sentadilla isométrica' o 'Puente de glúteo'). NUNCA incluyas un ejercicio que el usuario 
        reporte como doloroso.)

      - Ejercicios a Evitar: "${inputsUsuario.premiumEjerciciosOdiados || 'Ninguno'}"
        (INSTRUCCIÓN: NO incluyas estos ejercicios en la rutina bajo ningún concepto. 
        Busca alternativas que trabajen el mismo grupo muscular.)

      --- INSTRUCCIONES DE FORMATO JSON ---
      Responde SÓLO con el array JSON, sin explicaciones.
      El array debe tener ${inputsUsuario.premiumDiasSemana || 4} objetos, uno para cada día de entreno.
      Cada objeto 'dia' debe seguir esta estructura exacta:
      { 
        "nombreDia": "Día 1: Pecho y Tríceps", 
        "ejercicios": [
          { 
            "nombre": "Press de Banca con Mancuernas", 
            "series": "3", 
            "repeticiones": "8-12", 
            "descansoSeries": "90 seg",
            "descansoEjercicios": "2 min",
            "descripcion": "Instrucciones de técnica o video-link..." 
          },
          // ... (resto de ejercicios del día)
        ]
      }
  `;
  
  return masterPrompt;
}


/**
 * [ADMIN] Aprueba un plan (flujo manual)
 * ¡MODIFICADO! Ahora espera un JSON unificado como Dieta.
 */
exports.aprobarPlan = async (req, res) => {
  const { idPlan } = req.params;
  const { jsonString } = req.body; // Espera UN solo string JSON

  if (!jsonString) {
    return res.status(400).json({ mensaje: 'Falta el JSON generado (jsonString).' });
  }

  let planDataParseado;
  try {
    planDataParseado = JSON.parse(jsonString);
    
    // Verificamos la nueva estructura de Objeto
    if (typeof planDataParseado !== 'object' || planDataParseado === null || Array.isArray(planDataParseado)) {
      throw new Error('El JSON proporcionado no es un objeto válido.');
    }
    if (!planDataParseado.planGenerado || !Array.isArray(planDataParseado.planGenerado)) {
      throw new Error('El JSON debe contener la clave "planGenerado" (un array).');
    }
    if (!planDataParseado.diasAsignados || !Array.isArray(planDataParseado.diasAsignados)) {
      throw new Error('El JSON debe contener la clave "diasAsignados" (un array).');
    }

  } catch (error) { 
    console.error(`Error al parsear JSON para plan ${idPlan}:`, error.message); 
    return res.status(400).json({ 
      mensaje: 'El JSON pegado no es válido o no tiene la estructura { planGenerado: [], diasAsignados: [] }.', 
      error: error.message 
    }); 
  }

  try {
    const plan = await PlanEntrenamiento.findByIdAndUpdate( 
      idPlan, 
      { 
        planGenerado: planDataParseado.planGenerado,
        diasAsignados: planDataParseado.diasAsignados,
        estado: 'aprobado' 
      }, 
      { new: true } 
    );
    
    if (!plan) return res.status(404).json({ mensaje: 'Plan no encontrado' });
    res.status(200).json({ mensaje: 'Plan de entrenamiento aprobado.', plan });

  } catch (error) {
    console.error('Error al aprobar plan de entrenamiento:', error);
    res.status(500).json({ mensaje: 'Error interno al guardar el plan.' });
  }
};


/**
 * [ADMIN] Obtiene el prompt para un plan específico.
 */
exports.obtenerPromptParaRevision = async (req, res) => {
  try {
    const { idPlan } = req.params;
    const plan = await PlanEntrenamiento.findById(idPlan);
    if (!plan) { return res.status(404).json({ mensaje: 'Plan no encontrado' }); }
    if (!plan.inputsUsuario) { return res.status(400).json({ mensaje: 'Datos de entrada no disponibles.' }); }
    
    // Usamos la función helper actualizada
    const prompt = generarPromptParaPlan(plan.inputsUsuario);
    
    res.status(200).json({ prompt: prompt });
  } catch (error) { console.error('Error al obtener prompt para revisión (entrenamiento):', error); res.status(500).json({ mensaje: 'Error interno del servidor.' }); }
};

/**
 * [ADMIN] Obtiene planes para revisar (SOLO 'pendiente_revision')
 */
exports.obtenerPlanesPendientes = async (req, res) => {
  try {
    const planes = await PlanEntrenamiento.find({ estado: 'pendiente_revision' })
                            .populate('usuario', 'nombre nombreGrupo')
                            .sort({ createdAt: -1 }); // Ordenar por más nuevos primero
    res.status(200).json(planes);
  } catch(error){ console.error('Error al obtener planes pendientes (entrenamiento):', error); res.status(500).json({ mensaje: 'Error interno del servidor.' }); }
};


// --- FUNCIONES CLIENTE (Sin cambios) ---

exports.obtenerMiPlanDelMes = async (req, res) => {
   const plan = await PlanEntrenamiento.findOne({ usuario: req.user.id, mes: getMesActual() });
   if (!plan) { return res.status(200).json({ estado: 'pendiente_solicitud' }); }
   res.status(200).json({ estado: plan.estado });
};

exports.obtenerMiRutinaDelDia = async (req, res) => {
  const { fecha } = req.query; 
  const fechaSeleccionada = fecha ? new Date(fecha) : new Date();
  
  const diasSemana = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
  const diaLiteral = diasSemana[fechaSeleccionada.getUTCDay()]; // Ej: "Miércoles"
  
  const mesActual = fechaSeleccionada.toISOString().slice(0, 7);

  const planAprobado = await PlanEntrenamiento.findOne({
    usuario: req.user.id,
    mes: mesActual,
    estado: 'aprobado'
  });

  if (!planAprobado || !planAprobado.diasAsignados || planAprobado.diasAsignados.length === 0) {
    return res.status(404).json({ mensaje: 'No tienes un plan aprobado para este mes.' });
  }

  // 1. Comprobar si el día de hoy (ej: "Miércoles") está en los días asignados
  const indiceDia = planAprobado.diasAsignados.indexOf(diaLiteral);
  
  if (indiceDia === -1) {
    // No está en los días asignados, es día de descanso
    return res.status(404).json({ mensaje: 'Día de descanso.' });
  }
  
  // 2. Si está, obtener la rutina correspondiente a ese índice
  if (!planAprobado.planGenerado || indiceDia >= planAprobado.planGenerado.length) {
    return res.status(404).json({ mensaje: 'Error de plan: el número de rutinas no coincide con los días asignados.' });
  }
  
  const rutinaDelDia = planAprobado.planGenerado[indiceDia];
  
  if (!rutinaDelDia || !rutinaDelDia.ejercicios || rutinaDelDia.ejercicios.length === 0) {
    return res.status(404).json({ mensaje: 'Error de plan: no hay ejercicios generados.' });
  }

  if (!rutinaDelDia) {
    return res.status(404).json({ mensaje: 'Error de plan: rutinaDelDia no encontrada.' });
  }

  // 3. Enviamos la respuesta
  res.status(200).json(rutinaDelDia);
};


// --- ¡NUEVAS FUNCIONES DE ADMIN! ---

/**
 * [ADMIN] Obtiene planes APROBADOS (para editar/eliminar)
 */
exports.obtenerPlanesAprobados = async (req, res) => {
  try {
    const planes = await PlanEntrenamiento.find({ estado: 'aprobado' })
                            .populate('usuario', 'nombre nombreGrupo')
                            .sort({ updatedAt: -1 }); // Ordenar por más recientemente modificados
    res.status(200).json(planes);
  } catch(error){ 
    console.error('Error al obtener planes aprobados (entrenamiento):', error); 
    res.status(500).json({ mensaje: 'Error interno del servidor.' }); 
  }
};

/**
 * [ADMIN] Obtiene los datos de un plan aprobado para poder editarlos.
 */
exports.obtenerPlanParaEditar = async (req, res) => {
  try {
    const { idPlan } = req.params;
    const plan = await PlanEntrenamiento.findById(idPlan);

    if (!plan) {
      return res.status(404).json({ mensaje: 'Plan no encontrado' });
    }

    // Devolvemos la estructura que espera la función 'aprobarPlan'
    const jsonParaEditar = {
      planGenerado: plan.planGenerado || [],
      diasAsignados: plan.diasAsignados || []
    };

    const jsonString = JSON.stringify(jsonParaEditar, null, 2);

    res.status(200).json({ 
      jsonStringParaEditar: jsonString,
      inputsUsuario: plan.inputsUsuario 
    });

  } catch (error) {
    console.error('Error al obtener plan de entrenamiento para editar:', error);
    res.status(500).json({ mensaje: 'Error interno del servidor.' });
  }
};

/**
 * [ADMIN] Elimina un plan de entrenamiento permanentemente.
 */
exports.eliminarPlan = async (req, res) => {
  try {
    const { idPlan } = req.params;
    const planEliminado = await PlanEntrenamiento.findByIdAndDelete(idPlan);

    if (!planEliminado) {
      return res.status(404).json({ mensaje: 'Plan no encontrado.' });
    }

    res.status(200).json({ mensaje: 'Plan de entrenamiento eliminado permanentemente.' });

  } catch (error) {
    console.error('Error al eliminar plan de entrenamiento:', error);
    res.status(500).json({ mensaje: 'Error interno del servidor.' });
  }
};
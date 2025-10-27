// controllers/iaEntrenamientoController.js
// ¡¡VERSIÓN CORREGIDA!!
// Añadidos los nuevos campos de Nivel, Días y Lesiones.

const PlanEntrenamiento = require('../models/PlanEntrenamiento');
const Usuario = require('../models/Usuario');
const mongoose = require('mongoose');

const getMesActual = () => new Date().toISOString().slice(0, 7);

/**
 * [CLIENTE] Solicita un plan (flujo manual)
 */
exports.solicitarPlanEntrenamiento = async (req, res) => {
  // --- ¡CAMBIO AQUÍ! Recogemos TODOS los datos del formulario ---
  const { 
    premiumMeta, premiumFoco, premiumEquipamiento, premiumTiempo,
    premiumNivel, premiumDiasSemana, premiumLesiones // <-- CAMPOS NUEVOS
  } = req.body;
  
  const usuarioId = req.user.id;
  
  // Objeto con todos los datos a guardar
  const datosEntrenamiento = {
    premiumMeta, premiumFoco, premiumEquipamiento, premiumTiempo,
    premiumNivel, premiumDiasSemana, premiumLesiones
  };

  try {
    // --- ¡CAMBIO AQUÍ! Actualizamos el Usuario con TODOS los datos ---
    const usuario = await Usuario.findByIdAndUpdate( 
      usuarioId, 
      datosEntrenamiento, // Guardamos los nuevos datos en el perfil del usuario
      { new: true } 
    );
    
    if (!usuario.esPremium || !usuario.incluyePlanEntrenamiento) { 
      return res.status(403).json({ mensaje: 'Servicio no incluido.' }); 
    }
    
    const mesActual = getMesActual();
    
    // --- ¡CAMBIO AQUÍ! Guardamos TODOS los datos en inputsUsuario del Plan ---
    await PlanEntrenamiento.findOneAndUpdate( 
      { usuario: usuarioId, mes: mesActual }, 
      { 
        inputsUsuario: datosEntrenamiento, // Guardamos el objeto completo
        estado: 'pendiente_revision', 
        planGenerado: [], 
        diasAsignados: [] 
      }, 
      { upsert: true, new: true } 
    );
    
    res.status(200).json({ mensaje: 'Preferencias guardadas. Tu entrenador revisará tu plan pronto.' });
  } catch (error) { 
    console.error('Error al solicitar plan entrenamiento:', error); 
    res.status(500).json({ mensaje: 'Error al solicitar plan', error: error.message }); 
  }
};

// =================================================================
//          FUNCIÓN "SÚPER-PROMPT" (CORREGIDA)
// =================================================================
/**
 * [HELPER INTERNO] Genera el string del prompt basado en los inputs.
 */
function generarPromptParaPlan(inputsUsuario) {
  // --- ¡PROMPT MEJORADO CON TODOS LOS DATOS! ---
  const masterPrompt = `
      Eres un entrenador personal experto de nivel élite. 
      Genera un plan de entrenamiento semanal detallado en formato JSON.

      --- DATOS DEL USUARIO ---
      - Nivel: ${inputsUsuario.premiumNivel || 'principiante'}
      - Días por semana: ${inputsUsuario.premiumDiasSemana || 4}
      - Objetivo (Meta): ${inputsUsuario.premiumMeta || 'No especificado'}
      - Foco muscular: ${inputsUsuario.premiumFoco || 'No especificado'}
      - Equipamiento: ${inputsUsuario.premiumEquipamiento || 'No especificado'}
      - Tiempo por sesión: ${inputsUsuario.premiumTiempo || 45} minutos
      - Lesiones/Limitaciones: "${inputsUsuario.premiumLesiones || 'Ninguna'}"
      
      --- INSTRUCCIONES CLAVE ---
      1. Genera un plan para EXACTAMENTE ${inputsUsuario.premiumDiasSemana || 4} días.
      2. Adapta los ejercicios y el volumen al Nivel: "${inputsUsuario.premiumNivel || 'principiante'}".
      3. ¡MUY IMPORTANTE! Ten en cuenta las lesiones: "${inputsUsuario.premiumLesiones || 'Ninguna'}". Si se mencionan, EVITA ejercicios que impacten esa zona o sugiere alternativas seguras (ej. si duele rodilla, usar prensa en lugar de sentadilla).
      4. El formato de respuesta debe ser EXCLUSIVAMENTE un array JSON, sin texto introductorio.

      --- ESTRUCTURA JSON DE RESPUESTA OBLIGATORIA ---
      [
        {
          "nombreDia": "Día 1: [Enfoque del día, ej: Tren Superior]",
          "ejercicios": [
            {
              "nombre": "Nombre del Ejercicio 1",
              "series": "3",
              "repeticiones": "10-12",
              "descansoSeries": "60 seg",
              "descansoEjercicios": "2 min",
              "descripcion": "Breve descripción de la técnica."
            },
            {
              "nombre": "Nombre del Ejercicio 2",
              "series": "4",
              "repeticiones": "8-10",
              "descansoSeries": "90 seg",
              "descansoEjercicios": "2 min",
              "descripcion": "Breve descripción de la técnica."
            }
          ]
        },
        {
          "nombreDia": "Día 2: [Enfoque del día, ej: Tren Inferior y Core]",
          "ejercicios": [
             {
              "nombre": "Nombre del Ejercicio 3",
              "series": "3",
              "repeticiones": "12-15",
              "descansoSeries": "60 seg",
              "descansoEjercicios": "2 min",
              "descripcion": "Breve descripción de la técnica."
            }
          ]
        }
        // ... (etc., hasta completar los ${inputsUsuario.premiumDiasSemana || 4} días)
      ]
  `;
  // --- FIN PROMPT MEJORADO ---
  return masterPrompt;
}
// =================================================================
//          FIN DE LA CORRECCIÓN
// =================================================================

/**
 * [ADMIN] Obtiene el prompt para un plan específico.
 */
exports.obtenerPromptParaRevision = async (req, res) => {
  try {
    const { idPlan } = req.params;
    const plan = await PlanEntrenamiento.findById(idPlan);
    if (!plan) { return res.status(404).json({ mensaje: 'Plan no encontrado' }); }
    if (!plan.inputsUsuario) { return res.status(400).json({ mensaje: 'Datos de entrada no disponibles.' }); }
    
    // Llama a la nueva función de prompt mejorada
    const prompt = generarPromptParaPlan(plan.inputsUsuario); 
    
    res.status(200).json({ prompt: prompt });
  } catch (error) { console.error('Error al obtener prompt para revisión (entrenamiento):', error); res.status(500).json({ mensaje: 'Error interno del servidor.' }); }
};

/**
 * [ADMIN] Obtiene planes para revisar (SOLO 'pendiente_revision')
 */
exports.obtenerPlanesPendientes = async (req, res) => {
 try {
    const planes = await PlanEntrenamiento.find({ estado: 'pendiente_revision' }).populate('usuario', 'nombre nombreGrupo'); // Quitamos 'pendiente_ia'
    res.status(200).json(planes);
 } catch(error){ console.error('Error al obtener planes pendientes (entrenamiento):', error); res.status(500).json({ mensaje: 'Error interno del servidor.' }); }
};

/**
 * [ADMIN] Aprueba un plan recibiendo JSON string y días.
 */
exports.aprobarPlan = async (req, res) => {
  console.log('--- APROBAR PLAN ENTREN REQ.BODY ---');
  console.log(req.body);
  console.log('----------------------------------');

  const { idPlan } = req.params;
  const { jsonString, diasAsignados } = req.body; 

  if (!jsonString || !diasAsignados || !Array.isArray(diasAsignados) || diasAsignados.length === 0) { return res.status(400).json({ mensaje: 'Faltan el JSON generado (jsonString) o los días asignados (diasAsignados).' }); }

  let planGeneradoParseado;
  try {
    planGeneradoParseado = JSON.parse(jsonString);
    if (!Array.isArray(planGeneradoParseado)) { throw new Error('El JSON proporcionado no es un array válido.'); }
  } catch (error) { console.error(`Error al parsear JSON para plan ${idPlan}:`, error.message); return res.status(400).json({ mensaje: 'El JSON pegado no es válido.', error: error.message }); }

  try {
    const plan = await PlanEntrenamiento.findByIdAndUpdate( idPlan, { planGenerado: planGeneradoParseado, diasAsignados: diasAsignados, estado: 'aprobado' }, { new: true } );
    if (!plan) return res.status(404).json({ mensaje: 'Plan no encontrado' });
    res.status(200).json({ mensaje: 'Plan de entrenamiento aprobado.', plan });
  } catch(error){ console.error(`Error al aprobar plan de entrenamiento ${idPlan}:`, error); res.status(500).json({ mensaje: 'Error interno al guardar el plan.' }); }
};

/**
 * [CLIENTE] Obtiene el estado del plan del mes (para bloquear el formulario)
 */
exports.obtenerMiPlanDelMes = async (req, res) => {
  const plan = await PlanEntrenamiento.findOne({ 
    usuario: req.user.id, 
    mes: getMesActual() 
  });
  if (!plan) {
    return res.status(200).json({ estado: 'pendiente_solicitud' }); // 200 ok
  }
  res.status(200).json({ estado: plan.estado });
};

/**
 * [CLIENTE] Obtiene la rutina del día para el calendario
 */
exports.obtenerMiRutinaDelDia = async (req, res) => {
  const { fecha } = req.query;
  const fechaSeleccionada = fecha ? new Date(fecha) : new Date();
  const dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
  const diaSemanaSeleccionado = dias[fechaSeleccionada.getUTCDay()];
  const mesActual = fechaSeleccionada.toISOString().slice(0, 7);

  const planAprobado = await PlanEntrenamiento.findOne({
    usuario: req.user.id,
    mes: mesActual,
    estado: 'aprobado'
  });

  if (!planAprobado || !planAprobado.diasAsignados.includes(diaSemanaSeleccionado)) {
    return res.status(404).json({ mensaje: `Día de descanso.` });
  }

  // Asigna "Dia 1" o "Dia 2"
  let rutinaDelDia;
  const indiceDia = planAprobado.diasAsignados.indexOf(diaSemanaSeleccionado);
  
  if (indiceDia !== -1 && planAprobado.planGenerado[indiceDia]) {
     rutinaDelDia = planAprobado.planGenerado[indiceDia];
  } else if (planAprobado.planGenerado.length > 0) {
     // Fallback: Si los días asignados no coinciden con el plan (ej. asigna 5 días pero el JSON solo tiene 3)
     // Hacemos un módulo para rotar.
     const indiceFallback = indiceDia % planAprobado.planGenerado.length;
     rutinaDelDia = planAprobado.planGenerado[indiceFallback];
  } else {
     return res.status(404).json({ mensaje: 'Error de plan: no hay ejercicios generados.' });
  }


  if (!rutinaDelDia) return res.status(404).json({ mensaje: 'Error de plan.' });

  // Simula la estructura de 'Rutina.js' para el frontend
  res.status(200).json({
    _id: planAprobado._id,
    diaSemana: rutinaDelDia.nombreDia,
    ejercicios: rutinaDelDia.ejercicios.map(e => ({
      _id: new mongoose.Types.ObjectId(),
      ejercicio: { 
        _id: new mongoose.Types.ObjectId(),
        nombre: e.nombre,
        descripcion: e.descripcion,
      },
      series: e.series,
      repeticiones: e.repeticiones,
      descansoSeries: e.descansoSeries,
      descansoEjercicios: e.descansoEjercicios
    }))
  });
};
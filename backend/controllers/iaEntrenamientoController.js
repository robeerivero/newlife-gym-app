// controllers/iaEntrenamientoController.js
// ¡ESTE ARCHIVO YA ERA CORRECTO!

const { GoogleGenerativeAI } = require('@google/generative-ai');
const PlanEntrenamiento = require('../models/PlanEntrenamiento');
const Usuario = require('../models/Usuario');
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const mongoose = require('mongoose'); // Añadido para los IDs simulados

// Obtiene el mes actual en formato "YYYY-MM"
const getMesActual = () => new Date().toISOString().slice(0, 7);

/**
 * [CLIENTE] Solicita un plan (rellena el formulario de metas)
 */
exports.solicitarPlanEntrenamiento = async (req, res) => {
  const { premiumMeta, premiumFoco, premiumEquipamiento, premiumTiempo } = req.body;
  const usuarioId = req.user.id;
  
  try {
    const usuario = await Usuario.findByIdAndUpdate(
      usuarioId,
      { premiumMeta, premiumFoco, premiumEquipamiento, premiumTiempo },
      { new: true }
    );
    if (!usuario.esPremium || !usuario.incluyePlanEntrenamiento) {
      return res.status(403).json({ mensaje: 'Servicio no incluido.' });
    }

    const mesActual = getMesActual();
    const plan = await PlanEntrenamiento.findOneAndUpdate(
      { usuario: usuarioId, mes: mesActual },
      { 
        inputsUsuario: req.body,
        estado: 'pendiente_ia',
        planGenerado: [], diasAsignados: []
      },
      { upsert: true, new: true }
    );

    // Dispara la IA en segundo plano
    const token = req.headers.authorization.split(' ')[1];
    const url = `${req.protocol}://${req.get('host')}/api/entrenamiento/admin/generar-ia/${plan._id}`;
    fetch(url, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` }
    }).catch(err => console.error('Error al disparar IA de Entrenamiento:', err.message));

    res.status(200).json({ mensaje: 'Preferencias guardadas. Tu entrenador revisará tu plan pronto.' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al solicitar plan', error: error.message });
  }
};

/**
 * [SISTEMA/ADMIN] Genera el borrador de IA
 */
exports.generarBorradorIA = async (req, res) => {
  try {
    const { idPlan } = req.params;
    const plan = await PlanEntrenamiento.findById(idPlan);
    if (!plan) {
      return console.error(`[IA Entren] Plan con ID ${idPlan} no encontrado.`);
    }

    const { inputsUsuario } = plan;
    const masterPrompt = `
      Eres un entrenador personal. Cliente ya entrena 3 días (L-M-V) con "Funcional".
      Genera un plan complementario para 2 días libres (ej. Martes y Jueves).
      DATOS:
      - Objetivo: "${inputsUsuario.premiumMeta}"
      - Foco: "${inputsUsuario.premiumFoco}"
      - Equipamiento: "${inputsUsuario.premiumEquipamiento}"
      - Tiempo: ${inputsUsuario.premiumTiempo} min.
      RESPUESTA (Solo JSON):
      [
        {
          "nombreDia": "Dia 1 (Enfoque: ${inputsUsuario.premiumFoco})",
          "ejercicios": [
            { "nombre": "...", "series": "3", "repeticiones": "8-12", "descansoSeries": "90 seg", "descansoEjercicios": "3 min", "descripcion": "..." }
          ]
        },
        {
          "nombreDia": "Dia 2 (Enfoque: Complementario)",
          "ejercicios": [
            { "nombre": "...", "series": "4", "repeticiones": "10-15", "descansoSeries": "60 seg", "descansoEjercicios": "2 min", "descripcion": "..." }
          ]
        }
      ]
    `;
    
    const model = genAI.getGenerativeModel({ model: 'gemini-1.0-pro' });
    const result = await model.generateContent(masterPrompt);
    const response = await result.response;
    const jsonText = response.text().replace(/```json/g, '').replace(/```/g, '');
    const jsonResponse = JSON.parse(jsonText);

    plan.planGenerado = jsonResponse;
    plan.estado = 'pendiente_revision';
    await plan.save();

    if (res) res.status(200).json(plan);
  } catch (error) {
    // ¡TU CATCH ESTÁ BIEN! No lo cambies.
    console.error('Error en IA Entrenamiento:', error);
    if (res) res.status(500).json({ mensaje: 'Error en IA', error: error.message });
  }
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
     rutinaDelDia = planAprobado.planGenerado[0]; // Fallback al primero
  } else {
     return res.status(404).json({ mensaje: 'Error de plan.' });
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

/**
 * [ADMIN] Obtiene planes para revisar
 */
exports.obtenerPlanesPendientes = async (req, res) => {
  const planes = await PlanEntrenamiento.find({ 
    estado: { $in: ['pendiente_ia', 'pendiente_revision'] } 
  }).populate('usuario', 'nombre correo');
  res.status(200).json(planes);
};

/**
 * [ADMIN] Aprueba, edita y asigna días
 */
exports.aprobarPlan = async (req, res) => {
  const { idPlan } = req.params;
  const { planEditado, diasAsignados } = req.body;

  if (!planEditado || !diasAsignados || diasAsignados.length === 0) {
    return res.status(400).json({ mensaje: 'Faltan el plan editado o los días.' });
  }

  const plan = await PlanEntrenamiento.findByIdAndUpdate(
    idPlan,
    {
      planGenerado: planEditado,
      diasAsignados: diasAsignados,
      estado: 'aprobado'
    },
    { new: true }
  );
  if (!plan) return res.status(404).json({ mensaje: 'Plan no encontrado' });
  res.status(200).json({ mensaje: 'Plan de entrenamiento aprobado.', plan });
};
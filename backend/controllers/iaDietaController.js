// controllers/iaDietaController.js
// ¡¡VERSIÓN CORRECTA PARA FLUJO MANUAL!!

// const { GoogleGenerativeAI } = require('@google/generative-ai'); // No se usa
const PlanDieta = require('../models/PlanDieta');
const Usuario = require('../models/Usuario');
// const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY); // No se usa

const getMesActual = () => new Date().toISOString().slice(0, 7);

// --- Helper para calcular Kcal (sin cambios) ---
function calcularKcal(peso, altura, edad, genero, nivelActividad, objetivo) {
  let tmb;
  if (genero === 'masculino') { tmb = (10 * peso) + (6.25 * altura) - (5 * edad) + 5; }
  else { tmb = (10 * peso) + (6.25 * altura) - (5 * edad) - 161; }
  const factores = { 'sedentario': 1.2, 'ligero': 1.375, 'moderado': 1.55, 'activo': 1.725, 'muy_activo': 1.9 };
  const tdee = tmb * (factores[nivelActividad] || 1.2);
  let kcalObjetivo;
  switch (objetivo) {
    case 'perder': kcalObjetivo = tdee - 500; break;
    case 'ganar': kcalObjetivo = tdee + 500; break;
    default: kcalObjetivo = tdee;
  }
  return Math.round(kcalObjetivo);
}

/**
 * [CLIENTE] Solicita un plan (Versión unificada, flujo manual)
 */
exports.solicitarPlanDieta = async (req, res) => {
  const { dietaAlergias, dietaPreferencias, dietaComidas, peso, altura, edad, genero, nivelActividad, objetivo } = req.body;
  const usuarioId = req.user.id;
  try {
    if (!peso || !altura || !edad || !genero || !nivelActividad || !objetivo) { return res.status(400).json({ mensaje: 'Faltan datos metabólicos.' }); }
    const kcalCalculadas = calcularKcal(peso, altura, edad, genero, nivelActividad, objetivo);
    const usuario = await Usuario.findByIdAndUpdate( usuarioId, { $set: { dietaAlergias, dietaPreferencias, dietaComidas, peso, altura, edad, genero, nivelActividad, objetivo, kcalObjetivo: kcalCalculadas } }, { new: true } );
    if (!usuario.esPremium || !usuario.incluyePlanDieta) { return res.status(403).json({ mensaje: 'Servicio no incluido.' }); }
    const mesActual = getMesActual();
    await PlanDieta.findOneAndUpdate( { usuario: usuarioId, mes: mesActual }, { inputsUsuario: { objetivo: usuario.objetivo, kcalObjetivo: usuario.kcalObjetivo, dietaAlergias: usuario.dietaAlergias, dietaPreferencias: usuario.dietaPreferencias, dietaComidas: usuario.dietaComidas }, estado: 'pendiente_revision', planGenerado: [] }, { new: true, upsert: true } );
    // --- FETCH ELIMINADO ---
    res.status(200).json({ mensaje: 'Solicitud recibida. Tu nutricionista la revisará.' });
  } catch (error) { console.error('Error en solicitarPlanDieta:', error); res.status(500).json({ mensaje: 'Error interno del servidor.' }); }
};

/**
 * [HELPER INTERNO] Genera el string del prompt basado en los inputs.
 */
function generarPromptParaPlan(inputsUsuario) {
  const masterPrompt = `
      Eres un nutricionista experto. Genera un plan de comidas semanal.
      DATOS:
      - Objetivo: ${inputsUsuario.objetivo} (aprox ${inputsUsuario.kcalObjetivo} kcal/día)
      - Alergias/Restricciones: "${inputsUsuario.dietaAlergias}"
      - Preferencias: "${inputsUsuario.dietaPreferencias}"
      - Comidas por día: ${inputsUsuario.dietaComidas}
      RESPUESTA (Solo JSON): ... (Asegúrate de que tu prompt completo esté aquí) ...
      [ { "nombreDia": "Lunes a Viernes", ... }, { "nombreDia": "Fin de Semana", ... } ]`;
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
    const prompt = generarPromptParaPlan(plan.inputsUsuario);
    res.status(200).json({ prompt: prompt });
  } catch (error) { console.error('Error al obtener prompt para revisión (dieta):', error); res.status(500).json({ mensaje: 'Error interno del servidor.' }); }
};

/**
 * [ADMIN] Obtiene planes para revisar (SOLO 'pendiente_revision')
 */
exports.obtenerPlanesPendientes = async (req, res) => {
  try {
    const planes = await PlanDieta.find({ estado: 'pendiente_revision' }).populate('usuario', 'nombre correo'); // Quitamos 'pendiente_ia'
    res.status(200).json(planes);
  } catch(error){ console.error('Error al obtener planes pendientes (dieta):', error); res.status(500).json({ mensaje: 'Error interno del servidor.' }); }
};

/**
 * [ADMIN] Aprueba un plan recibiendo el JSON como string.
 */
exports.aprobarPlan = async (req, res) => {
  console.log('--- APROBAR PLAN DIETA REQ.BODY ---'); // Log para depurar
  console.log(req.body); // Log para depurar
  console.log('---------------------------------'); // Log para depurar

  const { idPlan } = req.params;
  const { jsonString } = req.body; // Espera jsonString

  if (!jsonString) { return res.status(400).json({ mensaje: 'Falta el JSON generado (jsonString).' }); }

  let planGeneradoParseado;
  try {
    planGeneradoParseado = JSON.parse(jsonString);
    if (!Array.isArray(planGeneradoParseado)) { throw new Error('El JSON proporcionado no es un array válido.'); }
  } catch (error) { console.error(`Error al parsear JSON para plan ${idPlan}:`, error.message); return res.status(400).json({ mensaje: 'El JSON pegado no es válido.', error: error.message }); }

  try {
    const plan = await PlanDieta.findByIdAndUpdate( idPlan, { planGenerado: planGeneradoParseado, estado: 'aprobado' }, { new: true } );
    if (!plan) return res.status(404).json({ mensaje: 'Plan no encontrado' });
    res.status(200).json({ mensaje: 'Plan de dieta aprobado.', plan });
  } catch(error){ console.error(`Error al aprobar plan de dieta ${idPlan}:`, error); res.status(500).json({ mensaje: 'Error interno al guardar el plan.' }); }
};

// --- FUNCIONES SIN CAMBIOS o que no afectan al flujo manual ---
exports.obtenerMiPlanDelMes = async (req, res) => {
   const plan = await PlanDieta.findOne({ usuario: req.user.id, mes: getMesActual() });
   if (!plan) { return res.status(200).json({ estado: 'pendiente_solicitud' }); } // Devuelve 200 con el estado correcto
   res.status(200).json({ estado: plan.estado });
};
exports.obtenerMiDietaDelDia = async (req, res) => {
  const { fecha } = req.query;
  const fechaSeleccionada = fecha ? new Date(fecha) : new Date();
  const dia = fechaSeleccionada.getUTCDay();
  const mesActual = fechaSeleccionada.toISOString().slice(0, 7);

  const planAprobado = await PlanDieta.findOne({
    usuario: req.user.id,
    mes: mesActual,
    estado: 'aprobado'
  });

  if (!planAprobado || !planAprobado.planGenerado || planAprobado.planGenerado.length === 0) {
    return res.status(404).json({ mensaje: `No tienes una dieta aprobada para ${mesActual}.` });
  }
  
  let dietaDelDia;
  const esFinDeSemana = (dia === 0 || dia === 6);
  const diaFinde = planAprobado.planGenerado.find(d => d.nombreDia.toLowerCase().includes('fin de semana'));
  const diaSemana = planAprobado.planGenerado.find(d => d.nombreDia.toLowerCase().includes('lunes'));
  
  if (esFinDeSemana && diaFinde) {
    dietaDelDia = diaFinde;
  } else if (diaSemana) {
    dietaDelDia = diaSemana;
  } else {
     dietaDelDia = planAprobado.planGenerado[0];
  }

  if (!dietaDelDia) return res.status(404).json({ mensaje: 'Error de plan de dieta.' });
  res.status(200).json(dietaDelDia);
};
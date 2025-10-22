// controllers/iaDietaController.js
// ¡¡MODIFICADO PARA FLUJO MANUAL ADMIN-IN-THE-LOOP!!

// const { GoogleGenerativeAI } = require('@google/generative-ai'); // <-- Ya no se necesita
const PlanDieta = require('../models/PlanDieta');
const Usuario = require('../models/Usuario');
// const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY); // <-- Ya no se necesita

const getMesActual = () => new Date().toISOString().slice(0, 7);

// --- Función Helper para calcular Kcal (sin cambios) ---
function calcularKcal(peso, altura, edad, genero, nivelActividad, objetivo) {
  let tmb;
  if (genero === 'masculino') {
    tmb = (10 * peso) + (6.25 * altura) - (5 * edad) + 5;
  } else {
    tmb = (10 * peso) + (6.25 * altura) - (5 * edad) - 161;
  }
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
  const { 
    dietaAlergias, dietaPreferencias, dietaComidas,
    peso, altura, edad, genero, nivelActividad, objetivo 
  } = req.body;
  const usuarioId = req.user.id;

  try {
    if (!peso || !altura || !edad || !genero || !nivelActividad || !objetivo) {
      return res.status(400).json({ mensaje: 'Faltan datos metabólicos.' });
    }
    const kcalCalculadas = calcularKcal(peso, altura, edad, genero, nivelActividad, objetivo);

    const usuario = await Usuario.findByIdAndUpdate(
      usuarioId,
      { 
        $set: {
          dietaAlergias, dietaPreferencias, dietaComidas,
          peso, altura, edad, genero, nivelActividad, objetivo,
          kcalObjetivo: kcalCalculadas
        }
      },
      { new: true }
    );
    
    if (!usuario.esPremium || !usuario.incluyePlanDieta) {
      return res.status(403).json({ mensaje: 'Servicio no incluido.' });
    }

    const mesActual = getMesActual();
    await PlanDieta.findOneAndUpdate( // No necesitamos guardar la variable 'plan'
      { usuario: usuarioId, mes: mesActual },
      { 
        inputsUsuario: {
          objetivo: usuario.objetivo,
          kcalObjetivo: usuario.kcalObjetivo,
          dietaAlergias: usuario.dietaAlergias,
          dietaPreferencias: usuario.dietaPreferencias,
          dietaComidas: usuario.dietaComidas
        },
        // --- CAMBIO CLAVE: Directo a revisión ---
        estado: 'pendiente_revision', 
        planGenerado: [] 
      },
      { new: true, upsert: true }
    );

    // --- ELIMINADO: Ya no disparamos el fetch ---
    /*
    const token = req.headers.authorization.split(' ')[1];
    const internalPort = process.env.PORT || 5000; 
    const url = `http://localhost:${internalPort}/api/dietas/admin/generar-ia/${plan._id}`; 
    console.log(`[IA Dieta] Fetch URL completa: ${url}`);
    console.log(`[IA Dieta] Disparando fetch interno para Plan ID: ${plan._id}`); 
    fetch(url, { ... }).catch(err => ...);
    */

    res.status(200).json({ mensaje: 'Solicitud recibida. Tu nutricionista la revisará.' });

  } catch (error) {
    console.error('Error en solicitarPlanDieta:', error);
    res.status(500).json({ mensaje: 'Error interno del servidor.' });
  }
};

/**
 * [HELPER INTERNO] Genera el string del prompt basado en los inputs.
 */
function generarPromptParaPlan(inputsUsuario) {
  // La misma lógica que tenías en generarBorradorIA
  const masterPrompt = `
      Eres un nutricionista experto. Genera un plan de comidas semanal.
      DATOS:
      - Objetivo: ${inputsUsuario.objetivo} (aprox ${inputsUsuario.kcalObjetivo} kcal/día)
      - Alergias/Restricciones: "${inputsUsuario.dietaAlergias}"
      - Preferencias: "${inputsUsuario.dietaPreferencias}"
      - Comidas por día: ${inputsUsuario.dietaComidas}

      RESPUESTA (Solo JSON):
      Genera 2 planes (uno "Lunes a Viernes", otro "Fin de Semana").
      Para cada comida ("Desayuno", "Almuerzo", "Cena", etc.), da 2 opciones de plato.
      Para cada plato, incluye "nombrePlato", "kcalAprox", "ingredientes" (string simple), y "receta" (string simple).
      Asegúrate de que el JSON resultante sea un array válido que contenga dos objetos, uno para cada plan (L-V y Fin de Semana). No incluyas comentarios ni markdown \`\`\`json\`\`\`.

      Ejemplo de estructura JSON esperada:
      [
        {
          "nombreDia": "Lunes a Viernes",
          "kcalDiaAprox": ${inputsUsuario.kcalObjetivo},
          "comidas": [
            {
              "nombreComida": "Desayuno",
              "opciones": [
                { "nombrePlato": "...", "kcalAprox": ..., "ingredientes": "...", "receta": "..." },
                { "nombrePlato": "...", "kcalAprox": ..., "ingredientes": "...", "receta": "..." }
              ]
            }, 
            { "nombreComida": "Almuerzo", "opciones": [...] },
            { "nombreComida": "Cena", "opciones": [...] }
            // Añadir más comidas si inputsUsuario.dietaComidas > 3
          ]
        },
        {
          "nombreDia": "Fin de Semana",
          "kcalDiaAprox": ${Math.round(inputsUsuario.kcalObjetivo * 1.1)},
          "comidas": [ ... ] // Similar estructura
        }
      ]
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
    if (!plan) {
      return res.status(404).json({ mensaje: 'Plan no encontrado' });
    }
    if (!plan.inputsUsuario) {
        return res.status(400).json({ mensaje: 'Los datos de entrada del usuario no están disponibles para este plan.' });
    }

    const prompt = generarPromptParaPlan(plan.inputsUsuario);
    res.status(200).json({ prompt: prompt }); // Devuelve el prompt como JSON

  } catch (error) {
    console.error('Error al obtener prompt para revisión:', error);
    res.status(500).json({ mensaje: 'Error interno del servidor.' });
  }
};


/**
 * [ADMIN] Obtiene planes para revisar (SOLO 'pendiente_revision')
 */
exports.obtenerPlanesPendientes = async (req, res) => {
  try {
    const planes = await PlanDieta.find({ 
      // --- CAMBIO: Ya no buscamos 'pendiente_ia' ---
      estado: 'pendiente_revision' 
    }).populate('usuario', 'nombre correo');
    res.status(200).json(planes);
  } catch(error){
      console.error('Error al obtener planes pendientes (dieta):', error);
      res.status(500).json({ mensaje: 'Error interno del servidor.' });
  }
};

/**
 * [ADMIN] Aprueba un plan recibiendo el JSON como string.
 */
exports.aprobarPlan = async (req, res) => {
  const { idPlan } = req.params;
  // --- CAMBIO: Esperamos un string con el JSON ---
  const { jsonString } = req.body; 

  if (!jsonString) {
    return res.status(400).json({ mensaje: 'Falta el JSON generado (jsonString).' });
  }

  let planGeneradoParseado;
  try {
    // --- CAMBIO: Parseamos el string ---
    planGeneradoParseado = JSON.parse(jsonString);
    // Validación básica (debe ser un array)
    if (!Array.isArray(planGeneradoParseado)) {
        throw new Error('El JSON proporcionado no es un array válido.');
    }
  } catch (error) {
    console.error(`Error al parsear JSON para plan ${idPlan}:`, error.message);
    // Devuelve un error específico si el JSON está mal formado
    return res.status(400).json({ mensaje: 'El JSON pegado no es válido.', error: error.message });
  }

  try {
    const plan = await PlanDieta.findByIdAndUpdate(
      idPlan,
      {
        // --- CAMBIO: Guardamos el objeto parseado ---
        planGenerado: planGeneradoParseado, 
        estado: 'aprobado'
      },
      { new: true }
    );
    if (!plan) return res.status(404).json({ mensaje: 'Plan no encontrado' });
    res.status(200).json({ mensaje: 'Plan de dieta aprobado.', plan });
  } catch(error){
     console.error(`Error al aprobar plan de dieta ${idPlan}:`, error);
     res.status(500).json({ mensaje: 'Error interno al guardar el plan.' });
  }
};

exports.obtenerMiPlanDelMes = async (req, res) => {
  const plan = await PlanDieta.findOne({ 
    usuario: req.user.id, 
    mes: getMesActual() 
  });
  if (!plan) {
    return res.status(200).json({ estado: 'pendiente_solicitud' }); // 200 ok
  }
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

exports.obtenerPlanesPendientes = async (req, res) => {
  const planes = await PlanDieta.find({ 
    estado: { $in: ['pendiente_ia', 'pendiente_revision'] } 
  }).populate('usuario', 'nombre correo');
  res.status(200).json(planes);
};

exports.aprobarPlan = async (req, res) => {
  const { idPlan } = req.params;
  const { planEditado } = req.body;
  if (!planEditado) {
    return res.status(400).json({ mensaje: 'Falta el plan editado.' });
  }
  const plan = await PlanDieta.findByIdAndUpdate(
    idPlan,
    { planGenerado: planEditado, estado: 'aprobado' },
    { new: true }
  );
  if (!plan) return res.status(404).json({ mensaje: 'Plan no encontrado' });
  res.status(200).json({ mensaje: 'Plan de dieta aprobado.', plan });
};
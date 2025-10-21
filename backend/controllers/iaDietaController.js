// controllers/iaDietaController.js
const { GoogleGenerativeAI } = require('@google/generative-ai');
const PlanDieta = require('../models/PlanDieta');
const Usuario = require('../models/Usuario');
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const getMesActual = () => new Date().toISOString().slice(0, 7);

/**
 * [CLIENTE] Solicita un plan (rellena el formulario de metas)
 */
exports.solicitarPlanDieta = async (req, res) => {
  const { dietaAlergias, dietaPreferencias, dietaComidas } = req.body;
  const usuarioId = req.user.id;

  try {
    const usuario = await Usuario.findByIdAndUpdate(
      usuarioId,
      { dietaAlergias, dietaPreferencias, dietaComidas },
      { new: true }
    );
    if (!usuario.esPremium || !usuario.incluyePlanDieta) {
      return res.status(403).json({ mensaje: 'Servicio no incluido.' });
    }

    const mesActual = getMesActual();
    const plan = await PlanDieta.findOneAndUpdate(
      { usuario: usuarioId, mes: mesActual },
      { 
        inputsUsuario: {
          objetivo: usuario.objetivo,
          kcalObjetivo: usuario.kcalObjetivo,
          dietaAlergias: usuario.dietaAlergias,
          dietaPreferencias: usuario.dietaPreferencias,
          dietaComidas: usuario.dietaComidas
        },
        estado: 'pendiente_ia',
        planGenerado: []
      },
      { upsert: true, new: true }
    );

    // Dispara la IA en segundo plano
    const token = req.headers.authorization.split(' ')[1];
    const url = `${req.protocol}://${req.get('host')}/api/dietas/admin/generar-ia/${plan._id}`;
    fetch(url, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` }
    }).catch(err => console.error('Error al disparar IA de Dieta:', err.message));

    res.status(200).json({ mensaje: 'Preferencias guardadas. Tu nutricionista revisará tu plan pronto.' });
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
    const plan = await PlanDieta.findById(idPlan);
    if (!plan) return res.status(404).json({ mensaje: 'Plan no encontrado' });

    const { inputsUsuario } = plan;
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
      
      [
        {
          "nombreDia": "Lunes a Viernes",
          "kcalDiaAprox": ${inputsUsuario.kcalObjetivo},
          "comidas": [
            {
              "nombreComida": "Desayuno",
              "opciones": [
                { "nombrePlato": "Tostadas de Aguacate", "kcalAprox": 400, "ingredientes": "...", "receta": "..." },
                { "nombrePlato": "Avena con Fruta", "kcalAprox": 450, "ingredientes": "...", "receta": "..." }
              ]
            } // ... (Almuerzo, Cena, etc.)
          ]
        },
        {
          "nombreDia": "Fin de Semana",
          "kcalDiaAprox": ${Math.round(inputsUsuario.kcalObjetivo * 1.1)},
          "comidas": [ ... ]
        }
      ]
    `;
    
    const model = genAI.getGenerativeModel({ model: 'gemini-pro' });
    const result = await model.generateContent(masterPrompt);
    const response = await result.response;
    const jsonText = response.text().replace(/```json/g, '').replace(/```/g, '');
    const jsonResponse = JSON.parse(jsonText);

    plan.planGenerado = jsonResponse;
    plan.estado = 'pendiente_revision';
    await plan.save();

    if (res) res.status(200).json(plan);
  } catch (error) {
    console.error('Error en IA Dieta:', error);
    if (res) res.status(500).json({ mensaje: 'Error en IA', error: error.message });
  }
};

/**
 * [CLIENTE] Obtiene el estado del plan del mes (para bloquear el formulario)
 */
exports.obtenerMiPlanDelMes = async (req, res) => {
  const plan = await PlanDieta.findOne({ 
    usuario: req.user.id, 
    mes: getMesActual() 
  });
  if (!plan) {
    return res.status(404).json({ estado: 'pendiente_solicitud' });
  }
  res.status(200).json({ estado: plan.estado });
};

/**
 * [CLIENTE] Obtiene la dieta del día para el calendario
 */
exports.obtenerMiDietaDelDia = async (req, res) => {
  const { fecha } = req.query;
  const fechaSeleccionada = fecha ? new Date(fecha) : new Date();
  const dia = fechaSeleccionada.getUTCDay(); // 0=Domingo, 6=Sábado
  const mesActual = fechaSeleccionada.toISOString().slice(0, 7);

  const planAprobado = await PlanDieta.findOne({
    usuario: req.user.id,
    mes: mesActual,
    estado: 'aprobado'
  });

  if (!planAprobado) {
    return res.status(404).json({ mensaje: `No tienes una dieta aprobada para ${mesActual}.` });
  }
  
  // Asigna "Fin de Semana" o "Lunes a Viernes"
  let dietaDelDia;
  const esFinDeSemana = (dia === 0 || dia === 6);
  
  if (esFinDeSemana && planAprobado.planGenerado.length > 1) {
    dietaDelDia = planAprobado.planGenerado[1]; // Asume que el índice 1 es "Fin de Semana"
  } else {
    dietaDelDia = planAprobado.planGenerado[0]; // Asume que el índice 0 es "L-V"
  }

  if (!dietaDelDia) return res.status(404).json({ mensaje: 'Error de plan de dieta.' });

  res.status(200).json(dietaDelDia);
};

/**
 * [ADMIN] Obtiene planes para revisar
 */
exports.obtenerPlanesPendientes = async (req, res) => {
  const planes = await PlanDieta.find({ 
    estado: { $in: ['pendiente_ia', 'pendiente_revision'] } 
  }).populate('usuario', 'nombre correo');
  res.status(200).json(planes);
};

/**
 * [ADMIN] Aprueba y edita el plan
 */
exports.aprobarPlan = async (req, res) => {
  const { idPlan } = req.params;
  const { planEditado } = req.body; // El admin envía el plan (editado)

  if (!planEditado) {
    return res.status(400).json({ mensaje: 'Falta el plan editado.' });
  }

  const plan = await PlanDieta.findByIdAndUpdate(
    idPlan,
    {
      planGenerado: planEditado,
      estado: 'aprobado'
    },
    { new: true }
  );
  if (!plan) return res.status(404).json({ mensaje: 'Plan no encontrado' });
  res.status(200).json({ mensaje: 'Plan de dieta aprobado.', plan });
};
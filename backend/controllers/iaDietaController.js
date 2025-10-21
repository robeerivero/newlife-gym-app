// controllers/iaDietaController.js
// ¡¡ACTUALIZADO!!

const { GoogleGenerativeAI } = require('@google/generative-ai');
const PlanDieta = require('../models/PlanDieta');
const Usuario = require('../models/Usuario');
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const getMesActual = () => new Date().toISOString().slice(0, 7);

// --- ¡NUEVO! Función Helper para calcular Kcal ---
// (Copiada de tu usuariosController.js)
function calcularKcal(peso, altura, edad, genero, nivelActividad, objetivo) {
  let tmb;
  if (genero === 'masculino') {
    tmb = (10 * peso) + (6.25 * altura) - (5 * edad) + 5;
  } else { // Asume femenino
    tmb = (10 * peso) + (6.25 * altura) - (5 * edad) - 161;
  }
  
  const factores = { 'sedentario': 1.2, 'ligero': 1.375, 'moderado': 1.55, 'activo': 1.725, 'muy_activo': 1.9 };
  const tdee = tmb * (factores[nivelActividad] || 1.2);

  let kcalObjetivo;
  switch (objetivo) {
    case 'perder': kcalObjetivo = tdee - 500; break;
    case 'ganar': kcalObjetivo = tdee + 500; break;
    default: kcalObjetivo = tdee; // 'mantener'
  }
  return Math.round(kcalObjetivo);
}
// --- Fin del Helper ---

/**
 * [CLIENTE] Solicita un plan (¡NUEVA VERSIÓN UNIFICADA!)
 */
exports.solicitarPlanDieta = async (req, res) => {
  // 1. Recibimos TODOS los datos del formulario unificado
  const { 
    dietaAlergias, dietaPreferencias, dietaComidas,
    peso, altura, edad, genero, nivelActividad, objetivo 
  } = req.body;
  
  const usuarioId = req.user.id;

  try {
    // 2. Validamos y calculamos las Kcal AHORA
    if (!peso || !altura || !edad || !genero || !nivelActividad || !objetivo) {
      return res.status(400).json({ mensaje: 'Faltan datos metabólicos.' });
    }
    const kcalCalculadas = calcularKcal(peso, altura, edad, genero, nivelActividad, objetivo);

    // 3. Actualizamos el modelo Usuario (para futuros usos)
    // Usamos $set para actualizar solo los campos que llegan
    const usuario = await Usuario.findByIdAndUpdate(
      usuarioId,
      { 
        $set: {
          dietaAlergias, dietaPreferencias, dietaComidas,
          peso, altura, edad, genero, nivelActividad, objetivo,
          kcalObjetivo: kcalCalculadas // Guardamos el cálculo
        }
      },
      { new: true }
    );
    
    if (!usuario.esPremium || !usuario.incluyePlanDieta) {
      return res.status(403).json({ mensaje: 'Servicio no incluido.' });
    }

    // 4. Creamos el Plan (Snapshot) con los datos 100% correctos
    const mesActual = getMesActual();
    const plan = await PlanDieta.findOneAndUpdate(
      { usuario: usuarioId, mes: mesActual },
      { 
        inputsUsuario: { // Creamos el snapshot con los datos frescos
          objetivo: usuario.objetivo,
          kcalObjetivo: usuario.kcalObjetivo,
          dietaAlergias: usuario.dietaAlergias,
          dietaPreferencias: usuario.dietaPreferencias,
          dietaComidas: usuario.dietaComidas
        },
        estado: 'pendiente_ia', // ¡Listo para la IA!
        planGenerado: [] // Limpiamos el plan anterior si existía
      },
      { new: true, upsert: true }
    );

    // 5. Disparamos el fetch (que ahora SÍ funcionará bien)
    const token = req.headers.authorization.split(' ')[1];
    const url = `${req.protocol}://${req.get('host')}/api/dietas/admin/generar-ia/${plan._id}`;
    
    fetch(url, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` }
    }).catch(err => console.error('Error al disparar IA de Dieta:', err.message));

    res.status(200).json({ mensaje: 'Solicitud recibida. Tu nutricionista la revisará.' });

  } catch (error) {
    console.error('Error en solicitarPlanDieta:', error);
    res.status(500).json({ mensaje: 'Error interno del servidor.' });
  }
};

/**
 * [SISTEMA/ADMIN] Genera el borrador de IA
 */
exports.generarBorradorIA = async (req, res) => {
  try {
    const { idPlan } = req.params;
    const plan = await PlanDieta.findById(idPlan);
    if (!plan) {
      // Si el plan no se encuentra, simplemente termina. No envíes respuesta (fetch).
      return console.error(`[IA Dieta] Plan con ID ${idPlan} no encontrado.`);
    }

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

    plan.planGenerado = jsonResponse; // Guardamos el array directamente
    plan.estado = 'pendiente_revision';
    await plan.save();

    // No hay 'res' que enviar si es llamado por fetch, pero si es admin, sí.
    if (res) res.status(200).json(plan);
  } catch (error) {
    // ¡TU CATCH ESTÁ BIEN! No lo cambies.
    // No revierte el estado, lo cual es correcto.
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
    return res.status(200).json({ estado: 'pendiente_solicitud' }); // 200 ok, estado 'pendiente_solicitud'
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

  if (!planAprobado || !planAprobado.planGenerado || planAprobado.planGenerado.length === 0) {
    return res.status(404).json({ mensaje: `No tienes una dieta aprobada para ${mesActual}.` });
  }
  
  // Asigna "Fin de Semana" o "Lunes a Viernes"
  let dietaDelDia;
  const esFinDeSemana = (dia === 0 || dia === 6);
  
  // Lógica más robusta para encontrar el día
  const diaFinde = planAprobado.planGenerado.find(d => d.nombreDia.toLowerCase().includes('fin de semana'));
  const diaSemana = planAprobado.planGenerado.find(d => d.nombreDia.toLowerCase().includes('lunes'));
  
  if (esFinDeSemana && diaFinde) {
    dietaDelDia = diaFinde;
  } else if (diaSemana) {
    dietaDelDia = diaSemana;
  } else {
     dietaDelDia = planAprobado.planGenerado[0]; // Fallback al primero
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
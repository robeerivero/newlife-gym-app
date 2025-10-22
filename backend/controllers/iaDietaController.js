// controllers/iaDietaController.js
// ¡¡ACTUALIZADO CON LOGS DE DEPURACIÓN!!

const { GoogleGenerativeAI } = require('@google/generative-ai');
const PlanDieta = require('../models/PlanDieta');
const Usuario = require('../models/Usuario');
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const getMesActual = () => new Date().toISOString().slice(0, 7);

// --- Función Helper para calcular Kcal ---
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
 * [CLIENTE] Solicita un plan (Versión unificada)
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

    // 3. Actualizamos el modelo Usuario
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

    // 4. Creamos el Plan (Snapshot)
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
      { new: true, upsert: true }
    );

    // 5. Disparamos el fetch
    const token = req.headers.authorization.split(' ')[1];
   // ... dentro de solicitarPlanDieta / solicitarPlanEntrenamiento ...
    
    // 1. Determina el puerto interno. Render lo pone en process.env.PORT
    //    Si estás en local, puede ser 3000, 5000, etc. (ajusta si es necesario)
    const internalPort = process.env.PORT || 3000; // Usa el puerto de Render o 3000 como fallback local
    
    // 2. Construye la URL usando localhost y el puerto interno
    const url = `http://localhost:${internalPort}/api/dietas/admin/generar-ia/${plan._id}`; 
    //   ¡Asegúrate de cambiar '/api/dietas/' por '/api/entrenamiento/' en el otro controlador!

    
    // --- ¡¡AÑADE ESTE LOG!! ---
    console.log(`[IA Dieta] Fetch URL completa: ${url}`);
    console.log(`[IA Dieta] Disparando fetch interno para Plan ID: ${plan._id}`); // <-- LOG AÑADIDO
    
    fetch(url, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` }
    }).catch(err => console.error('Error al disparar IA de Dieta (Fetch):', err.message)); // <-- ESTE ES OTRO POSIBLE ERROR

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
  // --- LOG 1: ¿SE ESTÁ LLAMANDO LA FUNCIÓN? ---
  console.log(`[IA Dieta] INICIO: generando borrador para Plan ID: ${req.params.idPlan}`);
  
  try {
    const { idPlan } = req.params;
    const plan = await PlanDieta.findById(idPlan);
    if (!plan) {
      return console.error(`[IA Dieta] ERROR: Plan con ID ${idPlan} no encontrado.`);
    }

    const { inputsUsuario } = plan;
    const masterPrompt = `... (Tu prompt de dieta) ...`; // (No lo pego para abreviar)
    
    // --- LOG 2: ¿EL PROMPT SE CONSTRUYE BIEN? ---
    console.log(`[IA Dieta] PROMPT: Generando contenido para ${inputsUsuario.kcalObjetivo} kcal...`);

    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-pro' });
    const result = await model.generateContent(masterPrompt);
    
    // --- LOG 3: ¿GOOGLE HA RESPONDIDO ALGO? ---
    console.log(`[IA Dieta] RESPUESTA GOOGLE: Recibida. Procesando texto...`);

    const response = await result.response;
    const jsonText = response.text().replace(/```json/g, '').replace(/```/g, '');
    const jsonResponse = JSON.parse(jsonText);
    
    // --- LOG 4: ¿EL JSON SE HA PARSEADO BIEN? ---
    console.log(`[IA Dieta] PARSEADO: JSON parseado correctamente.`);

    plan.planGenerado = jsonResponse;
    plan.estado = 'pendiente_revision';
    await plan.save();

    // --- LOG 5: ¿SE HA GUARDADO EN LA BD? ---
    console.log(`[IA Dieta] ÉXITO: Plan ${idPlan} guardado. Estado: pendiente_revision.`);

    if (res) res.status(200).json(plan);
    
  } catch (error) {
    // --- LOG DE ERROR MEJORADO: MUESTRA EL ERROR COMPLETO ---
    console.error('--- ERROR GRAVE EN IA DIETA ---');
    console.error(error); // ¡¡ESTO NOS DARÁ EL ERROR COMPLETO!!
    console.error('---------------------------------');
    if (res) res.status(500).json({ mensaje: 'Error en IA', error: error.message });
  }
};

// ... (El resto de funciones: obtenerMiPlanDelMes, obtenerMiDietaDelDia, etc., siguen igual)
// ... (Copio las tuyas para que esté completo)

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
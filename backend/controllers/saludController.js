// controllers/saludController.js
const Salud = require('../models/Salud');
const PlanDieta = require('../models/PlanDieta');
const Usuario = require('../models/Usuario');

/**
 * Actualiza Pasos y/o Kcal Quemadas (manual/automático), y opcionalmente Kcal Consumidas.
 * Esta función ahora es la principal para actualizar datos diarios.
 */
exports.actualizarPasos = async (req, res) => {
  try {
    const usuarioId = req.user.id;
    // Recibe pasos, kcalQuemadas (manuales), kcalConsumidas (manuales), fecha y sumarKcal
    const { pasos, kcalQuemadas, kcalConsumidas, fecha, sumarKcal } = req.body;
    console.log("ACTUALIZAR DATOS SALUD:", req.body);

    // Validación: Al menos un dato debe venir
    if (pasos === undefined && kcalQuemadas === undefined && kcalConsumidas === undefined) {
      return res.status(400).json({ mensaje: 'Debe proporcionar al menos un dato (pasos, kcalQuemadas o kcalConsumidas) para actualizar.' });
    }

    // Determina la fecha a actualizar (hoy por defecto)
    const fechaDia = new Date(fecha || new Date().toISOString().split('T')[0]);
    fechaDia.setUTCHours(0, 0, 0, 0); // Normaliza a UTC inicio del día

    // Busca o crea el registro de salud para ese día
    let salud = await Salud.findOne({ usuario: usuarioId, fecha: fechaDia });
    if (!salud) {
      salud = new Salud({ usuario: usuarioId, fecha: fechaDia });
    }

    // Actualiza Pasos y recalcula Kcal Quemadas por pasos si es necesario
    if (typeof pasos === 'number' && pasos >= 0) {
      salud.pasos = pasos;
      // Recalcula el total quemado (pasos + manual) solo si no se envió explícitamente kcalQuemadas
      // O si se envió kcalQuemadas pero NO era para sumar (era un valor manual total)
      if (kcalQuemadas === undefined || !sumarKcal) {
        const kcalPorPasos = salud.pasos * 0.04; // Tu fórmula
        const kcalManual = salud.kcalQuemadasManual || 0;
        salud.kcalQuemadas = Math.round(kcalPorPasos + kcalManual);
      }
    }

    // Actualiza Kcal Quemadas Manuales (si se envían)
    if (typeof kcalQuemadas === 'number' && kcalQuemadas >= 0) {
      if (sumarKcal === true) { // Suma al valor manual existente
        salud.kcalQuemadasManual = (salud.kcalQuemadasManual || 0) + kcalQuemadas;
      } else { // Reemplaza el valor manual
        salud.kcalQuemadasManual = kcalQuemadas;
      }
      // Siempre recalcula el total quemado después de actualizar el manual
      const kcalPorPasos = (salud.pasos || 0) * 0.04;
      salud.kcalQuemadas = Math.round(kcalPorPasos + salud.kcalQuemadasManual);
    }

    // Actualiza Kcal Consumidas (si se envían) -> Entrada Manual del Cliente
    if (typeof kcalConsumidas === 'number' && kcalConsumidas >= 0) {
      salud.kcalConsumidas = kcalConsumidas;
    }

    await salud.save();

    res.json({ mensaje: 'Datos de salud actualizados.', salud });
  } catch (error) {
    console.error("Error en actualizarPasos:", error);
    res.status(500).json({ mensaje: 'Error al actualizar los datos de salud' });
  }
};

/**
 * Obtiene el historial de salud de los últimos 7 días.
 * Estima kcalConsumidas si el valor guardado es 0, basándose en PlanDieta.
 */
exports.obtenerHistorialSalud = async (req, res) => {
  try {
    const usuarioId = req.user.id;
    const hoy = new Date();
    hoy.setUTCHours(0, 0, 0, 0);
    const sieteDiasAtras = new Date(hoy);
    sieteDiasAtras.setUTCDate(hoy.getUTCDate() - 6); // Incluye hoy y 6 días atrás

    // Busca historial en el rango
    const historial = await Salud.find({
      usuario: usuarioId,
      fecha: { $gte: sieteDiasAtras }
    }).sort({ fecha: 1 }); // Ordena de más antiguo a más reciente

    // --- LÓGICA DE ESTIMACIÓN DE KCAL CONSUMIDAS ---
    // Busca todos los planes aprobados para los meses relevantes (máximo 2 meses)
    const meses = [...new Set(historial.map(h => h.fecha.toISOString().slice(0, 7)))];
    const planesAprobados = await PlanDieta.find({
      usuario: usuarioId,
      mes: { $in: meses },
      estado: 'aprobado'
    });
    const planesMap = new Map(planesAprobados.map(p => [p.mes, p])); // Mapa mes -> plan

    for (let i = 0; i < historial.length; i++) {
      // Si kcalConsumidas es 0 o null, intentamos estimar
      if (!historial[i].kcalConsumidas || historial[i].kcalConsumidas === 0) {
        const fechaHistorial = historial[i].fecha;
        const mesHistorial = fechaHistorial.toISOString().slice(0, 7);
        const planDelMes = planesMap.get(mesHistorial); // Busca el plan del mes

        if (planDelMes && planDelMes.planGenerado && planDelMes.planGenerado.length > 0) {
          const diaSemana = fechaHistorial.getUTCDay(); // 0 = Domingo, 6 = Sábado
          const esFinDeSemana = (diaSemana === 0 || diaSemana === 6);

          // Encuentra el DiaDieta correspondiente (L-V o FinDe)
          let diaDietaEstimado;
          if (esFinDeSemana && planDelMes.planGenerado.length > 1) {
            // Asume que el índice 1 es Fin de Semana si existe
            diaDietaEstimado = planDelMes.planGenerado[1];
          } else {
            // Usa el índice 0 (L-V) por defecto o si solo hay uno
            diaDietaEstimado = planDelMes.planGenerado[0];
          }

          if (diaDietaEstimado && diaDietaEstimado.kcalDiaAprox > 0) {
            historial[i].kcalConsumidas = diaDietaEstimado.kcalDiaAprox; // Usa el Kcal Aprox del plan
            // No guardamos la estimación en la BD, solo la devolvemos
          }
        }
      }
    }
    // --- FIN LÓGICA DE ESTIMACIÓN ---

    // Calcular racha
    let racha = 0;
    let fechaEsperada = new Date(hoy); // Empieza desde hoy
    fechaEsperada.setUTCDate(hoy.getUTCDate() - 1); // El día esperado es ayer

    for (let i = historial.length - 1; i >= 0; i--) {
      const fechaBD = new Date(historial[i].fecha); // Ya está en UTC 00:00:00
      if (fechaBD.getTime() === fechaEsperada.getTime()) {
        racha++;
        fechaEsperada.setUTCDate(fechaEsperada.getUTCDate() - 1); // Retrocede un día más
      } else if (fechaBD.getTime() < fechaEsperada.getTime()) {
        // Si hay un salto en las fechas, la racha se rompe
        break;
      }
    }
    // Comprueba si el registro de 'hoy' existe para la racha
    const registroHoy = historial.find(h => h.fecha.getTime() === hoy.getTime());
    if (registroHoy && racha === 0) {
      // Si solo hay registro de hoy, y racha era 0, podríamos contar 1 si cumple requisitos.
      // (Opcional: lógica de validación de racha mínima)
    }

    res.json({ historial, racha });
  } catch (error) {
    console.error("Error en obtenerHistorialSalud:", error);
    res.status(500).json({ mensaje: 'Error al obtener historial de salud' });
  }
};

/**
 * Guarda un registro completo de salud para un día.
 * Usado si la app envía todos los datos juntos.
 */
exports.guardarDatosSalud = async (req, res) => {
  try {
    const usuarioId = req.user.id;
    const { fecha, pasos, kcalQuemadas, kcalConsumidas } = req.body;

    if (!fecha || pasos == null || kcalQuemadas == null || kcalConsumidas == null) {
      return res.status(400).json({ mensaje: 'Faltan datos requeridos (fecha, pasos, kcalQuemadas, kcalConsumidas).' });
    }

    const fechaDia = new Date(fecha);
    fechaDia.setUTCHours(0, 0, 0, 0); // Normaliza

    // Busca o crea el registro
    let salud = await Salud.findOne({ usuario: usuarioId, fecha: fechaDia });
    if (!salud) salud = new Salud({ usuario: usuarioId, fecha: fechaDia });

    // Asigna los valores recibidos
    salud.pasos = pasos;
    salud.kcalQuemadas = kcalQuemadas;
    salud.kcalConsumidas = kcalConsumidas;

    await salud.save();

    // --- CORREGIDO: Eliminada llamada a chequearLogrosYDesbloquear ---

    res.json({ mensaje: 'Datos de salud guardados.', salud });
  } catch (error) {
    console.error("Error en guardarDatosSalud:", error);
    res.status(500).json({ mensaje: 'Error al guardar los datos de salud' });
  }
};
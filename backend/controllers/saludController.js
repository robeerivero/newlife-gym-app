// saludController.js (actualizado)
const Salud = require('../models/Salud');
const Plato = require('../models/Plato');
const Dieta = require('../models/Dieta');

exports.actualizarPasos = async (req, res) => {
  try {
    const usuarioId = req.user.id;
    const { pasos, kcalQuemadas, kcalConsumidas, fecha } = req.body;

    if (pasos == null || pasos < 0) {
      return res.status(400).json({ mensaje: 'Número de pasos inválido' });
    }

    const fechaDia = new Date(fecha || new Date().toISOString().split('T')[0]);
    fechaDia.setHours(0, 0, 0, 0);

    let salud = await Salud.findOne({ usuario: usuarioId, fecha: fechaDia });
    if (!salud) {
      salud = new Salud({ usuario: usuarioId, fecha: fechaDia });
    }

    salud.pasos = pasos;
    if (kcalQuemadas !== undefined) salud.kcalQuemadas = kcalQuemadas;
    if (kcalConsumidas !== undefined) salud.kcalConsumidas = kcalConsumidas;

    await salud.save();
    res.json({ mensaje: 'Pasos y calorías actualizados', salud });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al actualizar pasos' });
  }
};

exports.actualizarKcalConsumidas = async (req, res) => {
  try {
    const usuarioId = req.user.id;
    const hoy = new Date();
    hoy.setHours(0, 0, 0, 0);

    const dieta = await Dieta.findOne({ usuario: usuarioId, fecha: hoy }).populate('platos');
    if (!dieta) return res.status(404).json({ mensaje: 'No hay dieta registrada para hoy.' });

    const kcalConsumidas = dieta.platos.reduce((total, plato) => total + plato.kcal, 0);
    let salud = await Salud.findOne({ usuario: usuarioId, fecha: hoy });
    if (!salud) salud = new Salud({ usuario: usuarioId, fecha: hoy });

    salud.kcalConsumidas = kcalConsumidas;
    await salud.save();

    res.json({ mensaje: 'Kcal consumidas actualizadas', kcalConsumidas });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al actualizar kcal consumidas' });
  }
};

exports.obtenerHistorialSalud = async (req, res) => {
  try {
    const usuarioId = req.user.id;
    const sieteDiasAtras = new Date();
    sieteDiasAtras.setDate(sieteDiasAtras.getDate() - 7);
    sieteDiasAtras.setHours(0, 0, 0, 0);

    const historial = await Salud.find({ usuario: usuarioId, fecha: { $gte: sieteDiasAtras } }).sort({ fecha: 1 });

    // calcular racha
    let racha = 0;
    let fechaEsperada = new Date();
    fechaEsperada.setHours(0, 0, 0, 0);
    fechaEsperada.setDate(fechaEsperada.getDate() - 1);

    for (let i = historial.length - 1; i >= 0; i--) {
      const fechaBD = new Date(historial[i].fecha);
      fechaBD.setHours(0, 0, 0, 0);
      if (fechaBD.getTime() === fechaEsperada.getTime()) {
        racha++;
        fechaEsperada.setDate(fechaEsperada.getDate() - 1);
      } else {
        break;
      }
    }

    res.json({ historial, racha });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener historial de salud' });
  }
};

exports.obtenerLogros = async (req, res) => {
  try {
    const usuarioId = req.user.id;
    const registros = await Salud.find({ usuario: usuarioId }).sort({ fecha: -1 });

    const hoy = registros[0] || {};
    const pasosHoy = hoy.pasos || 0;
    const kcalHoy = hoy.kcalQuemadas || 0;
    const logros = [];

    if (pasosHoy >= 10000) logros.push('🏅 10.000 pasos alcanzados');
    if (kcalHoy >= 500) logros.push('🔥 500 kcal quemadas');
    if (registros.length >= 7) logros.push('📅 Semana completa registrada');

    res.json({ logros });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener logros' });
  }
};
exports.guardarDatosSalud = async (req, res) => {
  try {
    const usuarioId = req.user.id;
    const { fecha, pasos, kcalQuemadas, kcalConsumidas } = req.body;

    if (!fecha || pasos == null || kcalQuemadas == null || kcalConsumidas == null) {
      return res.status(400).json({ mensaje: 'Faltan datos requeridos.' });
    }

    const fechaDia = new Date(fecha);
    fechaDia.setHours(0, 0, 0, 0);

    let salud = await Salud.findOne({ usuario: usuarioId, fecha: fechaDia });
    if (!salud) salud = new Salud({ usuario: usuarioId, fecha: fechaDia });

    salud.pasos = pasos;
    salud.kcalQuemadas = kcalQuemadas;
    salud.kcalConsumidas = kcalConsumidas;

    await salud.save();
    res.json({ mensaje: 'Datos de salud guardados exitosamente', salud });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al guardar los datos de salud' });
  }
};

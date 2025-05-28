// saludController.js (actualizado)
const Salud = require('../models/Salud');
const Plato = require('../models/Plato');
const Dieta = require('../models/Dieta');

exports.actualizarPasos = async (req, res) => {
  try {
    const usuarioId = req.user.id;
    const { pasos, kcalQuemadas, kcalConsumidas, fecha, sumarKcal } = req.body;
    console.log("ACTUALIZAR PASOS", req.body);

    if (
      pasos === undefined &&
      kcalQuemadas === undefined &&
      kcalConsumidas === undefined
    ) {
      return res.status(400).json({ mensaje: 'Debe proporcionar al menos un dato para actualizar.' });
    }

    const fechaDia = new Date(fecha || new Date().toISOString().split('T')[0]);
    fechaDia.setHours(0, 0, 0, 0);

    let salud = await Salud.findOne({ usuario: usuarioId, fecha: fechaDia });

    if (!salud) {
      salud = new Salud({ usuario: usuarioId, fecha: fechaDia });
    }

    if (typeof pasos === 'number' && pasos >= 0) {
      salud.pasos = pasos;

      if (kcalQuemadas === undefined && !sumarKcal) {
        // ⚠️ Antes: pisa el total
        // salud.kcalQuemadas = pasos * 0.04;

        // ✅ Después: calcula automáticamente y suma al extra manual
        const kcalPorPasos = pasos * 0.04;
        const kcalManual = salud.kcalQuemadasManual || 0;
        salud.kcalQuemadas = kcalPorPasos + kcalManual;
      }
    }



    if (typeof kcalQuemadas === 'number' && kcalQuemadas >= 0) {
      if (sumarKcal) {
        salud.kcalQuemadasManual = (salud.kcalQuemadasManual || 0) + kcalQuemadas;
      } else {
        salud.kcalQuemadasManual = kcalQuemadas;
      }

      // Después de actualizar manual, recalcula total
      const kcalPorPasos = salud.pasos * 0.04;
      salud.kcalQuemadas = kcalPorPasos + salud.kcalQuemadasManual;
    }


    if (typeof kcalConsumidas === 'number' && kcalConsumidas >= 0) {
      salud.kcalConsumidas = kcalConsumidas;
    }

    await salud.save();
    const usuariosController = require('./usuariosController');
    const nuevosLogros = await usuariosController.chequearLogrosYDesbloquear(usuarioId);
    res.json({ mensaje: 'Datos de salud actualizados correctamente.', salud, nuevosLogros });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al actualizar los datos de salud' });
  }
};



exports.actualizarKcalConsumidas = async (req, res) => {
  try {
    const usuarioId = req.user.id;

    // Rango del día actual
    const inicioDia = new Date();
    inicioDia.setHours(0, 0, 0, 0);

    const finDia = new Date(inicioDia);
    finDia.setDate(inicioDia.getDate() + 1); // para usar $lt

    const dieta = await Dieta.findOne({
      usuario: usuarioId,
      fecha: { $gte: inicioDia, $lt: finDia }
    }).populate('platos');

    if (!dieta) {
      return res.status(404).json({ mensaje: 'No hay dieta registrada para hoy.' });
    }

    const kcalConsumidas = dieta.platos.reduce((total, plato) => total + (plato.kcal || 0), 0);

    let salud = await Salud.findOne({ usuario: usuarioId, fecha: inicioDia });
    if (!salud) salud = new Salud({ usuario: usuarioId, fecha: inicioDia });

    salud.kcalConsumidas = kcalConsumidas;
    await salud.save();

    res.json({ mensaje: 'Kcal consumidas sincronizadas desde la dieta.', kcalConsumidas });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al sincronizar kcal consumidas' });
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
    const nuevosLogros = await chequearLogrosYDesbloquear(usuarioId);
    res.json({ mensaje: 'Datos de salud guardados exitosamente', salud, nuevosLogros });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al guardar los datos de salud' });
  }
};

exports.DatosSalud = async (req, res) => {
  try {
    const usuarioId = req.user.id;
    const fecha = new Date(req.params.fecha);
    fecha.setHours(0, 0, 0, 0);

    let salud = await Salud.findOne({ usuario: usuarioId, fecha });

    // Si no existe aún, se crea un documento base
    if (!salud) {
      salud = new Salud({ usuario: usuarioId, fecha });
    }

    // 🔄 Sincroniza automáticamente las kcalConsumidas desde la dieta
    const inicioDia = new Date(fecha);
    const finDia = new Date(inicioDia);
    finDia.setDate(inicioDia.getDate() + 1);

    const dieta = await Dieta.findOne({
      usuario: usuarioId,
      fecha: { $gte: inicioDia, $lt: finDia }
    }).populate('platos');

    if (dieta) {
      const kcalConsumidas = dieta.platos.reduce((total, plato) => total + (plato.kcal || 0), 0);
      salud.kcalConsumidas = kcalConsumidas;
    }

    await salud.save();

    res.json(salud);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener los datos de salud' });
  }
};



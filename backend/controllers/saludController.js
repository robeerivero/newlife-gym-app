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

        const fechaDia = fecha || new Date().toISOString().split('T')[0];

        let salud = await Salud.findOne({ usuario: usuarioId, fecha: fechaDia });

        if (!salud) {
            salud = new Salud({ usuario: usuarioId, fecha: fechaDia });
        }

        salud.pasos = pasos;
        salud.kcalQuemadas = kcalQuemadas || (pasos * 0.04); // Si no llega quemadas, calcula
        salud.kcalConsumidas = kcalConsumidas ?? salud.kcalConsumidas; // Si no llega, deja el mismo valor

        await salud.save();

        res.json({ mensaje: 'Pasos y calorías actualizados', salud });
    } catch (error) {
        console.error(error);
        res.status(500).json({ mensaje: 'Error al actualizar pasos' });
    }
};


// 📌 2. Registrar kcal consumidas basadas en la dieta del usuario
exports.actualizarKcalConsumidas = async (req, res) => {
    try {
        const usuarioId = req.user.id;
        const hoy = new Date().toISOString().split('T')[0];

        // Obtener la dieta de hoy
        const dieta = await Dieta.findOne({ usuario: usuarioId, fecha: hoy }).populate('platos');

        if (!dieta) {
            return res.status(404).json({ mensaje: 'No hay dieta registrada para hoy.' });
        }

        // Sumar las kcal de los platos
        const kcalConsumidas = dieta.platos.reduce((total, plato) => total + plato.kcal, 0);

        let salud = await Salud.findOne({ usuario: usuarioId, fecha: hoy });

        if (!salud) {
            salud = new Salud({ usuario: usuarioId, fecha: hoy });
        }

        salud.kcalConsumidas = kcalConsumidas;

        await salud.save();

        res.json({ mensaje: 'Kcal consumidas actualizadas', kcalConsumidas });
    } catch (error) {
        console.error(error);
        res.status(500).json({ mensaje: 'Error al actualizar kcal consumidas' });
    }
};

// 📌 3. Obtener historial de salud (últimos 7 días)
exports.obtenerHistorialSalud = async (req, res) => {
    try {
        const usuarioId = req.user.id;
        const sieteDiasAtras = new Date();
        sieteDiasAtras.setDate(sieteDiasAtras.getDate() - 7);

        const historial = await Salud.find({ usuario: usuarioId, fecha: { $gte: sieteDiasAtras } })
            .sort({ fecha: 1 });

        res.json(historial);
    } catch (error) {
        console.error(error);
        res.status(500).json({ mensaje: 'Error al obtener historial de salud' });
    }
};

exports.guardarDatosSalud = async (req, res) => {
    try {
      const usuarioId = req.user.id; // Cambiar de req.usuario a req.user
      const { fecha, pasos, kcalQuemadas, kcalConsumidas } = req.body;
  
      // Validar que los datos necesarios estén presentes
      if (!fecha || pasos === undefined || kcalQuemadas === undefined || kcalConsumidas === undefined) {
        return res.status(400).json({ mensaje: 'Faltan datos requeridos.' });
      }
  
      // Buscar o crear un registro de salud para el usuario y la fecha
      let salud = await Salud.findOne({ usuario: usuarioId, fecha });
  
      if (!salud) {
        salud = new Salud({ usuario: usuarioId, fecha });
      }
  
      // Actualizar los datos
      salud.pasos = pasos;
      salud.kcalQuemadas = kcalQuemadas;
      salud.kcalConsumidas = kcalConsumidas;
  
      // Guardar los datos
      await salud.save();
  
      res.json({ mensaje: 'Datos de salud guardados exitosamente', salud });
    } catch (error) {
      console.error(error);
      res.status(500).json({ mensaje: 'Error al guardar los datos de salud' });
    }
  };

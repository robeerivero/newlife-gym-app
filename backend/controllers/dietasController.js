// backend/controllers/dietasController.js
const Dieta = require('../models/Dieta');
const DietaPredefinida = require('../models/Plato');

exports.crearDieta = async (req, res) => {
  const { usuario, fecha, platos } = req.body;

  try {
    const nuevaDieta = new Dieta({ usuario, fecha, platos });
    await nuevaDieta.save();
    res.status(201).json({ mensaje: 'Dieta creada con éxito', dieta: nuevaDieta });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al crear la dieta', error });
  }
};


// backend/controllers/dietasController.js
exports.obtenerDietas = async (req, res) => {
  console.log('Rol del usuario:', req.user.rol);

  const idUsuario = req.user._id;
  const fecha = req.query.fecha; // Obtener fecha del query string

  try {
    const filtro = { usuario: idUsuario };
    if (fecha) {
      // Filtrar por la fecha exacta
      const fechaInicio = new Date(fecha);
      const fechaFin = new Date(fecha);
      fechaFin.setDate(fechaFin.getDate() + 1);
      filtro.fecha = { $gte: fechaInicio, $lt: fechaFin };
    }

    const dietas = await Dieta.find(filtro)
      .populate('platos')
      .sort({ fecha: -1 });
    res.status(200).json(dietas);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener las dietas', error });
  }
};



exports.obtenerDietasPorUsuario = async (req, res) => {
  const { idUsuario } = req.params;

  try {
    const dietas = await Dieta.find({ usuario: idUsuario }).populate('platos').sort({ fecha: -1 });
    res.status(200).json(dietas);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener las dietas', error });
  }
};


// Actualizar una dieta
exports.modificarDieta = async (req, res) => {
  const { idDieta } = req.params;
  const { fecha, platos } = req.body;

  try {
    const dietaActualizada = await Dieta.findByIdAndUpdate(
      idDieta,
      { fecha, platos },
      { new: true }
    );

    if (!dietaActualizada) {
      return res.status(404).json({ mensaje: 'Dieta no encontrada' });
    }

    res.status(200).json({ mensaje: 'Dieta modificada con éxito', dieta: dietaActualizada });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al modificar la dieta', error });
  }
};


// Eliminar una dieta
exports.eliminarDieta = async (req, res) => {
  const { idDieta } = req.params;

  try {
    const dietaEliminada = await Dieta.findByIdAndDelete(idDieta);
    if (!dietaEliminada) {
      return res.status(404).json({ mensaje: 'Dieta no encontrada' });
    }
    res.status(200).json({ mensaje: 'Dieta eliminada' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al eliminar la dieta', error });
  }
};

exports.asignarPlatoADieta = async (req, res) => {
  const { idDieta, idPlato } = req.params;

  try {
    const dieta = await Dieta.findById(idDieta);
    if (!dieta) {
      return res.status(404).json({ mensaje: 'Dieta no encontrada' });
    }

    if (!dieta.platos.includes(idPlato)) {
      dieta.platos.push(idPlato);
      await dieta.save();
    }

    res.status(200).json({ mensaje: 'Plato asignado a la dieta', dieta });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al asignar el plato a la dieta', error });
  }
};


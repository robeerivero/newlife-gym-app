// backend/controllers/dietasController.js
const Dieta = require('../models/Dieta');
const Plato = require('../models/Plato');
const Usuario = require('../models/Usuario');

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
/**
 * Endpoint para OBTENER SUGERENCIAS de platos basadas en
 * las calorías objetivo del usuario.
 */
exports.obtenerSugerenciasDieta = async (req, res) => {
  const { id } = req.user;

  try {
    const usuario = await Usuario.findById(id);
    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    const { kcalObjetivo } = usuario;

    // --- CAMBIOS AQUÍ (PASO 1) ---
    // 1. Distribuir Kcal en 4 comidas
    const rangoKcal = 120; // Un rango un poco más ajustado
    
    const kcalDesayuno = kcalObjetivo * 0.25;
    const kcalAlmuerzo = kcalObjetivo * 0.35;
    const kcalMerienda = kcalObjetivo * 0.15; // <-- AÑADIDO
    const kcalCena = kcalObjetivo * 0.25;

    // --- CAMBIOS AQUÍ (PASO 2) ---
    // 2. Buscar platos en paralelo (4 comidas)
    const [desayunos, almuerzos, meriendas, cenas] = await Promise.all([
      // Buscar Desayunos
      Plato.find({
        comidaDelDia: 'Desayuno',
        kcal: {
          $gte: kcalDesayuno - rangoKcal,
          $lte: kcalDesayuno + rangoKcal
        }
      }).limit(7),

      // Buscar Almuerzos
      Plato.find({
        comidaDelDia: 'Almuerzo',
        kcal: {
          $gte: kcalAlmuerzo - rangoKcal,
          $lte: kcalAlmuerzo + rangoKcal
        }
      }).limit(7),

      // <-- AÑADIDO -->
      // Buscar Meriendas
      Plato.find({
        comidaDelDia: 'Merienda',
        kcal: {
          $gte: kcalMerienda - rangoKcal,
          $lte: kcalMerienda + rangoKcal
        }
      }).limit(7),

      // Buscar Cenas
      Plato.find({
        comidaDelDia: 'Cena',
        kcal: {
          $gte: kcalCena - rangoKcal,
          $lte: kcalCena + rangoKcal
        }
      }).limit(7)
    ]);

    // --- CAMBIOS AQUÍ (PASO 3) ---
    // 3. Devolver las sugerencias
    res.status(200).json({
      kcalObjetivo,
      sugerencias: {
        desayunos,
        almuerzos,
        meriendas, // <-- AÑADIDO
        cenas
      }
    });

  } catch (error) {
    console.error('Error al generar sugerencias de dieta:', error);
    res.status(500).json({ mensaje: 'Error al generar sugerencias' });
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


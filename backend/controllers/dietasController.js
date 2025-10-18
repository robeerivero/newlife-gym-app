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

async function findDishesWithFallback(mealType, targetKcal, range, limit = 7) {
  const minKcal = Math.max(0, targetKcal - range);
  const maxKcal = targetKcal + range;

  // 1. Intenta encontrar dentro del rango ideal
  let dishes = await Plato.find({
    comidaDelDia: mealType,
    kcal: { $gte: minKcal, $lte: maxKcal }
  }).limit(limit);

  // 2. Fallback: Si se encuentran muy pocos (0, 1 o 2), busca los más cercanos
  if (dishes.length < 3 && limit > 0) {
    console.log(`[DIETA FALLBACK] Pocos ${mealType} en rango [${minKcal.toFixed(0)}-${maxKcal.toFixed(0)}]. Buscando los más cercanos a ${targetKcal.toFixed(0)} kcal.`);

    const closestDishesAggregation = await Plato.aggregate([
      { $match: { comidaDelDia: mealType } },
      {
        $addFields: {
          kcalDifference: { $abs: { $subtract: ["$kcal", targetKcal] } }
        }
      },
      { $sort: { kcalDifference: 1 } }, // Ordena por la diferencia más pequeña
      { $limit: limit }, // Coge los N más cercanos
      { $project: { _id: 1 } } // Solo necesitamos los IDs para la siguiente consulta
    ]);

    // Extrae solo los IDs del resultado de la agregación
    const closestIds = closestDishesAggregation.map(d => d._id);

    if (closestIds.length > 0) {
      // Busca los documentos completos usando los IDs encontrados
      dishes = await Plato.find({ '_id': { $in: closestIds } });
      // Opcional: Re-ordenar por diferencia si es necesario, aunque `limit` ya cogió los más cercanos.
      // dishes.sort((a, b) => Math.abs(a.kcal - targetKcal) - Math.abs(b.kcal - targetKcal));
    }
  }

  return dishes;
}

exports.obtenerSugerenciasDieta = async (req, res) => {
  const { id } = req.user;

  try {
    const usuario = await Usuario.findById(id);
    if (!usuario) { return res.status(404).json({ mensaje: 'Usuario no encontrado' }); }

    const { kcalObjetivo } = usuario;
    const rangoKcal = 180; // Mantenemos el rango amplio

    const kcalDesayuno = kcalObjetivo * 0.25;
    const kcalAlmuerzo = kcalObjetivo * 0.35;
    const kcalMerienda = kcalObjetivo * 0.15;
    const kcalCena     = kcalObjetivo * 0.25;

    // Logs (mantenlos para depurar si sigue fallando)
    console.log(`[DIETA DEBUG] Buscando para ${kcalObjetivo} Kcal:`);
    console.log(`  -> Desayuno (${(kcalDesayuno).toFixed(0)} kcal): Rango [${Math.max(0, kcalDesayuno - rangoKcal).toFixed(0)} - ${(kcalDesayuno + rangoKcal).toFixed(0)}]`);
    console.log(`  -> Almuerzo (${(kcalAlmuerzo).toFixed(0)} kcal): Rango [${Math.max(0, kcalAlmuerzo - rangoKcal).toFixed(0)} - ${(kcalAlmuerzo + rangoKcal).toFixed(0)}]`);
    console.log(`  -> Merienda (${(kcalMerienda).toFixed(0)} kcal): Rango [${Math.max(0, kcalMerienda - rangoKcal).toFixed(0)} - ${(kcalMerienda + rangoKcal).toFixed(0)}]`);
    console.log(`  -> Cena     (${(kcalCena).toFixed(0)} kcal): Rango [${Math.max(0, kcalCena - rangoKcal).toFixed(0)} - ${(kcalCena + rangoKcal).toFixed(0)}]`);

    // Usa el helper mejorado
    const [desayunos, almuerzos, meriendas, cenas] = await Promise.all([
      findDishesWithFallback('Desayuno', kcalDesayuno, rangoKcal),
      findDishesWithFallback('Almuerzo', kcalAlmuerzo, rangoKcal),
      findDishesWithFallback('Merienda', kcalMerienda, rangoKcal),
      findDishesWithFallback('Cena', kcalCena, rangoKcal)
    ]);

    // Logs
    console.log(`[DIETA DEBUG] Platos encontrados (después de fallback):`);
    console.log(`  -> Desayunos: ${desayunos.length}`);
    console.log(`  -> Almuerzos: ${almuerzos.length}`);
    console.log(`  -> Meriendas: ${meriendas.length}`);
    console.log(`  -> Cenas:     ${cenas.length}`);

    res.status(200).json({
      kcalObjetivo,
      sugerencias: { desayunos, almuerzos, meriendas, cenas }
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


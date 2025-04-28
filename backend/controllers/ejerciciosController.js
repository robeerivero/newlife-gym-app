const Ejercicio = require('../models/Ejercicio');

// Crear un nuevo ejercicio
exports.crearEjercicio = async (req, res) => {
  const { nombre, video, descripcion, dificultad } = req.body;

  try {
    // Validación de los campos requeridos
    if (!nombre || !video || !dificultad) {
      return res.status(400).json({ mensaje: 'Los campos nombre, video y dificultad son obligatorios.' });
    }

    const ejercicioExistente = await Ejercicio.findOne({ nombre });
    if (ejercicioExistente) {
      return res.status(400).json({ mensaje: 'Ya existe un ejercicio con ese nombre.' });
    }

    const nuevoEjercicio = new Ejercicio({
      nombre,
      video,
      descripcion,
      dificultad,
    });

    await nuevoEjercicio.save();
    res.status(201).json({ mensaje: 'Ejercicio creado exitosamente', nuevoEjercicio });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al crear el ejercicio.', error: error.message });
  }
};

// Obtener todos los ejercicios
exports.obtenerEjercicios = async (req, res) => {
  try {
    const ejercicios = await Ejercicio.find({});
    res.status(200).json(ejercicios);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener los ejercicios.', error: error.message });
  }
};

// Obtener un ejercicio por ID
exports.obtenerEjercicioPorId = async (req, res) => {
  const { idEjercicio } = req.params;

  try {
    const ejercicio = await Ejercicio.findById(idEjercicio);
    if (!ejercicio) {
      return res.status(404).json({ mensaje: 'Ejercicio no encontrado.' });
    }
    res.status(200).json(ejercicio);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener el ejercicio.', error: error.message });
  }
};

// Modificar un ejercicio existente
exports.modificarEjercicio = async (req, res) => {
  const { idEjercicio } = req.params;
  const { nombre, video, descripcion, dificultad } = req.body;

  try {
    const ejercicio = await Ejercicio.findById(idEjercicio);
    if (!ejercicio) {
      return res.status(404).json({ mensaje: 'Ejercicio no encontrado.' });
    }

    // Actualización de los campos
    ejercicio.nombre = nombre || ejercicio.nombre;
    ejercicio.video = video || ejercicio.video;
    ejercicio.descripcion = descripcion || ejercicio.descripcion;
    ejercicio.dificultad = dificultad || ejercicio.dificultad;

    await ejercicio.save();
    res.status(200).json({ mensaje: 'Ejercicio modificado exitosamente', ejercicio });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al modificar el ejercicio.', error: error.message });
  }
};

// Eliminar un ejercicio por ID
exports.eliminarEjercicio = async (req, res) => {
  const { idEjercicio } = req.params;

  try {
    const ejercicioEliminado = await Ejercicio.findByIdAndDelete(idEjercicio);
    if (!ejercicioEliminado) {
      return res.status(404).json({ mensaje: 'Ejercicio no encontrado.' });
    }
    res.status(200).json({ mensaje: 'Ejercicio eliminado exitosamente.' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al eliminar el ejercicio.', error: error.message });
  }
};

// Eliminar todos los ejercicios
exports.eliminarTodosLosEjercicios = async (req, res) => {
  try {
    await Ejercicio.deleteMany({});
    res.status(200).json({ mensaje: 'Todos los ejercicios han sido eliminados.' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al eliminar todos los ejercicios.', error: error.message });
  }
};

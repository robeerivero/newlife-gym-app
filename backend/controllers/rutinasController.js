const Rutina = require('../models/Rutina');
const Usuario = require('../models/Usuario'); // Asegúrate de importar el modelo Usuario
const Ejercicio = require('../models/Ejercicio'); 
exports.crearRutina = async (req, res) => {
  const { usuario, diaSemana, ejercicios } = req.body;

  try {
    // Verificar que el usuario existe
    const usuarioExiste = await Usuario.findById(usuario);
    if (!usuarioExiste) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    // Validar cada ejercicio
    for (const ejercicioObj of ejercicios) {
      const ejercicioExiste = await Ejercicio.findById(ejercicioObj.ejercicio);
      if (!ejercicioExiste) {
        return res.status(404).json({ mensaje: `Ejercicio no encontrado: ${ejercicioObj.ejercicio}` });
      }
      if (ejercicioObj.series <= 0 || ejercicioObj.repeticiones <= 0) {
        return res.status(400).json({ mensaje: 'Series y repeticiones deben ser mayores a 0.' });
      }
    }

    // Crear y guardar la rutina
    const nuevaRutina = new Rutina({ usuario, diaSemana, ejercicios });
    await nuevaRutina.save();

    res.status(201).json({ mensaje: 'Rutina creada exitosamente', rutina: nuevaRutina });
  } catch (error) {
    console.error('Error al crear la rutina:', error);
    res.status(500).json({ mensaje: 'Error al crear la rutina', error });
  }
};



exports.modificarRutina = async (req, res) => {
  const { idRutina } = req.params;
  const { diaSemana, ejercicios } = req.body;

  console.log('➡️ [modificarRutina] ID:', idRutina);
  console.log('📥 Body recibido:', req.body);

  try {
    const rutina = await Rutina.findById(idRutina);
    if (!rutina) {
      console.warn('❌ Rutina no encontrada');
      return res.status(404).json({ mensaje: 'Rutina no encontrada' });
    }

    const ejerciciosValidados = [];

    for (const ej of ejercicios) {
      console.log('🔍 Validando ejercicio:', ej);

      const ejercicioExiste = await Ejercicio.findById(ej.ejercicio);
      if (!ejercicioExiste) {
        console.warn('❌ Ejercicio no encontrado:', ej.ejercicio);
        return res.status(404).json({ mensaje: `Ejercicio no encontrado: ${ej.ejercicio}` });
      }

      if (ej.series <= 0 || ej.repeticiones <= 0) {
        console.warn('❌ Series o repeticiones inválidas:', ej);
        return res.status(400).json({ mensaje: 'Series y repeticiones deben ser mayores a 0.' });
      }

      ejerciciosValidados.push({
        ejercicio: ejercicioExiste._id,
        series: ej.series,
        repeticiones: ej.repeticiones,
      });
    }

    rutina.diaSemana = diaSemana || rutina.diaSemana;
    rutina.ejercicios = ejerciciosValidados;

    console.log('💾 Guardando rutina actualizada...');
    await rutina.save();
    console.log('✅ Rutina actualizada:', rutina);

    res.status(200).json({ mensaje: 'Rutina actualizada exitosamente', rutina });

  } catch (error) {
    console.error('🔥 Error al actualizar la rutina:', error);
    res.status(500).json({ mensaje: 'Error al actualizar la rutina', error });
  }
};

exports.obtenerRutinaPorId = async (req, res) => {
  try {
    const rutina = await Rutina.findById(req.params.idRutina)
      .populate('usuario', 'nombre correo rol') // incluir más si querés
      .populate('ejercicios.ejercicio', 'nombre');

    if (!rutina) {
      return res.status(404).json({ mensaje: 'Rutina no encontrada' });
    }

    res.status(200).json(rutina);
  } catch (error) {
    console.error('Error al obtener rutina por ID:', error);
    res.status(500).json({ mensaje: 'Error interno', error });
  }
};


  
  exports.obtenerRutinasPorUsuario = async (req, res) => {
    const idUsuario = req.user._id;
  
    try {
      const rutinas = await Rutina.find({ usuario: idUsuario })
        .populate('ejercicios.ejercicio')
        .exec();
  
      res.status(200).json(rutinas);
    } catch (error) {
      console.error('Error al obtener rutinas:', error);
      res.status(500).json({ mensaje: 'Error al obtener las rutinas' });
    }
  };
  // Obtener todos las rutinas
  exports.obtenerRutinas = async (req, res) => {
    try {
      const rutinas = await Rutina.find()
        .populate('usuario', 'nombre') // Solo devuelve el nombre del usuario
        .populate('ejercicios.ejercicio', 'nombre'); // Solo devuelve el nombre del ejercicio
  
      res.status(200).json(rutinas);
    } catch (error) {
      console.error('Error al obtener rutinas:', error);
      res.status(500).json({ mensaje: 'Error al obtener rutinas', error });
    }
  };
  
  
  exports.eliminarRutina = async (req, res) => {
    const { idRutina } = req.params;
  
    try {
      const rutina = await Rutina.findByIdAndDelete(idRutina);
  
      if (!rutina) {
        return res.status(404).json({ mensaje: 'Rutina no encontrada' });
      }
  
      res.status(200).json({ mensaje: 'Rutina eliminada exitosamente' });
    } catch (error) {
      res.status(500).json({ mensaje: 'Error al eliminar la rutina', error });
    }
  };
  
  exports.eliminarRutinasPorUsuario = async (req, res) => {
    const { idUsuario } = req.params;
  
    try {
      await Rutina.deleteMany({ usuario: idUsuario });
      res.status(200).json({ mensaje: 'Todas las rutinas del usuario han sido eliminadas' });
    } catch (error) {
      res.status(500).json({ mensaje: 'Error al eliminar las rutinas del usuario', error });
    }
  };
  
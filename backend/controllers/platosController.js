const Dieta = require('../models/Dieta');
const Plato = require('../models/Plato');


exports.crearPlato = async (req, res) => {
    const { nombre, kcal, comidaDelDia, ingredientes, instrucciones, tiempoPreparacion, observaciones } = req.body;
    console.log(req.body);
    try {
      // Verificar si ya existe un plato con el mismo nombre
      const existePlato = await Plato.findOne({ nombre });
      if (existePlato) {
        return res.status(400).json({ mensaje: 'El plato ya existe, intenta reutilizarlo.' });
      }
  
      const nuevoPlato = new Plato({
        nombre,
        kcal,
        comidaDelDia,
        ingredientes,
        instrucciones,
        tiempoPreparacion,
        observaciones,
      });
  
      await nuevoPlato.save();
      res.status(201).json({ mensaje: 'Plato creado con éxito', plato: nuevoPlato });
    } catch (error) {
      res.status(500).json({ mensaje: 'Error al crear el plato', error });
    }
  };
  
  // Obtener todos los platos
exports.obtenerPlatos = async (req, res) => {
  try {
    const platos = await Plato.find();
    res.status(200).json(platos);
  } catch (error) {
    console.error('Error al obtener usuarios:', error);
    res.status(500).json({ mensaje: 'Error al obtener usuarios', error });
  }
};
  
  exports.modificarPlato = async (req, res) => {
    const { idPlato } = req.params;
    const { nombre, kcal, comidaDelDia, ingredientes, instrucciones, tiempoPreparacion, observaciones } = req.body;
  
    try {
      const platoActualizado = await Plato.findByIdAndUpdate(
        idPlato,
        { nombre, kcal, comidaDelDia, ingredientes, instrucciones, tiempoPreparacion, observaciones },
        { new: true }
      );
  
      if (!platoActualizado) {
        return res.status(404).json({ mensaje: 'Plato no encontrado' });
      }
  
      res.status(200).json({ mensaje: 'Plato modificado con éxito', plato: platoActualizado });
    } catch (error) {
      res.status(500).json({ mensaje: 'Error al modificar el plato', error });
    }
  };

  exports.eliminarPlato = async (req, res) => {
    const { idPlato } = req.params;
  
    try {
      const platoEliminado = await Plato.findByIdAndDelete(idPlato);
      if (!platoEliminado) {
        return res.status(404).json({ mensaje: 'Plato no encontrado' });
      }
  
      res.status(200).json({ mensaje: 'Plato eliminado con éxito' });
    } catch (error) {
      res.status(500).json({ mensaje: 'Error al eliminar el plato', error });
    }
  };

  exports.eliminarTodosLosPlatos = async (req, res) => {
    try {
      await Plato.deleteMany({});
      res.status(200).json({ mensaje: 'Todos los platos han sido eliminados con éxito' });
    } catch (error) {
      res.status(500).json({ mensaje: 'Error al eliminar todos los platos', error });
    }
  };
  
  
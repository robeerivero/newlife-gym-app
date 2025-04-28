const Grupo = require('../models/Grupo');
const Usuario = require('../models/Usuario');

// Crear un grupo
exports.crearGrupo = async (req, res) => {
  const { nombre, descripcion } = req.body;

  try {
    // Verificar si ya existe un grupo con el mismo nombre
    const grupoExistente = await Grupo.findOne({ nombre });
    if (grupoExistente) {
      return res.status(400).json({ mensaje: 'Ya existe un grupo con este nombre' });
    }

    const nuevoGrupo = new Grupo({ nombre, descripcion });
    await nuevoGrupo.save();

    res.status(201).json({ mensaje: 'Grupo creado exitosamente', grupo: nuevoGrupo });
  } catch (error) {
    console.error('Error al crear el grupo:', error);
    res.status(500).json({ mensaje: 'Error al crear el grupo', error });
  }
};

// Obtener todos los grupos
exports.obtenerGrupos = async (req, res) => {
  try {
    const grupos = await Grupo.find();
    res.status(200).json(grupos);
  } catch (error) {
    console.error('Error al obtener usuarios:', error);
    res.status(500).json({ mensaje: 'Error al obtener usuarios', error });
  }
};

// Ver un grupo por ID
exports.verGrupo = async (req, res) => {
  const { idGrupo } = req.params;

  try {
    const grupo = await Grupo.findById(idGrupo).populate('usuarios', 'nombre correo');
    if (!grupo) {
      return res.status(404).json({ mensaje: 'Grupo no encontrado' });
    }
    res.status(200).json(grupo);
  } catch (error) {
    console.error('Error al obtener el grupo:', error);
    res.status(500).json({ mensaje: 'Error al obtener el grupo', error });
  }
};

// Eliminar un usuario de un grupo
exports.eliminarUsuarioDeGrupo = async (req, res) => {
  const { idGrupo, idUsuario } = req.body;

  try {
    const grupo = await Grupo.findById(idGrupo);
    if (!grupo) {
      return res.status(404).json({ mensaje: 'Grupo no encontrado' });
    }

    grupo.usuarios = grupo.usuarios.filter((userId) => userId.toString() !== idUsuario);
    await grupo.save();

    res.status(200).json({ mensaje: 'Usuario eliminado del grupo exitosamente', grupo });
  } catch (error) {
    console.error('Error al eliminar usuario del grupo:', error);
    res.status(500).json({ mensaje: 'Error al eliminar usuario del grupo', error });
  }
};


// Eliminar un grupo
exports.eliminarGrupo = async (req, res) => {
  const { idGrupo } = req.params;

  try {
    const grupo = await Grupo.findByIdAndDelete(idGrupo);
    if (!grupo) {
      return res.status(404).json({ mensaje: 'Grupo no encontrado' });
    }
    res.status(200).json({ mensaje: 'Grupo eliminado exitosamente' });
  } catch (error) {
    console.error('Error al eliminar el grupo:', error);
    res.status(500).json({ mensaje: 'Error al eliminar el grupo', error });
  }
};

// Añadir un usuario a un grupo
exports.anadirUsuarioAGrupo = async (req, res) => {
  const { idGrupo, idUsuario } = req.body;

  try {
    const grupo = await Grupo.findById(idGrupo);
    const usuario = await Usuario.findById(idUsuario);

    if (!grupo) {
      return res.status(404).json({ mensaje: 'Grupo no encontrado' });
    }
    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    if (grupo.usuarios.includes(idUsuario)) {
      return res.status(400).json({ mensaje: 'El usuario ya pertenece a este grupo' });
    }

    grupo.usuarios.push(idUsuario);
    await grupo.save();

    res.status(200).json({ mensaje: 'Usuario añadido al grupo exitosamente', grupo });
  } catch (error) {
    console.error('Error al añadir usuario al grupo:', error);
    res.status(500).json({ mensaje: 'Error al añadir usuario al grupo', error });
  }
};

const Usuario = require('../models/Usuario');
const Salud = require('../models/Salud');
const Reserva = require('../models/Reserva');
const bcrypt = require('bcryptjs'); // Necesario para actualizarDatosAdmin

// --- RANKING MENSUAL ---
exports.rankingMensual = async (req, res) => {
  try {
    const now = new Date();
    const mesActual = now.getMonth();
    const anioActual = now.getFullYear();

    // Solo usuarios cliente
    const usuarios = await Usuario.find({ rol: 'cliente' });

    // Buscar reservas con asistencia en este mes
    const reservasMes = await Reserva.find({
      asistio: true
    }).populate('clase').where('clase.fecha').gte(new Date(anioActual, mesActual, 1)).lt(new Date(anioActual, mesActual + 1, 1));

    // Contar asistencias por usuario
    let asistenciasPorUsuario = {};
    reservasMes.forEach(r => {
      const id = r.usuario.toString();
      asistenciasPorUsuario[id] = (asistenciasPorUsuario[id] || 0) + 1;
    });

    // Pasos del mes por usuario
    const saludMes = await Salud.aggregate([
      {
        $match: {
          fecha: {
            $gte: new Date(anioActual, mesActual, 1),
            $lt: new Date(anioActual, mesActual + 1, 1),
          }
        }
      },
      {
        $group: {
          _id: "$usuario",
          totalPasos: { $sum: "$pasos" }
        }
      }
    ]);

    let pasosPorUsuario = {};
    saludMes.forEach(s => {
      pasosPorUsuario[s._id.toString()] = s.totalPasos;
    });

    // Crea ranking para cada usuario
    let ranking = usuarios.map(usuario => ({
      _id: usuario._id,
      nombre: usuario.nombre,
      avatar: usuario.avatar, // Se envía el objeto avatar guardado (o vacío)
      asistenciasEsteMes: asistenciasPorUsuario[usuario._id.toString()] || 0,
      pasosEsteMes: pasosPorUsuario[usuario._id.toString()] || 0,
    }));

    ranking.sort((a, b) => {
      if (b.asistenciasEsteMes !== a.asistenciasEsteMes) {
        return b.asistenciasEsteMes - a.asistenciasEsteMes;
      }
      return b.pasosEsteMes - a.pasosEsteMes;
    });

    res.json(ranking);

  } catch (error) {
    console.error("ERROR EN rankingMensual:", error);
    res.status(500).json({ mensaje: 'Error al generar ranking mensual' });
  }
};


// --- VER PERFIL ---
exports.obtenerPerfilUsuario = async (req, res) => {
  try {
    const usuario = await Usuario.findById(req.user.id);
    res.status(200).json(usuario);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener el perfil', error });
  }
};


// --- CREAR USUARIO (LIMPIO) ---
exports.crearUsuario = async (req, res) => {
  const { nombre, correo, contrasena, rol, tiposDeClases, nombreGrupo, esPremium } = req.body;

  try {
    const existeUsuario = await Usuario.findOne({ correo });
    if (existeUsuario) {
      return res.status(400).json({ msg: 'El correo ya está registrado.' });
    }

    // Validación básica de tipos de clases
    if (!Array.isArray(tiposDeClases) || tiposDeClases.length === 0) {
      return res.status(400).json({ mensaje: 'El campo tiposDeClases debe ser un array no vacío.' });
    }
    const valoresValidos = ['funcional', 'pilates', 'zumba'];
    const tiposValidos = tiposDeClases.every((tipo) => valoresValidos.includes(tipo));
    if (!tiposValidos) {
      return res.status(400).json({ mensaje: 'El campo tiposDeClases contiene valores no válidos.' });
    }

    // --- CAMBIO PRINCIPAL: Eliminada lógica de "prendasLogros" ---
    // Ya no calculamos desbloqueados ni avatar por defecto complejo.

    const nuevoUsuario = new Usuario({
      nombre,
      correo,
      contrasena, // El hook pre-save lo hasheará
      rol: rol || 'cliente',
      tiposDeClases,
      nombreGrupo: nombreGrupo || null,
      esPremium: esPremium || false,
      avatar: {}, // Se inicia vacío, el usuario lo editará en el frontend
      // desbloqueados: ELIMINADO
    });

    await nuevoUsuario.save();

    res.status(201).json({ msg: 'Usuario creado correctamente' });

  } catch (error) {
    console.error('Error al crear usuario:', error.message);
    if (error.code === 11000) {
      return res.status(400).json({ msg: 'El correo electrónico ya está registrado.' });
    }
    res.status(500).json({ msg: 'Error en el servidor al crear usuario' });
  }
};


// --- CAMBIAR CONTRASEÑA (USUARIO) ---
exports.cambiarContrasena = async (req, res) => {
  const { contrasenaActual, nuevaContrasena } = req.body;

  try {
    const usuario = await Usuario.findById(req.user.id);
    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    const esContrasenaValida = await usuario.verificarContrasena(contrasenaActual);
    if (!esContrasenaValida) {
      return res.status(400).json({ mensaje: 'La contraseña actual no es válida' });
    }

    usuario.contrasena = nuevaContrasena; // Se encripta automáticamente en el modelo
    await usuario.save();

    res.status(200).json({ mensaje: 'Contraseña actualizada exitosamente' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al cambiar la contraseña', error });
  }
};


// --- OBTENER TODOS LOS USUARIOS (ADMIN) ---
exports.obtenerUsuarios = async (req, res) => {
  try {
    const { nombreGrupo } = req.query;
    let filterOptions = {};
    const sortOptions = { nombre: 1 };

    if (nombreGrupo && nombreGrupo !== 'Todos') {
      if (nombreGrupo === 'Sin Grupo') {
        filterOptions.nombreGrupo = { $in: [null, '', undefined] };
      } else {
        filterOptions.nombreGrupo = nombreGrupo;
      }
    }

    const usuarios = await Usuario.find(filterOptions)
      .sort(sortOptions)
      .select('-contrasena'); // No devolvemos la contraseña
    res.json(usuarios);

  } catch (error) {
    console.error('Error al obtener usuarios:', error);
    res.status(500).send('Error en el servidor');
  }
};


// --- OBTENER GRUPOS ---
exports.obtenerGrupos = async (req, res) => {
  try {
    const grupos = await Usuario.distinct('nombreGrupo', { nombreGrupo: { $ne: null } });
    res.json(grupos);
  } catch (error) {
    res.status(500).json({ msg: 'Error al obtener grupos' });
  }
};


// --- ACTUALIZAR DATOS (ADMIN) ---
exports.actualizarDatosAdmin = async (req, res) => {
  const { idUsuario } = req.params;
  const { nombreGrupo, haPagado, nombre, correo, rol, esPremium, incluyePlanDieta, incluyePlanEntrenamiento, nuevaContrasena } = req.body;

  try {
    let fieldsToUpdate = {};

    if (nombre !== undefined) fieldsToUpdate.nombre = nombre;
    if (correo !== undefined) fieldsToUpdate.correo = correo;
    if (rol !== undefined) fieldsToUpdate.rol = rol;
    if (nombreGrupo !== undefined) fieldsToUpdate.nombreGrupo = nombreGrupo;
    if (haPagado !== undefined) fieldsToUpdate.haPagado = haPagado;
    if (esPremium !== undefined) fieldsToUpdate.esPremium = esPremium;
    if (incluyePlanDieta !== undefined) fieldsToUpdate.incluyePlanDieta = incluyePlanDieta;
    if (incluyePlanEntrenamiento !== undefined) fieldsToUpdate.incluyePlanEntrenamiento = incluyePlanEntrenamiento;

    if (nuevaContrasena) {
      const salt = await bcrypt.genSalt(10);
      fieldsToUpdate.contrasena = await bcrypt.hash(nuevaContrasena, salt);
    }

    if (Object.keys(fieldsToUpdate).length === 0) {
      return res.status(400).json({ msg: 'No se enviaron datos para actualizar' });
    }

    const usuario = await Usuario.findByIdAndUpdate(
      idUsuario,
      { $set: fieldsToUpdate },
      { new: true, runValidators: true }
    ).select('-contrasena');

    if (!usuario) {
      return res.status(404).json({ msg: 'Usuario no encontrado' });
    }

    res.json(usuario);

  } catch (error) {
    console.error('Error al actualizar datos de admin:', error);
    if (error.name === 'ValidationError') {
      return res.status(400).json({ msg: error.message });
    }
    if (error.code === 11000) {
      return res.status(400).json({ msg: 'El correo electrónico ya está en uso por otro usuario.' });
    }
    res.status(500).send('Error en el servidor al actualizar');
  }
};


// --- OBTENER USUARIO POR ID ---
exports.obtenerUsuarioPorId = async (req, res) => {
  const { idUsuario } = req.params;

  try {
    const usuario = await Usuario.findById(idUsuario);
    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }
    res.status(200).json(usuario);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener el usuario', error });
  }
};


// --- ACTUALIZAR USUARIO (GENERAL) ---
exports.actualizarUsuario = async (req, res) => {
  const idDelUsuarioAActualizar = req.params.idUsuario || req.user.id;
  const esPeticionDeAdmin = req.user.rol === 'admin';
  const esAdminEditandoAOtro = esPeticionDeAdmin && req.params.idUsuario;

  const {
    nombre, correo, rol, tiposDeClases, esPremium,
    incluyePlanDieta, incluyePlanEntrenamiento,
    nuevaContrasena
  } = req.body;

  try {
    const usuario = await Usuario.findById(idDelUsuarioAActualizar);
    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    // Campos comunes
    usuario.nombre = nombre || usuario.nombre;
    usuario.correo = correo || usuario.correo;

    // Solo cliente puede editar sus tipos de clases (o admin si quisiera implementarlo)
    if (!esPeticionDeAdmin && tiposDeClases) {
      if (!Array.isArray(tiposDeClases) || tiposDeClases.length === 0 || !tiposDeClases.every(tipo => ['funcional', 'pilates', 'zumba'].includes(tipo))) {
        return res.status(400).json({ mensaje: 'Tipos de clases inválidos.' });
      }
      usuario.tiposDeClases = tiposDeClases;
    }

    // Campos solo Admin
    if (esAdminEditandoAOtro) {
      usuario.rol = rol || usuario.rol;
      if (esPremium !== undefined) usuario.esPremium = esPremium;
      if (incluyePlanDieta !== undefined) usuario.incluyePlanDieta = incluyePlanDieta;
      if (incluyePlanEntrenamiento !== undefined) usuario.incluyePlanEntrenamiento = incluyePlanEntrenamiento;
      if (nuevaContrasena) usuario.contrasena = nuevaContrasena;
    }

    await usuario.save();
    res.status(200).json({ mensaje: 'Usuario actualizado exitosamente', usuario });

  } catch (error) {
    console.error('Error al actualizar el usuario:', error);
    if (error.code === 11000) {
      return res.status(400).json({ mensaje: 'El correo electrónico ya está en uso por otro usuario.' });
    }
    res.status(500).json({ mensaje: 'Error interno al actualizar el usuario', error: error.message });
  }
};


// --- ELIMINAR USUARIO ---
exports.eliminarUsuario = async (req, res) => {
  console.log(`[CONTROLLER] 8. eliminarUsuario iniciado para ID: ${req.params.idUsuario}`);
  try {
    const usuario = await Usuario.findById(req.params.idUsuario);
    if (!usuario) {
      console.log(`[CONTROLLER] 9. ERROR: Usuario no encontrado.`);
      return res.status(404).json({ msg: 'Usuario no encontrado' });
    }

    console.log(`[CONTROLLER] 9. Usuario encontrado. Eliminando...`);
    await usuario.deleteOne(); // Activa middleware pre-delete
    console.log(`[CONTROLLER] 10. Usuario eliminado de la DB.`);

    res.json({ msg: 'Usuario eliminado correctamente' });
  } catch (error) {
    console.error('[CONTROLLER] 10. ¡ERROR! Capturado en Controller:', error);
    res.status(500).json({ msg: 'Error en el servidor' });
  }
};


// --- ACTUALIZAR AVATAR (NUEVO - SIN LOGROS) ---
exports.actualizarAvatar = async (req, res) => {
  try {
    const { avatar } = req.body;
    // Permitimos que avatar sea un objeto o un string, dependiendo de cómo lo envíe el frontend,
    // pero validamos que exista.
    if (!avatar) return res.status(400).json({ mensaje: 'Falta la configuración del avatar' });

    const usuario = await Usuario.findByIdAndUpdate(
      req.user.id,
      { avatar },
      { new: true }
    );
    res.json({ mensaje: 'Avatar actualizado', avatar: usuario.avatar });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al actualizar avatar', error });
  }
};


// --- ACTUALIZAR DATOS METABÓLICOS ---
exports.actualizarDatosMetabolicos = async (req, res) => {
  const { id } = req.user;
  const { peso, altura, edad, genero, ocupacion, ejercicio, objetivo } = req.body;

  try {
    // 1. Calcular TMB
    let tmb;
    if (genero === 'masculino') {
      tmb = (10 * peso) + (6.25 * altura) - (5 * edad) + 5;
    } else {
      tmb = (10 * peso) + (6.25 * altura) - (5 * edad) - 161;
    }

    // 2. Calcular TDEE
    const factoresOcupacion = {
      sedentaria: 1.2,
      ligera: 1.375,
      activa: 1.55
    };
    const caloriasEjercicio = {
      '0': 0, '1-3': 300, '4-5': 500, '6-7': 700
    };

    const tdee = (tmb * (factoresOcupacion[ocupacion] || 1.2)) + (caloriasEjercicio[ejercicio] || 0);

    // 3. Calcular Objetivo
    let kcalObjetivo;
    switch (objetivo) {
      case 'perder':
        kcalObjetivo = tdee - 500;
        kcalObjetivo = Math.max(kcalObjetivo, tmb + 100);
        break;
      case 'ganar':
        kcalObjetivo = tdee + 300;
        break;
      case 'mantener':
      default:
        kcalObjetivo = tdee;
    }
    kcalObjetivo = Math.round(kcalObjetivo);

    // 4. Guardar
    const usuario = await Usuario.findByIdAndUpdate(
      id,
      {
        peso, altura, edad, genero, objetivo,
        ocupacion,
        ejercicio,
        nivelActividad: null,
        kcalObjetivo
      },
      { new: true }
    );

    res.status(200).json({
      mensaje: 'Datos metabólicos actualizados',
      kcalObjetivo: usuario.kcalObjetivo,
      tdee: Math.round(tdee),
      tmb: Math.round(tmb)
    });

  } catch (error) {
    console.error('Error al actualizar datos metabólicos:', error);
    res.status(500).json({ mensaje: 'Error en el servidor', error: error.message });
  }
};


// --- CAMBIAR CONTRASEÑA (ADMIN) ---
exports.cambiarContrasenaAdmin = async (req, res) => {
  const { contrasena } = req.body;
  const { idUsuario } = req.params;

  if (!contrasena || contrasena.length < 6) {
    return res.status(400).json({ mensaje: 'La contraseña debe tener al menos 6 caracteres.' });
  }

  try {
    const usuario = await Usuario.findById(idUsuario);
    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado.' });
    }

    usuario.contrasena = contrasena;
    await usuario.save(); // pre-save hook hashea

    res.status(200).json({ mensaje: 'Contraseña actualizada correctamente.' });

  } catch (error) {
    console.error('Error al cambiar contraseña (admin):', error);
    res.status(500).json({ mensaje: 'Error del servidor.', error: error.message });
  }
};
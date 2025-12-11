const Usuario = require('../models/Usuario');
const Salud = require('../models/Salud');
const Reserva = require('../models/Reserva');

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

    // Pasos del mes por usuario (igual que antes)
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
      avatar: usuario.avatar,
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


// Ver perfil del usuario
exports.obtenerPerfilUsuario = async (req, res) => {
  try {
    const usuario = await Usuario.findById(req.user.id);
    res.status(200).json(usuario);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener el perfil', error });
  }
};

exports.crearUsuario = async (req, res) => {
  // Extrae nombreGrupo
  const { nombre, correo, contrasena, rol, tiposDeClases, nombreGrupo, esPremium } = req.body; // Añadido esPremium por si acaso

  try {
    const existeUsuario = await Usuario.findOne({ correo });
    if (existeUsuario) {
      return res.status(400).json({ msg: 'El correo ya está registrado.' });
    }

    // --- VALIDACIONES DE TIPOS DE CLASE (COMO LAS TENÍAS) ---
    if (!Array.isArray(tiposDeClases) || tiposDeClases.length === 0) {
      return res.status(400).json({ mensaje: 'El campo tiposDeClases debe ser un array no vacío.' });
    }
    const valoresValidos = ['funcional', 'pilates', 'zumba'];
    const tiposValidos = tiposDeClases.every((tipo) => valoresValidos.includes(tipo));
    if (!tiposValidos) {
      return res.status(400).json({ mensaje: 'El campo tiposDeClases contiene valores no válidos.' });
    }
    // --- FIN VALIDACIONES ---

    // --- LÓGICA DE PRENDAS Y AVATAR POR DEFECTO (COMO LA TENÍAS) ---
    const mapPrendas = {};
    for (const prenda of prendasLogros) {
      if (!mapPrendas[prenda.key]) mapPrendas[prenda.key] = [];
      if (!mapPrendas[prenda.key].includes(prenda.value)) {
        mapPrendas[prenda.key].push(prenda.value);
      }
    }
    const desbloqueadosPorDefecto = prendasLogros
      .filter(p => p.desbloqueadoPorDefecto)
      .map(p => ({ key: p.key, value: p.value }));
    const avatar = {};
    for (const d of desbloqueadosPorDefecto) {
      if (!(d.key in avatar)) {
        const valores = mapPrendas[d.key];
        const idx = valores.indexOf(d.value);
        if (idx !== -1) {
          avatar[d.key] = idx;
        }
      }
    }
    // --- FIN LÓGICA PRENDAS/AVATAR ---

    // --- ¡¡NO SE HASHEA LA CONTRASEÑA AQUÍ!! ---
    const nuevoUsuario = new Usuario({
      nombre,
      correo,
      contrasena, // <-- Contraseña en texto plano
      rol: rol || 'cliente', // Rol por defecto si no se especifica
      tiposDeClases,
      nombreGrupo: nombreGrupo || null,
      esPremium: esPremium || false, // Asignar esPremium si viene
      avatar: avatar, // Asignar avatar por defecto
      desbloqueados: desbloqueadosPorDefecto // Asignar desbloqueados por defecto
      // haPagado será false por defecto (definido en el Modelo)
    });

    await nuevoUsuario.save(); // El hook pre('save') en Usuario.js la hashea

    res.status(201).json({ msg: 'Usuario creado correctamente' }); // Mensaje simple

  } catch (error) {
    console.error('Error al crear usuario:', error.message);
    if (error.code === 11000) {
      return res.status(400).json({ msg: 'El correo electrónico ya está registrado.' });
    }
    res.status(500).json({ msg: 'Error en el servidor al crear usuario' });
  }
};





// Cambiar la contraseña del usuario
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


// Obtener todos los usuarios
exports.obtenerUsuarios = async (req, res) => {
  try {
    const { nombreGrupo } = req.query; // Solo necesitamos este filtro
    let filterOptions = {};
    const sortOptions = { nombre: 1 }; // Ordenar siempre por nombre

    // Filtro de Grupo
    if (nombreGrupo && nombreGrupo !== 'Todos') {
      if (nombreGrupo === 'Sin Grupo') {
        filterOptions.nombreGrupo = { $in: [null, '', undefined] };
      } else {
        filterOptions.nombreGrupo = nombreGrupo;
      }
    }
    // Si es 'Todos', no se aplica filtro

    const usuarios = await Usuario.find(filterOptions)
      .sort(sortOptions)
      .select('-contrasena');
    res.json(usuarios);

  } catch (error) {
    console.error('Error al obtener usuarios:', error);
    res.status(500).send('Error en el servidor');
  }
};

// --- ¡AÑADE ESTA NUEVA FUNCIÓN! ---
// Obtiene una lista única de nombres de grupo existentes
exports.obtenerGrupos = async (req, res) => {
  try {
    // ¡CORRECCIÓN! Añadimos un filtro para que no incluya los 'null'
    const grupos = await Usuario.distinct('nombreGrupo', { nombreGrupo: { $ne: null } });
    res.json(grupos);
  } catch (error) {
    res.status(500).json({ msg: 'Error al obtener grupos' });
  }
};
exports.actualizarDatosAdmin = async (req, res) => {
  const { idUsuario } = req.params;
  // Añadimos más campos que el admin puede querer editar
  const { nombreGrupo, haPagado, nombre, correo, rol, esPremium, incluyePlanDieta, incluyePlanEntrenamiento, nuevaContrasena } = req.body;

  try {
    let fieldsToUpdate = {};

    // Comprobar y añadir cada campo si está presente en el body
    if (nombre !== undefined) fieldsToUpdate.nombre = nombre;
    if (correo !== undefined) fieldsToUpdate.correo = correo;
    if (rol !== undefined) fieldsToUpdate.rol = rol;
    if (nombreGrupo !== undefined) fieldsToUpdate.nombreGrupo = nombreGrupo;
    if (haPagado !== undefined) fieldsToUpdate.haPagado = haPagado;
    if (esPremium !== undefined) fieldsToUpdate.esPremium = esPremium;
    if (incluyePlanDieta !== undefined) fieldsToUpdate.incluyePlanDieta = incluyePlanDieta;
    if (incluyePlanEntrenamiento !== undefined) fieldsToUpdate.incluyePlanEntrenamiento = incluyePlanEntrenamiento;

    // Actualizar contraseña SOLO si se proporciona una nueva
    if (nuevaContrasena) {
      // ¡IMPORTANTE! Al usar findByIdAndUpdate, el hook pre('save') NO se ejecuta.
      // Necesitamos hashear la contraseña aquí si se va a cambiar.
      const salt = await bcrypt.genSalt(10);
      fieldsToUpdate.contrasena = await bcrypt.hash(nuevaContrasena, salt);
    }


    if (Object.keys(fieldsToUpdate).length === 0) {
      return res.status(400).json({ msg: 'No se enviaron datos para actualizar' });
    }

    const usuario = await Usuario.findByIdAndUpdate(
      idUsuario,
      { $set: fieldsToUpdate },
      { new: true, runValidators: true } // runValidators para asegurar que el rol sea válido
    ).select('-contrasena');

    if (!usuario) {
      return res.status(404).json({ msg: 'Usuario no encontrado' });
    }

    res.json(usuario); // Devuelve el usuario actualizado (sin contraseña)

  } catch (error) {
    console.error('Error al actualizar datos de admin:', error);
    // Manejar error de validación (ej. rol inválido)
    if (error.name === 'ValidationError') {
      return res.status(400).json({ msg: error.message });
    }
    // Manejar error de correo duplicado si se intenta cambiar a uno existente
    if (error.code === 11000) {
      return res.status(400).json({ msg: 'El correo electrónico ya está en uso por otro usuario.' });
    }
    res.status(500).send('Error en el servidor al actualizar');
  }
};

// Obtener un usuario por ID
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

// Actualizar usuario
exports.actualizarUsuario = async (req, res) => {
  // 1. Determinar a quién actualizar y quién hace la petición
  const idDelUsuarioAActualizar = req.params.idUsuario || req.user.id;
  const esPeticionDeAdmin = req.user.rol === 'admin';
  const esAdminEditandoAOtro = esPeticionDeAdmin && req.params.idUsuario;

  // 2. Obtener todos los posibles datos del body
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

    // --- Campos que CUALQUIERA (Admin o Cliente) puede intentar actualizar ---
    usuario.nombre = nombre || usuario.nombre;
    usuario.correo = correo || usuario.correo; // El 'save' validará si el correo ya existe

    // --- Campo que SÓLO el CLIENTE puede actualizar en su perfil ---
    // (Un admin podría tener otra ruta/lógica si necesita cambiar esto)
    if (!esPeticionDeAdmin && tiposDeClases) {
      // Validación de tiposDeClases (como la tenías)
      if (!Array.isArray(tiposDeClases) || tiposDeClases.length === 0 || !tiposDeClases.every(tipo => ['funcional', 'pilates', 'zumba'].includes(tipo))) {
        return res.status(400).json({ mensaje: 'Tipos de clases inválidos.' });
      }
      usuario.tiposDeClases = tiposDeClases;
    }

    // --- Campos que SÓLO el ADMIN puede actualizar ---
    if (esAdminEditandoAOtro) {
      usuario.rol = rol || usuario.rol;

      // Actualiza booleans solo si vienen explícitamente en la petición
      if (esPremium !== undefined) {
        usuario.esPremium = esPremium;
      }
      if (incluyePlanDieta !== undefined) {
        usuario.incluyePlanDieta = incluyePlanDieta;
      }
      if (incluyePlanEntrenamiento !== undefined) {
        usuario.incluyePlanEntrenamiento = incluyePlanEntrenamiento;
      }

      // Admin puede resetear contraseña directamente
      if (nuevaContrasena) {
        usuario.contrasena = nuevaContrasena; // El pre-save hook hará el hash
      }
    }

    // Si es un cliente actualizando su perfil (/perfil), 
    // se ignorarán rol, esPremium, incluyePlan..., nuevaContrasena, etc. aunque los envíe.

    await usuario.save();
    res.status(200).json({ mensaje: 'Usuario actualizado exitosamente', usuario });

  } catch (error) {
    console.error('Error al actualizar el usuario:', error);
    if (error.code === 11000) { // Error de índice único (correo duplicado)
      return res.status(400).json({ mensaje: 'El correo electrónico ya está en uso por otro usuario.' });
    }
    res.status(500).json({ mensaje: 'Error interno al actualizar el usuario', error: error.message });
  }
};

/**
 * [ADMIN] Elimina un usuario por ID
 */
exports.eliminarUsuario = async (req, res) => {
  // --- LOG AÑADIDO ---
  console.log(`[CONTROLLER] 8. eliminarUsuario iniciado para ID: ${req.params.idUsuario}`);
  // -------------------

  try {
    const usuario = await Usuario.findById(req.params.idUsuario);

    if (!usuario) {
      // --- LOG AÑADIDO ---
      console.log(`[CONTROLLER] 9. ERROR: Usuario no encontrado.`);
      // -------------------
      return res.status(404).json({ msg: 'Usuario no encontrado' });
    }

    // --- LOG AÑADIDO ---
    console.log(`[CONTROLLER] 9. Usuario encontrado. Llamando a .remove()`);
    // -------------------

    // Usamos .remove() para activar el middleware 'pre("remove")' en Usuario.js
    await usuario.deleteOne();

    // --- LOG AÑADIDO ---
    console.log(`[CONTROLLER] 10. Usuario eliminado de la DB.`);
    // -------------------
    res.json({ msg: 'Usuario eliminado correctamente' });

  } catch (error) {
    // --- LOG AÑADIDO ---
    console.error('[CONTROLLER] 10. ¡ERROR! Capturado en Controller:', error);
    // -------------------
    res.status(500).json({ msg: 'Error en el servidor' });
  }
};


exports.actualizarAvatar = async (req, res) => {
  try {
    const { avatar } = req.body; // <-- asegúrate de usar 'avatar' (no 'fluttermojiJson')
    if (!avatar) return res.status(400).json({ mensaje: 'Falta el JSON del avatar' });

    const usuario = await Usuario.findByIdAndUpdate(
      req.user.id,
      { avatar }, // <--- guarda directamente el string del frontend
      { new: true }
    );
    res.json({ mensaje: 'Avatar actualizado', avatar: usuario.avatar });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al actualizar avatar', error });
  }
};


exports.actualizarDatosMetabolicos = async (req, res) => {
  const { id } = req.user;

  // --- ¡CAMBIO! Recibimos los nuevos campos ---
  const { peso, altura, edad, genero, ocupacion, ejercicio, objetivo } = req.body;

  // --- LOG DE DEBUG ---
  console.log('[actualizarDatosMetabolicos] Recibido:', req.body);

  try {
    // 1. Calcular TMB (Sin cambios)
    let tmb;
    if (genero === 'masculino') {
      tmb = (10 * peso) + (6.25 * altura) - (5 * edad) + 5;
    } else {
      tmb = (10 * peso) + (6.25 * altura) - (5 * edad) - 161;
    }

    // --- ¡¡LÓGICA MEJORADA!! ---
    const factoresOcupacion = {
      sedentaria: 1.2,
      ligera: 1.375,
      activa: 1.55
    };
    const caloriasEjercicio = {
      '0': 0, '1-3': 300, '4-5': 500, '6-7': 700 // Ajusta estos valores
    };

    const tdee = (tmb * (factoresOcupacion[ocupacion] || 1.2)) + (caloriasEjercicio[ejercicio] || 0);
    // --- FIN LÓGICA MEJORADA ---

    let kcalObjetivo;
    switch (objetivo) {
      case 'perder':
        kcalObjetivo = tdee - 500;
        kcalObjetivo = Math.max(kcalObjetivo, tmb + 100); // No bajar de TMB
        break;
      case 'ganar':
        kcalObjetivo = tdee + 300;
        break;
      case 'mantener':
      default:
        kcalObjetivo = tdee;
    }
    kcalObjetivo = Math.round(kcalObjetivo);

    // 4. Guardar TODOS los datos nuevos en el Usuario
    const usuario = await Usuario.findByIdAndUpdate(
      id,
      {
        peso, altura, edad, genero, objetivo,
        ocupacion,  // <-- NUEVO
        ejercicio,  // <-- NUEVO
        nivelActividad: null, // Anulamos el antiguo
        kcalObjetivo
      },
      { new: true }
    );

    // 5. Devolver la respuesta
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
exports.cambiarContrasenaAdmin = async (req, res) => {
  const { contrasena } = req.body; // Recibe la nueva contraseña
  const { idUsuario } = req.params;

  if (!contrasena || contrasena.length < 6) {
    return res.status(400).json({ mensaje: 'La contraseña debe tener al menos 6 caracteres.' });
  }

  try {
    // 1. Encontrar al usuario
    const usuario = await Usuario.findById(idUsuario);
    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado.' });
    }

    // 2. Asignar la nueva contraseña
    // ¡IMPORTANTE! Solo la asignamos, no la hasheamos aquí
    usuario.contrasena = contrasena;

    // 3. Guardar
    // El .save() SÍ activa el 'pre(save)' hook en Usuario.js
    await usuario.save();

    res.status(200).json({ mensaje: 'Contraseña actualizada correctamente.' });

  } catch (error) {
    console.error('Error al cambiar contraseña (admin):', error);
    res.status(500).json({ mensaje: 'Error del servidor.', error: error.message });
  }
};

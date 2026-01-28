const Usuario = require('../models/Usuario');
const Salud = require('../models/Salud');
const Reserva = require('../models/Reserva');
const bcrypt = require('bcryptjs'); // Necesario para actualizarDatosAdmin
const admin = require('firebase-admin');
// --- RANKING MENSUAL ---
exports.rankingMensual = async (req, res) => {
  try {
    const now = new Date();
    const mesActual = now.getMonth();
    const anioActual = now.getFullYear();
    
    // Fechas de inicio y fin del mes
    const fechaInicio = new Date(anioActual, mesActual, 1);
    const fechaFin = new Date(anioActual, mesActual + 1, 1);

    // 1. OBTENER LOS IDs DE LAS CLASES DE ESTE MES
    // Primero buscamos todas las clases que caen en este rango de fechas
    const clasesDelMes = await require('../models/Clase').find({
        fecha: { $gte: fechaInicio, $lt: fechaFin }
    }).select('_id'); // Solo necesitamos el ID

    // Convertimos el resultado a un array simple de IDs
    const idsClasesMes = clasesDelMes.map(c => c._id);

    // 2. BUSCAR RESERVAS QUE COINCIDAN CON ESOS IDs
    const reservasMes = await Reserva.find({
      asistio: true,
      clase: { $in: idsClasesMes } // <-- Aquí está la magia: buscamos si el ID de la clase está en la lista
    });

    // --- EL RESTO SIGUE IGUAL ---

    // Solo usuarios cliente
    const usuarios = await Usuario.find({ rol: 'cliente' });

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
            $gte: fechaInicio,
            $lt: fechaFin,
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

    // Ordenamos (primero asistencias, luego pasos)
    ranking.sort((a, b) => {
      if (b.asistenciasEsteMes !== a.asistenciasEsteMes) {
        return b.asistenciasEsteMes - a.asistenciasEsteMes;
      }
      return b.pasosEsteMes - a.pasosEsteMes;
    });

    // Tomamos solo los 10 primeros
    const top10 = ranking.slice(0, 10);

    res.json(top10);

  } catch (error) {
    console.error("ERROR EN rankingMensual:", error);
    res.status(500).json({ mensaje: 'Error al generar ranking mensual' });
  }
};


// --- VER PERFIL ---
exports.obtenerPerfilUsuario = async (req, res) => {
  try {
    // Buscamos al usuario
    const usuario = await Usuario.findById(req.user._id).select('-contrasena');

    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    const ahora = new Date();
    
    // Filtramos: Solo contamos los cupos cuya fecha de expiración sea FUTURA
    const cuposValidos = usuario.cuposCompensatorios.filter(c => new Date(c.fechaExpiracion) > ahora);

    // TRUCO: Convertimos el objeto a JSON para poder modificarlo antes de enviarlo
    const usuarioResponse = usuario.toObject();

    // Sobreescribimos el campo 'cancelaciones' con el número real de cupos válidos
    // El frontend recibirá un número simple (ej: 2) y será feliz.
    usuarioResponse.cancelaciones = cuposValidos.length;
    // ============================================================

    res.json(usuarioResponse);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener perfil' });
  }
};


exports.crearUsuario = async (req, res) => {
  const { nombre, correo, contrasena, rol, tiposDeClases, nombreGrupo, esPremium } = req.body;

  try {
    // 1. Verificar si ya existe
    const existeUsuario = await Usuario.findOne({ correo });
    if (existeUsuario) {
      return res.status(400).json({ msg: 'El correo ya está registrado.' });
    }

    // 2. Validaciones de tipos de clases
    if (!Array.isArray(tiposDeClases) || tiposDeClases.length === 0) {
      return res.status(400).json({ mensaje: 'El campo tiposDeClases debe ser un array no vacío.' });
    }
    const valoresValidos = ['funcional', 'pilates', 'zumba'];
    const tiposValidos = tiposDeClases.every((tipo) => valoresValidos.includes(tipo));
    if (!tiposValidos) {
      return res.status(400).json({ mensaje: 'El campo tiposDeClases contiene valores no válidos.' });
    }

    // 3. DEFINIR AVATAR POR DEFECTO (Vital para Fluttermoji)
    // Estos son los índices numéricos que espera la librería para dibujar una cara básica.
    const avatarPorDefecto = {
      "topType": 4,             // Pelo corto
      "accessoriesType": 0,     // Nada
      "hairColor": 1,           // Negro
      "facialHairType": 0,      // Afeitado
      "facialHairColor": 1,     // Negro
      "clotheType": 4,          // Camiseta
      "eyeType": 0,             // Ojos normales
      "eyebrowType": 0,         // Cejas normales
      "mouthType": 1,           // Sonrisa
      "skinColor": 1,           // Piel clara/media
      "clotheColor": 1,         // Ropa negra/gris
      "style": 0,               // Estilo normal
      "graphicType": 0          // Sin gráficos
    };

    // 4. Crear el usuario
    const nuevoUsuario = new Usuario({
      nombre,
      correo,
      contrasena, // El hook pre-save del modelo se encargará de hashearla
      rol: rol || 'cliente',
      tiposDeClases,
      nombreGrupo: nombreGrupo || null,
      esPremium: esPremium || false,
      
      // ASIGNAMOS EL AVATAR VÁLIDO AQUÍ
      avatar: avatarPorDefecto 
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
  // 1. AÑADIR 'tiposDeClases' AQUÍ 👇
  const { nombre, correo, rol, haPagado, nombreGrupo, esPremium, tiposDeClases } = req.body;

  try {
    // Buscar usuario primero para verificar que existe
    const usuario = await Usuario.findById(idUsuario);
    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    // 2. Si se envía una nueva contraseña, la encriptamos (esto ya lo tendrás seguramente)
    if (req.body.contrasena && req.body.contrasena.trim() !== '') {
        const salt = await bcrypt.genSalt(10);
        usuario.contrasena = await bcrypt.hash(req.body.contrasena, salt);
    }

    // 3. Actualizamos los campos básicos
    usuario.nombre = nombre || usuario.nombre;
    usuario.correo = correo || usuario.correo;
    usuario.rol = rol || usuario.rol;
    usuario.nombreGrupo = nombreGrupo; // Este puede ser null, así que no usamos ||
    
    // Convertimos haPagado y esPremium a Boolean si vienen
    if (haPagado !== undefined) usuario.haPagado = haPagado;
    if (esPremium !== undefined) usuario.esPremium = esPremium;

    // 4. AÑADIR LA LÓGICA PARA tiposDeClases AQUÍ 👇
    // Verificamos si viene el array en la petición antes de asignarlo
    if (tiposDeClases) {
      usuario.tiposDeClases = tiposDeClases;
    }

    // Guardamos
    const usuarioActualizado = await usuario.save();

    res.json(usuarioActualizado);

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al actualizar usuario' });
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

exports.registrarFcmToken = async (req, res) => {
  const { token } = req.body;
  const usuarioId = req.user._id;

  console.log(`📡 [API] Petición de registro de token recibida para usuario: ${usuarioId}`);

  if (!token) {
    console.log('⚠️ [API] Intento de registro sin token.');
    return res.status(400).json({ mensaje: 'El token es obligatorio' });
  }

  try {
    // Usamos $addToSet para evitar duplicados
    await Usuario.findByIdAndUpdate(usuarioId, {
      $addToSet: { fcmTokens: token }
    });

    console.log(`✅ [DB] Token guardado correctamente en MongoDB.`);
    res.status(200).json({ mensaje: 'Token FCM registrado correctamente' });
  } catch (error) {
    console.error('❌ [API] Error al registrar token FCM:', error);
    res.status(500).json({ mensaje: 'Error interno del servidor' });
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

exports.solicitarServicioPremium = async (req, res) => {
  const usuarioId = req.user._id;

  console.log(`📡 [PREMIUM] Usuario ${usuarioId} solicita servicio premium.`);

  try {
    // 1. Marcar en la base de datos que el usuario quiere premium
    const usuario = await Usuario.findByIdAndUpdate(
      usuarioId,
      { solicitudPremium: new Date() },
      { new: true }
    );

    // 2. Buscar a TODOS los administradores
    const administradores = await Usuario.find({ rol: 'admin' });

    // Recopilar tokens de todos los admins
    const adminTokens = administradores.flatMap(admin => admin.fcmTokens);

    if (adminTokens.length > 0) {
      // 3. Enviar Notificación Push a los Admins
      const message = {
        notification: {
          title: "🚀 Nueva Solicitud Premium",
          body: `${usuario.nombre} ha solicitado información sobre el servicio Premium.`
        },
        tokens: adminTokens
      };

      try {
        // Usamos sendEachForMulticast como corregimos anteriormente
        await admin.messaging().sendEachForMulticast(message);
        console.log(`🔔 [PREMIUM] Notificación enviada a ${adminTokens.length} admins.`);
      } catch (notifError) {
        console.error("❌ Error enviando notificación al admin:", notifError);
      }
    } else {
      console.log("⚠️ [PREMIUM] No se encontraron tokens de Admin para notificar.");
    }

    res.status(200).json({ mensaje: 'Solicitud enviada correctamente. Te contactaremos pronto.' });

  } catch (error) {
    console.error("Error al procesar la solicitud premium:", error);
    res.status(500).json({ mensaje: 'Error al procesar la solicitud' });
  }
};

exports.limpiarSolicitudPremium = async (req, res) => {
  const { idUsuario } = req.params;

  try {
    const usuario = await Usuario.findByIdAndUpdate(
      idUsuario,
      { $unset: { solicitudPremium: "" } }, // $unset borra el campo completamente
      { new: true }
    );

    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    res.json({ mensaje: 'Solicitud limpiada correctamente', usuario });

  } catch (error) {
    console.error('Error al limpiar solicitud:', error);
    res.status(500).json({ mensaje: 'Error del servidor' });
  }
};
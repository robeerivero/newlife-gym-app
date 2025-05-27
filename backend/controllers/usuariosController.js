const Usuario = require('../models/Usuario');
const fs = require('fs');
const path = require('path');
const Salud = require('../models/Salud');
const Clase = require('../models/Clase');
const prendasPath = path.join(__dirname, '../data/prendas_logros.json');
const prendasLogros = JSON.parse(fs.readFileSync(prendasPath, 'utf-8'));

exports.rankingMensual = async (req, res) => {
  try {
    console.log("LLEGA A RANKING MENSUAL!");

    const now = new Date();
    const mesActual = now.getMonth();
    const anioActual = now.getFullYear();

    // Solo usuarios cliente
    const usuarios = await Usuario.find({ rol: 'cliente' });
    console.log("Usuarios cliente:", usuarios.map(u => ({ id: u._id, nombre: u.nombre })));

    // Todas las clases de este mes
    const clasesMes = await Clase.find({
      fecha: {
        $gte: new Date(anioActual, mesActual, 1),
        $lt: new Date(anioActual, mesActual + 1, 1),
      }
    }).select('asistencias fecha');
    console.log("Clases este mes:", clasesMes.length);

    // Asistencias por usuario
    let asistenciasPorUsuario = {};
    clasesMes.forEach(clase => {
      clase.asistencias.forEach(idUsuario => {
        asistenciasPorUsuario[idUsuario] = (asistenciasPorUsuario[idUsuario] || 0) + 1;
      });
    });
    console.log("Asistencias por usuario:", asistenciasPorUsuario);

    // Pasos del mes por usuario (agregado Mongo)
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
    console.log("Salud (pasos mes):", saludMes);

    let pasosPorUsuario = {};
    saludMes.forEach(s => {
      pasosPorUsuario[s._id.toString()] = s.totalPasos;
    });
    console.log("Pasos por usuario:", pasosPorUsuario);

    // Crea ranking para cada usuario
    let ranking = usuarios.map(usuario => ({
      _id: usuario._id,
      nombre: usuario.nombre,
      avatar: usuario.avatar,
      asistenciasEsteMes: asistenciasPorUsuario[usuario._id.toString()] || 0,
      pasosEsteMes: pasosPorUsuario[usuario._id.toString()] || 0,
    }));

    console.log("Ranking (antes sort):", ranking);

    ranking.sort((a, b) => {
      if (b.asistenciasEsteMes !== a.asistenciasEsteMes) {
        return b.asistenciasEsteMes - a.asistenciasEsteMes;
      }
      return b.pasosEsteMes - a.pasosEsteMes;
    });

    console.log("Ranking (despues sort):", ranking);

    res.json(ranking);

  } catch (error) {
    console.error("ERROR EN rankingMensual:", error);
    res.status(500).json({ mensaje: 'Error al generar ranking mensual' });
  }
};



exports.obtenerPrendasDesbloqueadas = async (req, res) => {
  try {
        console.log("=> PETICIÓN prendas desbloqueadas de", req.user.id);
    const usuario = await Usuario.findById(req.user.id);
    if (!usuario) return res.status(404).json({ mensaje: "Usuario no encontrado" });

    // Construir un mapa key -> array de values en el orden correcto
    const mapPrendas = {};
    for (const prenda of prendasLogros) {
      if (!mapPrendas[prenda.key]) mapPrendas[prenda.key] = [];
      if (!mapPrendas[prenda.key].includes(prenda.value)) {
        mapPrendas[prenda.key].push(prenda.value);
      }
    }
    console.log("=> MapPrendas keys:", Object.keys(mapPrendas));
    console.log("=> Usuario.desbloqueados:", usuario.desbloqueados);
    // Ahora, devolver array [{key, idx}]
    const desbloqueados = (usuario.desbloqueados || []).map(d => {
      const arr = mapPrendas[d.key] || [];
      const idx = arr.indexOf(d.value);
      // si existe, devolver {key, idx}
      return idx !== -1 ? { key: d.key, idx } : null;
    }).filter(x => x !== null);

    res.json(desbloqueados);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error', error });
  }
};

exports.chequearLogrosYDesbloquear = async function(usuarioId) {
  const Usuario = require('../models/Usuario');
  const usuario = await Usuario.findById(usuarioId);
  if (!usuario) return [];

  const desbloqueados = usuario.desbloqueados || [];
  const totalAsistencias = usuario.asistencias ? usuario.asistencias.length : 0;
  const fechasAsistencias = usuario.asistenciasFechas
    ? usuario.asistenciasFechas.map(f => new Date(f)).sort((a, b) => a - b)
    : [];

  // Cálculo de racha máxima (días consecutivos)
  let maxRacha = 0, actualRacha = 1;
  for (let i = 1; i < fechasAsistencias.length; i++) {
    let diff = (fechasAsistencias[i] - fechasAsistencias[i-1]) / (1000 * 60 * 60 * 24);
    if (diff === 1) actualRacha++;
    else actualRacha = 1;
    if (actualRacha > maxRacha) maxRacha = actualRacha;
  }
  if (fechasAsistencias.length) maxRacha = Math.max(maxRacha, 1);

  // Datos de salud de hoy
  const hoy = new Date();
  hoy.setHours(0,0,0,0);
  const manana = new Date(hoy); manana.setDate(hoy.getDate()+1);

  const saludHoy = await Salud.findOne({
    usuario: usuario._id,
    fecha: { $gte: hoy, $lt: manana }
  });

  // Fechas especiales
  const esSanValentin = fechasAsistencias.some(f =>
    (new Date(f)).getDate() === 14 && (new Date(f)).getMonth() === 1
  );
  const es8Marzo = fechasAsistencias.some(f =>
    (new Date(f)).getDate() === 8 && (new Date(f)).getMonth() === 2
  );
  const esHalloween = fechasAsistencias.some(f =>
    (new Date(f)).getDate() === 31 && (new Date(f)).getMonth() === 9
  );
  const esNavidad = fechasAsistencias.some(f =>
    (new Date(f)).getDate() === 25 && (new Date(f)).getMonth() === 11
  );

  // Chequeo
  let nuevosDesbloqueos = [];
  for (const prenda of prendasLogros) {
    if (prenda.desbloqueadoPorDefecto) continue;
    if (desbloqueados.find(d => d.key === prenda.key && d.value === prenda.value)) continue;
    const logro = prenda.logro;
    let cumple = false;
    if (logro === 'asiste_primera_clase' && totalAsistencias >= 1) cumple = true;
    if (logro && logro.startsWith('asistencia_')) {
      const match = logro.match(/asistencia_(\d+)_total/);
      if (match && totalAsistencias >= parseInt(match[1])) cumple = true;
    }
    if (logro && logro.startsWith('asistencia_') && logro.includes('seguidas')) {
      const match = logro.match(/asistencia_(\d+)_seguidas/);
      if (match && maxRacha >= parseInt(match[1])) cumple = true;
    }
    if (logro && logro.startsWith('racha_')) {
      const match = logro.match(/racha_(\d+)_seguidas/);
      if (match && maxRacha >= parseInt(match[1])) cumple = true;
    }
    if (logro && logro.startsWith('pasos_')) {
      const match = logro.match(/pasos_(\d+)_dia/);
      if (match && saludHoy && saludHoy.pasos >= parseInt(match[1])) cumple = true;
    }
    if (logro && logro.startsWith('kcal_')) {
      const match = logro.match(/kcal_(\d+)_dia/);
      if (match && saludHoy && ((saludHoy.kcalQuemadas || 0) + (saludHoy.kcalQuemadasManual || 0)) >= parseInt(match[1])) cumple = true;
    }
    if (logro === 'clase_san_valentin' && esSanValentin) cumple = true;
    if (logro === 'clase_8_marzo' && es8Marzo) cumple = true;
    if (logro === 'clase_halloween' && esHalloween) cumple = true;
    if (logro === 'clase_navidad' && esNavidad) cumple = true;

    if (cumple) nuevosDesbloqueos.push({ key: prenda.key, value: prenda.value });
  }

  if (nuevosDesbloqueos.length) {
    usuario.desbloqueados = [...desbloqueados, ...nuevosDesbloqueos];
    await usuario.save();
    return nuevosDesbloqueos;
  }
  return [];
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

// Crear un nuevo usuario
exports.crearUsuario = async (req, res) => {
  const { nombre, correo, contrasena, rol, tiposDeClases } = req.body;

  try {
    // Validación de los valores enviados
    if (!Array.isArray(tiposDeClases) || tiposDeClases.length === 0) {
      return res.status(400).json({ mensaje: 'El campo tiposDeClases debe ser un array no vacío.' });
    }

    const valoresValidos = ['funcional', 'pilates', 'zumba'];
    const tiposValidos = tiposDeClases.every((tipo) => valoresValidos.includes(tipo));
    if (!tiposValidos) {
      return res.status(400).json({ mensaje: 'El campo tiposDeClases contiene valores no válidos.' });
    }
    const desbloqueadosPorDefecto = prendasLogros
      .filter(prenda => prenda.desbloqueadoPorDefecto)
      .map(prenda => ({ key: prenda.key, value: prenda.value }));
    const nuevoUsuario = new Usuario({ nombre, correo, contrasena, rol, tiposDeClases, desbloqueados: desbloqueadosPorDefecto });
    await nuevoUsuario.save();
    res.status(201).json({ mensaje: 'Usuario creado exitosamente', nuevoUsuario });
  } catch (error) {
    console.error('Error al crear el usuario:', error);
    res.status(500).json({ mensaje: 'Error al crear el usuario', error });
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
    console.log('Accediendo a obtenerUsuarios');
    const usuarios = await Usuario.find();
    res.status(200).json(usuarios);
  } catch (error) {
    console.error('Error al obtener usuarios:', error);
    res.status(500).json({ mensaje: 'Error al obtener usuarios', error });
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
  const { idUsuario } = req.params;
  const { nombre, correo, rol, tiposDeClases } = req.body;

  try {
    const usuario = await Usuario.findById(idUsuario);
    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    // Validación de los valores enviados para tiposDeClases
    if (tiposDeClases && (!Array.isArray(tiposDeClases) || tiposDeClases.length === 0)) {
      return res.status(400).json({ mensaje: 'El campo tiposDeClases debe ser un array no vacío.' });
    }

    const valoresValidos = ['funcional', 'pilates', 'zumba'];
    if (tiposDeClases && !tiposDeClases.every((tipo) => valoresValidos.includes(tipo))) {
      return res.status(400).json({ mensaje: 'El campo tiposDeClases contiene valores no válidos.' });
    }

    // Actualización de campos
    usuario.nombre = nombre || usuario.nombre;
    usuario.correo = correo || usuario.correo;
    usuario.rol = rol || usuario.rol;
    if (tiposDeClases) {
      usuario.tiposDeClases = tiposDeClases;
    }

    await usuario.save();
    res.status(200).json({ mensaje: 'Usuario actualizado exitosamente', usuario });
  } catch (error) {
    console.error('Error al actualizar el usuario:', error);
    res.status(500).json({ mensaje: 'Error al actualizar el usuario', error });
  }
};


// Eliminar un usuario
exports.eliminarUsuario = async (req, res) => {
  const { idUsuario } = req.params;

  try {
    const usuario = await Usuario.findByIdAndDelete(idUsuario);
    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }
    res.status(200).json({ mensaje: 'Usuario eliminado exitosamente' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al eliminar el usuario', error });
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


exports.obtenerCatalogoPrendas = (req, res) => {
  const prendasPath = path.join(__dirname, '../data/prendas_logros.json');
  const prendas = JSON.parse(fs.readFileSync(prendasPath));
  res.json(prendas);
};



exports.obtenerProgresoLogros = async (req, res) => {
  try {
    const usuario = await Usuario.findById(req.user.id);
    if (!usuario) return res.status(404).json({ mensaje: "Usuario no encontrado" });

    // Puedes centralizar el mapeo de emojis
    const mapeoEmojis = {
      "accesorio": "🕶️",
      "ojos": "👀",
      "ropa": "👕",
      "cabeza": "🎩",
      "color ropa": "🌈",
      "barba": "🧔",
      "grafico": "🎨",
      "piel": "🧑",
      "marco": "🟡"

    };

    // Para saber qué ha conseguido
    const desbloqueados = usuario.desbloqueados || [];
    const progreso = prendasLogros.map(prenda => {
      const conseguido = prenda.desbloqueadoPorDefecto ||
        desbloqueados.some(d => d.key === prenda.key && d.value === prenda.value);

      return {
        ...prenda,
        conseguido,
        emoji: mapeoEmojis[prenda.categoria] || "🎉"
      };
    });

    res.json(progreso);
  } catch (error) {
    res.status(500).json({ mensaje: "Error al obtener el progreso de logros", error });
  }
};

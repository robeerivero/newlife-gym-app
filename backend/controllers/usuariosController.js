const Usuario = require('../models/Usuario');
const fs = require('fs');
const path = require('path');
const Salud = require('../models/Salud');
const Reserva = require('../models/Reserva');
const Clase = require('../models/Clase');
const prendasPath = path.join(__dirname, '../data/prendas_logros.json');
const prendasLogros = JSON.parse(fs.readFileSync(prendasPath, 'utf-8'));

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

async function chequearLogrosYDesbloquear(usuarioId){
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
exports.chequearLogrosYDesbloquear = chequearLogrosYDesbloquear;

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
    if (!Array.isArray(tiposDeClases) || tiposDeClases.length === 0) {
      return res.status(400).json({ mensaje: 'El campo tiposDeClases debe ser un array no vacío.' });
    }

    const valoresValidos = ['funcional', 'pilates', 'zumba'];
    const tiposValidos = tiposDeClases.every((tipo) => valoresValidos.includes(tipo));
    if (!tiposValidos) {
      return res.status(400).json({ mensaje: 'El campo tiposDeClases contiene valores no válidos.' });
    }

    // Mapa: key → array de valores válidos
    const mapPrendas = {};
    for (const prenda of prendasLogros) {
      if (!mapPrendas[prenda.key]) mapPrendas[prenda.key] = [];
      if (!mapPrendas[prenda.key].includes(prenda.value)) {
        mapPrendas[prenda.key].push(prenda.value);
      }
    }

    // Filtrar desbloqueadas por defecto
    const desbloqueadosPorDefecto = prendasLogros
      .filter(p => p.desbloqueadoPorDefecto)
      .map(p => ({ key: p.key, value: p.value }));

    // Avatar por índice
    const avatar = {};
    for (const d of desbloqueadosPorDefecto) {
      if (!(d.key in avatar)) {
        const valores = mapPrendas[d.key];
        const idx = valores.indexOf(d.value);
        if (idx !== -1) {
          avatar[d.key] = idx; // 👈 guardar el índice
        }
      }
    }

    const nuevoUsuario = new Usuario({
      nombre,
      correo,
      contrasena,
      rol,
      tiposDeClases,
      desbloqueados: desbloqueadosPorDefecto,
      avatar // 👈 avatar como { key: int }
    });

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

// Eliminar un usuario
exports.eliminarUsuario = async (req, res) => {
  const { idUsuario } = req.params;

  try {
    const usuario = await Usuario.findById(idUsuario);
    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    const reservas = await Reserva.find({ usuario: idUsuario });

    for (const reserva of reservas) {
      const clase = await Clase.findById(reserva.clase);

      if (clase) {
        clase.cuposDisponibles += 1;

        // Procesar lista de espera
        if (clase.listaDeEspera.length > 0) {
          const siguienteUsuarioId = clase.listaDeEspera.shift();

          await Reserva.create({
            usuario: siguienteUsuarioId,
            clase: clase._id,
            fecha: clase.fecha,
          });

          clase.cuposDisponibles -= 1; // porque se reasigna el cupo
        }

        await clase.save();
      }

      await reserva.deleteOne();
    }

    await usuario.deleteOne();

    res.status(200).json({ mensaje: 'Usuario, reservas y cupos actualizados correctamente' });
  } catch (error) {
    console.error('Error al eliminar el usuario y procesar reservas:', error);
    res.status(500).json({ mensaje: 'Error interno al eliminar usuario', error });
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

exports.actualizarDatosMetabolicos = async (req, res) => {
  const { id } = req.user; // O req.params.id si es un admin
  const { peso, altura, edad, genero, nivelActividad, objetivo } = req.body;

  try {
    // 1. Calcular TMB (Tasa Metabólica Basal) - Fórmula Mifflin-St Jeor
    let tmb;
    if (genero === 'masculino') {
      tmb = (10 * peso) + (6.25 * altura) - (5 * edad) + 5;
    } else { // 'femenino'
      tmb = (10 * peso) + (6.25 * altura) - (5 * edad) - 161;
    }

    // 2. Calcular TDEE (Gasto Energético Total Diario)
    const factoresActividad = {
      sedentario: 1.2,
      ligero: 1.375,
      moderado: 1.55,
      activo: 1.725,
      muy_activo: 1.9
    };
    const tdee = tmb * (factoresActividad[nivelActividad] || 1.2);

    // 3. Ajustar Kcal según el Objetivo
    let kcalObjetivo;
    switch (objetivo) {
      case 'perder':
        kcalObjetivo = tdee - 500; // Déficit de 500 kcal
        break;
      case 'ganar':
        kcalObjetivo = tdee + 500; // Superávit de 500 kcal
        break;
      case 'mantener':
      default:
        kcalObjetivo = tdee;
    }

    // Redondear al número entero más cercano
    kcalObjetivo = Math.round(kcalObjetivo);

    // 4. Guardar los datos en el Usuario
    const usuario = await Usuario.findByIdAndUpdate(
      id,
      {
        peso,
        altura,
        edad,
        genero,
        nivelActividad,
        objetivo,
        kcalObjetivo // <-- ¡Guardamos el resultado!
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
    console.error('Error al calcular datos metabólicos:', error);
    res.status(500).json({ mensaje: 'Error en el servidor' });
  }
};

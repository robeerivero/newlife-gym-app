const Clase = require('../models/Clase');
const Usuario = require('../models/Usuario');
const Reserva = require('../models/Reserva');

exports.asignarUsuarioAClase = async (req, res) => {
  const { idClase, idUsuario } = req.body;

  try {
    const clase = await Clase.findById(idClase);
    const usuario = await Usuario.findById(idUsuario);

    if (!clase) return res.status(404).json({ mensaje: 'Clase no encontrada' });
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });

    // Verificar si ya tiene reserva para esa clase
    const reservaExistente = await Reserva.findOne({ usuario: idUsuario, clase: idClase });
    if (reservaExistente) {
      return res.status(400).json({ mensaje: 'El usuario ya tiene una reserva para esta clase' });
    }

    if (clase.cuposDisponibles <= 0) {
      return res.status(400).json({ mensaje: 'No hay cupos disponibles para esta clase' });
    }

    // Crear la reserva
    await Reserva.create({
      usuario: idUsuario,
      clase: idClase
    });

    clase.cuposDisponibles -= 1;
    await clase.save();

    res.status(201).json({ mensaje: 'Usuario asignado a la clase con éxito' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al asignar usuario a la clase', error });
  }
};


exports.desasignarUsuarioDeClase = async (req, res) => {
  const { idClase, idUsuario } = req.params;

  try {
    const clase = await Clase.findById(idClase);
    const usuario = await Usuario.findById(idUsuario);

    if (!clase) return res.status(404).json({ mensaje: 'Clase no encontrada' });
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });

    // Eliminar reserva existente
    const reserva = await Reserva.findOneAndDelete({ usuario: idUsuario, clase: idClase });
    if (!reserva) {
      return res.status(404).json({ mensaje: 'Reserva no encontrada para este usuario y clase' });
    }

    clase.cuposDisponibles += 1;
    await clase.save();

    res.status(200).json({ mensaje: 'Usuario desasignado de la clase con éxito' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al desasignar usuario de la clase', error });
  }
};

exports.obtenerClasesPorUsuario = async (req, res) => {
  const { idUsuario } = req.params;

  try {
    const reservas = await Reserva.find({ usuario: idUsuario }).populate('clase');
    const clases = reservas.map(r => r.clase);
    res.status(200).json(clases);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener clases del usuario', error });
  }
};



exports.obtenerUsuariosPorClase = async (req, res) => {
  const { idClase } = req.params;

  try {
    const reservas = await Reserva.find({ clase: idClase }).populate('usuario');
    const usuarios = reservas.map(r => r.usuario);
    res.status(200).json(usuarios);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener usuarios de la clase', error });
  }
};


exports.obtenerUsuariosConAsistencia = async (req, res) => {
  const { idClase } = req.params;
  try {
    const reservas = await Reserva.find({ clase: idClase }).populate('usuario');
    const resultado = reservas.map(r => ({
      _id: r.usuario._id,
      nombre: r.usuario.nombre,
      correo: r.usuario.correo,
      asistio: r.asistio
    }));
    res.json(resultado);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener usuarios de la clase', error });
  }
};

exports.obtenerMisReservasPorRango = async (req, res) => {
  const idUsuario = req.user._id;
  const { fechaInicio, fechaFin } = req.query; // Ej: '2025-10-01' y '2025-10-31'

  if (!fechaInicio || !fechaFin) {
    return res.status(400).json({ mensaje: 'Se requieren fechaInicio y fechaFin' });
  }

  try {
    // 1. Convertir fechas a objetos Date (asegurando que cubran todo el día)
    const inicio = new Date(fechaInicio);
    inicio.setUTCHours(0, 0, 0, 0);

    const fin = new Date(fechaFin);
    fin.setUTCHours(23, 59, 59, 999);

    // 2. Encontrar las IDs de las clases que caen en ese rango de fechas
    const clasesEnRango = await Clase.find({
      fecha: { $gte: inicio, $lte: fin }
    }).select('_id'); // Solo nos interesan sus IDs

    const idsClasesEnRango = clasesEnRango.map(c => c._id);

    // 3. Buscar las reservas del usuario que coincidan con esas IDs de clases
    const reservas = await Reserva.find({
      usuario: idUsuario,
      clase: { $in: idsClasesEnRango }
    }).populate({
      path: 'clase', // Rellenar los detalles de la clase
      select: 'nombre dia horaInicio horaFin fecha' // Seleccionar solo campos útiles
    });

    res.status(200).json(reservas);

  } catch (error) {
    console.error('Error al obtener mis reservas por rango:', error);
    res.status(500).json({ mensaje: 'Error al obtener las reservas' });
  }
};

exports.asignarUsuarioAClasesPorDiaYHora = async (req, res) => {
  const { idUsuario, dia, horaInicio } = req.body;

  try {
    const usuario = await Usuario.findById(idUsuario);
    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    const clases = await Clase.find({ dia, horaInicio });
    if (clases.length === 0) {
      return res.status(404).json({ mensaje: 'No se encontraron clases para el día y hora especificados' });
    }

    const clasesAsignadas = [];
    for (const clase of clases) {
      const reservaExistente = await Reserva.findOne({ usuario: idUsuario, clase: clase._id });
      if (!reservaExistente && clase.cuposDisponibles > 0) {
        await Reserva.create({ usuario: idUsuario, clase: clase._id });
        clase.cuposDisponibles -= 1;
        await clase.save();
        clasesAsignadas.push(clase);
      }
    }

    res.status(200).json({ mensaje: 'Usuario asignado a las clases', clases: clasesAsignadas });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al asignar usuario a las clases', error });
  }
};

exports.cancelarClase = async (req, res) => {
  const idUsuario = req.user._id;
  const { idClase } = req.body;

  try {
    const clase = await Clase.findById(idClase);
    if (!clase) return res.status(404).json({ mensaje: 'Clase no encontrada' });

    // Encuentra y elimina la reserva
    const reserva = await Reserva.findOneAndDelete({ usuario: idUsuario, clase: idClase });
    if (!reserva) {
      return res.status(404).json({ mensaje: 'No tienes reserva para esta clase' });
    }

    // --- ¡LÓGICA CORREGIDA! ---
    const ahora = new Date(); // Hora actual (UTC)
    const fechaClase = new Date(clase.fecha); // Hora de inicio de la clase (ya en UTC)

    // Calcula la diferencia en milisegundos y luego en horas
    const diferenciaMilisegundos = fechaClase - ahora;
    const diferenciaHoras = diferenciaMilisegundos / (1000 * 60 * 60);

    // Si la clase aún no ha pasado Y la cancela con 3 o más horas de antelación
    if (diferenciaHoras >= 3) {
      const usuario = await Usuario.findById(idUsuario);
      usuario.cancelaciones += 1; // Devuelve el crédito de cancelación
      await usuario.save();
    }
    // --- FIN DE LA LÓGICA CORREGIDA ---

    clase.cuposDisponibles += 1;

    // Gestiona lista de espera: si hay usuarios esperando, mete al primero
    if (clase.listaEspera && clase.listaEspera.length > 0) {
      const siguienteUsuarioId = clase.listaEspera.shift(); 
      await Reserva.create({ usuario: siguienteUsuarioId, clase: idClase });
      clase.cuposDisponibles -= 1; 
    }

    await clase.save();

    res.status(200).json({ mensaje: 'Clase cancelada con éxito' });
  } catch (error) {
    console.error('Error al cancelar la clase:', error);
    res.status(500).json({ mensaje: 'Error al cancelar la clase', error });
  }
};

exports.reservarClase = async (req, res) => {
  const { idClase } = req.body;
  const idUsuario = req.user._id;

  try {
    const usuario = await Usuario.findById(idUsuario);
    const clase = await Clase.findById(idClase);

    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    if (!clase) return res.status(404).json({ mensaje: 'Clase no encontrada' });

    // Comprueba tipos de clase y créditos de cancelaciones
    const tiposDeClases = usuario.tiposDeClases.map(t => t.toLowerCase().trim());
    if (!tiposDeClases.includes(clase.nombre.toLowerCase().trim())) {
      return res.status(403).json({ mensaje: 'No tienes permiso para reservar este tipo de clase.' });
    }
    if (usuario.cancelaciones < 1) {
      return res.status(403).json({ mensaje: 'No tienes reservas pendientes.' });
    }

    // Verifica reserva existente
    const reservaExistente = await Reserva.findOne({ usuario: idUsuario, clase: idClase });
    if (reservaExistente) {
      return res.status(400).json({ mensaje: 'Ya estás inscrito en esta clase' });
    }

    // Cupo libre
    if (clase.cuposDisponibles > 0) {
      await Reserva.create({ usuario: idUsuario, clase: idClase });
      clase.cuposDisponibles -= 1;
      usuario.cancelaciones -= 1;
      await clase.save();
      await usuario.save();
      return res.status(201).json({ mensaje: 'Clase reservada con éxito' });
    }

    // Sin cupo: añadir a lista de espera si no está ya
    if (clase.listaEspera.includes(idUsuario)) {
      return res.status(400).json({ mensaje: 'Ya estás en la lista de espera para esta clase' });
    }
    clase.listaEspera.push(idUsuario);
    await clase.save();
    return res.status(200).json({ mensaje: 'Clase sin cupos disponibles. Te has unido a la lista de espera.' });

  } catch (error) {
    res.status(500).json({ mensaje: 'Error al reservar la clase', error });
  }
};

exports.registrarAsistencia = async (req, res) => {
  const usuarioId = req.user._id;
  const { codigoQR } = req.body;

  if (!codigoQR || !codigoQR.startsWith('CLASE:')) {
    return res.status(400).json({ mensaje: 'Código QR inválido' });
  }

  const idClase = codigoQR.replace('CLASE:', '');

  try {
    const reserva = await Reserva.findOne({ usuario: usuarioId, clase: idClase });
    if (!reserva) {
      return res.status(403).json({ mensaje: 'No tienes reserva para esta clase' });
    }
    if (reserva.asistio) {
      return res.status(400).json({ mensaje: 'Ya se registró tu asistencia' });
    }

    reserva.asistio = true;
    await reserva.save();

    // Llama a chequearLogrosYDesbloquear si procede
    // const nuevosLogros = await exports.chequearLogrosYDesbloquear(usuarioId);

    res.status(200).json({ mensaje: '✅ Asistencia registrada con éxito' /*, nuevosLogros*/ });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al registrar asistencia' });
  }

};

// Obtener total de asistencias y fechas de asistencia de un usuario
  exports.obtenerAsistenciasPorUsuario = async (req, res) => {
    const idUsuario = req.user._id; // o usa req.user._id para el usuario autenticado

    try {
      const reservas = await Reserva.find({ usuario: idUsuario, asistio: true }).populate('clase');
      const totalAsistencias = reservas.length;
      // Puedes usar la fecha de la clase para la lista de fechas de asistencia:
      const fechas = reservas.map(r => {
        // Puedes usar r.clase.fecha si la clase tiene un campo fecha
        return r.clase && r.clase.fecha
          ? r.clase.fecha
          : r.fechaReserva;
      });
      res.status(200).json({ totalAsistencias, fechas });
    } catch (error) {
      res.status(500).json({ mensaje: 'Error al obtener asistencias', error });
    }
  };
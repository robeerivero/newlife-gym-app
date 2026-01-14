const Clase = require('../models/Clase');
const Usuario = require('../models/Usuario');
const Reserva = require('../models/Reserva');
// 👇 1. IMPORTAMOS EL NOTIFICADOR
const { enviarNotificacion } = require('../utils/notificador');

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

    // Opcional: Notificar al usuario asignado manualmente
    // enviarNotificacion(idUsuario, "Reserva Confirmada", `Te han asignado a la clase de ${clase.nombre}`);

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

    // --- LÓGICA DE LISTA DE ESPERA (También aquí por si el admin saca a alguien) ---
    if (clase.listaEspera && clase.listaEspera.length > 0) {
      const siguienteUsuarioId = clase.listaEspera.shift();

      // Creamos la reserva para el siguiente
      await Reserva.create({ usuario: siguienteUsuarioId, clase: idClase });

      // No sumamos cupo disponible porque entró uno nuevo inmediatamente
      clase.cuposDisponibles -= 1;

      // 👇 NOTIFICAR AL AFORTUNADO
      await enviarNotificacion(
        siguienteUsuarioId,
        "¡Plaza Conseguida! 🎉",
        `Se ha liberado un hueco en ${clase.nombre}. ¡Ya tienes tu reserva confirmada!`
      );
    }
    // -----------------------------------------------------------------------------

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

exports.obtenerMisReservasPorRango = async (req, res) => {
  const { fechaInicio, fechaFin } = req.query;
  const usuarioId = req.user._id;

  try {
    const inicio = new Date(fechaInicio);
    const fin = new Date(fechaFin);

    // 1. Buscar Reservas Confirmadas (lo que ya tenías)
    // Nota: Filtramos por la fecha de la CLASE, no de la reserva
    const reservasConfirmadas = await Reserva.find({
      usuario: usuarioId
    })
    .populate({
      path: 'clase',
      match: { fecha: { $gte: inicio, $lte: fin } } // Filtramos aquí por fecha
    });

    // Filtramos nulls (reservas de fechas fuera del rango)
    const misReservas = reservasConfirmadas.filter(r => r.clase !== null);

    // 2. Buscar Clases donde estoy en Lista de Espera
    const clasesEnEspera = await Clase.find({
      listaEspera: usuarioId,
      fecha: { $gte: inicio, $lte: fin }
    });

    // 3. Convertimos las "Clases en espera" a formato "Reserva" falso para que el Frontend las entienda
    const listaEsperaFormateada = clasesEnEspera.map(clase => ({
      _id: 'espera_' + clase._id, // ID ficticio
      usuario: usuarioId,
      clase: clase, // Objeto clase completo
      fechaReserva: new Date(),
      asistio: false,
      esListaEspera: true // <--- ¡IMPORTANTE! Campo nuevo para distinguir
    }));

    // 4. Combinar ambas listas
    const resultadoFinal = [...misReservas, ...listaEsperaFormateada];

    res.json(resultadoFinal);

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener reservas' });
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

    const ahora = new Date();
    const fechaClase = new Date(clase.fecha);

    const diferenciaMilisegundos = fechaClase - ahora;
    const diferenciaHoras = diferenciaMilisegundos / (1000 * 60 * 60);

    // Si la clase aún no ha pasado Y la cancela con 3 o más horas de antelación
    if (diferenciaHoras >= 3) {
      const usuario = await Usuario.findById(idUsuario);
      usuario.cancelaciones += 1;
      await usuario.save();
    }

    clase.cuposDisponibles += 1;

    // --- GESTIÓN DE LISTA DE ESPERA ---
    if (clase.listaEspera && clase.listaEspera.length > 0) {
      const siguienteUsuarioId = clase.listaEspera.shift();

      // Crear reserva al siguiente
      await Reserva.create({ usuario: siguienteUsuarioId, clase: idClase });

      // Restar el cupo que acabamos de liberar (porque lo ocupa el nuevo)
      clase.cuposDisponibles -= 1;

      // 👇 NOTIFICAR AL USUARIO QUE HA ENTRADO
      await enviarNotificacion(
        siguienteUsuarioId,
        "¡Estás dentro! 💪",
        `Un usuario ha cancelado y has conseguido plaza en ${clase.nombre}.`
      );
    }
    // ----------------------------------

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
    // 1. Obtener datos y validar existencia
    const usuario = await Usuario.findById(idUsuario);
    const clase = await Clase.findById(idClase);

    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    if (!clase) return res.status(404).json({ mensaje: 'Clase no encontrada' });

    // 2. Validar Permisos (Tipo de clase)
    const tiposDeClases = usuario.tiposDeClases.map(t => t.toLowerCase().trim());
    if (!tiposDeClases.includes(clase.nombre.toLowerCase().trim())) {
      return res.status(403).json({ mensaje: 'No tienes permiso para reservar este tipo de clase.' });
    }

    // 3. Validar Créditos (CRÍTICO: Se valida antes de nada)
    if (usuario.cancelaciones < 1) {
      return res.status(403).json({ mensaje: 'No tienes bonos/créditos disponibles.' });
    }

    // 4. Validar si ya está dentro (Reserva o Espera)
    const reservaExistente = await Reserva.findOne({ usuario: idUsuario, clase: idClase });
    // Convertimos ObjectId a string para comparar array
    const enListaEspera = clase.listaEspera.some(id => id.toString() === idUsuario.toString());

    if (reservaExistente) {
      return res.status(400).json({ mensaje: 'Ya tienes plaza confirmada en esta clase.' });
    }
    if (enListaEspera) {
      return res.status(400).json({ mensaje: 'Ya estás en la lista de espera.' });
    }

    // 5. LÓGICA PRINCIPAL
    let respuesta = {};

    if (clase.cuposDisponibles > 0) {
      // --- ESCENARIO A: HAY SITIO (Reserva Directa) ---
      await Reserva.create({ usuario: idUsuario, clase: idClase });
      clase.cuposDisponibles -= 1;
      
      respuesta = {
        estado: 'reservado',
        mensaje: '¡Reserva confirmada! A entrenar.'
      };
    } else {
      // --- ESCENARIO B: NO HAY SITIO (Lista de Espera) ---
      clase.listaEspera.push(idUsuario);
      
      respuesta = {
        estado: 'en_espera',
        mensaje: 'Clase llena. Te has unido a la lista de espera.'
      };
    }

    // 6. COBRO DEL CRÉDITO (Se cobra en AMBOS casos para evitar fraudes)
    usuario.cancelaciones -= 1;

    // 7. Guardar todo atómicamente (Promise.all para velocidad)
    await Promise.all([clase.save(), usuario.save()]);

    // 8. Responder al Frontend con el saldo actualizado
    return res.status(200).json({
      success: true,
      mensaje: respuesta.mensaje,
      estado: respuesta.estado,
      cancelacionesRestantes: usuario.cancelaciones // Importante devolver esto actualizado
    });

  } catch (error) {
    console.error("Error reservando:", error);
    res.status(500).json({ mensaje: 'Error interno al reservar', error });
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

    res.status(200).json({ mensaje: '✅ Asistencia registrada con éxito' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al registrar asistencia' });
  }

};

exports.obtenerAsistenciasPorUsuario = async (req, res) => {
  const idUsuario = req.user._id;

  try {
    const reservas = await Reserva.find({ usuario: idUsuario, asistio: true }).populate('clase');
    const totalAsistencias = reservas.length;

    const fechas = reservas.map(r => {
      return r.clase && r.clase.fecha
        ? r.clase.fecha
        : r.fechaReserva;
    });
    res.status(200).json({ totalAsistencias, fechas });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener asistencias', error });
  }
};
const Clase = require('../models/Clase');
const Usuario = require('../models/Usuario');
const Reserva = require('../models/Reserva');
exports.asignarUsuarioAClase = async (req, res) => {
  const { idClase, idUsuario } = req.body;

  try {
    // Buscar clase y usuario
    const clase = await Clase.findById(idClase);
    const usuario = await Usuario.findById(idUsuario);

    if (!clase) return res.status(404).json({ mensaje: 'Clase no encontrada' });
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });

    // Verificar si ya está asignado
    if (clase.participantes.includes(idUsuario)) {
      return res.status(400).json({ mensaje: 'El usuario ya está asignado a esta clase' });
    }

    // Verificar disponibilidad
    if (clase.cuposDisponibles <= 0) {
      return res.status(400).json({ mensaje: 'No hay cupos disponibles para esta clase' });
    }

    // Asignar usuario
    clase.participantes.push(idUsuario);
    clase.cuposDisponibles -= 1;

    usuario.clasesAsignadas.push(idClase);

    await clase.save();
    await usuario.save();

    res.status(201).json({ mensaje: 'Usuario asignado a la clase con éxito' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al asignar usuario a la clase', error });
  }
};

exports.desasignarUsuarioDeClase = async (req, res) => {
  const { idClase, idUsuario } = req.params;

  try {
    // Buscar clase y usuario
    const clase = await Clase.findById(idClase);
    const usuario = await Usuario.findById(idUsuario);

    if (!clase) return res.status(404).json({ mensaje: 'Clase no encontrada' });
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });

    // Remover usuario de la clase
    if (!clase.participantes.includes(idUsuario)) {
      return res.status(404).json({ mensaje: 'El usuario no está asignado a esta clase' });
    }

    clase.participantes = clase.participantes.filter(p => p.toString() !== idUsuario);
    clase.cuposDisponibles += 1;

    usuario.clasesAsignadas = usuario.clasesAsignadas.filter(c => c.toString() !== idClase);

    await clase.save();
    await usuario.save();

    res.status(200).json({ mensaje: 'Usuario desasignado de la clase con éxito' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al desasignar usuario de la clase', error });
  }
};

exports.obtenerClasesPorUsuario = async (req, res) => {
  const { idUsuario } = req.params;

  try {
    const usuario = await Usuario.findById(idUsuario).populate('clasesAsignadas');
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });

    res.status(200).json(usuario.clasesAsignadas);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener clases del usuario', error });
  }
};


exports.obtenerUsuariosPorClase = async (req, res) => {
  const { idClase } = req.params;

  try {
    const clase = await Clase.findById(idClase)
      .populate('participantes', 'nombre correo')
      .populate('asistencias', 'nombre correo');

    if (!clase) return res.status(404).json({ mensaje: 'Clase no encontrada' });

    const usuarios = clase.participantes.map((u) => {
      return {
        _id: u._id,
        nombre: u.nombre,
        correo: u.correo,
        asistio: clase.asistencias.map(a => a.toString()).includes(u._id.toString())
      };
    });

    res.status(200).json(usuarios);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener usuarios de la clase', error });
  }
};

exports.obtenerUsuariosConAsistencia = async (req, res) => {
  const { idClase } = req.params;

  try {
    const clase = await Clase.findById(idClase).populate('participantes', 'nombre correo');

    if (!clase) return res.status(404).json({ mensaje: 'Clase no encontrada' });

    const usuarios = await Usuario.find({ _id: { $in: clase.participantes } });

    const resultado = usuarios.map(usuario => ({
      _id: usuario._id,
      nombre: usuario.nombre,
      correo: usuario.correo,
      asistio: (usuario.asistencias || []).includes(idClase),
    }));

    res.json(resultado);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener usuarios de la clase' });
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
      if (!clase.participantes.includes(idUsuario) && clase.cuposDisponibles > 0) {
        clase.participantes.push(idUsuario);
        clase.cuposDisponibles -= 1;

        usuario.clasesAsignadas.push(clase._id);
        await clase.save();

        clasesAsignadas.push(clase);
      }
    }

    await usuario.save();

    res.status(200).json({ mensaje: 'Usuario asignado a las clases', clases: clasesAsignadas });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al asignar usuario a las clases', error });
  }
};


exports.cancelarClase = async (req, res) => {
  try {
    // Log inicial: Ver qué datos llegan al endpoint
    console.log('Datos recibidos en cancelarClase:', {
      userIdFromToken: req.user._id, // Del token
      requestBody: req.body, // Lo que envía el cliente
    });

    const idUsuario = req.user._id; // Usuario autenticado (del token)
    const { idClase } = req.body; // Clase proporcionada en el cuerpo

    if (!idClase) {
      console.error('ID de clase no proporcionado');
      return res.status(400).json({ mensaje: 'ID de clase es requerido' });
    }

    // Buscar usuario y clase en la base de datos
    const usuario = await Usuario.findById(idUsuario);
    const clase = await Clase.findById(idClase);

    console.log('Usuario encontrado:', usuario);
    console.log('Clase encontrada:', clase);

    if (!usuario) {
      console.error('Usuario no encontrado');
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    if (!clase) {
      console.error('Clase no encontrada');
      return res.status(404).json({ mensaje: 'Clase no encontrada' });
    }

    if (!usuario.clasesAsignadas.includes(idClase)) {
      console.error('El usuario no está asignado a esta clase');
      return res.status(400).json({ mensaje: 'El usuario no está asignado a esta clase' });
    }

    // Calcular diferencia de horas hasta la clase
    const ahora = new Date();
    const fechaClase = new Date(clase.fecha);
    const [hora, minutos] = clase.horaInicio.split(':').map(Number);
    fechaClase.setHours(hora, minutos);

    console.log('Fecha y hora de la clase:', fechaClase);
    console.log('Fecha y hora actuales:', ahora);

    const diferenciaHoras = (fechaClase - ahora) / (1000 * 60 * 60);
    console.log('Diferencia en horas hasta la clase:', diferenciaHoras);

    // Determinar si se incrementa cancelaciones
    const puedeIncrementarCancelaciones = diferenciaHoras >= 3;
    if (puedeIncrementarCancelaciones) {
      usuario.cancelaciones += 1;
    }

    // Eliminar usuario de la clase
    usuario.clasesAsignadas = usuario.clasesAsignadas.filter(c => !c.equals(idClase));
    clase.participantes = clase.participantes.filter(p => !p.equals(idUsuario));
    
    clase.cuposDisponibles += 1;

    // Gestionar lista de espera
    if (clase.listaEspera.length > 0) {
      const siguienteUsuario = clase.listaEspera.shift();
      clase.participantes.push(siguienteUsuario);
      clase.cuposDisponibles -= 1;

      const usuarioEnEspera = await Usuario.findById(siguienteUsuario);
      if (usuarioEnEspera) {
        usuarioEnEspera.clasesAsignadas.push(idClase);
        await usuarioEnEspera.save();
        console.log('Usuario de la lista de espera actualizado:', usuarioEnEspera);
      }
    }

    // Guardar cambios
    await clase.save();
    await usuario.save();


    console.log('Cancelación completada. Cambios guardados en usuario y clase.');
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
    console.log('Tipos de clases del usuario:', usuario);
    console.log('Nombre de la clase:', clase);

    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }
    if (!clase) {
      return res.status(404).json({ mensaje: 'Clase no encontrada' });
    }

    // Log de tiposDeClases y nombre de la clase
    console.log('Tipos de clases del usuario:', usuario.tiposDeClases);
    console.log('Nombre de la clase:', clase.nombre);

    // Verificar si el tipo de la clase coincide
    const tiposDeClases = usuario.tiposDeClases.map(t => t.toLowerCase().trim());
    const nombreClase = clase.nombre.toLowerCase().trim();

    if (!tiposDeClases.includes(nombreClase)) {
      return res.status(403).json({
        mensaje: 'No tienes permiso para reservar este tipo de clase.',
      });
    }

    if (usuario.cancelaciones<1) {
      return res.status(403).json({
        mensaje: 'No tienes reservas pendientes.',
      });
    }


    if (clase.participantes.includes(idUsuario)) {
      return res.status(400).json({ mensaje: 'Ya estás inscrito en esta clase' });
    }

    if (clase.cuposDisponibles <= 0) {
      if (clase.listaEspera.includes(idUsuario)) {
        return res.status(400).json({
          mensaje: 'Ya estás en la lista de espera para esta clase',
        });
      }

      clase.listaEspera.push(idUsuario);
      await clase.save();
      return res.status(200).json({
        mensaje: 'Clase sin cupos disponibles. Te has unido a la lista de espera.',
      });
    }

    clase.participantes.push(idUsuario);
    clase.cuposDisponibles -= 1;

    usuario.clasesAsignadas.push(idClase);
    usuario.cancelaciones-=1;

    await clase.save();
    await usuario.save();

    res.status(201).json({ mensaje: 'Clase reservada con éxito' });
  } catch (error) {
    console.error('Error al reservar la clase:', error);
    res.status(500).json({ mensaje: 'Error al reservar la clase', error });
  }
};

exports.registrarAsistencia = async (req, res) => {
  const usuarioId = req.user.id;
  const { codigoQR } = req.body;

  // Extraer el idClase del código QR
  if (!codigoQR || !codigoQR.startsWith('CLASE:')) {
    return res.status(400).json({ mensaje: 'Código QR inválido' });
  }

  const idClase = codigoQR.replace('CLASE:', '');

  try {
    const clase = await Clase.findById(idClase);
    if (!clase) {
      return res.status(404).json({ mensaje: 'Clase no encontrada' });
    }

    // Verificar si el usuario está en la clase
    if (!clase.participantes.includes(usuarioId)) {
      return res.status(403).json({ mensaje: 'No estás registrado en esta clase' });
    }

    // Añadir campo dinámico en clase: asistencias
    if (!clase.asistencias) clase.asistencias = [];

    // Evitar múltiples registros
    if (clase.asistencias.includes(usuarioId)) {
      return res.status(400).json({ mensaje: 'Ya se registró tu asistencia' });
    }
    usuario.asistencias = usuario.asistencias || [];
    if (!usuario.asistencias.includes(idClase)) {
      usuario.asistencias.push(idClase);
      await usuario.save();
    }

    clase.asistencias.push(usuarioId);
    await clase.save();

    res.status(200).json({ mensaje: '✅ Asistencia registrada con éxito' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al registrar asistencia' });
  }
};

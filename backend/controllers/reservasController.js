const Clase = require('../models/Clase');
const Usuario = require('../models/Usuario');
const Reserva = require('../models/Reserva');
const HistorialReserva = require('../models/HistorialReserva');
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
  const { idUsuario, dias, horas } = req.body;

  // Validaciones básicas
  if (!idUsuario || !dias || !horas || dias.length === 0 || horas.length === 0) {
    return res.status(400).json({ mensaje: 'Faltan datos (usuario, días u horas).' });
  }

  try {
    const usuario = await Usuario.findById(idUsuario);
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });

    // 1. Buscar todas las clases futuras que coincidan con los días y horas seleccionados
    const hoy = new Date();
    
    const clasesCoincidentes = await Clase.find({
      dia: { $in: dias },          // Ejemplo: coincide con ["Lunes", "Miércoles"]
      horaInicio: { $in: horas },  // Ejemplo: coincide con ["09:30", "18:00"]
      fecha: { $gte: hoy }         // Solo clases futuras
    });

    if (clasesCoincidentes.length === 0) {
      return res.status(404).json({ mensaje: 'No se encontraron clases futuras con esos criterios.' });
    }

    let reservasCreadas = 0;
    let errores = 0;

    // 2. Iterar sobre las clases encontradas y reservar
    for (const clase of clasesCoincidentes) {
      // Verificar si ya tiene reserva
      const existe = await Reserva.findOne({ usuario: idUsuario, clase: clase._id });
      
      if (!existe) {
        // Verificar cupos (Opcional: Si eres admin, quizás quieras forzar la reserva aunque esté llena. 
        // Aquí asumiremos que respetamos los cupos por seguridad).
        if (clase.cuposDisponibles > 0) {
          await Reserva.create({
            usuario: idUsuario,
            clase: clase._id,
            asistio: false
          });

          // Actualizar cupos
          clase.cuposDisponibles -= 1;
          await clase.save();
          reservasCreadas++;
        } else {
          // Opcional: Añadir a lista de espera automáticamente si quieres
          errores++; 
        }
      }
    }

    res.json({
      success: true,
      mensaje: `Proceso finalizado. Se inscribió al usuario en ${reservasCreadas} clases. (Omitidas/Llenas: ${clasesCoincidentes.length - reservasCreadas})`
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error interno al realizar la asignación masiva', error });
  }
};

exports.cancelarClase = async (req, res) => {
  const { idClase } = req.body; 
  const idUsuario = req.user._id;

  try {
    const usuario = await Usuario.findById(idUsuario);
    const clase = await Clase.findById(idClase);

    if (!usuario || !clase) {
      return res.status(404).json({ mensaje: 'Usuario o Clase no encontrados' });
    }

    // --- CÁLCULO DE HORAS RESTANTES ---
    const fechaClase = new Date(clase.fecha);
    const [horas, minutos] = clase.horaInicio.split(':');
    fechaClase.setHours(horas, minutos, 0, 0);

    const ahora = new Date();
    const diferenciaMs = fechaClase - ahora;
    const horasRestantes = diferenciaMs / (1000 * 60 * 60);

    let accionRealizada = false;
    let mensaje = '';
    let penalizado = false;
    let tipoHistorial = ''; // Variable para guardar qué pasó en el historial

    // --- INTENTO A: BORRAR RESERVA CONFIRMADA ---
    const reservaBorrada = await Reserva.findOneAndDelete({ usuario: idUsuario, clase: idClase });

    if (reservaBorrada) {
      accionRealizada = true;
      clase.cuposDisponibles += 1;

      // LÓGICA DE PENALIZACIÓN (3 HORAS)
      if (horasRestantes >= 3) {
        // ✅ DEVOLUCIÓN: Creamos cupo con caducidad (14 días)
        const fechaVencimiento = new Date();
        fechaVencimiento.setDate(fechaVencimiento.getDate() + 14); 

        usuario.cuposCompensatorios.push({ 
          fechaExpiracion: fechaVencimiento 
        });
        
        mensaje = 'Reserva cancelada. Crédito devuelto (Válido por 2 semanas).';
        tipoHistorial = 'CANCELACION_DEVOLUCION';
      } else {
        // ❌ PENALIZACIÓN
        penalizado = true;
        mensaje = 'Cancelación con menos de 3h. Crédito NO devuelto.';
        tipoHistorial = 'CANCELACION_PENALIZACION';
      }
    } 
    else {
      // --- INTENTO B: SACAR DE LISTA DE ESPERA ---
      const indexEnEspera = clase.listaEspera.findIndex(id => id.toString() === idUsuario.toString());

      if (indexEnEspera > -1) {
        clase.listaEspera.splice(indexEnEspera, 1);
        accionRealizada = true;
        
        // Al salir de lista de espera, devolvemos el crédito también con caducidad
        const fechaVencimiento = new Date();
        fechaVencimiento.setDate(fechaVencimiento.getDate() + 14);

        usuario.cuposCompensatorios.push({ 
          fechaExpiracion: fechaVencimiento 
        });

        mensaje = 'Has salido de la lista de espera. Crédito devuelto.';
        tipoHistorial = 'CANCELACION_DEVOLUCION'; // O podrías crear uno llamado 'SALIDA_LISTA_ESPERA'
      }
    }

    if (!accionRealizada) {
      return res.status(404).json({ mensaje: 'No tienes reserva ni estás en lista de espera.' });
    }

    // --- 📝 GUARDAR EN HISTORIAL ---
    // Solo guardamos si realmente se hizo algo
    if (accionRealizada) {
      await HistorialReserva.create({
        usuario: idUsuario,
        nombreUsuario: usuario.nombre,
        clase: idClase,
        infoClase: `${clase.nombre} - ${clase.dia} ${clase.horaInicio} (${clase.fecha.toISOString().split('T')[0]})`,
        tipoAccion: tipoHistorial || 'CANCELACION' // Fallback por si acaso
      });
    }

    // Guardamos cambios en Usuario y Clase
    await Promise.all([clase.save(), usuario.save()]);

    // 🔄 TRUCO PARA EL FRONTEND:
    // Filtramos los vencidos visualmente para devolver el número real actual
    const cuposReales = usuario.cuposCompensatorios.filter(c => new Date(c.fechaExpiracion) > new Date()).length;

    return res.status(200).json({
      success: true,
      mensaje: mensaje,
      cancelacionesRestantes: cuposReales, // Enviamos el número que espera Flutter
      penalizado: penalizado
    });

  } catch (error) {
    console.error("Error cancelando:", error);
    res.status(500).json({ mensaje: 'Error al cancelar la clase' });
  }
};

exports.reservarClase = async (req, res) => {
  const { idClase } = req.body;
  const idUsuario = req.user._id;

  try {
    // 1. Obtener datos
    const usuario = await Usuario.findById(idUsuario);
    const clase = await Clase.findById(idClase);

    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    if (!clase) return res.status(404).json({ mensaje: 'Clase no encontrada' });

    // 2. VALIDAR ANTELACIÓN MÁXIMA (2 SEMANAS)
    const ahora = new Date();
    const fechaLimite = new Date();
    fechaLimite.setDate(ahora.getDate() + 14); // Hoy + 14 días

    if (new Date(clase.fecha) > fechaLimite) {
        return res.status(400).json({ 
            mensaje: 'Solo puedes reservar clases con un máximo de 2 semanas de antelación.' 
        });
    }

    // 3. Validar Permisos (Tipo de clase)
    const tiposDeClases = usuario.tiposDeClases.map(t => t.toLowerCase().trim());
    if (!tiposDeClases.includes(clase.nombre.toLowerCase().trim())) {
      return res.status(403).json({ mensaje: 'No tienes permiso para reservar este tipo de clase.' });
    }

    // 4. GESTIÓN DE CRÉDITOS Y CADUCIDAD
    // a) Limpiamos los cupos que ya han caducado de la base de datos
    const cuposValidos = usuario.cuposCompensatorios.filter(c => new Date(c.fechaExpiracion) > ahora);
    
    // Si la longitud cambió, es que borramos viejos. Actualizamos el array del usuario.
    if (cuposValidos.length !== usuario.cuposCompensatorios.length) {
        usuario.cuposCompensatorios = cuposValidos;
    }

    // b) Verificar si tiene cupos válidos
    if (cuposValidos.length < 1) {
      return res.status(403).json({ mensaje: 'No tienes bonos/créditos disponibles o han caducado.' });
    }

    // 5. Validar si ya está dentro
    const reservaExistente = await Reserva.findOne({ usuario: idUsuario, clase: idClase });
    const enListaEspera = clase.listaEspera.some(id => id.toString() === idUsuario.toString());

    if (reservaExistente) return res.status(400).json({ mensaje: 'Ya tienes plaza confirmada.' });
    if (enListaEspera) return res.status(400).json({ mensaje: 'Ya estás en la lista de espera.' });

    // 6. LÓGICA PRINCIPAL (Reservar o Espera)
    let respuesta = {};
    let tipoAccionHistorial = '';

    if (clase.cuposDisponibles > 0) {
      // --- ESCENARIO A: RESERVA DIRECTA ---
      await Reserva.create({ usuario: idUsuario, clase: idClase });
      clase.cuposDisponibles -= 1;
      
      respuesta = { estado: 'reservado', mensaje: '¡Reserva confirmada! A entrenar.' };
      tipoAccionHistorial = 'RESERVA_CON_CUPO'; // Porque gastó cupo y entró
    } else {
      // --- ESCENARIO B: LISTA DE ESPERA ---
      clase.listaEspera.push(idUsuario);
      
      respuesta = { estado: 'en_espera', mensaje: 'Clase llena. Unido a lista de espera.' };
      tipoAccionHistorial = 'LISTA_ESPERA';
    }

    // 7. COBRO DEL CRÉDITO
    // Eliminamos el cupo más antiguo
    usuario.cuposCompensatorios.shift(); 

    // --- 📝 GUARDAR EN HISTORIAL ---
    await HistorialReserva.create({
      usuario: idUsuario,
      nombreUsuario: usuario.nombre,
      clase: idClase,
      infoClase: `${clase.nombre} - ${clase.dia} ${clase.horaInicio} (${clase.fecha.toISOString().split('T')[0]})`,
      tipoAccion: tipoAccionHistorial
    });

    // 8. Guardar todo
    await Promise.all([clase.save(), usuario.save()]);

    // 9. Responder al Frontend
    return res.status(200).json({
      success: true,
      mensaje: respuesta.mensaje,
      estado: respuesta.estado,
      cancelacionesRestantes: usuario.cuposCompensatorios.length 
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

    // 🛑 CASO: USUARIO NO TIENE RESERVA
    if (!reserva) {
      
      // 1. Buscamos info de la clase solo para el log (aunque no tenga reserva)
      const claseInfo = await Clase.findById(idClase);
      const nombreClase = claseInfo ? `${claseInfo.nombre} ${claseInfo.horaInicio}` : 'Clase Desconocida';

      // 2. Registrar el intento fallido en BD
      await HistorialReserva.create({
        usuario: usuarioId,
        nombreUsuario: req.user.nombre, // req.user viene del middleware proteger
        clase: idClase,
        infoClase: nombreClase,
        tipoAccion: 'INTENTO_FALLIDO_QR'
      });

      // 3. Enviar Notificación de Alerta al Usuario (o al admin si prefieres)
      await enviarNotificacion(
        usuarioId, 
        "⛔ Acceso Denegado", 
        `Has intentado acceder a ${nombreClase} sin tener reserva confirmada.`
      );

      return res.status(403).json({ mensaje: '⛔ No tienes reserva para esta clase. Se ha registrado el incidente.' });
    }

    if (reserva.asistio) {
      return res.status(400).json({ mensaje: 'Ya se registró tu asistencia' });
    }

    // ✅ CASO ÉXITO
    reserva.asistio = true;
    await reserva.save();
    
    // Opcional: Registrar también la asistencia exitosa en el historial
    await HistorialReserva.create({
        usuario: usuarioId,
        nombreUsuario: req.user.nombre,
        clase: idClase,
        infoClase: 'Asistencia confirmada por QR',
        tipoAccion: 'ASISTENCIA'
    });

    res.status(200).json({ mensaje: '✅ Asistencia registrada con éxito' });

  } catch (error) {
    console.error(error);
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
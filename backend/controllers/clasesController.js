// backend/controllers/class.js
const Clase = require('../models/Clase');
const Reserva = require('../models/Reserva');

// Utilidad para obtener fechas recurrentes
const obtenerFechasPorDia = (diaSemana, anio, horaInicio) => {
  const diasMap = {
    'Lunes': 1,
    'Martes': 2,
    'Miércoles': 3,
    'Jueves': 4,
    'Viernes': 5,
  };

  const diaObjetivo = diasMap[diaSemana];
  const fechas = [];
  let fecha = new Date(anio, 0, 1);

  // Avanzar al primer día que coincida
  while (fecha.getDay() !== diaObjetivo) {
    fecha.setDate(fecha.getDate() + 1);
  }

  while (fecha.getFullYear() === anio) {
    const [horas, minutos] = horaInicio.split(':').map(Number); // Convertir horaInicio a horas y minutos
    const fechaConHora = new Date(fecha);
    fechaConHora.setHours(horas, minutos, 0, 0); // Ajustar la hora
    const offset = fechaConHora.getTimezoneOffset(); // Offset en minutos
    fechaConHora.setMinutes(fechaConHora.getMinutes() - offset);
    fechas.push(fechaConHora);
    fecha.setDate(fecha.getDate() + 7);
  }

  return fechas;
};

// Crear clases recurrentes (todas las semanas en un año para un día específico)
exports.crearClasesRecurrentes = async (req, res) => {
  const { nombre, dia, horaInicio, horaFin, maximoParticipantes } = req.body;
  console.log("Datos recibidos:", req.body); // Verificar qué llega desde el cliente

  try {
    const anioActual = new Date().getFullYear();
    console.log("Año actual:", anioActual);

    const fechas = obtenerFechasPorDia(dia, anioActual, horaInicio);
    console.log("Fechas generadas para el día:", dia, fechas);

    const clasesCreadas = [];
    for (const fecha of fechas) {
      console.log("Creando clase para la fecha:", fecha);

      const nuevaClase = new Clase({
        nombre,
        dia,
        horaInicio,
        horaFin,
        maximoParticipantes: maximoParticipantes || 14,
        cuposDisponibles: maximoParticipantes || 14,
        fecha,
      });

      try {
        const claseGuardada = await nuevaClase.save();
        console.log("Clase guardada:", claseGuardada);
        clasesCreadas.push(claseGuardada);
      } catch (error) {
        console.error("Error al guardar la clase:", error.message, error);
        throw error;
      }
    }

    res.status(201).json({
      mensaje: "Clases recurrentes creadas con éxito",
      clases: clasesCreadas,
    });
  } catch (error) {
    console.error("Error al crear clases recurrentes:", error.message, error);
    res.status(500).json({ mensaje: "Error al crear las clases recurrentes", error });
  }
};


// Obtener todas las clases (opcionalmente por fecha)
exports.obtenerClases = async (req, res) => {
  let filtro = {}; 
  const { fecha } = req.query;

  if (fecha) {
    const diaSolicitado = new Date(fecha);
    
    // Calcular inicio (00:00) y fin (23:59) del día solicitado
    const diaInicio = new Date(diaSolicitado);
    diaInicio.setUTCHours(0, 0, 0, 0);
    
    const diaFin = new Date(diaInicio);
    diaFin.setUTCDate(diaFin.getUTCDate() + 1);

    // --- LÓGICA DE TIEMPO REAL ---
    const ahora = new Date();
    
    // Variable para el límite inferior del filtro
    let limiteInferior = diaInicio;

    // Verificamos si el día solicitado es "Hoy"
    // Comprobamos si 'ahora' cae dentro del rango de ese día
    if (ahora > diaInicio && ahora < diaFin) {
       // Si es hoy, queremos clases cuya fecha (que incluye hora) sea MAYOR a ahora
       limiteInferior = ahora;
    }
    
    // Si pedimos un día pasado, limiteInferior será diaInicio, pero como ya pasó, 
    // podrías querer bloquearlo. Pero para 'reservar', lo crítico es el filtro de 'Hoy'.

    filtro.fecha = { $gte: limiteInferior, $lt: diaFin };
  } else {
    // Si no hay fecha específica, opcionalmente filtra solo futuras para no traer historial eterno
    filtro.fecha = { $gte: new Date() }; 
  }

  try {
    // Agregamos filtro de cupos disponibles > 0 por seguridad si quieres
    const clases = await Clase.find(filtro).sort({ fecha: 1 });
    res.json(clases);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener las clases', error });
  }
};

// Obtener una clase por ID
exports.obtenerClasePorId = async (req, res) => {
  const { idClase } = req.params;

  try {
    const clase = await Clase.findById(idClase);
    if (!clase) {
      return res.status(404).json({ mensaje: 'Clase no encontrada' });
    }
    res.status(200).json(clase);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener la clase', error });
  }
};

// Modificar una clase existente
exports.modificarClase = async (req, res) => {
  const { idClase } = req.params;
  const { nombre, dia, horaInicio, horaFin, maximoParticipantes } = req.body;

  try {
    const clase = await Clase.findById(idClase);
    if (!clase) {
      return res.status(404).json({ mensaje: 'Clase no encontrada' });
    }

    // Actualizar los campos
    clase.nombre = nombre !== undefined ? nombre : clase.nombre;
    clase.dia = dia !== undefined ? dia : clase.dia;
    clase.horaInicio = horaInicio !== undefined ? horaInicio : clase.horaInicio;
    clase.horaFin = horaFin !== undefined ? horaFin : clase.horaFin;
    clase.maximoParticipantes = maximoParticipantes !== undefined ? maximoParticipantes : clase.maximoParticipantes;

    await clase.save();
    res.status(200).json({ mensaje: 'Clase modificada con éxito', clase });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al modificar la clase', error });
  }
};

// Eliminar una clase
exports.eliminarClase = async (req, res) => {
  const { idClase } = req.params;

  try {
    // Eliminar todas las reservas asociadas a esta clase
    const result = await Reserva.deleteMany({ clase: idClase });
    console.log(`🗑️ Reservas eliminadas asociadas a la clase ${idClase}:`, result.deletedCount);

    // Luego eliminar la clase
    const clase = await Clase.findByIdAndDelete(idClase);
    if (!clase) {
      return res.status(404).json({ mensaje: 'Clase no encontrada' });
    }

    res.status(200).json({ mensaje: 'Clase y reservas eliminadas con éxito' });
  } catch (error) {
    console.error('❌ Error al eliminar la clase y sus reservas:', error);
    res.status(500).json({ mensaje: 'Error al eliminar la clase', error });
  }
};


// Eliminar todas las clases
exports.eliminarTodasLasClases = async (req, res) => {
  try {
    const resultClases = await Clase.deleteMany({});
    const resultReservas = await Reserva.deleteMany({});

    console.log(`🧹 Clases eliminadas: ${resultClases.deletedCount}`);
    console.log(`🧹 Reservas eliminadas: ${resultReservas.deletedCount}`);

    res.status(200).json({ mensaje: 'Todas las clases y reservas han sido eliminadas con éxito' });
  } catch (error) {
    console.error('❌ Error al eliminar todas las clases y reservas:', error);
    res.status(500).json({ mensaje: 'Error al eliminar todas las clases', error });
  }
};


// Obtener las próximas tres clases del usuario
exports.obtenerProximasClases = async (req, res) => {
  try {
    const userId = req.user._id;
    const now = new Date();

    // 1. Buscar las reservas del usuario para clases en el futuro
    const reservas = await Reserva.find({
      usuario: userId,
    }).populate('clase');
    console.log('Reservas del usuario:', reservas);
    // 2. Filtrar solo las clases que sean futuras
    const proximasClases = reservas
      .filter(r => r.clase && new Date(r.clase.fecha) >= now)
      .sort((a, b) => new Date(a.clase.fecha) - new Date(b.clase.fecha))
      .slice(0, 3) // solo las 3 próximas
      .map(r => r.clase);

    if (!proximasClases || proximasClases.length === 0) {
      return res.status(404).json({ mensaje: 'No tienes clases próximas' });
    }

    res.status(200).json(proximasClases);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener las próximas clases', error });
  }
};



// Desregistrarse de una clase
exports.desregistrarseDeClase = async (req, res) => {
  const { idClase } = req.params;
  const userId = req.user._id;

  try {
    const clase = await Clase.findById(idClase);

    if (!clase || !clase.participantes.includes(userId)) {
      return res.status(404).json({ mensaje: 'Clase no encontrada o no estás registrado' });
    }

    clase.participantes = clase.participantes.filter((id) => id.toString() !== userId.toString());
    clase.cuposDisponibles += 1;
    await clase.save();

    res.status(200).json({ mensaje: 'Te has desregistrado de la clase con éxito' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al desregistrarse de la clase', error });
  }
};


exports.obtenerUsuariosConAsistencia = async (req, res) => {
  const { idClase } = req.params;
  console.log('🔍 [BACKEND] Llamada a obtenerUsuariosConAsistencia con ID:', idClase);

  try {
    const reservas = await Reserva.find({ clase: idClase }).populate('usuario');

    console.log('✅ [BACKEND] Reservas encontradas:', reservas.length);

    reservas.forEach((r, i) => {
      console.log(`  - Usuario[${i}]:`, r.usuario?.nombre || 'null', '| Asistió:', r.asistio);
    });

    const resultado = reservas.map(r => ({
      _id: r.usuario._id,
      nombre: r.usuario.nombre,
      correo: r.usuario.correo,
      asistio: r.asistio
    }));

    res.json(resultado);
  } catch (error) {
    console.error('❌ [BACKEND] Error en obtenerUsuariosConAsistencia:', error);
    res.status(500).json({ mensaje: 'Error al obtener usuarios de la clase', error });
  }
};


const QRCode = require('qrcode');

exports.generarQR = async (req, res) => {
  const { idClase } = req.params;

  try {
    const payload = {
      idClase,
      exp: Math.floor(Date.now() / 1000) + 60 * 10 // 10 minutos de validez
    };

    const qrData = JSON.stringify(payload); // o firmarlo como JWT

    const qrImage = await QRCode.toDataURL(qrData);
    res.json({ qrImage }); // Lo devuelves como base64
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al generar QR' });
  }
};


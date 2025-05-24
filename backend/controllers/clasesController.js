// backend/controllers/class.js
const Clase = require('../models/Clase');

// Utilidad para obtener fechas recurrentes
const obtenerFechasPorDia = (diaSemana, anio,  horaInicio) => {
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

    const fechas = obtenerFechasPorDia(dia, anioActual,horaInicio);
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
        participantes: [],
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
  const { fecha } = req.query;
  const tiposDeClases = req.user?.tiposDeClases; // Verifica que req.user exista y tenga tiposClases
  const userId = req.user?._id;
  try {
    console.log('Tipos de clases del usuario:', tiposDeClases); // Log para depuración

    if (!tiposDeClases || !Array.isArray(tiposDeClases) || tiposDeClases.length === 0) {
      return res.status(400).json({
        mensaje: 'El usuario no tiene tipos de clases definidos o válidos.',
      });
    }

    let clases;
    if (fecha) {
      const fechaSeleccionada = new Date(fecha);
      fechaSeleccionada.setUTCHours(0, 0, 0, 0);

      clases = await Clase.find({
        fecha: {
          $gte: fechaSeleccionada,
          $lt: new Date(fechaSeleccionada.getTime() + 24 * 60 * 60 * 1000),
        },
        nombre: { $in: tiposDeClases }, // Filtrar por tipos de clase
        participantes: { $ne: userId },
      }).populate('participantes', 'nombre correo');
    } else {
      clases = await Clase.find({
        nombre: { $in: tiposDeClases }, // Filtrar por tipos de clase
        participantes: { $ne: userId },
      }).populate('participantes', 'nombre correo');
    }

    res.status(200).json(clases);
  } catch (error) {
    console.error('Error al obtener las clases:', error);
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
    const clase = await Clase.findByIdAndDelete(idClase);
    if (!clase) {
      return res.status(404).json({ mensaje: 'Clase no encontrada' });
    }
    res.status(200).json({ mensaje: 'Clase eliminada con éxito' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al eliminar la clase', error });
  }
};

// Eliminar todas las clases
exports.eliminarTodasLasClases = async (req, res) => {
  try {
    await Clase.deleteMany({});
    res.status(200).json({ mensaje: 'Todas las clases han sido eliminadas con éxito' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al eliminar todas las clases', error });
  }
};

// Obtener las próximas tres clases del usuario
exports.obtenerProximasClases = async (req, res) => {
  try {
    const userId = req.user._id;
    const now = new Date();

    const proximasClases = await Clase.find({
      participantes: userId,
      fecha: { $gte: now },
    })
      .sort({ fecha: 1 })
      .limit(3);

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

// Obtener clases por fecha y tipo de clase
exports.obtenerClasesPorFechaYTipo = async (req, res) => {
  try {
    const { fecha } = req.query;
    const tiposDeClases = req.user.tiposDeClases; // Supone que se incluye esta información en el token

    // Validar si se proporciona la fecha
    if (!fecha) {
      return res.status(400).json({ mensaje: 'Fecha es requerida.' });
    }

    // Convertir la fecha a un rango para filtrar por día completo
    const fechaSeleccionada = new Date(fecha);
    fechaSeleccionada.setUTCHours(0, 0, 0, 0);
    const siguienteDia = new Date(fechaSeleccionada.getTime() + 24 * 60 * 60 * 1000);

    // Filtrar clases por fecha y tipos de clase
    const clases = await Clase.find({
      fecha: {
        $gte: fechaSeleccionada,
        $lt: siguienteDia,
      },
      nombre: { $in: tiposDeClases }, // Solo clases cuyo nombre coincide con los tipos del usuario
    }).populate('participantes', 'nombre correo');

    res.status(200).json(clases);
  } catch (error) {
    console.error('Error al obtener las clases:', error);
    res.status(500).json({ mensaje: 'Error al obtener las clases', error });
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


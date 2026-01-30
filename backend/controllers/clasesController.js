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
  // Ahora esperamos listas de días y horas
  const { nombre, dias, horas, maximoParticipantes } = req.body;

  // Validaciones
  if (!nombre || !dias || !horas || !Array.isArray(dias) || !Array.isArray(horas)) {
    return res.status(400).json({ mensaje: 'Datos inválidos. Se requiere nombre, array de días y array de horas.' });
  }

  try {
    let totalCreadas = 0;
    const maxPart = maximoParticipantes || 14;

    // 1. Recorremos cada día seleccionado (Ej: Lunes, Miércoles)
    for (const diaNombre of dias) {
      
      // 2. Recorremos cada hora seleccionada (Ej: 09:30, 18:00)
      for (const horaInicio of horas) {
        
        // Calculamos la hora de fin (Asumimos 1 hora de duración)
        // Si necesitas duración variable, deberías pedirla en el front o calcularla aquí
        const [h, m] = horaInicio.split(':').map(Number);
        const fechaFinTemp = new Date();
        fechaFinTemp.setHours(h + 1, m);
        const horaFin = `${fechaFinTemp.getHours().toString().padLeft(2, '0')}:${fechaFinTemp.getMinutes().toString().padLeft(2, '0')}`;

        // 3. Generamos las fechas del calendario para este bloque
        const fechasParaCrear = obtenerFechasDelAnio(diaNombre, horaInicio);

        // 4. Guardamos en la BD una por una
        for (const fechaExacta of fechasParaCrear) {
          
          // Verificamos duplicados para no crear la misma clase dos veces
          const existe = await Clase.findOne({
            nombre: nombre,
            fecha: fechaExacta,
            horaInicio: horaInicio
          });

          if (!existe) {
            await Clase.create({
              nombre,
              dia: diaNombre,
              horaInicio,
              horaFin,
              fecha: fechaExacta,
              cuposDisponibles: maxPart,
              maximoParticipantes: maxPart,
              listaEspera: []
            });
            totalCreadas++;
          }
        }
      }
    }

    res.status(201).json({
      success: true,
      mensaje: `Proceso completado. Se han generado ${totalCreadas} clases nuevas para este año.`
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al crear las clases recurrentes', error });
  }
};


// Obtener todas las clases (opcionalmente por fecha)
// backend/controllers/clasesController.js

exports.obtenerClases = async (req, res) => {
  let filtro = {}; 
  const { fecha } = req.query;
  
  // 1. Obtenemos el rol del usuario (req.user viene del middleware 'proteger')
  const esAdmin = req.user.rol === 'admin'; 

  if (fecha) {
    const diaSolicitado = new Date(fecha);
    
    // Inicio del día (00:00)
    const diaInicio = new Date(diaSolicitado);
    diaInicio.setUTCHours(0, 0, 0, 0);
    
    // Fin del día (23:59)
    const diaFin = new Date(diaInicio);
    diaFin.setUTCDate(diaFin.getUTCDate() + 1);

    const ahora = new Date();
    
    // POR DEFECTO: El límite inferior es el inicio del día (para Admins o días futuros)
    let limiteInferior = diaInicio;

    // LÓGICA:
    // Solo si es HOY ... Y ... NO es administrador, filtramos por hora actual.
    // Si es admin, se queda con 'diaInicio' (ve todo el día).
    if (ahora > diaInicio && ahora < diaFin && !esAdmin) {
       limiteInferior = ahora;
    }
    
    filtro.fecha = { $gte: limiteInferior, $lt: diaFin };
  } else {
    // Si no hay fecha, el admin ve todo, el usuario solo futuro
    if (!esAdmin) {
        filtro.fecha = { $gte: new Date() }; 
    }
  }

  try {
    // Quitamos filtro de cupos para admin si quieres que vean clases llenas también
    // const clases = await Clase.find(filtro).sort({ fecha: 1 });
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
    // Buscamos reservas y poblamos los datos del usuario
    const reservas = await Reserva.find({ clase: idClase }).populate('usuario');

    console.log('✅ [BACKEND] Reservas encontradas:', reservas.length);

    reservas.forEach((r, i) => {
      console.log(`  - Usuario[${i}]:`, r.usuario?.nombre || 'null', '| Asistió:', r.asistio);
    });

    // Mapeamos el resultado incluyendo 'haPagado'
    const resultado = reservas.map(r => ({
      _id: r.usuario._id,
      nombre: r.usuario.nombre,
      correo: r.usuario.correo,
      asistio: r.asistio,
      haPagado: r.usuario.haPagado // 👈 CAMBIO AQUÍ: Enviamos el estado de pago
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


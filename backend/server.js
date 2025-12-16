const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const cron = require('node-cron');

// Configuración de variables de entorno (¡MOVIDO ARRIBA!)
// Esto debe ir antes de importar archivos que usen process.env
dotenv.config();

const connectDB = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const usuariosRoutes = require('./routes/usuariosRoutes');
const clasesRoutes = require('./routes/clasesRoutes');
const reservasRoutes = require('./routes/reservasRoutes');
const iaEntrenamientoRoutes = require('./routes/iaEntrenamientoRoutes');
const iaDietaRoutes = require('./routes/iaDietaRoutes');
const saludRouter = require('./routes/saludRoutes');
const videoRoutes = require('./routes/videoRoutes');

const Salud = require('./models/Salud');
const Clase = require('./models/Clase');
const Reserva = require('./models/Reserva');
const Usuario = require('./models/Usuario');

// --- 🔔 Importar el notificador ---
const { enviarNotificacion, enviarNotificacionMasiva } = require('./utils/notificador');

// Conexión a MongoDB
connectDB();

const app = express();

// ==========================================
// 🧪 ZONA DE PRUEBAS DE NOTIFICACIONES (BORRAR AL TERMINAR)
// ==========================================
// Se ejecuta en minutos impares: 1, 3, 5, 7, 9...
cron.schedule('1-59/2 * * * *', () => {
  console.log(`--- 🧪 Enviando notificación de PRUEBA (Minuto: ${new Date().getMinutes()}) ---`);

  const mensajesPrueba = [
    "Test de sistema: Funciona correctamente 🚀",
    "¡Hola! Probando notificaciones cada 2 min 🔔",
    "Sigue programando, vas genial 💻"
  ];
  const mensajeRandom = mensajesPrueba[Math.floor(Math.random() * mensajesPrueba.length)];

  // Enviamos a TODOS los usuarios que tengan token
  enviarNotificacionMasiva("🔔 Prueba Técnica", mensajeRandom);
});
// ==========================================

// ==========================================
// 🔔 1. NOTIFICACIÓN MOTIVADORA (Cada mañana a las 08:00)
// ==========================================
const frasesMotivadoras = require('./utils/frasesMotivadoras');
cron.schedule('0 8 * * *', () => { // Se ejecuta a las 08:00 AM
  console.log('--- ☀️ Enviando motivación matutina ---');
  // Verificamos que frasesMotivadoras tenga contenido para evitar error
  if (frasesMotivadoras && frasesMotivadoras.length > 0) {
    const fraseAleatoria = frasesMotivadoras[Math.floor(Math.random() * frasesMotivadoras.length)];
    enviarNotificacionMasiva("Buenos días, ", fraseAleatoria);
  }
});

// ==========================================
// 🔔 2. RECORDATORIO 1 HORA ANTES (Se revisa cada 10 mins)
// ==========================================
cron.schedule('*/10 * * * *', async () => {
  try {
    const ahora = new Date();
    // Ventana: Clases que empiezan entre 50 y 70 minutos desde ahora.
    const ventanaInicio = new Date(ahora.getTime() + 50 * 60000);
    const ventanaFin = new Date(ahora.getTime() + 70 * 60000);

    const reservas = await Reserva.find({
      recordatorioEnviado: false
    }).populate('clase').populate('usuario');

    for (const reserva of reservas) {
      if (!reserva.clase || !reserva.usuario) continue;

      const clase = reserva.clase;
      const fechaClase = new Date(clase.fecha);
      const [horas, minutos] = clase.horaInicio.split(':').map(Number);
      fechaClase.setHours(horas, minutos, 0, 0);

      if (fechaClase >= ventanaInicio && fechaClase <= ventanaFin) {
        console.log(`🔔 Enviando recordatorio a ${reserva.usuario.nombre} para clase de ${clase.nombre}`);

        await enviarNotificacion(
          reserva.usuario._id,
          "¡Tu clase empieza en 1 hora! ⏳",
          `Prepárate para ${clase.nombre} a las ${clase.horaInicio}. ¡No faltes!`,
          { tipo: 'recordatorio', idClase: clase._id.toString() }
        );

        reserva.recordatorioEnviado = true;
        await reserva.save();
      }
    }
  } catch (error) {
    console.error('❌ Error en cron recordatorios:', error);
  }
});

// ==========================================
// 🔔 3. RECORDATORIO SALUD NOCTURNO (Cada noche a las 22:00)
// ==========================================
cron.schedule('0 22 * * *', () => {
  console.log('--- 🌙 Enviando recordatorio nocturno de salud ---');

  const mensajesNoche = [
    "¿Registraste tus pasos hoy? No rompas tu racha 🔥",
    "Antes de dormir, revisa tu progreso del día 📉",
    "¡Buenas noches! No olvides actualizar tu salud 🌙",
    "¿Cumpliste tu objetivo de calorías hoy? 🍎",
    "Un día más fuerte. Registra tu actividad antes de descansar 💪"
  ];

  const mensajeAleatorio = mensajesNoche[Math.floor(Math.random() * mensajesNoche.length)];
  enviarNotificacionMasiva("Resumen Diario", mensajeAleatorio);
});


// --- TAREA COMBINADA: Limpieza de Salud Y Reseteo de Pagos ---
cron.schedule('0 0 1 * *', async () => {
  console.log('--- 🧹 INICIANDO TAREAS MENSUALES (00:00) ---');

  try {
    const ahora = new Date();
    const inicioDeEsteMes = new Date(ahora.getFullYear(), ahora.getMonth(), 1);
    inicioDeEsteMes.setHours(0, 0, 0, 0);

    // 1. Borrar datos de Salud antiguos
    const resultadoSalud = await Salud.deleteMany({
      fecha: { $lt: inicioDeEsteMes }
    });
    console.log(`✅ [Limpieza Salud] Se eliminaron ${resultadoSalud.deletedCount} registros antiguos.`);

    // 2. Resetear estado 'haPagado' de los clientes
    const resultadoPagos = await Usuario.updateMany(
      {
        rol: { $in: ['cliente', 'online'] },
        haPagado: true
      },
      { $set: { haPagado: false } }
    );
    console.log(`✅ [Reseteo Pagos] Se resetearon ${resultadoPagos.nModified} usuarios a 'No Pagado'.`);

  } catch (error) {
    console.error('❌ [Tareas Mensuales 00:00] Error en la tarea cron:', error);
  }
});

// Tarea para borrar Clases y Reservas antiguas
cron.schedule('0 1 1 * *', async () => {
  console.log('--- 🧹 INICIANDO TAREA DE LIMPIEZA DE HISTORIAL (Clases y Reservas) ---');

  try {
    const ahora = new Date();
    const fechaCorte = new Date(ahora.setMonth(ahora.getMonth() - 3));

    const clasesAntiguas = await Clase.find({
      fecha: { $lt: fechaCorte }
    }).select('_id');

    const idsClasesAntiguas = clasesAntiguas.map(c => c._id);

    if (idsClasesAntiguas.length > 0) {
      const resultadoReservas = await Reserva.deleteMany({
        clase: { $in: idsClasesAntiguas }
      });
      console.log(`✅ [Limpieza Historial] Se eliminaron ${resultadoReservas.deletedCount} reservas antiguas.`);

      const resultadoClases = await Clase.deleteMany({
        _id: { $in: idsClasesAntiguas }
      });
      console.log(`✅ [Limpieza Historial] Se eliminaron ${resultadoClases.deletedCount} clases antiguas.`);
    } else {
      console.log('✅ [Limpieza Historial] No se encontraron clases ni reservas antiguas para eliminar.');
    }

  } catch (error) {
    console.error('❌ [Limpieza Historial] Error al eliminar datos antiguos:', error);
  }
});

// Middleware
app.use(express.json());
app.use(cors());

// Rutas
app.use('/api/auth', authRoutes);
app.use('/api/usuarios', usuariosRoutes);
app.use('/api/clases', clasesRoutes);
app.use('/api/reservas', reservasRoutes);
app.use('/api/entrenamiento', iaEntrenamientoRoutes);
app.use('/api/dietas', iaDietaRoutes);
app.use('/api/salud', saludRouter);
app.use('/api/videos', videoRoutes);

// Ruta de "Health Check"
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'Servidor activo.' });
});

// Manejo de errores
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Ha ocurrido un error en el servidor' });
});

// Levantar el servidor
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Servidor corriendo en el puerto ${PORT}`);
});
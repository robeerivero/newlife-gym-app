const express = require('express');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const usuariosRoutes = require('./routes/usuariosRoutes');
const clasesRoutes = require('./routes/clasesRoutes');
const reservasRoutes = require('./routes/reservasRoutes');
const iaEntrenamientoRoutes = require('./routes/iaEntrenamientoRoutes');
const iaDietaRoutes = require('./routes/iaDietaRoutes');
const saludRouter = require('./routes/saludRoutes');
const videoRoutes = require('./routes/videoRoutes'); // Importar rutas de videos
const cron = require('node-cron');
const Salud = require('./models/Salud');
const Clase = require('./models/Clase'); 
const Reserva = require('./models/Reserva');
const Usuario = require('./models/Usuario'); // <-- ¡AÑADIDO!
const cors = require('cors');
// Configuración de variables de entorno
dotenv.config();

// Conexión a MongoDB
connectDB();

const app = express();

// --- TAREA COMBINADA: Limpieza de Salud Y Reseteo de Pagos ---
// Se ejecuta a las 00:00 del día 1 de cada mes.
cron.schedule('0 0 1 * *', async () => {
  console.log('--- 🧹 INICIANDO TAREAS MENSUALES (00:00) ---');

  try {
    const ahora = new Date();
    const inicioDeEsteMes = new Date(ahora.getFullYear(), ahora.getMonth(), 1);
    inicioDeEsteMes.setHours(0, 0, 0, 0); 

    // 1. Borrar datos de Salud antiguos
    console.log('[Tarea 1/2] Ejecutando limpieza de registros de Salud...');
    const resultadoSalud = await Salud.deleteMany({
      fecha: { $lt: inicioDeEsteMes }
    });
    console.log(`✅ [Limpieza Salud] Se eliminaron ${resultadoSalud.deletedCount} registros antiguos.`);

    // 2. Resetear estado 'haPagado' de los clientes
    console.log('[Tarea 2/2] Ejecutando reseteo de estado de pagos...');
    const resultadoPagos = await Usuario.updateMany(
      { 
        rol: { $in: ['cliente', 'online'] }, // Solo resetea a clientes
        haPagado: true // Solo actualiza los que SÍ habían pagado
      }, 
      { 
        $set: { haPagado: false } 
      }
    );
    console.log(`✅ [Reseteo Pagos] Se resetearon ${resultadoPagos.nModified} usuarios a 'No Pagado'.`);
    
    console.log('--- 🏁 TAREAS MENSUALES (00:00) COMPLETADAS ---');

  } catch (error) {
    console.error('❌ [Tareas Mensuales 00:00] Error en la tarea cron:', error);
  }
});

// Tarea para borrar Clases y Reservas antiguas (ej. más de 3 meses)
// Se ejecuta a la 1 AM del día 1 de cada mes.
cron.schedule('0 1 1 * *', async () => {
  console.log('--- 🧹 INICIANDO TAREA DE LIMPIEZA DE HISTORIAL (Clases y Reservas) ---');
  
  try {
    const ahora = new Date();
    // 1. Calcular la fecha de corte (todo lo anterior a 3 meses desde hoy)
    const fechaCorte = new Date(ahora.setMonth(ahora.getMonth() - 3));
    console.log(`[Limpieza Historial] Borrando registros anteriores a: ${fechaCorte.toISOString()}`);

    // 2. Buscar las Clases que sean más antiguas que la fecha de corte
    const clasesAntiguas = await Clase.find({
      fecha: { $lt: fechaCorte }
    }).select('_id'); // Solo necesitamos sus IDs

    const idsClasesAntiguas = clasesAntiguas.map(c => c._id);

    if (idsClasesAntiguas.length > 0) {
      // 3. Borrar todas las Reservas asociadas a esas clases antiguas
      const resultadoReservas = await Reserva.deleteMany({
        clase: { $in: idsClasesAntiguas }
      });
      console.log(`✅ [Limpieza Historial] Se eliminaron ${resultadoReservas.deletedCount} reservas antiguas.`);

      // 4. Borrar las Clases antiguas
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
app.use(express.json()); // Para procesar JSON
app.use(cors());         // Habilitar CORS

// Rutas
app.use('/api/auth', authRoutes);         // Autenticación
app.use('/api/usuarios', usuariosRoutes);       // Usuarios
app.use('/api/clases', clasesRoutes);        // Clases 
app.use('/api/reservas', reservasRoutes); // Reservas
app.use('/api/entrenamiento', iaEntrenamientoRoutes);
app.use('/api/dietas', iaDietaRoutes);
app.use('/api/salud', saludRouter);
app.use('/api/videos', videoRoutes); // Rutas de videos

// Ruta de "Health Check" para el servicio de cron job externo
app.get('/health', (req, res) => {
  // console.log('PING de keep-alive recibido.'); // Descomenta esto si quieres ver los pings en tus logs
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
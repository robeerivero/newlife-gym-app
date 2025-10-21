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
const Dieta = require('./models/Dieta'); // <--- 1. IMPORTA EL MODELO DIETA
const Clase = require('./models/Clase'); // <--- (Lo usaremos en la Propuesta 2)
const Reserva = require('./models/Reserva'); // <--- (Lo usaremos en la Propuesta 2)
const cors = require('cors');

// Configuración de variables de entorno
dotenv.config();

// Conexión a MongoDB
connectDB();

const app = express();

// Tarea para borrar datos DIARIOS (Salud y Dietas)
cron.schedule('0 0 1 * *', async () => {
  console.log('--- 🧹 INICIANDO TAREA DE LIMPIEZA MENSUAL (Salud y Dietas) ---');

  try {
    const ahora = new Date();
    const inicioDeEsteMes = new Date(ahora.getFullYear(), ahora.getMonth(), 1);
    inicioDeEsteMes.setHours(0, 0, 0, 0); 

    // 1. Borrar datos de Salud
    const resultadoSalud = await Salud.deleteMany({
      fecha: { $lt: inicioDeEsteMes }
    });
    console.log(`✅ [Limpieza Mensual] Se eliminaron ${resultadoSalud.deletedCount} registros antiguos de salud.`);

    // 2. BORRAR DATOS DE DIETA <--- 2. AÑADE ESTE BLOQUE
    const resultadoDieta = await Dieta.deleteMany({
      fecha: { $lt: inicioDeEsteMes } 
    });
    console.log(`✅ [Limpieza Mensual] Se eliminaron ${resultadoDieta.deletedCount} registros antiguos de dietas.`);

  } catch (error) {
    console.error('❌ [Limpieza Mensual] Error al eliminar datos antiguos:', error);
  }
});

// Tarea para borrar Clases y Reservas antiguas (ej. más de 6 meses)
// Se ejecuta a la 1 AM del día 1 de cada mes. (Le pongo la 1 AM para que no se ejecute a la vez que la otra)
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
app.use(cors());         // Habilitar CORS (opcional, según las necesidades del frontend)

// Rutas
app.use('/api/auth', authRoutes);             // Autenticación
app.use('/api/usuarios', usuariosRoutes);         // Usuarios
app.use('/api/clases', clasesRoutes);          // Clases 
app.use('/api/reservas', reservasRoutes);  // Reservas
app.use('/api/entrenamiento', iaEntrenamientoRoutes);
app.use('/api/dietas', iaDietaRoutes);
app.use('/api/salud', saludRouter);
app.use('/api/videos', videoRoutes); // Rutas de videos

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

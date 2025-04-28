const express = require('express');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const usuariosRoutes = require('./routes/usuariosRoutes');
const clasesRoutes = require('./routes/clasesRoutes');
const adminRoutes = require('./routes/adminRoutes');
const reservasRoutes = require('./routes/reservasRoutes');
const grupoRoutes = require('./routes/grupoRoutes');
const dietasRoutes = require('./routes/dietasRoutes');
const platosRoutes = require('./routes/platosRoutes');
const ejerciciosRoutes = require('./routes/ejerciciosRoutes');
const rutinasRoutes = require('./routes/rutinasRoutes');
const saludRouter = require('./routes/saludRoutes');
const videoRoutes = require('./routes/videoRoutes'); // Importar rutas de videos
const cors = require('cors');

// Configuración de variables de entorno
dotenv.config();

// Conexión a MongoDB
connectDB();

const app = express();

// Middleware
app.use(express.json()); // Para procesar JSON
app.use(cors());         // Habilitar CORS (opcional, según las necesidades del frontend)

// Rutas
app.use('/api/auth', authRoutes);             // Autenticación
app.use('/api/usuarios', usuariosRoutes);         // Usuarios
app.use('/api/clases', clasesRoutes);          // Clases
app.use('/api/admin', adminRoutes);           // Administración
app.use('/api/reservas', reservasRoutes);  // Reservas
app.use('/api/grupos', grupoRoutes);
app.use('/api/dietas', dietasRoutes);
app.use('/api/platos', platosRoutes);
app.use('/api/ejercicios', ejerciciosRoutes);
app.use('/api/rutinas', rutinasRoutes);
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

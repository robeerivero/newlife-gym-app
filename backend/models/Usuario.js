const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const esquemaUsuario = new mongoose.Schema({
  nombre: { type: String, required: true, trim: true },
  correo: { type: String, required: true, unique: true, trim: true },
  contrasena: { type: String, required: true },
  rol: { type: String, enum: ['admin', 'cliente', 'online'], default: 'cliente' },
  esPremium: { type: Boolean, default: false },
  cancelaciones: { type: Number, default: 0 },
  tiposDeClases: { type: [String], enum: ['funcional', 'pilates', 'zumba'], required: true },
  avatar: { type: Object, default: {} },
  desbloqueados: { type: [Object], default: [] },
  genero: {
    type: String,
    enum: ['masculino', 'femenino'],
    default: 'masculino'
  },
  edad: {
    type: Number,
    min: 16,
    default: 25
  },
  altura: { // En centímetros
    type: Number,
    min: 100,
    default: 170
  },
  peso: { // En kilogramos
    type: Number,
    min: 40,
    default: 70
  },
  nivelActividad: {
    type: String,
    enum: ['sedentario', 'ligero', 'moderado', 'activo', 'muy_activo'],
    default: 'sedentario'
  },
  objetivo: {
    type: String,
    enum: ['perder', 'mantener', 'ganar'],
    default: 'mantener'
  },
  
  // Resultado del cálculo (lo guardaremos aquí)
  kcalObjetivo: {
    type: Number,
    default: 2000
  },
}, { timestamps: true });

// Middleware para encriptar la contraseña antes de guardarla
esquemaUsuario.pre('save', async function (next) {
  if (!this.isModified('contrasena')) return next();
  const salt = await bcrypt.genSalt(10);
  this.contrasena = await bcrypt.hash(this.contrasena, salt);
  next();
});

// Método para verificar la contraseña
esquemaUsuario.methods.verificarContrasena = async function (contrasena) {
  return await bcrypt.compare(contrasena, this.contrasena);
};

const Usuario = mongoose.model('Usuario', esquemaUsuario);

module.exports = Usuario;

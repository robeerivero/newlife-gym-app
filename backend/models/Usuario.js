const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const esquemaUsuario = new mongoose.Schema({
  nombre: { type: String, required: true, trim: true },
  correo: { type: String, required: true, unique: true, trim: true },
  contrasena: { type: String, required: true },
  rol: { type: String, enum: ['admin', 'cliente', 'online'], default: 'cliente' },
  haPagado: {
    type: Boolean,
    default: false
  },
  nombreGrupo: {
    type: String,
    trim: true,
    index: true, // Para que la ordenación sea más rápida
    default: null
  },
  
  esPremium: { type: Boolean, default: false },
  cancelaciones: { type: Number, default: 0 },
  tiposDeClases: { type: [String], enum: ['funcional', 'pilates', 'zumba'], required: true },
  avatar: { type: Object, default: {} },
  desbloqueados: { type: [Object], default: [] },
  // --- CAMPOS DE SERVICIO PREMIUM ---
  esPremium: { type: Boolean, default: false },
  // Banderas de control del Admin
  incluyePlanDieta: { type: Boolean, default: false },
  incluyePlanEntrenamiento: { type: Boolean, default: false },
  
  // --- Inputs de Dieta ---
  dietaAlergias: { type: String, default: 'Ninguna' },
  dietaPreferencias: { type: String, default: 'Omnívoro, me gusta todo' },
  dietaComidas: { type: Number, default: 4 }, // Num comidas al día

  // --- Inputs de Entrenamiento ---
  premiumMeta: { type: String, default: 'Quiero ganar fuerza y definir.' },
  premiumFoco: { type: String, default: 'Pecho, espalda y piernas' },
  premiumEquipamiento: {
    type: String,
    enum: ['solo_cuerpo', 'mancuernas_basico', 'gym_completo'],
    default: 'solo_cuerpo'
  },
  premiumTiempo: { type: Number, default: 45 },
  // --- Datos Metabólicos ---
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

esquemaUsuario.pre('deleteOne', { document: true, query: false }, async function(next) {
  try {
    // 'this._id' es el ID del usuario que se va a borrar
    await Promise.all([
      Reserva.deleteMany({ usuario: this._id }),
      PlanDieta.deleteMany({ usuario: this._id }),
      PlanEntrenamiento.deleteMany({ usuario: this._id }),
      Salud.deleteMany({ usuario: this._id })
    ]);
    next();
  } catch (error) {
    next(error);
  }
});

// Método para verificar la contraseña
esquemaUsuario.methods.verificarContrasena = async function (contrasena) {
  return await bcrypt.compare(contrasena, this.contrasena);
};

const Usuario = mongoose.model('Usuario', esquemaUsuario);

module.exports = Usuario;

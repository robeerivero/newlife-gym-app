// models/Usuario.js
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const Reserva = require('./Reserva');
const PlanDieta = require('./PlanDieta');
const PlanEntrenamiento = require('./PlanEntrenamiento');
const Salud = require('./Salud');
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

  // --- Banderas de control del Admin ---
  incluyePlanDieta: { type: Boolean, default: false },
  incluyePlanEntrenamiento: { type: Boolean, default: false },

  // --- Inputs de Dieta ---
  dietaAlergias: { type: String, default: 'Ninguna' },
  dietaPreferencias: { type: String, default: 'Omnívoro, me gusta todo' },
  dietaComidas: { type: Number, default: 4 },
  historialMedico: { type: String, default: '' },
  horarios: { type: String, default: '' },
  platosFavoritos: { type: String, default: '' },
  dietaTiempoCocina: {
    type: String,
    enum: ['menos_15_min', '15_30_min', 'mas_30_min'],
    default: '15_30_min'
  },
  dietaHabilidadCocina: {
    type: String,
    enum: ['principiante', 'intermedio', 'avanzado'],
    default: 'intermedio'
  },
  dietaEquipamiento: {
    type: [String],
    default: ['basico']
  },
  dietaContextoComida: {
    type: String,
    enum: ['casa', 'oficina_tupper', 'restaurante'],
    default: 'casa'
  },
  dietaAlimentosOdiados: { type: String, default: 'Ninguno' },
  dietaRetoPrincipal: {
    type: String,
    enum: ['picoteo', 'social', 'organizacion', 'estres', 'raciones'],
    default: 'picoteo'
  },
  dietaBebidas: { type: String, default: 'Principalmente agua' },

  // --- ¡¡INPUTS DE ENTRENAMIENTO ACTUALIZADOS!! ---
  premiumMeta: {
    type: String,
    // (fuerza_pura = Powerlifting, rendimiento_atletico = Híbrido/Velocidad)
    enum: ['perder_grasa', 'hipertrofia', 'fuerza_pura', 'rendimiento_atletico', 'salud_general'],
    default: 'salud_general'
  },
  premiumFoco: { type: String, default: 'Cuerpo completo' },

  premiumEquipamiento: {
    type: [String], // Cambiado a Array de Strings
    default: ['solo_cuerpo']
    // Opciones: 'solo_cuerpo', 'bandas_elasticas', 'mancuernas_ligeras', 
    // 'mancuernas_ajustables', 'kettlebell', 'barra_dominadas', 'banco',
    // 'gym_basico', 'gym_completo'
  },
  premiumTiempo: { type: Number, default: 45 },

  premiumNivel: {
    type: String,
    enum: ['principiante_nuevo', 'intermedio_consistente', 'avanzado_programado'],
    default: 'principiante_nuevo'
  },
  premiumDiasSemana: {
    type: Number,
    default: 4
  },
  premiumLesiones: {
    type: String,
    default: 'Ninguna'
  },
  premiumEjerciciosOdiados: { // ¡NUEVO!
    type: String,
    default: 'Ninguno'
  },
  // -----------------------------------------

  // --- Datos Metabólicos (Dieta) ---
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
  ocupacion: {
    type: String,
    enum: ['sedentaria', 'ligera', 'activa'],
    default: 'sedentaria'
  },
  ejercicio: {
    type: String,
    enum: ['0', '1-3', '4-5', '6-7'],
    default: '0'
  },
  objetivo: {
    type: String,
    enum: ['perder', 'mantener', 'ganar'],
    default: 'mantener'
  },
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

// Middleware para borrar en cascada
esquemaUsuario.pre('deleteOne', { document: true, query: false }, async function (next) {
  try {
    const Clase = require('./Clase');

    // 1. Obtener todas las reservas del usuario para incrementar cupos
    const reservasDelUsuario = await Reserva.find({ usuario: this._id });

    // 2. Incrementar cuposDisponibles en cada clase donde tenía reserva
    for (const reserva of reservasDelUsuario) {
      await Clase.findByIdAndUpdate(
        reserva.clase,
        { $inc: { cuposDisponibles: 1 } }
      );
    }

    // 3. Eliminar datos relacionados
    await Promise.all([
      Reserva.deleteMany({ usuario: this._id }),
      PlanDieta.deleteMany({ usuario: this._id }),
      PlanEntrenamiento.deleteMany({ usuario: this._id }),
      Salud.deleteMany({ usuario: this._id }),
      // 4. Eliminar de todas las listas de espera
      Clase.updateMany(
        { listaEspera: this._id },
        { $pull: { listaEspera: this._id } }
      )
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
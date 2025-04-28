// backend/models/Usuario.js
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const esquemaUsuario = new mongoose.Schema({
  nombre: { type: String, required: true, trim: true },
  correo: { type: String, required: true, unique: true, trim: true },
  contrasena: { type: String, required: true },
  rol: { type: String, enum: ['admin', 'cliente', 'online'], default: 'cliente' },
  grupos: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Grupo' }], // Grupos a los que pertenece el usuario
  clasesAsignadas: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Clase' }],
  cancelaciones: { type: Number, default: 0 },
  tiposDeClases: {type: [String], enum: ['funcional', 'pilates', 'zumba'], required: true,
  },
}, { timestamps: true });

// Middleware para encriptar la contraseña antes de guardarla
esquemaUsuario.pre('save', async function (next) {
  if (!this.isModified('contrasena')) {
    next();
  }
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


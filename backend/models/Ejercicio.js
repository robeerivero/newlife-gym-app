const mongoose = require('mongoose');

const ejercicioSchema = new mongoose.Schema({
  nombre: {
    type: String,
    required: true,
    unique: true,
    trim: true,
  },
  video: {
    type: String, // Guarda la URL del video de YouTube
    required: true,
  },
  descripcion: {
    type: String,
    default: '',
  },
  dificultad: {
    type: String,
    enum: ['fácil', 'medio', 'difícil'],
    required: true,
  },
}, { timestamps: true });

const Ejercicio = mongoose.model('Ejercicio', ejercicioSchema);

module.exports = Ejercicio;

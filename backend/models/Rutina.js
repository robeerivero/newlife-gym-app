const mongoose = require('mongoose');

const rutinaSchema = new mongoose.Schema({
  usuario: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Usuario', // Relación con el modelo de Usuario
    required: true,
  },
  diaSemana: {
    type: String,
    enum: ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'],
    required: true,
  },
  ejercicios: [
    {
      ejercicio: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Ejercicio', // Relación con el modelo de Ejercicio
        required: true,
      },
      series: {
        type: Number,
        default: 3, // Series por defecto
      },
      repeticiones: {
        type: Number,
        default: 10, // Repeticiones por defecto
      },
    },
  ],
}, { timestamps: true });

const Rutina = mongoose.model('Rutina', rutinaSchema);

module.exports = Rutina;

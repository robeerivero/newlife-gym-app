const mongoose = require('mongoose');

const esquemaClase = new mongoose.Schema({
  nombre: {
    type: String,
    enum: ['funcional', 'pilates', 'zumba'],
    required: true
  },
  dia: {
    type: String,
    enum: ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'],
    required: true
  },
  horaInicio: {
    type: String, // Hora en formato "HH:mm"
    required: true
  },
  horaFin: {
    type: String,
    required: true
  },
  fecha: {
    type: Date, // Fecha exacta de la clase
    required: true
  },
  cuposDisponibles: { 
    type: Number, 
    default: 14 
  },
  maximoParticipantes: {
    type: Number,
    default: 14 // Máximo por defecto es 14, pero puede variar
  },
  listaEspera: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Usuario' // Usuarios en lista de espera
  }]
  // participantes y asistencias eliminados
}, { timestamps: true });

const Clase = mongoose.model('Clase', esquemaClase);

module.exports = Clase;

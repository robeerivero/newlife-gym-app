const mongoose = require('mongoose');

const esquemaHistorial = new mongoose.Schema({
  usuario: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Usuario',
    required: true 
  },
  nombreUsuario: { type: String },
  clase: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Clase',
    required: true 
  },
  infoClase: { type: String }, 
  tipoAccion: { 
    type: String, 
    // 👇 AÑADIMOS NUEVOS ESTADOS AQUÍ
    enum: [
      'RESERVA',                  // Reserva normal/directa
      'RESERVA_CON_CUPO',         // 👈 NUEVO: Para saber que gastó su cupo aquí
      'LISTA_ESPERA', 
      'CANCELACION_DEVOLUCION',   // 👈 NUEVO: Canceló y se le devolvió cupo
      'CANCELACION_PENALIZACION', // 👈 NUEVO: Canceló tarde (perdió cupo)
      'ASISTENCIA', 
      'INTENTO_FALLIDO_QR'        // 👈 NUEVO: El caso del QR inválido
    ], 
    required: true 
  },
  fechaAccion: { 
    type: Date, 
    default: Date.now 
  }
});

module.exports = mongoose.model('HistorialReserva', esquemaHistorial);
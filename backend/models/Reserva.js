const mongoose = require('mongoose');

const esquemaReserva = new mongoose.Schema({
  usuario: { type: mongoose.Schema.Types.ObjectId, ref: 'Usuario', required: true },
  clase: { type: mongoose.Schema.Types.ObjectId, ref: 'Clase', required: true },
  fechaReserva: { type: Date, default: Date.now },
  asistio: { type: Boolean, default: false }
}, { timestamps: true });

const Reserva = mongoose.model('Reserva', esquemaReserva);

module.exports = Reserva;

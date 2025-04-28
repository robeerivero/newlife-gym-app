const mongoose = require('mongoose');

const saludSchema = new mongoose.Schema({
  usuario: { type: mongoose.Schema.Types.ObjectId, ref: 'Usuario', required: true },
  fecha: { type: Date, required: true },
  pasos: { type: Number, default: 0 },
  kcalQuemadas: { type: Number, default: 0 },
  kcalConsumidas: { type: Number, default: 0 }
}, { timestamps: true });

module.exports = mongoose.model('Salud', saludSchema);

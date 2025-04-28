const mongoose = require('mongoose');

const dietaSchema = new mongoose.Schema({
  usuario: { type: mongoose.Schema.Types.ObjectId, ref: 'Usuario', required: true },
  fecha: { type: Date, required: true },
  platos: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Plato' }], // Referencia a los platos
}, { timestamps: true });

module.exports = mongoose.model('Dieta', dietaSchema);

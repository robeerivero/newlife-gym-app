// models/Plato.js
const mongoose = require('mongoose');

const platoSchema = new mongoose.Schema({
  nombre: { type: String, required: true, unique: true },
  kcal: { type: Number, required: true }, 
  comidaDelDia: { 
    type: String, 
    enum: ['Desayuno', 'Almuerzo', 'Cena', 'Merienda'], // <-- Cambiado 'Snack' por 'Merienda'
    required: true 
  },
  ingredientes: { type: [String], required: true }, 
  instrucciones: { type: String, required: true }, 
  tiempoPreparacion: { type: Number, required: true }, 
  observaciones: { type: String }, 
}, { timestamps: true });

module.exports = mongoose.model('Plato', platoSchema);
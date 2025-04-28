const mongoose = require('mongoose');

const platoSchema = new mongoose.Schema({
  nombre: { type: String, required: true, unique: true },
  kcal: { type: Number, required: true }, // Calorías
  comidaDelDia: { 
    type: String, 
    enum: ['Desayuno', 'Almuerzo', 'Cena', 'Snack'], 
    required: true 
  },
  ingredientes: { type: [String], required: true }, // Lista de ingredientes
  instrucciones: { type: String, required: true }, // Cómo realizarlo
  tiempoPreparacion: { type: Number, required: true }, // Minutos
  observaciones: { type: String }, // Opcional
}, { timestamps: true });

module.exports = mongoose.model('Plato', platoSchema);


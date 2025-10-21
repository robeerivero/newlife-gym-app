// models/PlanDieta.js
const mongoose = require('mongoose');

// Sub-esquemas de texto flexible
const platoGeneradoSchema = new mongoose.Schema({
  nombrePlato: { type: String, required: true },
  kcalAprox: { type: Number, default: 0 },
  ingredientes: { type: String, default: '' },
  receta: { type: String, default: '' }
}, { _id: false });

const comidaSchema = new mongoose.Schema({
  nombreComida: { type: String, required: true }, // Ej: "Desayuno", "Almuerzo"
  opciones: [platoGeneradoSchema] // Damos varias opciones por comida
}, { _id: false });

const diaDietaSchema = new mongoose.Schema({
  nombreDia: { type: String, required: true }, // Ej: "Lunes a Viernes", "Fin de Semana"
  kcalDiaAprox: { type: Number, default: 0 },
  comidas: [comidaSchema]
}, { _id: false });


const planDietaSchema = new mongoose.Schema({
  usuario: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Usuario',
    required: true,
  },
  mes: { type: String, required: true }, // Ej: "2025-10"
  inputsUsuario: {
    objetivo: { type: String },
    kcalObjetivo: { type: Number },
    dietaAlergias: { type: String },
    dietaPreferencias: { type: String },
    dietaComidas: { type: Number }
  },
  planGenerado: [diaDietaSchema],
  estado: {
    type: String,
    enum: ['pendiente_solicitud', 'pendiente_ia', 'pendiente_revision', 'aprobado'],
    default: 'pendiente_solicitud'
  }
  // La dieta se aplica a todos los días, no necesita 'diasAsignados'
}, { timestamps: true });

planDietaSchema.index({ usuario: 1, mes: 1 }, { unique: true });
module.exports = mongoose.model('PlanDieta', planDietaSchema);
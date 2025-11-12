// models/PlanEntrenamiento.js
const mongoose = require('mongoose');

// Sub-esquema 100% texto, editable por el admin
const ejercicioGeneradoSchema = new mongoose.Schema({
  nombre: { type: String, required: true },
  series: { type: String, required: true },
  repeticiones: { type: String, required: true },
  descansoSeries: { type: String, default: '60-90 seg' },
  descansoEjercicios: { type: String, default: '2-3 min' },
  descripcion: { type: String, default: '' }
}, { _id: false });

const diaEntrenamientoSchema = new mongoose.Schema({
  nombreDia: { type: String, required: true }, // Ej: "Día 1: Pecho y Tríceps"
  ejercicios: [ejercicioGeneradoSchema]
}, { _id: false });

const planEntrenamientoSchema = new mongoose.Schema({
  usuario: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Usuario',
    required: true,
  },
  mes: { type: String, required: true }, // Ej: "2025-10"
  
  // --- ¡INPUTS ACTUALIZADOS! ---
  inputsUsuario: {
    premiumMeta: { type: String },
    premiumFoco: { type: String },
    premiumEquipamiento: { type: [String] }, // ¡Cambiado a Array!
    premiumTiempo: { type: Number },
    premiumNivel: { type: String },
    premiumDiasSemana: { type: Number },
    premiumLesiones: { type: String },
    premiumEjerciciosOdiados: { type: String } // ¡Añadido!
  },
  // -----------------------------
  
  planGenerado: [diaEntrenamientoSchema],
  estado: {
    type: String,
    enum: ['pendiente_solicitud', 'pendiente_revision', 'aprobado'],
    default: 'pendiente_solicitud'
  },
  diasAsignados: { // Los días que TÚ asignas
    type: [String], 
    enum: ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'],
    default: []
  }
}, { timestamps: true });

// (El enum obsoleto de 'estado' 'pendiente_ia' ha sido eliminado)
planEntrenamientoSchema.index({ usuario: 1, mes: 1 }, { unique: true });
module.exports = mongoose.model('PlanEntrenamiento', planEntrenamientoSchema);
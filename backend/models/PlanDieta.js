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
  nombreDia: { type: String, required: true }, // Ej: "Lunes", "Martes"...
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
  estado: {
    type: String,
    enum: ['pendiente_solicitud', 'pendiente_revision', 'aprobado'],
    default: 'pendiente_solicitud'
  },

  // (Inputs guardados cuando el cliente rellena el formulario)
  inputsUsuario: {
    // --- Datos Metabólicos ---
    genero: { type: String },
    edad: { type: Number },
    altura: { type: Number },
    peso: { type: Number },
    ocupacion: { type: String },
    ejercicio: { type: String },
    objetivo: { type: String },
    kcalObjetivo: { type: Number },
    // --- Preferencias y Adherencia ---
    dietaComidas: { type: Number },
    dietaAlergias: { type: String },
    dietaPreferencias: { type: String },
    historialMedico: { type: String },
    horarios: { type: String },
    platosFavoritos: { type: String },
    dietaTiempoCocina: { type: String },
    dietaHabilidadCocina: { type: String },
    dietaEquipamiento: { type: [String] },
    dietaContextoComida: { type: String },
    dietaAlimentosOdiados: { type: String },
    dietaRetoPrincipal: { type: String },
    dietaBebidas: { type: String },
  },

  // (Output generado por el Admin/IA y aprobado)
  planGenerado: [diaDietaSchema], // El array de 7 días
  
  // --- ¡NUEVO CAMPO! ---
  listaCompraGenerada: {
    type: Object, // Guardará el JSON de la lista de la compra
    default: {}
  }
  
}, { timestamps: true });

// Middleware para borrar en cascada (si es necesario)
planDietaSchema.pre('deleteMany', { document: false, query: true }, async function(next) {
  // Esta lógica es compleja si 'usuario' es parte del filtro.
  // Por ahora, asumimos que se borra desde el Usuario.
  next();
});

const PlanDieta = mongoose.model('PlanDieta', planDietaSchema);

module.exports = PlanDieta;
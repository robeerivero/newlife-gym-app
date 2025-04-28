const mongoose = require('mongoose');

const esquemaGrupo = new mongoose.Schema({
  nombre: { type: String, required: true },
  descripcion: { type: String }, // Descripción opcional del grupo
  usuarios: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Usuario' }] // Usuarios en el grupo
}, { timestamps: true });

const Grupo = mongoose.model('Grupo', esquemaGrupo);

module.exports = Grupo;

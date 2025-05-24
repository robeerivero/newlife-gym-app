const mongoose = require('mongoose');

const AvatarSchema = new mongoose.Schema({
  gender: { type: String, enum: ['male', 'female'], default: 'male' },
  skinColor: { type: String, enum: ['light', 'medium', 'dark'], default: 'light' },
  hair: { type: String, default: 'short_brown' },
  clothing: { type: String, default: 'casual1' },
  // Puedes añadir más campos como accesorios, logros, etc.
}, { _id: false }); // _id: false para guardar dentro de Usuario

module.exports = AvatarSchema;

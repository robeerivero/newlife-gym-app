// Video.js
const mongoose = require('mongoose');

const videoSchema = new mongoose.Schema({
  titulo: { type: String, required: true, trim: true, maxlength: 100 },
  url: { type: String, required: true, unique: true },
  thumbnail: { type: String } // Ya no necesitamos el 'default' aquí
});

// Usamos un hook 'pre-save' para generar la miniatura automáticamente
videoSchema.pre('save', function (next) {
  const videoId = this.url.match(/(?:v=|\/)([a-zA-Z0-9_-]{11})/)?.[1];
  if (videoId) {
    this.thumbnail = `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`;
  }
  next();
});

module.exports = mongoose.model('Video', videoSchema);
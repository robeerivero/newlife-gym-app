const mongoose = require('mongoose');

const videoSchema = new mongoose.Schema({
  titulo: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  url: {
    type: String,
    required: true,
    unique: true,
    validate: {
      validator: v => {
        const regex = /^(https?\:\/\/)?(www\.)?(youtube\.com|youtu\.?be)\/.+/;
        return regex.test(v);
      },
      message: 'Debe ser una URL de YouTube válida'
    }
  },
  thumbnail: {
    type: String,
    default: function() {
      const videoId = this.url.match(/(?:v=|\/)([a-zA-Z0-9_-]{11})/)?.[1];
      return videoId ? `https://img.youtube.com/vi/${videoId}/hqdefault.jpg` : '';
    }
  }
});

module.exports = mongoose.model('Video', videoSchema);
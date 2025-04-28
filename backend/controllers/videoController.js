const Video = require('../models/Video');

// Crear un nuevo video
exports.crearVideo = async (req, res) => {
  try {
    const video = new Video(req.body);
    await video.save();
    res.status(201).json(video);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Obtener todos los videos
exports.obtenerVideos = async (req, res) => {
  try {
    const videos = await Video.find().sort({ _id: -1 });
    res.json(videos);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener videos' });
  }
};

// Actualizar un video por ID
exports.actualizarVideo = async (req, res) => {
  try {
    const video = await Video.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    
    if (!video) {
      return res.status(404).json({ error: 'Video no encontrado' });
    }
    
    res.json(video);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Eliminar un video por ID
exports.eliminarVideo = async (req, res) => {
  try {
    const video = await Video.findByIdAndDelete(req.params.id);
    
    if (!video) {
      return res.status(404).json({ error: 'Video no encontrado' });
    }
    
    res.json({ message: 'Video eliminado correctamente' });
  } catch (error) {
    res.status(500).json({ error: 'Error al eliminar el video' });
  }
};

// Eliminar todos los videos
exports.eliminarTodosVideos = async (req, res) => {
  try {
    await Video.deleteMany({});
    res.json({ message: 'Todos los videos han sido eliminados' });
  } catch (error) {
    res.status(500).json({ error: 'Error al eliminar los videos' });
  }
};
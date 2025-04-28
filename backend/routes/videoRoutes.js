const express = require('express');
const router = express.Router();
const videoController = require('../controllers/videoController');

// CRUD Completo
router.post('/', videoController.crearVideo);
router.get('/', videoController.obtenerVideos);
router.put('/:id', videoController.actualizarVideo);
router.delete('/:id', videoController.eliminarVideo);
router.delete('/', videoController.eliminarTodosVideos);

module.exports = router;
const express = require('express');
const { proteger, esAdministrador } = require('../middleware/authMiddleware');
const {
  crearRutina,
  modificarRutina,
  obtenerRutinasPorUsuario,
  obtenerRutinaPorId,
  obtenerRutinas,
  eliminarRutina,
  eliminarRutinasPorUsuario,
} = require('../controllers/rutinasController');

const router = express.Router();

router.post('/', proteger, esAdministrador, crearRutina); // Crear una rutina
router.get('/usuario', proteger, obtenerRutinasPorUsuario); // Obtener rutinas por usuario
router.get('/:idRutina', proteger, obtenerRutinaPorId);
router.get('/', proteger, obtenerRutinas); // Obtener rutinas por usuario
router.put('/:idRutina', proteger, esAdministrador, modificarRutina); // Modificar rutina
router.delete('/:idRutina', proteger, esAdministrador, eliminarRutina); // Eliminar una rutina
router.delete('/usuario/:idUsuario', proteger, esAdministrador, eliminarRutinasPorUsuario); // Eliminar todas las rutinas de un usuario

module.exports = router;

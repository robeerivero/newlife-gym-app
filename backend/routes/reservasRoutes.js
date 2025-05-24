const express = require('express');
const { proteger } = require('../middleware/authMiddleware');
const {
  cancelarClase,
  reservarClase,
  registrarAsistencia,
} = require('../controllers/reservasController');

const router = express.Router();

// Rutas protegidas para reservas
router.post('/reservar', proteger, reservarClase); // Reservar una clase
router.delete('/cancelar', proteger, cancelarClase); // Cancelar una reserva
router.post('/asistencia', proteger, registrarAsistencia); // Registrar asistencia a una clase
module.exports = router;

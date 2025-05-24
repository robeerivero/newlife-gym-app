const express = require('express');
const { proteger } = require('../middleware/authMiddleware');
const {
  obtenerProximasClases,
  desregistrarseDeClase,
  obtenerClases,
  generarQR
} = require('../controllers/clasesController');

const router = express.Router();

// Rutas protegidas para usuarios autenticados
router.get('/proximas-clases', proteger, obtenerProximasClases);
router.delete('/:idClase/desregistrarse', proteger, desregistrarseDeClase);
// Obtener clases por fecha y tipo de clase
router.get('/clases', proteger, obtenerClases);
router.get('/generar-qr/:idClase', proteger, generarQR);

module.exports = router;

const express = require('express');
const router = express.Router();
const {actualizarPasos, actualizarKcalConsumidas, obtenerLogros, obtenerHistorialSalud,guardarDatosSalud} = require('../controllers/saludController');
const { proteger} = require('../middleware/authMiddleware');

router.put('/pasos', proteger, actualizarPasos);
router.get('/kcal-consumidas', proteger, actualizarKcalConsumidas);
router.get('/historial', proteger, obtenerHistorialSalud);
router.post('/guardar', proteger, guardarDatosSalud);
router.get('/logros', proteger, obtenerLogros);
module.exports = router;

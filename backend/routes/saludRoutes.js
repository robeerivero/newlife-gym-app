const express = require('express');
const router = express.Router();
const {actualizarPasos, actualizarKcalConsumidas, obtenerHistorialSalud,guardarDatosSalud} = require('../controllers/saludController');
const { proteger} = require('../middleware/authMiddleware');

router.post('/pasos', proteger, actualizarPasos);
router.get('/kcal-consumidas', proteger, actualizarKcalConsumidas);
router.get('/historial', proteger, obtenerHistorialSalud);
router.post('/guardar', proteger, guardarDatosSalud);

module.exports = router;

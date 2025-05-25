const express = require('express');
const router = express.Router();
const {actualizarPasos, actualizarKcalConsumidas, DatosSalud, obtenerLogros, obtenerHistorialSalud, guardarDatosSalud} = require('../controllers/saludController');
const { proteger} = require('../middleware/authMiddleware');

router.put('/pasos', proteger, actualizarPasos);
router.get('/kcal-consumidas', proteger, actualizarKcalConsumidas);
router.get('/historial', proteger, obtenerHistorialSalud);
router.post('/guardar', proteger, guardarDatosSalud);
router.get('/dia/:fecha', proteger, DatosSalud); 
module.exports = router;

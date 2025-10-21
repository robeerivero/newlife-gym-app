const express = require('express');
const router = express.Router();
const {actualizarPasos, obtenerHistorialSalud, guardarDatosSalud} = require('../controllers/saludController');
const { proteger} = require('../middleware/authMiddleware');

router.put('/pasos', proteger, actualizarPasos);

router.get('/historial', proteger, obtenerHistorialSalud);
router.post('/guardar', proteger, guardarDatosSalud);

module.exports = router;

const express = require('express');
const { proteger, esAdministrador } = require('../middleware/authMiddleware');
const { crearDieta, modificarDieta, asignarPlatoADieta, eliminarDieta, obtenerDietasPorUsuario, obtenerDietas, obtenerSugerenciasDieta } = require('../controllers/dietasController');

const router = express.Router();

router.post('/', proteger, esAdministrador, crearDieta); // Crear una dieta
router.get('/:idUsuario', proteger, esAdministrador, obtenerDietasPorUsuario);
router.get('/', proteger, obtenerDietas);
router.put('/:idDieta',proteger, esAdministrador, modificarDieta); // Modificar una dieta
router.put('/:idDieta/platos/:idPlato', asignarPlatoADieta); // Asignar un plato a una dieta
router.delete('/:idDieta',proteger, esAdministrador, eliminarDieta); // Eliminar una dieta
router.get('/sugerencias', proteger, obtenerSugerenciasDieta);
module.exports = router;
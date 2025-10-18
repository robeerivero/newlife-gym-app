const express = require('express');
const { proteger, esAdministrador } = require('../middleware/authMiddleware');
const { crearDieta, modificarDieta, asignarPlatoADieta, eliminarDieta, obtenerDietasPorUsuario, obtenerDietas, obtenerSugerenciasDieta } = require('../controllers/dietasController');

const router = express.Router();

// --- RUTAS MÁS ESPECÍFICAS PRIMERO ---
router.get('/sugerencias', proteger, obtenerSugerenciasDieta); // <- Movida aquí
router.get('/', proteger, obtenerDietas); // Ruta general para obtener dietas del usuario logueado

// --- RUTAS DE ADMINISTRACIÓN (Con parámetros después) ---
router.post('/', proteger, esAdministrador, crearDieta); // Crear una dieta (Admin)
router.get('/:idUsuario', proteger, esAdministrador, obtenerDietasPorUsuario); // Obtener dietas de UN usuario (Admin)
router.put('/:idDieta', proteger, esAdministrador, modificarDieta); // Modificar una dieta (Admin)
router.put('/:idDieta/platos/:idPlato', proteger, esAdministrador, asignarPlatoADieta); // Asignar plato (Asumimos Admin)
router.delete('/:idDieta', proteger, esAdministrador, eliminarDieta); // Eliminar una dieta (Admin)

module.exports = router;
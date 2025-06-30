const express = require('express');
const { proteger, esAdministrador } = require('../middleware/authMiddleware');
const {
  crearEjercicio,
  obtenerEjercicios,
  obtenerEjercicioPorId,
  modificarEjercicio,
  eliminarEjercicio,
  eliminarTodosLosEjercicios,
} = require('../controllers/ejerciciosController');

const router = express.Router();

// Rutas para ejercicios
router.post('/', proteger, esAdministrador, crearEjercicio); // Crear un ejercicio
router.get('/', proteger, esAdministrador, obtenerEjercicios); // Obtener todos los ejercicios
router.get('/:idEjercicio', proteger, obtenerEjercicioPorId); // Obtener un ejercicio por ID
router.put('/:idEjercicio', proteger, esAdministrador, modificarEjercicio); // Modificar un ejercicio
router.delete('/:idEjercicio', proteger, esAdministrador, eliminarEjercicio); // Eliminar un ejercicio por ID
router.delete('/', proteger, esAdministrador, eliminarTodosLosEjercicios); // Eliminar todos los ejercicios

module.exports = router;

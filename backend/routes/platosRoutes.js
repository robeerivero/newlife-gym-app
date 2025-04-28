const express = require('express');
const { proteger, esAdministrador } = require('../middleware/authMiddleware');

const { crearPlato, obtenerPlatos, modificarPlato, eliminarPlato, eliminarTodosLosPlatos} = require('../controllers/platosController');

const router = express.Router();

router.post('/', proteger, esAdministrador, crearPlato); // Crear un plato
router.get('/', proteger, esAdministrador, obtenerPlatos); // Buscar un plato por nombre
router.put('/:idPlato', proteger, esAdministrador, modificarPlato); // Modificar un plato
router.delete('/:idPlato', proteger, esAdministrador, eliminarPlato); // Eliminar un plato
router.delete('/', proteger, esAdministrador, eliminarTodosLosPlatos);
module.exports = router;

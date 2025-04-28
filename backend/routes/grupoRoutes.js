const express = require('express');
const { proteger, esAdministrador } = require('../middleware/authMiddleware');
const {
  crearGrupo,
  verGrupo,
  eliminarGrupo,
  anadirUsuarioAGrupo,
} = require('../controllers/gruposController');

const router = express.Router();

// Rutas para grupos
router.post('/', proteger, esAdministrador, crearGrupo); // Crear grupo
router.get('/:idGrupo', proteger, esAdministrador, verGrupo); // Ver grupo
router.delete('/:idGrupo', proteger, esAdministrador, eliminarGrupo); // Eliminar grupo
router.post('/anadirusuario', proteger, esAdministrador, anadirUsuarioAGrupo); // Añadir usuario a grupo

module.exports = router;

const express = require('express');
const { proteger } = require('../middleware/authMiddleware');
const {
  obtenerPerfilUsuario,
  actualizarUsuario,
  obtenerUsuarios,
  obtenerUsuarioPorId,
  crearUsuario,
  eliminarUsuario,
  cambiarContrasena,
  actualizarAvatar
} = require('../controllers/usuariosController');

const router = express.Router();

// Rutas de perfil para usuarios autenticados
router.get('/perfil', proteger, obtenerPerfilUsuario);
router.put('/perfil', proteger, actualizarUsuario);
router.put('/perfil/contrasena', proteger, cambiarContrasena);

// Rutas de administración de usuarios (requiere autenticación)
router.get('/', proteger, obtenerUsuarios);
router.get('/:idUsuario', proteger, obtenerUsuarioPorId);
router.post('/', proteger, crearUsuario);
router.delete('/:idUsuario', proteger, eliminarUsuario);

router.put('/avatar', proteger, actualizarAvatar);
module.exports = router;

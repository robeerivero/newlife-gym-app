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
  actualizarAvatar, 
  obtenerCatalogoPrendas,
  obtenerPrendasDesbloqueadas,
  obtenerProgresoLogros,
  rankingMensual
} = require('../controllers/usuariosController');

const router = express.Router();

// Rutas de perfil para usuarios autenticados
router.get('/perfil', proteger, obtenerPerfilUsuario);
router.put('/perfil', proteger, actualizarUsuario);
router.put('/perfil/contrasena', proteger, cambiarContrasena);
router.put('/avatar', proteger, actualizarAvatar);
router.get('/ranking-mensual', proteger, rankingMensual);
// --- RUTAS DE LOGROS Y PRENDAS ---
router.get('/prendas/catalogo', proteger, obtenerCatalogoPrendas); // Ver todo el catálogo
router.get('/prendas/desbloqueadas', proteger, obtenerPrendasDesbloqueadas); // Ver prendas desbloqueadas
router.get('/prendas/progreso', proteger, obtenerProgresoLogros);

// Rutas de administración de usuarios (requiere autenticación)
router.get('/', proteger, obtenerUsuarios);
router.get('/:idUsuario', proteger, obtenerUsuarioPorId);
router.post('/', proteger, crearUsuario);
router.delete('/:idUsuario', proteger, eliminarUsuario);


module.exports = router;

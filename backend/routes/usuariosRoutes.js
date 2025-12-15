const express = require('express');
const { proteger } = require('../middleware/authMiddleware');
const { esAdministrador } = require('../middleware/authMiddleware');

const {
  obtenerPerfilUsuario,
  actualizarUsuario,
  obtenerUsuarios,
  obtenerUsuarioPorId,
  obtenerGrupos,
  crearUsuario,
  eliminarUsuario,
  cambiarContrasena,
  cambiarContrasenaAdmin,
  actualizarAvatar,
  rankingMensual,
  actualizarDatosMetabolicos,
  actualizarDatosAdmin,
  registrarFcmToken,
} = require('../controllers/usuariosController');

const router = express.Router();

// Rutas de perfil para usuarios autenticados
router.get('/perfil', proteger, obtenerPerfilUsuario);
router.put('/perfil', proteger, actualizarUsuario);
router.put('/perfil/contrasena', proteger, cambiarContrasena);
router.put('/avatar', proteger, actualizarAvatar);
router.get('/ranking-mensual', proteger, rankingMensual);

// --- *** MOVEMOS LA RUTA AQUÍ *** ---
// Ruta calculo kcal objetivo (DEBE IR ANTES DE /:idUsuario)
router.put('/metabolicos', proteger, actualizarDatosMetabolicos);
router.put('/:idUsuario/admin-contrasena', proteger, esAdministrador, cambiarContrasenaAdmin);

router.post('/register-fcm-token', proteger, registrarFcmToken);

// RUTAS DE ADMINISTRACIÓN DE USUARIOS (SOLO ADMINISTRADORES)
router.get('/grupos', proteger, esAdministrador, obtenerGrupos);
router.get('/', proteger, esAdministrador, obtenerUsuarios);
router.get('/:idUsuario', proteger, esAdministrador, obtenerUsuarioPorId);
router.post('/', proteger, esAdministrador, crearUsuario);
router.put('/:idUsuario', proteger, esAdministrador, actualizarDatosAdmin);
router.delete('/:idUsuario', proteger, esAdministrador, (req, res, next) => {
  console.log(`[ROUTE] 7. DELETE /api/usuarios/${req.params.idUsuario} - Petición recibida.`);
  next(); // Pasa al controlador
}, eliminarUsuario);


module.exports = router;
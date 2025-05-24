// backend/routes/adminRoutes.js
const express = require('express');
const { proteger, esAdministrador } = require('../middleware/authMiddleware');
const {
  crearClasesRecurrentes,
  obtenerClases,
  obtenerClasePorId,
  modificarClase,
  eliminarClase,
  eliminarTodasLasClases,
} = require('../controllers/clasesController');

const {
  crearUsuario,
  obtenerUsuarios,
  obtenerUsuarioPorId,
  actualizarUsuario,
  eliminarUsuario,
} = require('../controllers/usuariosController');

const {
  crearGrupo,
  obtenerGrupos,
  verGrupo,
  eliminarGrupo,
  anadirUsuarioAGrupo,
} = require('../controllers/gruposController');

const {
  asignarUsuarioAClase,
  desasignarUsuarioDeClase,
  obtenerClasesPorUsuario,
  obtenerUsuariosPorClase,
  asignarUsuarioAClasesPorDiaYHora,
  obtenerUsuariosConAsistencia
} = require('../controllers/reservasController');

const router = express.Router();

// Rutas relacionadas con la asignación de usuarios a clases
router.post('/reservas/asignar', proteger, esAdministrador, asignarUsuarioAClase); // Asignar usuario a una clase
router.delete('/reservas/clase/:idClase/usuario/:idUsuario', proteger, esAdministrador, desasignarUsuarioDeClase); // Desasignar usuario de una clase
router.get('/reservas/usuario/:idUsuario', proteger, esAdministrador, obtenerClasesPorUsuario); // Obtener clases asignadas a un usuario
router.get('/reservas/clase/:idClase', proteger, esAdministrador, obtenerUsuariosPorClase); // Obtener usuarios asignados a una clase
router.post('/reservas/asignarPorDiaYHora', proteger, esAdministrador, asignarUsuarioAClasesPorDiaYHora); // Asignar usuario a clases por día y hora


// Rutas para clases (solo administradores)
router.post('/clases', proteger, esAdministrador, crearClasesRecurrentes);
router.get('/clases', proteger, esAdministrador, obtenerClases);
router.get('/clases/:idClase', proteger, esAdministrador, obtenerClasePorId);
router.put('/clases/:idClase', proteger, esAdministrador, modificarClase);
router.delete('/clases/:idClase', proteger, esAdministrador, eliminarClase);
router.delete('/clases', proteger, esAdministrador, eliminarTodasLasClases);
router.get('/clases/usuarios/:idClase', proteger, esAdministrador, obtenerUsuariosConAsistencia);

// Rutas para usuarios (solo administradores)
router.post('/usuarios', proteger, esAdministrador, crearUsuario);
router.get('/usuarios', proteger, esAdministrador, obtenerUsuarios);
router.get('/usuarios/:idUsuario', proteger, esAdministrador, obtenerUsuarioPorId);
router.put('/usuarios/:idUsuario', proteger, esAdministrador, actualizarUsuario);
router.delete('/usuarios/:idUsuario', proteger, esAdministrador, eliminarUsuario);

// Rutas para grupos
router.post('/grupos', proteger, esAdministrador, crearGrupo); // Crear grupo
router.get('/grupos', proteger, esAdministrador, obtenerGrupos); // Ver grupos
router.get('/grupos/:idGrupo', proteger, esAdministrador, verGrupo); // Ver grupo
router.delete('/grupos/:idGrupo', proteger, esAdministrador, eliminarGrupo); // Eliminar grupo
router.post('/grupos/anadirusuario', proteger, esAdministrador, anadirUsuarioAGrupo); // Añadir usuario a grupo


module.exports = router;



const express = require('express');
const { proteger, esAdministrador } = require('../middleware/authMiddleware');
const {
  // Usuario normal
  cancelarClase,
  reservarClase,
  registrarAsistencia,
  obtenerAsistenciasPorUsuario,
  // Admin
  asignarUsuarioAClase,
  desasignarUsuarioDeClase,
  obtenerClasesPorUsuario,
  obtenerUsuariosPorClase,
  asignarUsuarioAClasesPorDiaYHora
} = require('../controllers/reservasController');

const router = express.Router();

/* ========= RUTAS PARA USUARIO AUTENTICADO ========= */

// Reservar una clase (usuario normal)
router.post('/reservar', proteger, reservarClase);

// Cancelar una reserva (usuario normal)
router.delete('/cancelar', proteger, cancelarClase);

// Registrar asistencia a una clase (usuario normal)
router.post('/asistencia', proteger, registrarAsistencia);

router.get('/asistencias/:idUsuario', proteger, obtenerAsistenciasPorUsuario);

/* ========= RUTAS SOLO PARA ADMINISTRADORES ========= */

// Asignar usuario a una clase
router.post('/asignar', proteger, esAdministrador, asignarUsuarioAClase);

// Desasignar usuario de una clase
router.delete('/clase/:idClase/usuario/:idUsuario', proteger, esAdministrador, desasignarUsuarioDeClase);

// Obtener clases asignadas a un usuario
router.get('/usuario/:idUsuario', proteger, esAdministrador, obtenerClasesPorUsuario);

// Obtener usuarios asignados a una clase
router.get('/clase/:idClase', proteger, esAdministrador, obtenerUsuariosPorClase);

// Asignar usuario a clases por día y hora
router.post('/asignarPorDiaYHora', proteger, esAdministrador, asignarUsuarioAClasesPorDiaYHora);

module.exports = router;


const express = require('express');
const { proteger, esAdministrador } = require('../middleware/authMiddleware');
const {
  // Acceso usuario y admin
  obtenerProximasClases,
  desregistrarseDeClase,
  obtenerClases,
  // Solo admin
  crearClasesRecurrentes,
  obtenerClasePorId,
  modificarClase,
  eliminarClase,
  eliminarTodasLasClases,
  obtenerUsuariosConAsistencia,
  generarQR
} = require('../controllers/clasesController');

const router = express.Router();

/* ========= RUTAS PARA USUARIO AUTENTICADO (usuario normal y admin) ========= */

// Ver próximas clases del usuario
router.get('/proximas-clases', proteger, obtenerProximasClases);

// Usuario se desregistra de una clase
router.delete('/:idClase/desregistrarse', proteger, desregistrarseDeClase);

// Obtener clases (acceso usuario y admin; la lógica interna puede variar según el rol)
router.get('/', proteger, obtenerClases);

/* ========= RUTAS SOLO PARA ADMINISTRADORES ========= */

// Crear clases recurrentes
router.post('/', proteger, esAdministrador, crearClasesRecurrentes);

// Obtener detalles de una clase concreta
router.get('/:idClase', proteger, esAdministrador, obtenerClasePorId);

// Modificar clase
router.put('/:idClase', proteger, esAdministrador, modificarClase);

// Eliminar clase concreta
router.delete('/:idClase', proteger, esAdministrador, eliminarClase);

// Eliminar todas las clases
router.delete('/', proteger, esAdministrador, eliminarTodasLasClases);

// Ver usuarios con asistencia en una clase
router.get('/usuarios/:idClase', proteger, esAdministrador, obtenerUsuariosConAsistencia);

// Obtener QR de asistencia de una clase
router.get('/generar-qr/:idClase', proteger, esAdministrador, generarQR);

module.exports = router;

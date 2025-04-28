// backend/middleware/authMiddleware.js
const jwt = require('jsonwebtoken');
const Usuario = require('../models/Usuario');

/**
 * Middleware para verificar el token JWT y proteger rutas privadas.
 */
exports.proteger = async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // Extraer el token del encabezado
      token = req.headers.authorization.split(' ')[1];

      // Verificar el token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Buscar al usuario basado en el ID del token
      req.user = await Usuario.findById(decoded.id).select('-contrasena');

      if (!req.user) {
        return res.status(404).json({ mensaje: 'Usuario no encontrado' });
      }

      next(); // Pasar al siguiente middleware o controlador
    } catch (error) {
      console.error('Error al verificar el token:', error);
      return res.status(401).json({ mensaje: 'Token no válido o expirado' });
    }
  } else {
    return res.status(401).json({ mensaje: 'No autorizado, token faltante' });
  }
};

/**
 * Middleware para verificar el rol del usuario.
 * @param {String} role - El rol requerido (por ejemplo, 'admin').
 */
exports.verificarRol = (role) => {
  return (req, res, next) => {
    // Verificar si req.user existe
    if (!req.user) {
      console.log('Usuario no autenticado. req.user no definido.');
      return res.status(401).json({ mensaje: 'No autenticado' });
    }

    // Verificar el rol del usuario
    if (req.user.rol === role) {
      next();
    } else {
      console.log(`Rol no autorizado: ${req.user.rol}`);
      return res.status(403).json({ mensaje: 'Acceso denegado, no tienes permisos suficientes' });
    }
  };
};

/**
 * Middleware específico para verificar si el usuario es administrador.
 */
exports.esAdministrador = exports.verificarRol('admin');



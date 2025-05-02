// backend/middleware/authMiddleware.js
const jwt = require('jsonwebtoken');
const Usuario = require('../models/Usuario');

/**
 * Middleware para verificar el token JWT y proteger rutas privadas.
 */
exports.proteger = async (req, res, next) => {
  let token;
  
  if (req.headers.authorization?.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
    
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      // Verificar expiración inminente (últimos 15 minutos)
      const ahora = Math.floor(Date.now() / 1000);
      if (decoded.exp - ahora < 900) {
        req.tokenExpirando = true;
      }

      req.user = await Usuario.findById(decoded.id).select('-contrasena');
      next();
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({ 
          mensaje: 'Sesión expirada',
          codigo: 'TOKEN_EXPIRADO'
        });
      }
      res.status(401).json({ mensaje: 'Autenticación fallida' });
    }
  } else {
    res.status(401).json({ mensaje: 'Token no proporcionado' });
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



// backend/middleware/authMiddleware.js
const jwt = require('jsonwebtoken');
const Usuario = require('../models/Usuario');

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

exports.verificarRol = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.rol)) {
      return res.status(403).json({
        mensaje: `Rol ${req.user.rol} no tiene acceso a este recurso`
      });
    }
    next();
  };
};
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const Usuario = require('../models/Usuario');

// Generar tokens
const generarToken = (id, rol, expiresIn = '1d') => {
  return jwt.sign({ id, rol }, process.env.JWT_SECRET, { expiresIn });
};

// Inicio de sesión con refresh token
exports.loginConRecordarSesion = async (req, res) => {
  const { correo, contrasena } = req.body;

  try {
    const usuario = await Usuario.findOne({ correo });
    if (!usuario) {
      return res.status(400).json({ mensaje: 'Credenciales inválidas' });
    }

    const contrasenaValida = await bcrypt.compare(contrasena, usuario.contrasena);
    if (!contrasenaValida) {
      return res.status(400).json({ mensaje: 'Credenciales inválidas' });
    }
    
    // Generar access token y refresh token
    const accessToken = generarToken(usuario._id, usuario.rol, '15m'); // 15 minutos
    const refreshToken = generarToken(usuario._id, usuario.rol, '7d'); // 7 días
    
    res.status(200).json({
      mensaje: 'Inicio de sesión exitoso',
      accessToken,
      refreshToken,
      usuario: { id: usuario._id, nombre: usuario.nombre, correo: usuario.correo, rol: usuario.rol },
    });
  } catch (error) {
    console.error('Error al iniciar sesión:', error);
    res.status(500).json({ mensaje: 'Error al procesar la solicitud' });
  }
};

// Renovar el token de acceso
exports.renovarToken = async (req, res) => {
  const { refreshToken } = req.body;

  try {
    if (!refreshToken) {
      return res.status(400).json({ mensaje: 'Token de refresco requerido' });
    }

    const decoded = jwt.verify(refreshToken, process.env.JWT_SECRET);

    const accessToken = generarToken(decoded.id, decoded.rol, '15m'); // Renovar por 15 minutos

    res.status(200).json({ accessToken });
  } catch (error) {
    console.error('Error al renovar el token:', error);
    res.status(401).json({ mensaje: 'Token de refresco inválido o expirado' });
  }
};

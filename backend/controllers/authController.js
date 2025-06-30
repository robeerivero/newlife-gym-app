// backend/controllers/authController.js
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const Usuario = require('../models/Usuario');

const generarToken = (id, rol, expiresIn) => {
  return jwt.sign({ id, rol }, process.env.JWT_SECRET, { expiresIn });
};

exports.login = async (req, res) => {
  const { correo, contrasena, recordar } = req.body;

  console.log('[LOGIN] Datos recibidos:', { correo, recordar });

  try {
    const usuario = await Usuario.findOne({ correo }).select('+contrasena');
    if (!usuario) {
      console.log('[LOGIN] Usuario no encontrado:', correo);
      return res.status(400).json({ mensaje: 'Credenciales inválidas' });
    }

    const contrasenaValida = await bcrypt.compare(contrasena, usuario.contrasena);
    if (!contrasenaValida) {
      console.log('[LOGIN] Contraseña incorrecta para:', correo);
      return res.status(400).json({ mensaje: 'Credenciales inválidas' });
    }

    const accessTokenExpira = recordar ? '365d' : '180d';
    const refreshTokenExpira = '730d';

    const accessToken = generarToken(usuario._id, usuario.rol, accessTokenExpira);
    const refreshToken = generarToken(usuario._id, usuario.rol, refreshTokenExpira);

    console.log('[LOGIN] Usuario autenticado:', usuario.correo);
    console.log('[LOGIN] Tokens generados con expiración:', {
      accessTokenExpira,
      refreshTokenExpira
    });

    res.status(200).json({
      mensaje: 'Inicio de sesión exitoso',
      accessToken,
      refreshToken,
      usuario: {
        id: usuario._id,
        nombre: usuario.nombre,
        correo: usuario.correo,
        rol: usuario.rol
      }
    });
  } catch (error) {
    console.error('[LOGIN] Error inesperado:', error);
    res.status(500).json({ mensaje: 'Error al procesar la solicitud' });
  }
};

exports.renovarToken = async (req, res) => {
  const { refreshToken } = req.body;

  try {
    const decoded = jwt.verify(refreshToken, process.env.JWT_SECRET);
    const usuario = await Usuario.findById(decoded.id);

    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    const newAccessToken = generarToken(usuario._id, usuario.rol, '12h');
    const newRefreshToken = generarToken(usuario._id, usuario.rol, '30d');

    res.status(200).json({
      accessToken: newAccessToken,
      refreshToken: newRefreshToken
    });
  } catch (error) {
    console.error('Error al renovar token:', error);
    res.status(401).json({ mensaje: 'Token de refresco inválido' });
  }
};

exports.verificarToken = async (req, res) => {
  try {
    const usuario = await Usuario.findById(req.user.id).select('-contrasena');
    const nuevoAccessToken = generarToken(usuario._id, usuario.rol, '7d');
    
    res.status(200).json({
      usuario,
      accessToken: nuevoAccessToken
    });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al verificar sesión' });
  }
};
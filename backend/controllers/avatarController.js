// backend/controllers/avatarController.js
const Usuario = require('../models/Usuario');

exports.getAvatar = async (req, res) => {
  try {
    const usuario = await Usuario.findById(req.user.id);
    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }
    res.json(usuario.avatar || {});
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al obtener avatar' });
  }
};

exports.updateAvatar = async (req, res) => {
  try {
    const { gender, skinColor, hair, clothing } = req.body;
    const usuario = await Usuario.findById(req.user.id);
    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }
    usuario.avatar = { gender, skinColor, hair, clothing };
    await usuario.save();
    res.json(usuario.avatar);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al actualizar avatar' });
  }
};

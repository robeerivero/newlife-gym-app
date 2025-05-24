// backend/routes/avatarRoutes.js
const express = require('express');
const router = express.Router();
const { proteger } = require('../middleware/authMiddleware');
const avatarController = require('../controllers/avatarController');

// GET el avatar del usuario logueado
router.get('/', proteger, avatarController.getAvatar);

// PUT actualizar el avatar del usuario logueado
router.put('/', proteger, avatarController.updateAvatar);

module.exports = router;

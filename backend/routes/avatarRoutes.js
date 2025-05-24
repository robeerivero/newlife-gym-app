// backend/routes/avatarRoutes.js
const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const avatarController = require('../controllers/avatarController');

// GET el avatar del usuario logueado
router.get('/', auth, avatarController.getAvatar);

// PUT actualizar el avatar del usuario logueado
router.put('/', auth, avatarController.updateAvatar);

module.exports = router;

// backend/routes/authRoutes.js
const express = require('express');
const { loginConRecordarSesion, renovarToken } = require('../controllers/authController');

const router = express.Router();

// Autenticación con tokens
router.post('/login', loginConRecordarSesion);
router.post('/token/renovar', renovarToken);

module.exports = router;


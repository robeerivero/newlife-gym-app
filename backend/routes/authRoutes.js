// backend/routes/authRoutes.js
const express = require('express');
const { 
  login,
  renovarToken,
  verificarToken 
} = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/login', login);
router.post('/token/renovar', renovarToken);
router.get('/verificar-token', authMiddleware.proteger, verificarToken);

module.exports = router;
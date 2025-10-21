// routes/iaDietaRoutes.js
const express = require('express');
const { proteger, esAdministrador } = require('../middleware/authMiddleware');
const {
  solicitarPlanDieta,
  generarBorradorIA,
  obtenerPlanesPendientes,
  aprobarPlan,
  obtenerMiDietaDelDia,
  obtenerMiPlanDelMes
} = require('../controllers/iaDietaController');

const router = express.Router();

// --- CLIENTE ---
router.put('/solicitud', proteger, solicitarPlanDieta);
router.get('/mi-plan-del-mes', proteger, obtenerMiPlanDelMes);
router.get('/mi-dieta-del-dia', proteger, obtenerMiDietaDelDia);

// --- ADMIN ---
router.get('/admin/planes-pendientes', proteger, esAdministrador, obtenerPlanesPendientes);
router.put('/admin/aprobar/:idPlan', proteger, esAdministrador, aprobarPlan);
router.post('/admin/generar-ia/:idPlan', proteger, generarBorradorIA);

module.exports = router;
// routes/iaEntrenamientoRoutes.js
const express = require('express');
const { proteger, esAdministrador } = require('../middleware/authMiddleware');
const {
  solicitarPlanEntrenamiento,
  generarBorradorIA,
  obtenerPlanesPendientes,
  aprobarPlan,
  obtenerMiRutinaDelDia,
  obtenerMiPlanDelMes
} = require('../controllers/iaEntrenamientoController');

const router = express.Router();

// --- CLIENTE ---
router.put('/solicitud', proteger, solicitarPlanEntrenamiento);
router.get('/mi-plan-del-mes', proteger, obtenerMiPlanDelMes);
router.get('/mi-rutina-del-dia', proteger, obtenerMiRutinaDelDia);

// --- ADMIN ---
router.get('/admin/planes-pendientes', proteger, esAdministrador, obtenerPlanesPendientes);
router.put('/admin/aprobar/:idPlan', proteger, esAdministrador, aprobarPlan);
router.post('/admin/generar-ia/:idPlan', proteger, generarBorradorIA); // Admin puede re-generar

module.exports = router;
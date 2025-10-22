// routes/iaEntrenamientoRoutes.js
const express = require('express');
const { proteger, esAdministrador } = require('../middleware/authMiddleware');
const iaEntrenamientoController = require('../controllers/iaEntrenamientoController');

const router = express.Router();

// --- CLIENTE ---
router.put('/solicitud', proteger, iaEntrenamientoController.solicitarPlanEntrenamiento);
router.get('/mi-plan-del-mes', proteger, iaEntrenamientoController.obtenerMiPlanDelMes);
router.get('/mi-rutina-del-dia', proteger, iaEntrenamientoController.obtenerMiRutinaDelDia);

// --- ADMIN ---
router.get('/admin/planes-pendientes', proteger, esAdministrador, iaEntrenamientoController.obtenerPlanesPendientes);
router.put('/admin/aprobar/:idPlan', proteger, esAdministrador, iaEntrenamientoController.aprobarPlan);
// --- NUEVA RUTA ---
router.get('/admin/plan/:idPlan/prompt', proteger, esAdministrador, iaEntrenamientoController.obtenerPromptParaRevision);
// --- RUTA ELIMINADA ---
// router.post('/admin/generar-ia/:idPlan', ... );

module.exports = router;
// routes/iaDietaRoutes.js
const express = require('express');
const { proteger, esAdministrador } = require('../middleware/authMiddleware');
const iaDietaController = require('../controllers/iaDietaController');

const router = express.Router();

// --- CLIENTE ---
router.put('/solicitud', proteger, iaDietaController.solicitarPlanDieta);
router.get('/mi-plan-del-mes', proteger, iaDietaController.obtenerMiPlanDelMes);
router.get('/mi-dieta-del-dia', proteger, iaDietaController.obtenerMiDietaDelDia);

// --- ADMIN ---
router.get('/admin/planes-pendientes', proteger, esAdministrador, iaDietaController.obtenerPlanesPendientes);
router.put('/admin/aprobar/:idPlan', proteger, esAdministrador, iaDietaController.aprobarPlan);
// --- NUEVA RUTA ---
router.get('/admin/plan/:idPlan/prompt', proteger, esAdministrador, iaDietaController.obtenerPromptParaRevision);
// --- RUTA ELIMINADA ---
// router.post('/admin/generar-ia/:idPlan', ... );

module.exports = router;
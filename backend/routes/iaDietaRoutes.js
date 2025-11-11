// routes/iaDietaRoutes.js
const express = require('express');
const { proteger, esAdministrador } = require('../middleware/authMiddleware');
const iaDietaController = require('../controllers/iaDietaController');

const router = express.Router();

// --- CLIENTE ---
router.put('/solicitud', proteger, iaDietaController.solicitarPlanDieta);
router.get('/mi-plan-del-mes', proteger, iaDietaController.obtenerMiPlanDelMes);
router.get('/mi-dieta-del-dia', proteger, iaDietaController.obtenerMiDietaDelDia);
router.get('/mi-lista-compra', proteger, iaDietaController.obtenerMiListaCompra);


// --- ADMIN ---
router.get('/admin/planes-pendientes', proteger, esAdministrador, iaDietaController.obtenerPlanesPendientes);
router.get('/admin/plan/:idPlan/prompt', proteger, esAdministrador, iaDietaController.obtenerPromptParaRevision);
router.put('/admin/aprobar/:idPlan', proteger, esAdministrador, iaDietaController.aprobarPlan);

// --- ¡NUEVAS RUTAS DE ADMIN! ---

// 1. (Para EDITAR) Obtiene el JSON de un plan para que el admin lo copie
router.get('/admin/plan/:idPlan/para-editar', proteger, esAdministrador, iaDietaController.obtenerPlanParaEditar);

// 2. (Para ELIMINAR) Borra un plan
router.delete('/admin/plan/:idPlan', proteger, esAdministrador, iaDietaController.eliminarPlan);


module.exports = router;
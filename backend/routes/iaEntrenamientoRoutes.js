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
router.get('/admin/plan/:idPlan/prompt', proteger, esAdministrador, iaEntrenamientoController.obtenerPromptParaRevision);

// --- ¡NUEVAS RUTAS DE ADMIN! ---
// (Para listar, editar y borrar planes YA APROBADOS)

// 1. Obtiene los planes ya aprobados
router.get('/admin/planes-aprobados', proteger, esAdministrador, iaEntrenamientoController.obtenerPlanesAprobados);

// 2. (Para EDITAR) Obtiene el JSON de un plan para que el admin lo copie
router.get('/admin/plan/:idPlan/para-editar', proteger, esAdministrador, iaEntrenamientoController.obtenerPlanParaEditar);

// 3. (Para ELIMINAR) Borra un plan
router.delete('/admin/plan/:idPlan', proteger, esAdministrador, iaEntrenamientoController.eliminarPlan);


module.exports = router;
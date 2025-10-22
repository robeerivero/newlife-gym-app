// routes/iaDietaRoutes.js
const express = require('express');
const { proteger, esAdministrador } = require('../middleware/authMiddleware'); // 'esAdministrador' puede que ya no esté aquí si lo quitaste
const iaDietaController = require('../controllers/iaDietaController'); // Importa el objeto completo

const router = express.Router();

// --- CLIENTE ---
router.put('/solicitud', proteger, iaDietaController.solicitarPlanDieta);
router.get('/mi-plan-del-mes', proteger, iaDietaController.obtenerMiPlanDelMes);
router.get('/mi-dieta-del-dia', proteger, iaDietaController.obtenerMiDietaDelDia);

// --- ADMIN / SISTEMA INTERNO ---
router.get('/admin/planes-pendientes', proteger, esAdministrador, iaDietaController.obtenerPlanesPendientes); // Revisa si necesitas 'esAdministrador' aquí
router.put('/admin/aprobar/:idPlan', proteger, esAdministrador, iaDietaController.aprobarPlan); // Revisa si necesitas 'esAdministrador' aquí

// --- ¡¡AQUÍ AÑADIMOS EL LOG!! ---
router.post(
  '/admin/generar-ia/:idPlan',
  proteger, // El middleware proteger se ejecuta primero
  (req, res, next) => { // Añadimos un middleware intermedio SOLO para loguear
    console.log(`[IA Dieta Route] Petición RECIBIDA para generar IA. ID Plan: ${req.params.idPlan}`);
    next(); // Llama a la siguiente función (generarBorradorIA)
  },
  iaDietaController.generarBorradorIA // La función final del controlador
);
// ---------------------------------

module.exports = router;
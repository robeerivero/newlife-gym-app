// utils/notificador.js
const admin = require('firebase-admin');
const Usuario = require('../models/Usuario');
require('dotenv').config();

// Inicializar Firebase Admin
try {
    if (admin.apps.length === 0) {
        const privateKey = process.env.FIREBASE_PRIVATE_KEY
            ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
            : undefined;

        const serviceAccount = {
            project_id: process.env.FIREBASE_PROJECT_ID,
            client_email: process.env.FIREBASE_CLIENT_EMAIL,
            private_key: privateKey
        };

        if (serviceAccount.project_id && serviceAccount.client_email && serviceAccount.private_key) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
            console.log("🔥 Firebase inicializado correctamente con Variables de Entorno.");
        } else {
            console.error("❌ Error: Faltan variables de entorno de FIREBASE.");
        }
    }
} catch (error) {
    console.error('❌ Error inicializando Firebase:', error);
}

/**
 * Envía notificación a un usuario específico
 */
const enviarNotificacion = async (usuarioId, titulo, cuerpo, datosExtra = {}) => {
    try {
        if (admin.apps.length === 0) return;

        const usuario = await Usuario.findById(usuarioId);
        if (!usuario || !usuario.fcmTokens || usuario.fcmTokens.length === 0) return;

        const message = {
            notification: { title: titulo, body: cuerpo },
            data: datosExtra,
            tokens: usuario.fcmTokens
        };

        // ⚠️ CAMBIO AQUÍ: sendMulticast -> sendEachForMulticast
        const response = await admin.messaging().sendEachForMulticast(message);

        // Limpieza de tokens inválidos
        if (response.failureCount > 0) {
            const tokensFallidos = [];
            response.responses.forEach((resp, idx) => {
                if (!resp.success) tokensFallidos.push(usuario.fcmTokens[idx]);
            });
            if (tokensFallidos.length > 0) {
                await Usuario.findByIdAndUpdate(usuarioId, { $pullAll: { fcmTokens: tokensFallidos } });
                console.log(`🧹 Eliminados ${tokensFallidos.length} tokens inválidos.`);
            }
        }
    } catch (error) {
        console.error(`Error enviando notificación a ${usuarioId}:`, error);
    }
};

/**
 * Envía notificación a TODOS los usuarios (Para el mensaje motivador)
 */
const enviarNotificacionMasiva = async (titulo, cuerpo) => {
    try {
        if (admin.apps.length === 0) {
            console.log('⚠️ Firebase no inicializado, saltando notificación.');
            return;
        }

        const usuarios = await Usuario.find({ fcmTokens: { $exists: true, $not: { $size: 0 } } });
        console.log(`🔎 [NOTIFICADOR] Buscando usuarios... Encontrados: ${usuarios.length} usuarios con tokens.`);

        const todosLosTokens = usuarios.flatMap(u => u.fcmTokens);

        if (todosLosTokens.length === 0) {
            console.log('⚠️ [NOTIFICADOR] No se envió nada porque no hay tokens registrados en la DB.');
            return;
        }

        const message = {
            notification: { title: titulo, body: cuerpo },
            tokens: todosLosTokens
        };

        // ⚠️ CAMBIO AQUÍ: sendMulticast -> sendEachForMulticast
        const response = await admin.messaging().sendEachForMulticast(message);

        console.log(`📢 Motivación enviada a ${todosLosTokens.length} dispositivos. Éxitos: ${response.successCount}, Fallos: ${response.failureCount}`);

    } catch (error) {
        console.error('❌ Error en masiva:', error);
    }
};

module.exports = { enviarNotificacion, enviarNotificacionMasiva };
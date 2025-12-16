// utils/notificador.js
const admin = require('firebase-admin');
const Usuario = require('../models/Usuario');
require('dotenv').config(); // Aseguramos que carguen las variables

// Inicializar Firebase Admin usando Variables de Entorno
try {
    if (admin.apps.length === 0) {

        // ⚠️ IMPORTANTE: Render a veces guarda los saltos de línea como texto literal "\n".
        // Este replace asegura que la clave privada tenga el formato correcto RSA.
        const privateKey = process.env.FIREBASE_PRIVATE_KEY
            ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
            : undefined;

        const serviceAccount = {
            project_id: process.env.FIREBASE_PROJECT_ID,
            client_email: process.env.FIREBASE_CLIENT_EMAIL,
            private_key: privateKey
        };

        // Validamos que existan las variables antes de inicializar para evitar errores ocultos
        if (serviceAccount.project_id && serviceAccount.client_email && serviceAccount.private_key) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
            console.log("🔥 Firebase inicializado correctamente con Variables de Entorno.");
        } else {
            console.error("❌ Error: Faltan variables de entorno de FIREBASE (PROJECT_ID, CLIENT_EMAIL o PRIVATE_KEY).");
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
        // Si Firebase no inició por error de credenciales, salimos para no romper el server
        if (admin.apps.length === 0) return;

        const usuario = await Usuario.findById(usuarioId);
        if (!usuario || !usuario.fcmTokens || usuario.fcmTokens.length === 0) return;

        const message = {
            notification: { title: titulo, body: cuerpo },
            data: datosExtra,
            tokens: usuario.fcmTokens
        };

        const response = await admin.messaging().sendMulticast(message);

        // Limpieza de tokens inválidos
        if (response.failureCount > 0) {
            const tokensFallidos = [];
            response.responses.forEach((resp, idx) => {
                if (!resp.success) tokensFallidos.push(usuario.fcmTokens[idx]);
            });
            if (tokensFallidos.length > 0) {
                await Usuario.findByIdAndUpdate(usuarioId, { $pullAll: { fcmTokens: tokensFallidos } });
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

        // 👇 LOG NUEVO: Para saber cuántos usuarios encontró
        console.log(`🔎 [NOTIFICADOR] Buscando usuarios... Encontrados: ${usuarios.length} usuarios con tokens.`);

        const todosLosTokens = usuarios.flatMap(u => u.fcmTokens);

        if (todosLosTokens.length === 0) {
            // 👇 LOG NUEVO: Aviso explícito
            console.log('⚠️ [NOTIFICADOR] No se envió nada porque no hay tokens registrados en la DB.');
            return;
        }

        const message = {
            notification: { title: titulo, body: cuerpo },
            tokens: todosLosTokens
        };

        const response = await admin.messaging().sendMulticast(message);
        console.log(`📢 Motivación enviada a ${todosLosTokens.length} dispositivos. Éxitos: ${response.successCount}, Fallos: ${response.failureCount}`);

    } catch (error) {
        console.error('Error en masiva:', error);
    }
};

module.exports = { enviarNotificacion, enviarNotificacionMasiva };
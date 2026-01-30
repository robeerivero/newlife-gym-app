// 1. CARGA DE DEPENDENCIAS Y CONEXIÓN
require('dotenv').config(); // Para leer tu MONGO_URI del archivo .env
const mongoose = require('mongoose');
const Reserva = require('./models/Reserva');
const Clase = require('./models/Clase'); 

// Conectamos a la BD manualmente para este script
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('✅ Conectado a la base de datos. Buscando...');
    ejecutarConsulta();
  })
  .catch(err => console.error('❌ Error de conexión:', err));

// 2. TU LÓGICA (La misma que hiciste)
async function buscarExcepciones() {
  const usuarioId = '69679df0ad82ccbeef1449e2'; // ID de la chica

  console.log(`🔍 Buscando reservas para el usuario: ${usuarioId}`);

  // Buscamos todas las reservas del usuario y traemos los datos de la clase
  const reservas = await Reserva.find({ usuario: usuarioId }).populate('clase');

  // Filtramos manualmente
  const reservasDistintas = reservas.filter(r => {
    const c = r.clase;
    if (!c) return false; // Si la clase se borró, ignorar

    const diasEstandar = ['Lunes', 'Miércoles', 'Viernes'];
    const esDiaEstandar = diasEstandar.includes(c.dia);
    const esHoraEstandar = c.horaInicio === '18:00';

    // Queremos las que NO cumplan la combinación "Día Estándar Y Hora Estándar"
    // Es decir: O es otro día, O es otra hora.
    return !(esDiaEstandar && esHoraEstandar);
  });

  return reservasDistintas;
}

// 3. EJECUCIÓN Y SALIDA
async function ejecutarConsulta() {
  try {
    const resultados = await buscarExcepciones();
    
    console.log('\nResultados encontrados: ' + resultados.length);
    console.log('------------------------------------------------');
    
    resultados.forEach(r => {
      // Mostramos algo legible en la consola
      console.log(`📅 ${r.clase.dia} - ⏰ ${r.clase.horaInicio} (Fecha: ${r.clase.fecha.toISOString().split('T')[0]})`);
    });
    
    console.log('------------------------------------------------');

  } catch (error) {
    console.error("Hubo un error:", error);
  } finally {
    // Cerramos la conexión para que el script termine y no se quede pensando
    mongoose.connection.close();
    process.exit();
  }
}
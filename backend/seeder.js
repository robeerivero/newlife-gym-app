const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');
const connectDB = require('./config/db'); // Importa tu función de conexión

// Importa los modelos que quieras poblar
const Plato = require('./models/Plato'); 
// Podrías añadir también Ejercicio, Video, etc.

// Configurar variables de entorno
dotenv.config();

// Conectar a la BD
connectDB();

// Leer el archivo JSON
const platos = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'data', 'platos.json'), 'utf-8')
);

// Función para importar/actualizar los platos
const importarPlatos = async () => {
  try {
    let contadorCreados = 0;
    let contadorActualizados = 0;

    // Usamos Promesas para manejar todas las operaciones
    const operaciones = platos.map(plato => {
      // Esta es la operación "Upsert":
      // 1. Busca un plato con el mismo 'nombre'.
      // 2. Si lo encuentra, lo actualiza ($set: plato).
      // 3. Si no lo encuentra, lo crea (upsert: true).
      return Plato.updateOne(
        { nombre: plato.nombre }, // El filtro para buscar
        { $set: plato },          // Los datos a insertar/actualizar
        { upsert: true }           // La opción mágica
      ).then(resultado => {
        if (resultado.upsertedCount > 0) {
          contadorCreados++;
        } else if (resultado.modifiedCount > 0) {
          contadorActualizados++;
        }
      });
    });

    // Esperar a que todas las operaciones terminen
    await Promise.all(operaciones);
    
    console.log('--- 🥑 Sincronización de Platos Completada ---');
    console.log(`✅ ${contadorCreados} platos nuevos creados.`);
    console.log(`🔄 ${contadorActualizados} platos existentes actualizados.`);
    console.log('-------------------------------------------');

    process.exit();
  } catch (error) {
    console.error('❌ Error al importar platos:', error);
    process.exit(1);
  }
};

// Función para eliminar TODOS los platos (¡con cuidado!)
const eliminarPlatos = async () => {
  try {
    await Plato.deleteMany();
    console.log('--- 🗑️ Platos Eliminados ---');
    process.exit();
  } catch (error) {
    console.error('❌ Error al eliminar platos:', error);
    process.exit(1);
  }
};

// Lógica para ejecutar desde la terminal
// process.argv[2] es el argumento que le pasamos (ej: --importar)
if (process.argv[2] === '--importar') {
  importarPlatos();
} else if (process.argv[2] === '--eliminar') {
  eliminarPlatos();
} else {
  console.log('Por favor, usa --importar o --eliminar');
  process.exit();
}
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Usuario = require('./models/Usuario');

dotenv.config();

const PASSWORD_DEFAULT = '123456';
const AVATAR_DEFECTO = {
  "topType": 4, "accessoriesType": 0, "hairColor": 1, "facialHairType": 0,
  "facialHairColor": 1, "clotheType": 4, "eyeType": 0, "eyebrowType": 0,
  "mouthType": 1, "skinColor": 1, "clotheColor": 1, "style": 0, "graphicType": 0
};

// HE CORREGIDO LOS NOMBRES (Solo 1er apellido) Y CORREOS
const usuariosChat = [
  // --- BLOQUE 1 ---
  { nombre: 'Natalia Carmona', correo: 'Nataliapinto876@gmail.com', grupo: 'Pilates 19:00' },
  { nombre: 'Eva Rodríguez', correo: 'evaromar@gmail.com', grupo: 'Pilates 19:00' },
  { nombre: 'Mercedes Velazquez', correo: 'Mercedesvelazquezgarces@gmail.com', grupo: 'LMV Funcional 9:00' },
  { nombre: 'Petri Gutiérrez', correo: 'petrigutierrezreyes@gmail.com', grupo: 'LMV Funcional 9:00' },
  { nombre: 'Verónica Aragon', correo: 'veronica.aragondominguez@gmail.com', grupo: 'LMV Funcional 9:00' },
  { nombre: 'Inma Rodríguez', correo: 'inmarodriguezortiz91@gmail.com', grupo: 'LMV Funcional 9:00' },
  { nombre: 'Montse Rivero', correo: 'injatain@gmail.com', grupo: 'Pilates 19:00' },
  { nombre: 'Ana Rodríguez', correo: 'Anarpantoja@gmail.com', grupo: 'Funcional 8:00' },

  // --- BLOQUE 2 ---
  { nombre: 'Nieves Macías', correo: 'niepetobi3@gmail.com', grupo: 'Pilates 11:00' },
  { nombre: 'Alba Freire', correo: 'nescuel@gmail.com', grupo: 'Funcional 10:00' },
  { nombre: 'Angeles Rodriguez', correo: 'Angelesrodriguez66@gmail.com', grupo: 'Pilates 19:00' },
  { nombre: 'Nerea Muriel', correo: 'nerealealmuriel.97@gmail.com', grupo: 'Funcional 10:00' },
  { nombre: 'Manuela Galindo', correo: 'manoligalindo1@gmail.com', grupo: 'Funcional 10:00' },
  { nombre: 'Maripaz Doblas', correo: 'mpdoblas.1976@gmail.com', grupo: 'Funcional 18:30' },
  { nombre: 'María del Carmen Sánchez', correo: 'mariadelcarmensanchezcabezadev@gmail.com', grupo: 'Pilates 10:00' },
  { nombre: 'Adriana Montiel', correo: 'montielperezadriana45@gmail.com', grupo: 'Pilates 17:30' },
  { nombre: 'Lola Camacho', correo: 'camachomelendezlola@gmail.com', grupo: 'MJ Funcional 9:00' }
];

const importarChatFinal = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Conectado a MongoDB');

    let creados = 0;
    let existentes = 0;

    for (const u of usuariosChat) {
      // 1. Limpieza: Correo a minúsculas y quitar espacios extra
      const emailLimpio = u.correo.trim().toLowerCase(); 
      const nombreLimpio = u.nombre.trim();

      // 2. Verificar duplicados
      const existe = await Usuario.findOne({ correo: emailLimpio });
      if (existe) {
        console.log(`🔹 Ya existe: ${nombreLimpio} -> Se salta.`);
        existentes++;
        continue;
      }

      // 3. Definir tipo de clase (array)
      let tipos = ['funcional']; 
      if (u.grupo.toLowerCase().includes('pilates')) tipos = ['pilates'];
      if (u.grupo.toLowerCase().includes('funcional')) tipos = ['funcional'];
      if (u.grupo.includes('MJ')) tipos = ['funcional']; 

      // 4. Crear Usuario
      try {
        await Usuario.create({
          nombre: nombreLimpio,
          correo: emailLimpio, // Aquí ya va en minúscula
          contrasena: PASSWORD_DEFAULT,
          rol: 'cliente',
          nombreGrupo: u.grupo,
          tiposDeClases: tipos,
          avatar: AVATAR_DEFECTO,
          haPagado: false,
          esPremium: false
        });
        console.log(`✅ Creado: ${nombreLimpio} (${u.grupo})`);
        creados++;
      } catch (err) {
        console.error(`❌ Error creando a ${nombreLimpio}:`, err.message);
      }
    }

    console.log(`\n========================================`);
    console.log(`RESUMEN IMPORTACIÓN CHAT (FINAL)`);
    console.log(`✅ Nuevos usuarios creados: ${creados}`);
    console.log(`🔹 Usuarios ya existentes: ${existentes}`);
    console.log(`========================================`);

    mongoose.connection.close();
    process.exit(0);

  } catch (error) {
    console.error('Error fatal:', error);
    process.exit(1);
  }
};

importarChatFinal();
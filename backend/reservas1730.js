const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Usuario = require('./models/Usuario');
const Clase = require('./models/Clase');
const Reserva = require('./models/Reserva');

dotenv.config();

// --- CONFIGURACIÓN DE DÍAS ---
const DIAS_LMV = ['Lunes', 'Miércoles', 'Viernes'];
const DIAS_MJ = ['Martes', 'Jueves'];
const DIAS_LM = ['Lunes', 'Miércoles']; // Específico para Pilates 17:30

const generarReservas1730 = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Conectado a MongoDB');

    // 🔴 FILTRO CLAVE: Solo buscamos usuarios cuyo grupo contenga "17:30"
    const usuarios = await Usuario.find({ 
      nombreGrupo: { $regex: '17:30', $options: 'i' },
      rol: 'cliente'
    });

    console.log(`🔍 Se encontraron ${usuarios.length} usuarios en grupos de las 17:30.`);

    let reservasCreadas = 0;
    let errores = 0;

    for (const usuario of usuarios) {
      const grupo = usuario.nombreGrupo.trim();
      const grupoLower = grupo.toLowerCase();
      
      let diasObjetivo = [];
      let tipoClase = ''; 
      let horaObjetivo = '17:30'; // Ya sabemos la hora fija

      // LÓGICA ESPECÍFICA PARA 17:30
      if (grupoLower.includes('pilates')) {
        tipoClase = 'pilates';
        // Regla que definiste: Pilates 17:30 son Lunes y Miércoles
        diasObjetivo = DIAS_LM; 
      } else if (grupoLower.includes('funcional')) {
        tipoClase = 'funcional';
        // Si hubiera funcional a esta hora, aplicaría regla general LMV o la que tú digas
        diasObjetivo = DIAS_LMV; 
      } else {
        console.warn(`⚠️ Grupo ${grupo} no reconocido como Pilates ni Funcional.`);
        continue;
      }

      // --- BUSCAR CLASES ---
      const fechaHoy = new Date();
      fechaHoy.setHours(0,0,0,0);

      const clasesDisponibles = await Clase.find({
        nombre: tipoClase,
        horaInicio: horaObjetivo,
        dia: { $in: diasObjetivo },
        fecha: { $gte: fechaHoy }
      });

      if (clasesDisponibles.length === 0) {
        console.warn(`⚠️ No hay clases creadas para ${tipoClase} a las ${horaObjetivo} (${diasObjetivo.join(', ')})`);
        continue;
      }

      // --- CREAR RESERVAS ---
      for (const clase of clasesDisponibles) {
        const reservaExiste = await Reserva.findOne({
          usuario: usuario._id,
          clase: clase._id
        });

        if (!reservaExiste) {
          try {
            await Reserva.create({
              usuario: usuario._id,
              clase: clase._id,
              asistio: false
            });

            // Restar cupo
            await Clase.findByIdAndUpdate(clase._id, { $inc: { cuposDisponibles: -1 } });

            reservasCreadas++;
            process.stdout.write('.');
          } catch (err) {
            console.error(`❌ Error reservando:`, err.message);
            errores++;
          }
        }
      }
    }

    console.log('\n\n========================================');
    console.log('RESUMEN ACTUALIZACIÓN 17:30');
    console.log('========================================');
    console.log(`✅ Nuevas reservas: ${reservasCreadas}`);
    console.log(`❌ Errores: ${errores}`);
    console.log('========================================');

    mongoose.connection.close();
    process.exit(0);

  } catch (error) {
    console.error('Error fatal:', error);
    process.exit(1);
  }
};

generarReservas1730();
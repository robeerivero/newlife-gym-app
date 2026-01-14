const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Usuario = require('./models/Usuario');
const Clase = require('./models/Clase');
const Reserva = require('./models/Reserva');

dotenv.config();

// --- CONFIGURACIÓN DE DÍAS ---
const DIAS_LMV = ['Lunes', 'Miércoles', 'Viernes'];
const DIAS_MJ = ['Martes', 'Jueves'];
const DIAS_LM = ['Lunes', 'Miércoles'];

const generarReservasMasivas = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Conectado a MongoDB');

    // 1. Obtener todos los usuarios que tengan grupo asignado
    // (Filtramos admins o usuarios sin grupo para no perder tiempo)
    const usuarios = await Usuario.find({ 
      nombreGrupo: { $ne: null, $exists: true },
      rol: 'cliente'
    });

    console.log(`🔍 Encontrados ${usuarios.length} usuarios con grupo para procesar.`);

    let reservasCreadas = 0;
    let errores = 0;
    let clasesNoEncontradas = new Set(); // Para loguear qué clases faltan

    for (const usuario of usuarios) {
      const grupo = usuario.nombreGrupo.trim();
      const grupoLower = grupo.toLowerCase();

      // --- DETERMINAR DÍAS Y HORA ---
      let diasObjetivo = [];
      let tipoClase = ''; 
      
      // Extraer hora con Regex (ej: busca "18:00", "9:00", "09:30")
      const matchHora = grupo.match(/(\d{1,2}:\d{2})/);
      let horaObjetivo = matchHora ? matchHora[1] : null;

      // Si la hora es ej: "9:00", la convertimos a "09:00" por si acaso en la BD está con 0 inicial
      if (horaObjetivo && horaObjetivo.split(':')[0].length === 1) {
        horaObjetivo = '0' + horaObjetivo;
      }

      if (!horaObjetivo) {
        console.warn(`⚠️ Usuario ${usuario.nombre} tiene grupo "${grupo}" sin hora reconocible. Saltando.`);
        continue;
      }

      // LÓGICA DE ASIGNACIÓN SEGÚN TUS REGLAS
      
      // 1. Pilates
      if (grupoLower.includes('pilates')) {
        tipoClase = 'pilates';
        if (horaObjetivo === '17:30') {
          diasObjetivo = DIAS_LM; // Excepción: Lunes y Miércoles
        } else {
          diasObjetivo = DIAS_MJ; // Regla general Pilates: Martes y Jueves
        }
      }
      // 2. Funcional
      else if (grupoLower.includes('funcional')) {
        tipoClase = 'funcional';
        // Excepciones específicas mencionadas
        if (grupo.includes('18:00') || grupo.includes('MJ') || grupoLower.includes('mj')) {
           diasObjetivo = DIAS_MJ;
        } else {
           // Regla general Funcional: Lunes, Miércoles, Viernes
           diasObjetivo = DIAS_LMV; 
        }
      } else {
        console.warn(`⚠️ Grupo no reconocido (ni pilates ni funcional): "${grupo}". Saltando.`);
        continue;
      }

      // --- BUSCAR CLASES EN EL FUTURO ---
      // Buscamos todas las clases futuras que coincidan con Tipo, Hora y Días permitidos
      const fechaHoy = new Date();
      fechaHoy.setHours(0,0,0,0);

      const clasesDisponibles = await Clase.find({
        nombre: tipoClase,
        horaInicio: horaObjetivo,
        dia: { $in: diasObjetivo },
        fecha: { $gte: fechaHoy } // Solo clases futuras
      });

      if (clasesDisponibles.length === 0) {
        clasesNoEncontradas.add(`${tipoClase} - ${horaObjetivo} (${diasObjetivo.join(', ')})`);
        continue;
      }

      // --- CREAR RESERVAS ---
      for (const clase of clasesDisponibles) {
        // Verificar si ya tiene reserva para evitar duplicados
        const reservaExiste = await Reserva.findOne({
          usuario: usuario._id,
          clase: clase._id
        });

        if (!reservaExiste) {
          try {
            // Crear la reserva
            await Reserva.create({
              usuario: usuario._id,
              clase: clase._id,
              asistio: false
            });

            // Actualizar cupos (Restar 1)
            // Nota: No verificamos si hay cupo (<=0) porque es una importación inicial forzosa,
            // pero si quisieras respetar cupos, añade un if (clase.cuposDisponibles > 0)
            await Clase.findByIdAndUpdate(clase._id, { $inc: { cuposDisponibles: -1 } });

            reservasCreadas++;
            process.stdout.write('.'); // Feedback visual de progreso
          } catch (err) {
            console.error(`❌ Error reservando para ${usuario.nombre}:`, err.message);
            errores++;
          }
        }
      }
    }

    console.log('\n\n========================================');
    console.log('RESUMEN DE RESERVAS MASIVAS');
    console.log('========================================');
    console.log(`✅ Reservas nuevas creadas: ${reservasCreadas}`);
    console.log(`❌ Errores: ${errores}`);
    
    if (clasesNoEncontradas.size > 0) {
      console.log('⚠️ NO SE ENCONTRARON CLASES PARA ESTOS GRUPOS (Revisa si las creaste en el calendario):');
      clasesNoEncontradas.forEach(c => console.log(`   - ${c}`));
    }
    console.log('========================================');

    mongoose.connection.close();
    process.exit(0);

  } catch (error) {
    console.error('Error fatal:', error);
    process.exit(1);
  }
};

generarReservasMasivas();
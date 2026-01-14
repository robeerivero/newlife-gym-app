const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Usuario = require('./models/Usuario'); // Asegúrate de que la ruta sea correcta

// Cargar variables de entorno
dotenv.config();

// --- CONFIGURACIÓN ---
const PASSWORD_DEFAULT = '123456'; // El modelo se encarga de encriptarla
const AVATAR_DEFECTO = {
  "topType": 4,
  "accessoriesType": 0,
  "hairColor": 1,
  "facialHairType": 0,
  "facialHairColor": 1,
  "clotheType": 4,
  "eyeType": 0,
  "eyebrowType": 0,
  "mouthType": 1,
  "skinColor": 1,
  "clotheColor": 1,
  "style": 0,
  "graphicType": 0
};

// He limpiado un poco tu lista original (quitando comas extras, palabras 'email', y corrigiendo .con/.cin)
const RAW_DATA = `
Funcional 18:00
Patricia Otero Patriyuni37@hotmail.com
Vanessa Rodríguez Vanesurrirodri@gmail.com
Eva María Sánchez evamasanchez85@gmail.com
Ana Baro ambaro237@gmail.com
Almudena Torti almudenatortipalmero@gmail.com
María José Ramos mariajoramos@hotmail.es
Manuela Illazquez manoliillazquezpanes@gmail.com
Esther Vázquez esvazqal@hotmail.com
Mónica Piñero mopica14@gmail.com
Mamen García manme23@hotmail.com
Vanesa Otero vaneotepri8@gmail.com
Aurora Toledo agtoledogomez@gmail.com
Gema Rodríguez jrodsan739@g.educaand.es
Natividad Torres jovena_antares@hotmail.com
Regli Domínguez regli_dguez@hotmail.com
Natalia Brenes nataliabrenes1983@gmail.com

Funcional 18:30
Mari Paz Vela maripaz8340@gmail.com
Raquel Sibon raquel.sibon@hotmail.com
Paula López pauladeviladecans@hotmail.com
María Manzano marimanza14@gmail.com
Juani Grimaldi Juanigrimaldiguerrero1@gmail.com
Oliva Ramos Jorge olivarjedu@gmail.com
Maria Jose Gonzalez majogoro66@gmail.com
Cristina Martín crismg1993@outlook.com
Ana Belén Ramírez Belmar31@hotmail.com
Lucía Braza luciabrazaramirez@gmail.com
Isabel Collantes icollantes.medina@gmail.com
Mari Galván mgalvan956@gmail.com
Yolanda Troya yotrofe@gmail.com
Ana Macías anamb2204@gmail.com
Ana Giráldez anagiraldez1990@gmail.com

Funcional 19:30
Mari Angeles Velázquez mavelazquezgomez@hotmail.es
M.Ángeles Ortega Marikansita@gmail.com
Javier Parro Javierparroperdigones@gmail.com
Antonia Alcazar antoniaalcazarcastellano@gmail.com
Montse Sánchez ducatimonster18@hotmail.com
Raquel Torrejimeno rakitorru@gmail.com
Rocio González rociogleztt61@gmail.com
Telma queiros Telma_queiros@hotmail.com
Elena Garcia ele.garciabrea@gmail.com

Funcional 20:30
Cristina Ruiz cristinaruizdguez@gmail.com
Almudena Yeste almuyesca@gmail.com
Juan Antonio Aragón 81juanito@gmail.com
Jesús García garciavj7@gmail.com
Tatiana Mesa tmesarivero@gmail.com
Iván Belizón ivan.belizon@gmail.com
Noelia Mesa nmesarivero@gmail.com
Eva flores Evaff86@gmail.com 
Ana Gutiérrez anacristinaguve@gmail.com
Celia Lambiris Manzanedo celilambi@gmail.com 
Vicente Palmero Aragón ozullama@gmail.com
Renan Garcia Serra rserra85@icloud.com
Lola Suárez lolasuarezvirues@gmail.com
Lola Ojeda lolaojedaguerrero7@gmail.com
Anabel Carballat Carbonell anabel.carballat@gmail.com
Joaquín David Soto davidsp5@hotmail.es

Funcional 8:00
Gloria Ríos gloria_rios86@hotmail.es
Patricia Valdivia iciapatri@gmail.com
Noelia Baro antoniogarabito@hotmail.es
Esperanza Romero esperanci76@gmail.com
Estefanía de la llave Delallaveguerreroestefania@gmail.com
Inma Rodríguez Inmarpantoja@gmail.com 
Nieves Barrera mijitarcos@gmail.com
Angeles Enriquez Montero angelesenriquez18@gmail.com
Ana Tocino Gómez anatocinogomez@gmail.com
María José Sánchez mj_sanchez_v@hotmail.com
Cristina Sánchez Roldán cristinasanchezroldan5@gmail.com
Maria Victoria Garret Lozano mariagarretlozano@gmail.com
Antonia Pérez Ramos ivanpagodelhumo@gmail.com
Antonio Ruiz antoniochiclana@hotmail.com
Mercedes Benítez mercebr72@gmail.com

LMV Funcional 9:00
Sonia Carballat Kukinachicla@hotmail.com
Cristina Alcedo Misol13@hotmail.com
Carmen Márquez Aragón carmenmarquezaragon@gmail.com
María Benítez maria1990.mbda@gmail.com
Lola Gómez Lolagomcab@gmail.com
Estefanía Morales arianaestefania16@gmail.com
Irene Torres irenetb1983@gmail.com
Yolanda Macías yoli_miji@hotmail.com
Nazaret Sánchez Nazaret.nepa89@gmail.com
Silvia Muñoz Pardo silviamunozpardo@gmail.com
Patricia de la Llave guerrero delallaveguerreropatricia@gmail.com
Mercedes Velazquez Garcés Mercedesvelazquezgarces@gmail.com
Petri Gutiérrez petrigutierrezreyes@gmail.com
Verónica Aragon veronica.aragondominguez@gmail.com
Inma rodriguez inmarodriguezortiz91@gmail.com

Funcional 10:00
Ana García anigarmed67@gmail.com
Ana Fernández ana.fernandezgarcia91@gmail.com
Isabel María Rivera isabelriveco@hotmail.com
María del mar López nieblapelusa@gmail.com
Carmen Díaz morfeo7092@gmail.com
Celia Vital celiavitaldafonseca@gmail.com
Mari Santos santisanto305.sm@gmail.com

MJ Funcional 9:00
Isabel Maria Lago isabel.lago1977@gmail.com
Magdalena Aragón magdalenabizcochin1967@gmail.com
Patricia Rodriguez Patriciarodriguezvaldivia08@gmail.com
Cristina Rodríguez cristina161090@gmail.com
M. Carmen Alcázar alcázarcastellano@gmail.com
Cristina Rodríguez MV chrisita94@gmail.com
Charo Ariza charota@gmail.com
Susana Bernal susana261177@hotmail.com

Pilates 17:30
Marian Piulestan mariaday80@gmail.com
Maria del Mar Ruiz mmruizv@hotmail.com
Manuela Valverde mvalverdeguerrero@gmail.com
Mari Carmen Pérez mariph1978@gmail.com
Rosa María Mora rosi21.rmn@gmail.com
María Luisa Real mluisarealtorres1@gmail.com 
María Inés Torres mariainestorresrodriguez1@gmail.com
Rosario Aragón rosarioaragon67@gmail.com
Teresa Hernández opticadiz@gmail.com
M. Carmen Galván carmentier1@hotmail.com
Ángela Pellicer angelapellicermoreno25@gmail.com
Sonia Butrón soniabutronperez@gmail.com

Pilates 8:00
Ana Rodríguez anamari_77@hotmail.com
Demi Morin demimorin7@gmail.com
Belén Chaves belenchavesverdugo20@gemail.com
Eloísa Aragón eloisaaraga@gmail.com 
Maria Herrera mary7ha@gmail.com
Pepi Ponce josefaponce70@gmail.com
María del Carmen Pedrosa carmen.pedrosi@hotmail.com
Alicia Bernal aliciabernal1974@gmail.com
Fali suazo onocasaeris@gmail.com

Pilates 10:00
Toñi Ortega ortegaflorin@gmail.com
Ana Guerra anamariaguerra020964@icloud.com
Paqui Altamirano altami2003@gmail.com
Paqui Ortega manuali65@gmail.com
Manoli Ruiz manoliruizvela@gmail.com
Susana Aragón anko7351@gmail.com
Ana María Jorge anitamaria298@gmail.com
Rosa María González rosicosturera1971@gmail.com
Encarni Garcés encarnigarcesrufi@gmail.com
Irene Jorge irennej82@gmail.com
Manuela Ruiz González manuelarugo123@gmail.com

Pilates 19:00
Maleni Guerrero maleniguerrero@hotmail.com
Manoli Verdugo manolimejico@gmail.com
Remedios Gómez Ramos remedios1971gomez@gmail.com
Soraya Pérez sorytarabat@hotmail.com
Chari Pérez xarileoncia@gmail.com
María José Verdugo verdugorodriguezmariajose@gmail.com
Natalia Carmona Nataliapinto876@gmail.com
Eva Rodríguez evaromar@gmail.com
Montse Rivero injatain@gmail.com

Pilates 20:00
Ana Polanco apolancor@hotmail.es
Eugenia Carballat eugeniachicla@gmail.com
Patricia Carmona patriciacarmonazuaza@gmail.com
Angeles Álvarez angelesalme25@gmail.com
Maria del Mar Puget marpuget@hotmail.com
Nieves Aragón nevus@outlook.es
Virtudes Vela Virtudesvelazajara@icloud.com
José Antonio García tallerja@hotmail.com
Vanesa Collantes vanesacolsol@gmail.com
MariCarmen Bellido mabelba@gmail.com
Antonio Jesús Ruíz anjerusa89@gmail.com
Mayca Zuaza mayca1976@hotmail.es

Pilates 11:00
Francisca Miranda paquimiran@hotmail.com
Claire Mrs.chatterbox@orange.fr
`;

const importarUsuarios = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Conectado a MongoDB');

    const lineas = RAW_DATA.split('\n');
    let grupoActual = '';
    let contadorCreados = 0;
    let contadorErrores = 0;
    let contadorExistentes = 0;

    for (let linea of lineas) {
      linea = linea.trim();
      if (!linea) continue;

      // 1. Detectar si la línea es un Grupo (No tiene @)
      if (!linea.includes('@')) {
        grupoActual = linea;
        console.log(`\n📂 PROCESANDO GRUPO: ${grupoActual}`);
        continue;
      }

      // 2. Extraer Email y Nombre
      // Usamos regex para encontrar el email al final de la línea
      const match = linea.match(/\s+([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)/);
      
      let email = '';
      let nombre = '';

      if (match) {
        email = match[1];
        // El nombre es todo lo que está antes del email
        nombre = linea.substring(0, match.index).trim();
      } else {
        console.warn(`⚠️ No se pudo parsear la línea: "${linea}"`);
        continue;
      }

      // Limpieza extra del nombre (quitar comas finales si las hay)
      if (nombre.endsWith(',')) nombre = nombre.slice(0, -1);

      // 3. Determinar Tipo de Clase basado en el Grupo
      const tipoLower = grupoActual.toLowerCase();
      let tiposDeClases = [];
      if (tipoLower.includes('funcional')) tiposDeClases.push('funcional');
      if (tipoLower.includes('pilates')) tiposDeClases.push('pilates');
      // Si el grupo no dice explícitamente, asignamos ambos por seguridad o uno por defecto
      if (tiposDeClases.length === 0) tiposDeClases = ['funcional']; 

      // 4. Verificar existencia
      const existe = await Usuario.findOne({ correo: email });
      if (existe) {
        console.log(`🔹 El usuario ya existe: ${email} (${nombre})`);
        contadorExistentes++;
        continue;
      }

      // 5. Crear Usuario
      try {
        const nuevoUsuario = new Usuario({
          nombre: nombre,
          correo: email,
          contrasena: PASSWORD_DEFAULT, // Se hashea en el pre-save del modelo
          rol: 'cliente',
          nombreGrupo: grupoActual,
          tiposDeClases: tiposDeClases,
          avatar: AVATAR_DEFECTO,
          haPagado: false,
          esPremium: false
        });

        await nuevoUsuario.save();
        console.log(`✅ Creado: ${nombre} - ${grupoActual}`);
        contadorCreados++;
      } catch (error) {
        console.error(`❌ Error creando ${email}:`, error.message);
        contadorErrores++;
      }
    }

    console.log(`\n========================================`);
    console.log(`RESUMEN DE IMPORTACIÓN`);
    console.log(`========================================`);
    console.log(`✅ Creados exitosamente: ${contadorCreados}`);
    console.log(`🔹 Ya existían: ${contadorExistentes}`);
    console.log(`❌ Errores: ${contadorErrores}`);
    console.log(`========================================`);

    mongoose.connection.close();
    process.exit(0);

  } catch (error) {
    console.error('Error fatal en el script:', error);
    process.exit(1);
  }
};

importarUsuarios();
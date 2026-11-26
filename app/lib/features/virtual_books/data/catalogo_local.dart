import 'libros_service.dart';

class LibroLocal extends LibroVirtual {
  LibroLocal({
    required super.titulo,
    required super.categoria,
    required super.autor,
    required super.descripcion,
    required super.url,
    required this.capitulos,
  });

  final List<CapituloLocal> capitulos;
}

class CapituloLocal {
  const CapituloLocal(this.titulo, this.parrafos);
  final String titulo;
  final List<String> parrafos;
}

final Uri _localUri = Uri.parse('lectio://biblioteca');

/// Catálogo original integrado en la aplicación; no requiere conexión.
final librosLocales = <LibroLocal>[
  LibroLocal(
    titulo: 'La casa de las mareas quietas',
    categoria: 'Novelas',
    autor: 'Elena Mar de Olmos',
    descripcion: 'Una restauradora vuelve a la isla donde desapareció su hermano y encuentra cartas escondidas en las paredes de una casa costera.',
    url: _localUri,
    capitulos: [
      CapituloLocal('La llave de cobre', [
        'Cuando Inés bajó del autobús, el pueblo olía a algas y a madera mojada. Llevaba doce años sin volver, pero reconoció de inmediato la torre del reloj, detenida a las seis y veinte, la misma hora que marcaba la última carta de Tomás.',
        'La casa esperaba al final del camino, cerrada y cubierta de sal. Bajo una maceta seca encontró una llave de cobre y una nota: «No abras el cuarto azul hasta escuchar la marea». Inés pensó que era una broma de su tía, aunque nadie sabía que ella regresaría.',
      ]),
      CapituloLocal('El cuarto azul', [
        'La llave abrió una habitación estrecha que no aparecía en los planos. Las paredes conservaban un azul profundo, y detrás de un armario Inés encontró marcas hechas con lápiz: alturas, fechas y una línea que llegaba hasta el día en que Tomás desapareció.',
        'Esa noche, el mar se retiró más de lo habitual. Bajo las tablas del suelo apareció una caja de cartas, protegida por una tela encerada. La primera estaba dirigida a ella y empezaba con una frase que no pudo dejar de leer: «Si has vuelto, la isla ya decidió contarte la verdad».',
      ]),
      CapituloLocal('La marea devuelve', [
        'Las cartas describían una ruta entre cuevas que solo quedaban al descubierto durante la marea viva. Inés siguió las indicaciones al amanecer, acompañada por Julián, el viejo farero que había enseñado a Tomás a leer el cielo.',
        'En la última cueva hallaron una pequeña embarcación y el cuaderno de su hermano. No había una confesión ni una despedida, sino un registro de rescates: Tomás había dedicado sus noches a guiar barcos perdidos. Inés comprendió que la isla guardaba silencios para proteger, pero también que algunos silencios debían terminar.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El mapa de las cosas perdidas',
    categoria: 'Novelas',
    autor: 'Mateo R. Cifuentes',
    descripcion: 'Una joven cartógrafa dibuja los objetos extraviados de su ciudad y descubre que todos señalan el mismo lugar.',
    url: _localUri,
    capitulos: [
      CapituloLocal('Un paraguas rojo', [
        'Lara trabajaba en una oficina municipal donde nadie reclamaba los objetos perdidos. Su tarea era registrar guantes, llaves y juguetes, pero ella los dibujaba en un cuaderno con calles que no existían.',
        'Un paraguas rojo apareció tres veces en barrios distintos. En cada mango había grabada una inicial y una hora. Al unir los puntos en el mapa, las líneas convergieron en la vieja estación, clausurada desde antes de que Lara naciera.',
      ]),
      CapituloLocal('La estación vacía', [
        'Tras una verja doblada encontró una sala cubierta de polvo y relojes detenidos. El cuaderno de la taquillera contenía nombres de personas que habían perdido algo más difícil de nombrar: el valor, una promesa, una despedida pendiente.',
        'Lara reconoció el apellido de su madre. Junto a él, alguien había escrito: «Perdió el camino de regreso». Por primera vez entendió que el mapa no señalaba objetos, sino historias que la ciudad había dejado sin terminar.',
      ]),
      CapituloLocal('El punto de encuentro', [
        'Con ayuda de los vecinos, Lara organizó una tarde para devolver cada hallazgo. El paraguas pertenecía a una mujer que esperaba noticias de su hermana; las llaves, a un músico que llevaba años sin visitar su casa.',
        'Su madre llegó al final, sin saber qué buscaba. Lara le mostró la anotación y ambas hablaron de la mudanza que las había separado. El mapa quedó lleno de rutas nuevas. Ninguna devolvió el pasado exactamente, pero todas señalaron una puerta que todavía podía abrirse.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'La ciudad debajo del jardín',
    categoria: 'Fantasía',
    autor: 'Nadia Soler',
    descripcion: 'En un jardín comunitario, un aprendiz de jardinero descubre una ciudad diminuta que cambia con cada estación.',
    url: _localUri,
    capitulos: [
      CapituloLocal('La semilla plateada', [
        'A Simón le asignaron una parcela olvidada detrás del mercado. Al cavar encontró una semilla plateada, fría como una moneda. La plantó por curiosidad y al día siguiente brotó una escalera diminuta entre las raíces.',
        'Bajo la tierra había calles iluminadas por luciérnagas y casas construidas con corteza. Sus habitantes lo llamaron Guardián del Suelo, aunque él apenas sabía cuidar sus propias macetas. La ciudad necesitaba agua antes de que llegara el invierno.',
      ]),
      CapituloLocal('El río de las raíces', [
        'La corriente subterránea se había secado porque alguien había cubierto el canal con piedras. Simón siguió el río hasta una raíz enorme que atravesaba el jardín. Cada golpe de pala hacía temblar las casas de abajo.',
        'Aprendió a retirar las piedras sin dañar el árbol. La gente diminuta le enseñó que el jardín tenía memoria: cada planta crecía mejor cuando alguien recordaba quién la había sembrado y por qué.',
      ]),
      CapituloLocal('La estación de las hojas', [
        'Cuando llegó el otoño, la ciudad celebró su festival de faroles. Simón llevó semillas de caléndula y recibió a cambio una brújula hecha con una gota de rocío.',
        'La escalera desapareció con la primera helada, pero el jardín floreció como nunca. Simón dejó una placa junto a la parcela para que otros cuidaran el lugar. En primavera, la brújula apuntó al suelo y una nueva escalera empezó a formarse.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El relojero de la lluvia',
    categoria: 'Fantasía',
    autor: 'Iván del Río',
    descripcion: 'Una aprendiz de relojería descubre que los relojes de su ciudad regulan las lluvias y que uno de ellos ha dejado de funcionar.',
    url: _localUri,
    capitulos: [
      CapituloLocal('Minutos de agua', [
        'En San Telmo llovía siempre a la misma hora: las cuatro y doce. Mara ayudaba a su abuelo a reparar relojes y sabía que aquella puntualidad no era natural. En el mecanismo de la torre encontró una pieza hecha de nube endurecida.',
        'El abuelo le explicó que cada reloj guardaba minutos de lluvia para los campos. Alguien había retirado el engranaje central, y el río comenzaría a desbordarse si no lo encontraban antes del domingo.',
      ]),
      CapituloLocal('El taller sin ventanas', [
        'Las huellas de aceite conducían a un taller bajo el puente. Su dueño, un antiguo aprendiz, había robado la pieza para impedir que la ciudad regara los terrenos de una fábrica.',
        'Mara escuchó su historia antes de acusarlo. El hombre había perdido su hogar en una inundación provocada por los mismos relojes. Juntos revisaron los mecanismos y encontraron una forma de repartir el agua con más justicia.',
      ]),
      CapituloLocal('La hora nueva', [
        'La reparación no consistió en devolver el reloj a su ritmo antiguo. Mara ajustó las campanas para que cada barrio recibiera lluvia en turnos distintos, y pidió que la comunidad supervisara el sistema.',
        'A las cuatro y doce el cielo permaneció despejado. Una hora después, una lluvia tranquila cayó sobre los huertos del sur. El abuelo sonrió: por primera vez, la ciudad no obedecía al reloj; el reloj escuchaba a la ciudad.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'Las voces del faro dormido',
    categoria: 'Novelas',
    autor: 'Clara B. Estévez',
    descripcion: 'Dos hermanas heredan un faro apagado y reconstruyen la historia de quienes buscaron refugio allí.',
    url: _localUri,
    capitulos: [
      CapituloLocal('La herencia', [
        'El faro llevaba veinte años apagado cuando Alba y Vera recibieron las llaves. Una quería venderlo; la otra deseaba restaurarlo. En la lámpara hallaron nombres tallados, cientos de ellos, todos acompañados por una fecha de tormenta.',
        'Una grabación vieja mencionaba una habitación bajo la escalera. Las hermanas encontraron mantas, diarios y una radio. El faro había servido de refugio durante una guerra que sus abuelos nunca quisieron recordar.',
      ]),
      CapituloLocal('La frecuencia', [
        'Alba reparó la radio y captó una voz que repetía coordenadas. Vera reconoció el apellido de su bisabuela en uno de los diarios: ella había guiado barcos de refugiados cuando las autoridades cerraron el puerto.',
        'La investigación las llevó a entrevistar a vecinos que conservaban recuerdos distintos. Cada versión completaba una parte, pero ninguna explicaba por qué la familia había guardado silencio durante tanto tiempo.',
      ]),
      CapituloLocal('Luz de regreso', [
        'Las hermanas decidieron abrir el faro como archivo y lugar de encuentro. En la inauguración, una mujer anciana llegó con una fotografía de su madre, una de las personas salvadas allí.',
        'Alba ya no quería vender. Vera ya no quería decidir sola. Encendieron la lámpara restaurada, no para guiar barcos, sino para que cualquiera pudiera encontrar la puerta abierta cuando necesitara contar su historia.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El jardín de los nombres',
    categoria: 'Fantasía',
    autor: 'Rocío Valverde',
    descripcion: 'En un valle donde las flores guardan recuerdos, un niño busca el nombre que su familia dejó de pronunciar.',
    url: _localUri,
    capitulos: [
      CapituloLocal('Flores que recuerdan', [
        'Cada flor del valle llevaba un nombre en sus pétalos. Leo cuidaba el jardín de su abuela y notó que una parcela permanecía vacía, aunque la tierra estaba húmeda y fértil.',
        'Su abuela nunca hablaba de aquella esquina. Una tarde, el viento trajo una semilla blanca que no aparecía en ningún libro. Cuando la plantó, escuchó una risa conocida desde debajo del suelo.',
      ]),
      CapituloLocal('La persona sin retrato', [
        'La flor creció durante la noche y mostró escenas de una niña que construía barcos de papel. Leo preguntó a su familia; su madre cerró el álbum y dijo que aquella niña se llamaba Amalia, su hermana, fallecida antes de que él naciera.',
        'El dolor había borrado el nombre de las conversaciones, pero no el cariño. Leo pidió escuchar las historias. Cada recuerdo añadido hizo que la flor abriera un pétalo nuevo.',
      ]),
      CapituloLocal('Un nombre compartido', [
        'La familia se reunió junto a la planta y contó anécdotas distintas: una canción desafinada, una cometa enredada, una promesa de volver. La abuela lloró sin ocultarse.',
        'Leo escribió «Amalia» en una placa de madera. El jardín no devolvió a la niña, pero dejó de estar vacío. Desde entonces, las flores crecieron con más fuerza cada vez que alguien pronunciaba un nombre querido.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'La última biblioteca del viento',
    categoria: 'Fantasía',
    autor: 'Samuel Arce',
    descripcion: 'Una mensajera lleva libros por un desierto donde el viento borra las palabras de las páginas.',
    url: _localUri,
    capitulos: [
      CapituloLocal('Páginas en blanco', [
        'Ariadna recorría el desierto con una biblioteca sobre ruedas. El viento borraba los libros en pocos días, así que ella memorizaba cada historia antes de entregarla.',
        'En la última ciudad encontró un volumen sin título que seguía intacto. Su primera página tenía una dirección escrita con tinta azul: el observatorio abandonado al norte de las dunas.',
      ]),
      CapituloLocal('El observatorio', [
        'El edificio estaba lleno de mapas celestes y cartas que nadie había enviado. Allí vivía un astrónomo que había inventado un modo de fijar las palabras usando polvo de meteorito.',
        'El material era escaso y solo alcanzaba para un libro. Ariadna propuso enseñar a la gente a copiar las historias en sus propias voces, para que no dependieran de una tinta que el desierto podía borrar.',
      ]),
      CapituloLocal('Historias al aire', [
        'La ciudad se reunió en la plaza. Cada persona aprendió un fragmento y lo compartió con otra. El viento sopló con fuerza, pero las historias pasaron de boca en boca.',
        'Ariadna continuó su camino con el libro intacto en el carro. Ya no era la única guardiana de la biblioteca: en cada pueblo quedaban lectores capaces de llevar una historia más lejos que cualquier rueda.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'La brújula de los sueños',
    categoria: 'Fantasía',
    autor: 'Mireya Campos',
    descripcion: 'Un joven encuentra una brújula que señala los sueños que otros han abandonado.',
    url: _localUri,
    capitulos: [
      CapituloLocal('La aguja quieta', [
        'En el mercado de antigüedades, Nico compró una brújula que no apuntaba al norte. La aguja giraba cada vez que alguien suspiraba cerca.',
        'Al caer la noche, la brújula señaló la azotea de una escuela cerrada. Allí encontró dibujos de cohetes y una lista de nombres: estudiantes que alguna vez quisieron explorar el cielo.',
      ]),
      CapituloLocal('El museo de los intentos', [
        'Nico siguió la aguja hasta un almacén lleno de maquetas, partituras y cuadernos sin terminar. La encargada guardaba esos objetos para recordar que abandonar un proyecto también podía ser una decisión necesaria.',
        'Entre las cajas halló una maqueta firmada por su padre, quien había soñado con diseñar puentes antes de dedicarse a cuidar a su familia. Nico no sabía que su padre había querido otra vida.',
      ]),
      CapituloLocal('Rumbo propio', [
        'Nico llevó la brújula a casa y preguntó por la maqueta. Su padre habló de su sueño sin nostalgia, pero con afecto. Luego ayudó a Nico a construir un pequeño planeador.',
        'La aguja volvió a girar, esta vez hacia el patio. Nico entendió que la brújula no ordenaba cumplir los sueños ajenos; solo recordaba que todavía se podía elegir qué hacer con los propios.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'La casa de cristal verde',
    categoria: 'Novelas',
    autor: 'Paula Niebla',
    descripcion: 'Una botánica hereda un invernadero y descubre que su familia protegía especies desaparecidas.',
    url: _localUri,
    capitulos: [
      CapituloLocal('Herencia de hojas', [
        'Eva recibió un invernadero cubierto de cristales verdes y una caja con semillas numeradas. La casa llevaba años cerrada, pero dentro todavía se sentía el calor de una tarde de verano.',
        'Un cuaderno identificaba plantas que ya no existían en los registros. Junto a cada una había una nota de su abuela sobre el lugar donde fue encontrada y la persona que la había cuidado.',
      ]),
      CapituloLocal('La semilla número nueve', [
        'La semilla nueve no germinaba. Eva pidió ayuda a un agricultor del valle, quien reconoció el símbolo dibujado en la etiqueta: pertenecía a un manantial cubierto por una carretera.',
        'Ambos organizaron una búsqueda y hallaron el agua bajo una capa de cemento. La planta necesitaba humedad, pero también un suelo que el invernadero no podía ofrecer por sí solo.',
      ]),
      CapituloLocal('Un invernadero abierto', [
        'Eva invitó a la escuela y a los agricultores a cuidar las especies. Algunas semillas prosperaron, otras no. Aprendieron que conservar no era guardar cada planta tras un cristal, sino recuperar el entorno que la hacía posible.',
        'Al amanecer, la semilla nueve abrió una flor diminuta. Eva dejó la puerta del invernadero sin llave y escribió un nuevo cuaderno para quienes continuarían el trabajo.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El tren de las cinco estaciones',
    categoria: 'Novelas',
    autor: 'Tomás Leiva',
    descripcion: 'Un tren aparece una vez al año y permite a sus pasajeros visitar momentos que todavía pueden cambiar.',
    url: _localUri,
    capitulos: [
      CapituloLocal('El boleto sin fecha', [
        'A las cinco de la mañana llegó un tren sin conductor a la estación de San Marcos. Julia encontró un boleto en el bolsillo de su abrigo, aunque llevaba años sin viajar.',
        'El revisor dijo que habría cinco estaciones y que ningún pasajero podría quedarse en el pasado. Julia subió pensando en la conversación que nunca tuvo con su mejor amiga.',
      ]),
      CapituloLocal('Estaciones de regreso', [
        'En cada parada, Julia vio un instante de su vida: una despedida apurada, una llamada ignorada, una tarde en que eligió callar. No podía cambiar lo ocurrido, pero sí podía comprender qué había sentido cada persona.',
        'En el cuarto vagón encontró una carta que había escrito y nunca enviado. La leyó en voz alta. El tren respondió con un silbido y avanzó hacia la estación final.',
      ]),
      CapituloLocal('La quinta parada', [
        'La última estación era el presente. Julia bajó con el boleto convertido en papel blanco. Llamó a su amiga y le propuso caminar, sin intentar fingir que los años no habían pasado.',
        'La conversación fue difícil y sincera. No recuperaron exactamente la antigua amistad, pero abrieron un camino nuevo. Al mirar atrás, Julia vio que el tren ya se alejaba, dejando las vías iluminadas por la mañana.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El cuaderno de las mareas',
    categoria: 'Historia',
    autor: 'Lucía Pardo',
    descripcion: 'Una estudiante ordena el diario de una navegante y reconstruye una travesía olvidada por los archivos oficiales.',
    url: _localUri,
    capitulos: [
      CapituloLocal('La caja del archivo', [
        'En el archivo municipal, Sara encontró un cuaderno cubierto de sal dentro de una caja sin inventariar. Las fechas coincidían con una expedición marítima del siglo pasado, pero los mapas oficiales no mencionaban a ninguna mujer a bordo.',
        'La letra del diario pertenecía a Amalia Ríos, una navegante que había cartografiado arrecifes durante meses. Sara decidió comparar sus notas con los registros del puerto.',
      ]),
      CapituloLocal('Cartas cruzadas', [
        'Las páginas describían tormentas, reparaciones y acuerdos con comunidades costeras. En una carta, Amalia pedía que los mapas incluyeran los nombres locales de las bahías.',
        'Sara halló esos nombres en documentos de otra región. La expedición había sido real, pero su trabajo fue atribuido al capitán. Las pruebas mostraban una historia más amplia que una simple disputa de autoría.',
      ]),
      CapituloLocal('Un mapa completo', [
        'Sara presentó los hallazgos en el museo y propuso una exposición con las cartas originales. Descendientes de las comunidades aportaron fotografías y relatos transmitidos en sus familias.',
        'El nuevo mapa conservó los nombres de Amalia y de quienes la guiaron. Sara entendió que investigar el pasado exige escuchar voces distintas, incluso cuando los archivos parecen haberlas dejado fuera.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El archivo de las luciérnagas',
    categoria: 'Historia',
    autor: 'Andrés Cuéllar',
    descripcion: 'Un aprendiz de cronista guarda testimonios de un barrio que será transformado por una gran obra.',
    url: _localUri,
    capitulos: [
      CapituloLocal('La lista de casas', [
        'Elena recibió el encargo de documentar un barrio antes de que comenzara la construcción de una avenida. Tenía una libreta, una grabadora y tres semanas para escuchar a todos.',
        'La primera vecina le pidió que anotara el sonido de las luciérnagas junto al río. Elena creyó que hablaba en sentido figurado, hasta que vio el valle encendido en la noche.',
      ]),
      CapituloLocal('Voces en la libreta', [
        'Cada casa guardaba una historia diferente: una panadería que sobrevivió a dos mudanzas, una cancha construida por los niños, un árbol donde se reunían los vecinos.',
        'Elena empezó a comprender que el barrio no podía resumirse en fotografías de fachadas. Las relaciones y los recuerdos eran parte del lugar, aunque no aparecieran en los planos.',
      ]),
      CapituloLocal('Lo que permanece', [
        'La avenida se construyó, pero el proyecto cambió para conservar el río y la plaza. No todas las familias pudieron quedarse, así que Elena entregó copias del archivo a quienes se mudaron.',
        'En la primera noche de la nueva calle, las luciérnagas regresaron al tramo protegido. La libreta no detuvo el cambio, pero ayudó a que el barrio participara en decidir qué debía permanecer.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'La ciudad de los puentes pequeños',
    categoria: 'Historia',
    autor: 'Marcos Villalba',
    descripcion: 'Un profesor reconstruye la historia de los puentes vecinales que mantuvieron unidas dos orillas durante generaciones.',
    url: _localUri,
    capitulos: [
      CapituloLocal('El puente de madera', [
        'Una crecida dejó al descubierto los pilares de un puente antiguo bajo el río. El profesor Daniel encontró marcas de herramientas y una moneda fechada en 1892.',
        'Los documentos indicaban que la estructura había sido levantada por vecinos, no por el gobierno. Daniel inició una búsqueda de fotografías y relatos para conocer a sus constructores.',
      ]),
      CapituloLocal('Las dos orillas', [
        'En la orilla norte vivían familias de pescadores; en la sur, agricultores. Cada grupo recordaba el puente de una manera distinta, pero ambos coincidían en que fue construido después de una temporada de inundaciones.',
        'Una mujer entregó un cuaderno de cuentas donde aparecían aportes de personas que no podían dar dinero: comida, madera, transporte y días de trabajo.',
      ]),
      CapituloLocal('Cruzar juntos', [
        'La escuela organizó una exposición y pidió declarar el lugar patrimonio comunitario. Las autoridades aceptaron restaurar los pilares como parte de un nuevo paseo peatonal.',
        'El día de la apertura, descendientes de ambas orillas cruzaron juntos. Daniel guardó el cuaderno en el archivo, sabiendo que aquel puente no solo unía tierras: también mostraba lo que una comunidad podía construir cuando compartía una necesidad.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El atlas de la primera lluvia',
    categoria: 'Ciencia',
    autor: 'Valentina Ríos',
    descripcion: 'Una joven meteoróloga compara los registros de lluvia de su abuela con los datos modernos para entender el clima del valle.',
    url: _localUri,
    capitulos: [
      CapituloLocal('Registros de papel', [
        'Mila encontró cuadernos de lluvia en el altillo de su abuela. Cada página registraba nubes, viento y olor del aire, con una precisión que sorprendió a su profesor de ciencias.',
        'Los datos mostraban que el primer aguacero del año llegaba cada vez más tarde. Mila propuso comparar las observaciones con las mediciones de la estación meteorológica.',
      ]),
      CapituloLocal('El valle cambia', [
        'Las mediciones confirmaron una tendencia, pero también revelaron diferencias entre barrios. La ciudad había perdido árboles y construido sobre antiguos humedales.',
        'Mila entrevistó a agricultores y reunió muestras de suelo. El proyecto dejó de ser solo una tabla de números: ahora buscaba entender por qué algunas calles se inundaban mientras otras permanecían secas.',
      ]),
      CapituloLocal('Una lluvia compartida', [
        'El equipo presentó jardines de lluvia, techos verdes y un sistema de medición abierto a las escuelas. No podían controlar el clima, pero sí reducir el daño que causaba.',
        'Cuando llegó la primera tormenta, varias plazas absorbieron el agua sin desbordarse. Mila añadió la fecha al cuaderno de su abuela y dejó una página en blanco para las observaciones del próximo año.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El laboratorio del señor Nube',
    categoria: 'Ciencia',
    autor: 'Diego Santacruz',
    descripcion: 'Tres amigos ayudan a un inventor a medir las nubes y descubren que la mejor pregunta científica nace de observar.',
    url: _localUri,
    capitulos: [
      CapituloLocal('La máquina del patio', [
        'En el patio de la escuela apareció una máquina construida con paraguas, tubos y una bicicleta vieja. Su creador, el señor Nube, decía que podía pesar una nube.',
        'Los estudiantes no le creyeron hasta que vieron cómo el aparato registraba gotas y cambios de presión. Entonces preguntaron cómo se podía comprobar la idea.',
      ]),
      CapituloLocal('Medir sin adivinar', [
        'El grupo construyó instrumentos sencillos y tomó datos durante semanas. Algunas mediciones salieron mal por el viento y otras porque olvidaron anotar la hora.',
        'El señor Nube les enseñó a repetir el experimento y a reconocer sus errores. La máquina no pesaba nubes enteras, pero permitía estimar cuánta agua podía caer de ellas.',
      ]),
      CapituloLocal('La pregunta correcta', [
        'Al final, los amigos investigaron qué tipo de nube anunciaba lluvia en su zona. Compartieron sus registros con agricultores y aprendieron que una respuesta útil también debía indicar sus límites.',
        'El señor Nube guardó la máquina, satisfecho. La ciencia no había terminado con un gran descubrimiento, sino con mejores preguntas y un cuaderno lleno de observaciones que otros podían continuar.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'Pequeñas máquinas para grandes preguntas',
    categoria: 'Ciencia',
    autor: 'Sara Montalvo',
    descripcion: 'Un club escolar diseña artefactos para resolver problemas cotidianos sin perder de vista a las personas que los usan.',
    url: _localUri,
    capitulos: [
      CapituloLocal('El reto del agua', [
        'El club de ciencias recibió un problema concreto: llevar agua desde el tanque hasta el huerto escolar. Las soluciones iniciales eran complicadas y costosas.',
        'Antes de construir, entrevistaron a quienes cuidaban el huerto. Descubrieron que el mayor desperdicio ocurría cuando nadie podía revisar las mangueras al final del día.',
      ]),
      CapituloLocal('Probar y corregir', [
        'Diseñaron un temporizador con piezas recicladas. La primera versión se atascó; la segunda regó demasiado. En vez de esconder los fallos, los registraron y cambiaron una variable a la vez.',
        'Una estudiante propuso añadir un indicador visible para que cualquiera pudiera saber si el sistema estaba funcionando. El diseño mejoró cuando dejó de ser una máquina que solo entendían sus inventores.',
      ]),
      CapituloLocal('Una solución compartida', [
        'El temporizador redujo el desperdicio y permitió que más cursos usaran el huerto. El club publicó planos sencillos y una lista de materiales fáciles de conseguir.',
        'No resolvieron todos los problemas del agua, pero aprendieron a comenzar con una necesidad real, probar una idea y escuchar a las personas afectadas. El siguiente reto ya esperaba sobre la mesa.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El bosque que aprendió a escuchar',
    categoria: 'Ciencia',
    autor: 'Nicolás Pineda',
    descripcion: 'Una ecóloga instala sensores en un bosque y descubre que sus datos solo tienen sentido cuando se combinan con el conocimiento local.',
    url: _localUri,
    capitulos: [
      CapituloLocal('Sensores entre hojas', [
        'La ecóloga Irene instaló sensores para medir humedad y temperatura en una reserva. Las cifras indicaban que una zona estaba seca, aunque los árboles crecían allí con vigor.',
        'Un guardabosques le explicó que bajo el suelo corría agua en una capa profunda. Los instrumentos registraban una parte del bosque, no toda su historia.',
      ]),
      CapituloLocal('El canto nocturno', [
        'El equipo grabó sonidos y detectó que una especie de rana había desaparecido de un arroyo. Los habitantes recordaban que cantaba después de las lluvias intensas.',
        'Al revisar el cauce, encontraron una tubería que desviaba el agua. La grabación, los datos y la memoria de la comunidad juntos señalaron el problema.',
      ]),
      CapituloLocal('Un plan para cuidar', [
        'La reserva y el pueblo acordaron liberar el arroyo en ciertas temporadas y monitorear la recuperación. Irene dejó los sensores funcionando, pero compartió el acceso a los datos.',
        'Meses después, la rana volvió a cantar. El bosque no había hablado con palabras; había hecho falta aprender a escuchar sus señales y a quienes lo conocían desde mucho antes.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El museo de las cosas comunes',
    categoria: 'Arte',
    autor: 'Jimena Acosta',
    descripcion: 'Una artista convierte objetos cotidianos en piezas de museo y descubre las historias que sus vecinos esconden en ellos.',
    url: _localUri,
    capitulos: [
      CapituloLocal('Una silla vacía', [
        'Jimena pidió a sus vecinos un objeto sin valor económico que no pudieran tirar. Recibió una taza rota, una cinta azul y una silla con una pata reparada.',
        'Cada objeto llegó acompañado de una historia breve. La silla había esperado durante meses a una persona que finalmente regresó de viaje. Jimena decidió que el museo debía mostrar también las voces.',
      ]),
      CapituloLocal('La exposición invisible', [
        'La sala quedó llena de objetos sencillos, pero la gente se detenía frente a ellos más tiempo que ante las pinturas famosas. Las etiquetas describían gestos, no materiales.',
        'Un visitante reconoció una taza de su infancia. Su relato añadió un capítulo que la dueña original no conocía. Jimena abrió un cuaderno para que el público pudiera continuar las historias.',
      ]),
      CapituloLocal('Lo que guardamos', [
        'Al cerrar la muestra, los objetos volvieron a sus casas o encontraron nuevos dueños. El museo conservó las historias en un archivo público.',
        'Jimena comprendió que el arte no siempre transforma las cosas: a veces cambia la atención con que las miramos. La silla reparada siguió en la cocina de su vecina, lista para otra visita.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'Pintar con la luz de la tarde',
    categoria: 'Arte',
    autor: '?lvaro Méndez',
    descripcion: 'Un aprendiz de pintor intenta capturar una luz que cambia cada día y aprende a mirar más allá del paisaje.',
    url: _localUri,
    capitulos: [
      CapituloLocal('El color imposible', [
        'A Tomás le encargaron pintar la plaza al atardecer. La luz duraba apenas unos minutos y cada día teñía las paredes de un color distinto.',
        'Sus primeros cuadros parecían fotografías incompletas. Una anciana que barría la plaza le dijo que pintara también lo que la luz hacía sentir a las personas.',
      ]),
      CapituloLocal('La plaza cambia', [
        'Tomás regresó durante semanas y habló con vendedores, niños y músicos. Descubrió que la plaza no era la misma en días de mercado que en días de lluvia.',
        'En lugar de perseguir un solo tono, mezcló colores según los recuerdos de quienes habitaban el lugar. La escena se volvió menos exacta y más verdadera.',
      ]),
      CapituloLocal('La última pincelada', [
        'El cuadro terminó cuando la plaza estaba vacía. Tomás añadió una franja de luz en el suelo y dejó un espacio sin pintar para que el espectador completara la escena.',
        'La gente del barrio se reconoció en la obra, incluso quienes no aparecían retratados. El aprendiz entendió que mirar con atención también era una forma de participar.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El teatro de papel',
    categoria: 'Arte',
    autor: 'Mariana Beltrán',
    descripcion: 'Una compañía escolar crea una obra con marionetas y aprende que la imaginación necesita trabajo en equipo.',
    url: _localUri,
    capitulos: [
      CapituloLocal('El escenario pequeño', [
        'La escuela solo tenía cartón, hilo y una linterna para preparar su festival. A Lucía le preocupaba que la obra pareciera demasiado sencilla.',
        'El grupo decidió contar una historia sobre una montaña que buscaba el mar. Cada estudiante hizo una figura distinta y nadie sabía todavía cómo unir las escenas.',
      ]),
      CapituloLocal('Hilos enredados', [
        'Los ensayos fueron un caos. Las marionetas chocaban, la luz caía y el narrador olvidaba sus líneas. La directora pidió que cada persona explicara qué necesitaba para hacer su parte.',
        'Al escuchar, descubrieron que varias escenas repetían la misma idea. Recortaron algunas, añadieron música y repartieron tareas según las habilidades de cada quien.',
      ]),
      CapituloLocal('La montaña y el mar', [
        'La función comenzó con una linterna temblorosa y terminó con el público cantando. El cartón proyectó sombras enormes que llenaron el salón.',
        'Lucía ya no veía un escenario pobre. Veía una obra hecha por muchas manos, capaz de convertir pocos materiales en un mundo compartido.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'La fotografía que faltaba',
    categoria: 'Arte',
    autor: 'Felipe Londoño',
    descripcion: 'Un fotógrafo reconstruye la historia de una familia a partir de un álbum con un espacio vacío.',
    url: _localUri,
    capitulos: [
      CapituloLocal('El hueco del álbum', [
        'Al restaurar fotografías antiguas, Gabriel encontró un álbum con una página arrancada. El borde conservaba restos de pegamento y la silueta de una imagen cuadrada.',
        'La familia decía no recordar qué foto faltaba. Gabriel amplió las imágenes cercanas y encontró, reflejada en una ventana, a una persona que nadie mencionaba.',
      ]),
      CapituloLocal('La persona reflejada', [
        'La búsqueda condujo a una tía que se había marchado del país tras una discusión. En las fotos aparecía de fondo: detrás de una mesa, junto a una bicicleta, sosteniendo un paraguas.',
        'Gabriel envió una copia digital. La respuesta llegó semanas después, junto con una fotografía nueva y una carta que explicaba el silencio sin convertirlo en una acusación.',
      ]),
      CapituloLocal('Un lugar para volver', [
        'La familia se reunió para añadir la imagen al álbum. No todos estaban listos para reconciliarse, pero sí para escuchar la historia completa.',
        'Gabriel restauró la página sin ocultar la marca del pegamento. El espacio vacío quedó visible como parte del objeto, un recordatorio de que recordar también incluye lo que falta.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'Filosofía para una banca azul',
    categoria: 'Filosofía',
    autor: 'Esteban Rojas',
    descripcion: 'Dos desconocidos se encuentran cada jueves en un parque y conversan sobre decisiones, justicia y la vida buena.',
    url: _localUri,
    capitulos: [
      CapituloLocal('La pregunta del jueves', [
        'La banca azul estaba frente a un árbol viejo. Allí se sentaban Emilia, jubilada, y Andrés, estudiante de derecho. El primer jueves discutieron si una buena decisión debía beneficiar siempre a la mayoría.',
        'Emilia contó que había protegido a un vecino impopular durante una inundación. Andrés preguntó si habría hecho lo mismo con alguien que considerara peligroso. Ninguno respondió con seguridad.',
      ]),
      CapituloLocal('La ciudad justa', [
        'La semana siguiente observaron quién podía usar el parque y quién debía cruzar calles sin sombra. Hablaron de reglas que parecen iguales, pero afectan de manera distinta a cada persona.',
        'Andrés llevó sus preguntas a la universidad. Emilia preguntó a los vecinos qué cambiarían. La conversación dejó de ser abstracta cuando todos pudieron nombrar una necesidad concreta.',
      ]),
      CapituloLocal('Una respuesta provisional', [
        'Meses después, el barrio consiguió una rampa, bebederos y más iluminación. No resolvieron todas las desigualdades, pero aprendieron a deliberar sin esperar unanimidad perfecta.',
        'La banca siguió azul, aunque la pintura empezó a descascararse. Emilia y Andrés regresaron cada jueves, convencidos de que pensar juntos no ofrecía respuestas finales: ayudaba a hacer mejores preguntas.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El peso de una promesa',
    categoria: 'Filosofía',
    autor: 'Laura Sanabria',
    descripcion: 'Una joven debe decidir qué significa cumplir una promesa cuando las circunstancias cambian por completo.',
    url: _localUri,
    capitulos: [
      CapituloLocal('La promesa del río', [
        'Antes de partir, Mateo prometió a su hermana que volvería para cuidar el puente familiar. Años después, ella le escribió: el puente ya no era seguro y el pueblo necesitaba construir otro.',
        'Mateo sentía que abandonar el viejo puente era traicionar a su padre. Su hermana respondió que una promesa debía proteger a las personas, no conservar una estructura por orgullo.',
      ]),
      CapituloLocal('Lo que obliga', [
        'En el viaje de regreso, Mateo preguntó a distintos vecinos qué recordaban del puente. Unos lo asociaban con juegos; otros, con una ruta peligrosa durante las crecidas.',
        'Comprendió que cumplir literalmente la promesa no era lo mismo que cumplir su intención. El compromiso había nacido para ayudar a la comunidad a cruzar el río.',
      ]),
      CapituloLocal('La forma de cumplir', [
        'Mateo ayudó a diseñar el puente nuevo y guardó una tabla del antiguo para la plaza. Su hermana decidió que ambos firmaran el proyecto como continuadores de la promesa.',
        'El río siguió cambiando su curso, pero la familia aprendió a cambiar con él. Mateo dejó de medir su lealtad por lo que conservaba y empezó a medirla por el cuidado que ofrecía.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El silencio entre dos preguntas',
    categoria: 'Filosofía',
    autor: 'Camilo Bernal',
    descripcion: 'Un aprendiz de maestro descubre que escuchar antes de responder puede cambiar la vida de su aula.',
    url: _localUri,
    capitulos: [
      CapituloLocal('La clase difícil', [
        'El profesor Julián siempre tenía una respuesta preparada. Cuando una alumna preguntó por qué unas familias tenían más oportunidades que otras, él comenzó una explicación y se detuvo al ver que nadie escuchaba.',
        'La directora le sugirió esperar antes de responder. Julián pidió a la clase que describiera lo que había observado, sin discutir todavía quién tenía razón.',
      ]),
      CapituloLocal('Escuchar el problema', [
        'Los estudiantes compartieron trayectos largos, trabajos después de clase y responsabilidades en casa. Julián conocía algunos datos, pero no las experiencias concretas que les daban sentido.',
        'La clase investigó becas, transporte y horarios. Cada propuesta debía explicar a quién ayudaba y a quién podía dejar por fuera.',
      ]),
      CapituloLocal('Otra manera de enseñar', [
        'Julián convirtió la pregunta en un proyecto colectivo. Los alumnos presentaron ideas al consejo escolar y consiguieron un espacio de estudio después de clases.',
        'El maestro siguió enseñando contenidos, pero empezó a reservar un silencio entre pregunta y respuesta. En ese espacio, sus estudiantes aprendían a pensar y él aprendía a escucharlos.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El camino de las palabras',
    categoria: 'Novelas',
    autor: 'Sara Villamarín',
    descripcion: 'Una intérprete regresa a su pueblo para ayudar a dos comunidades a recuperar una lengua que casi nadie habla.',
    url: _localUri,
    capitulos: [
      CapituloLocal('Palabras dormidas', [
        'Marina volvió al pueblo para ordenar el diccionario de su abuelo, escrito en una lengua que solo unas pocas personas recordaban. Las páginas mezclaban recetas, nombres de plantas y canciones.',
        'El consejo local discutía si valía la pena enseñar una lengua con tan pocos hablantes. Marina propuso empezar por las palabras que la gente usaba en su vida diaria.',
      ]),
      CapituloLocal('La escuela de la tarde', [
        'Niños y mayores se reunieron dos veces por semana. Cada sesión comenzaba con una palabra que alguien había oído en casa y terminaba con una historia breve.',
        'Marina descubrió que algunas palabras no tenían traducción exacta. En vez de forzarlas, pidió a los alumnos que dibujaran las situaciones donde se utilizaban.',
      ]),
      CapituloLocal('Un idioma en movimiento', [
        'Al cabo de un año, la escuela publicó un cuaderno ilustrado. No era un diccionario completo, sino una invitación a seguir preguntando y creando frases nuevas.',
        'Marina entregó el original de su abuelo al archivo y guardó una copia para la escuela. La lengua no regresó a un pasado intacto: encontró una forma nueva de vivir en las conversaciones del pueblo.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'Los mapas de la abuela Amalia',
    categoria: 'Historia',
    autor: 'Julián Escobar',
    descripcion: 'Una familia descubre que los mapas dibujados por su abuela narran migraciones, cambios de frontera y nuevos comienzos.',
    url: _localUri,
    capitulos: [
      CapituloLocal('Un mapa sin norte', [
        'Después del funeral, los nietos encontraron mapas dibujados a mano dentro de una caja de botones. Ninguno tenía norte, escala ni nombres oficiales.',
        'Amalia había marcado casas, árboles y tiendas con símbolos personales. Una línea roja recorría varios países y terminaba junto al río donde había vivido sus últimos años.',
      ]),
      CapituloLocal('Fronteras cotidianas', [
        'La familia visitó los lugares y entrevistó a parientes que habían migrado en distintas décadas. Cada uno recordaba un motivo distinto: trabajo, estudio, seguridad o amor.',
        'Los mapas mostraban fronteras que cambiaban mientras las personas seguían viviendo sus vidas. La abuela había usado el papel para recordar cómo una casa podía convertirse en otra sin dejar de ser hogar.',
      ]),
      CapituloLocal('El mapa familiar', [
        'Los nietos agregaron fotografías y relatos a una versión nueva del mapa. Dejaron zonas vacías para quienes aún no querían compartir su historia.',
        'Al terminar, entendieron que la memoria familiar no era una ruta recta. Era un conjunto de caminos que se cruzaban, se separaban y volvían a encontrarse junto al río.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El eco de la montaña',
    categoria: 'Novelas',
    autor: 'Daniela Ospina',
    descripcion: 'Una guía de montaña y un geólogo siguen un eco que aparece en lugares donde el pueblo ha perdido algo importante.',
    url: _localUri,
    capitulos: [
      CapituloLocal('La voz en el sendero', [
        'Cada amanecer, el eco repetía una palabra distinta desde la montaña. El primer día dijo «agua»; el siguiente, «nombre». Los vecinos empezaron a subir para escucharlo.',
        'Lucía, guía local, se unió al geólogo Simón. Él buscaba una explicación física; ella sospechaba que el eco seguía una ruta antigua de pastoreo.',
      ]),
      CapituloLocal('La quebrada seca', [
        'El sendero los llevó a una quebrada cubierta de sedimentos. Simón midió las paredes y encontró señales de un derrumbe reciente. Lucía reconoció el lugar donde su abuelo recogía agua.',
        'Al revisar los permisos de construcción, descubrieron que una obra había desviado el cauce. El eco era un fenómeno natural amplificado por la roca, pero su mensaje era una consecuencia humana.',
      ]),
      CapituloLocal('Voces en la plaza', [
        'El pueblo exigió restaurar el cauce y proteger el sendero. La empresa aceptó financiar los trabajos después de una mediación pública.',
        'Cuando el agua volvió a la quebrada, el eco dejó de repetir palabras. En la plaza, la gente empezó a decirlas por sí misma: agua, memoria, cuidado. La montaña había amplificado lo que el pueblo necesitaba conversar.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El pequeño planeta de Inés',
    categoria: 'Ciencia',
    autor: 'Federico Luna',
    descripcion: 'Una niña construye un modelo del sistema solar para entender por qué su barrio ve menos estrellas cada año.',
    url: _localUri,
    capitulos: [
      CapituloLocal('Una estrella menos', [
        'Inés notó que desde la azotea ya no veía la constelación que su abuelo le enseñó. Pensó que las estrellas habían desaparecido y construyó un planetario con cajas y linternas.',
        'Su maestra explicó que la luz de la ciudad podía esconderlas. Inés organizó una observación nocturna y pidió a sus vecinos apagar las luces innecesarias durante una hora.',
      ]),
      CapituloLocal('El cielo compartido', [
        'La primera noche solo vieron unas pocas estrellas. Un astrónomo aficionado les enseñó a orientar el telescopio y a distinguir planetas de estrellas.',
        'Los niños registraron cuántas luces quedaban encendidas y compararon las observaciones desde distintos barrios. La contaminación lumínica no era igual para todos.',
      ]),
      CapituloLocal('Una noche más oscura', [
        'El barrio cambió algunas luminarias y cubrió los focos que apuntaban al cielo. La siguiente observación reveló más estrellas, aunque no tantas como en el campo.',
        'Inés entendió que su pequeño planeta era la Tierra y que observarlo también implicaba cuidarlo. Su modelo quedó en la biblioteca, junto a una invitación para mirar el cielo el mes siguiente.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'El taller de los colores perdidos',
    categoria: 'Arte',
    autor: 'Natalia Rincón',
    descripcion: 'Una restauradora busca pigmentos tradicionales para devolverle color a los murales de un barrio.',
    url: _localUri,
    capitulos: [
      CapituloLocal('El muro gris', [
        'El mural de la plaza se había vuelto gris después de varias capas de pintura. Natalia, restauradora, recibió permiso para recuperarlo, pero no encontraba los pigmentos originales.',
        'Un vecino recordó que su madre preparaba un azul intenso con una piedra de la región. La búsqueda comenzó entre archivos, talleres y conversaciones de cocina.',
      ]),
      CapituloLocal('Mezclas y recuerdos', [
        'Los primeros intentos cambiaban de color al secarse. Natalia invitó a artistas mayores a probar recetas y documentó cada proporción.',
        'Una niña propuso dejar visibles algunos fragmentos grises para contar las distintas épocas del muro. El equipo decidió que restaurar no significaba borrar las marcas del tiempo.',
      ]),
      CapituloLocal('El mural vivo', [
        'La comunidad pintó una nueva sección con motivos elegidos por los vecinos. El azul tradicional apareció junto a tonos modernos, y una franja gris quedó como testimonio de los años anteriores.',
        'Natalia entregó las fórmulas al centro cultural. El mural ya no dependía de una sola restauradora: cualquiera podía aprender a cuidarlo y aportar una imagen nueva.',
      ]),
    ],
  ),
  LibroLocal(
    titulo: 'La noche de los faroles lentos',
    categoria: 'Fantasía',
    autor: 'Pilar Cárdenas',
    descripcion: 'En una ciudad donde los deseos se convierten en faroles, una niña ayuda a su comunidad a elegir qué sueños compartir.',
    url: _localUri,
    capitulos: [
      CapituloLocal('El farol de papel', [
        'Cada año, los habitantes escribían un deseo y lo soltaban en forma de farol luminoso. El deseo de Alma no voló: quedó suspendido sobre su balcón, temblando.',
        'La abuela explicó que algunos sueños pesaban demasiado para viajar solos. Alma escribió debajo: «Que nadie tenga que cruzar el río a oscuras».',
      ]),
      CapituloLocal('Deseos distintos', [
        'Al caminar por la ciudad, Alma vio faroles que pedían trabajo, salud, descanso y justicia. Muchos tenían palabras parecidas, aunque sus dueños nunca se habían conocido.',
        'Alma invitó a los vecinos a leer sus deseos en la plaza. Descubrieron que podían colaborar: unos sabían construir lámparas, otros organizar rutas y otros conocían a quienes tomaban decisiones.',
      ]),
      CapituloLocal('La luz que se queda', [
        'La comunidad instaló luces en el puente y dejó varios faroles en la plaza para recordar los deseos que todavía faltaban cumplir.',
        'El farol de Alma finalmente despegó, lento y bajo, hasta quedarse sobre el río. No desapareció en el cielo: alumbró el camino mientras los vecinos cruzaban juntos.',
      ]),
    ],
  ),
];

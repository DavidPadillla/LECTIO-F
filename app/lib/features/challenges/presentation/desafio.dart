import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../auth/data/lectio_auth_service.dart';

const _ink = Color(0xFF0D2B1D);
const _muted = Color(0xFF6B8377);
const _green = Color(0xFF1A6B45);
const _line = Color(0xFFD4E5D9);
const _paper = Color(0xFFF7FAF8);
const _defaultBackendUri = 'https://lectio-biblioteca.onrender.com';

@immutable
class ChallengeBook {
  const ChallengeBook({
    required this.id,
    required this.title,
    required this.icon,
    required this.accent,
    required this.description,
    required this.chapters,
  });

  final String id;
  final String title;
  final String icon;
  final Color accent;
  final String description;
  final List<String> chapters;
}

const _books = [
  ChallengeBook(
    id: 'principito',
    title: 'El Principito',
    icon: '✦',
    accent: Color(0xFFBE7B45),
    description: 'Relato original sobre amistad, curiosidad y nuevos caminos.',
    chapters: [
      'En una isla pequeña, Vera encontró una botella con un mapa dibujado a mano. No señalaba un tesoro, sino cinco lugares donde alguien había dejado una pregunta. Vera guardó el mapa en su mochila y decidió buscar las respuestas antes de que terminara el verano.',
      'La primera pista la llevó hasta el faro, donde conoció a Tomás, un cuidador que llevaba años sin salir de la isla. Él le prestó una brújula antigua y le contó que el mapa pertenecía a una exploradora que ayudaba a sus vecinos a conocerse.',
      'En el mercado, Vera y Tomás preguntaron por la segunda marca. Una panadera les habló de una familia que necesitaba reparar su huerto. Los dos amigos reunieron herramientas y semillas; al terminar, encontraron una nueva nota escondida bajo una maceta.',
      'La última pista estaba en una colina azotada por el viento. Allí, Vera comprendió que el mapa no conducía a un objeto escondido: cada lugar señalaba a alguien que necesitaba compañía. Tomás sonrió al descubrir que ya no quería quedarse solo en el faro.',
      'Al llegar al puerto, Vera escribió una pregunta nueva y la puso en una botella: «¿A quién puedes ayudar hoy?». El mapa quedó listo para otro viajero. Antes de volver a casa, ambos acordaron recorrer juntos la isla, con tiempo para escuchar cada historia.',
    ],
  ),
  ChallengeBook(
    id: '1984',
    title: '1984',
    icon: '◉',
    accent: Color(0xFF9C4B4B),
    description: 'Relato original sobre memoria, verdad y libertad.',
    chapters: [
      'En la ciudad de Bruma, cada pantalla repetía el mismo pronóstico: «Mañana será igual». Inés, aprendiz de cartógrafa, notó que los mapas oficiales ya no mostraban los callejones donde vivían sus vecinos. Empezó a dibujarlos de memoria en un cuaderno escondido.',
      'Su amigo Julián encontró el cuaderno y reconoció la plaza que habían borrado del mapa. Allí todavía se reunían personas mayores para contar cómo era el barrio antes de las nuevas pantallas. Los dos decidieron registrar aquellas historias con nombres y fechas.',
      'Una mañana, el sistema anunció que el río nunca había cruzado la ciudad. Inés llevó a sus vecinos hasta la orilla y les pidió que describieran lo que veían. Cada testimonio era distinto, pero todos coincidían en el sonido del agua bajo el puente.',
      'El cuaderno llegó a la biblioteca, donde decenas de personas añadieron recuerdos y correcciones. Al comparar las páginas, descubrieron quién había cambiado los mapas y por qué. La ciudad no despertó de golpe, pero la gente volvió a preguntar antes de aceptar una respuesta.',
      'Inés trazó un mapa nuevo: no prometía que todos recordarían lo mismo, solo mostraba dónde encontrar las voces del barrio. Lo colgó en la plaza recuperada. Desde entonces, cuando una pantalla afirmaba que algo no existía, los vecinos sabían dónde ir a comprobarlo.',
    ],
  ),
  ChallengeBook(
    id: 'harrypotter',
    title: 'Harry Potter',
    icon: '✧',
    accent: Color(0xFF8270A8),
    description: 'Relato original sobre ingenio, cooperación y descubrimiento.',
    chapters: [
      'Cuando el reloj de la estación dejó de andar, Lea oyó un tintineo dentro de una pared. Era una diminuta campana que sonaba cada vez que alguien olvidaba una promesa. La niña, aprendiz de relojera, decidió averiguar quién la había instalado y qué intentaba advertir.',
      'Con su vecino Nilo, Lea siguió el sonido hasta el taller cerrado de su abuela. Allí encontraron planos de mecanismos que funcionaban con música, vapor y luz. Ninguno explicaba la campana, pero una nota decía: «Para abrir lo difícil, escucha a los demás».',
      'Los niños pidieron ayuda a quienes trabajaban en la estación. Una maquinista reconoció el ritmo del tintineo; un jardinero encontró una llave entre las raíces de una maceta. Cada persona aportó una pieza distinta y juntos abrieron una puerta detrás del reloj.',
      'En la habitación había cientos de cartas sin entregar. La campana sonaba por las promesas que la gente había querido cumplir, pero nunca se había atrevido a decir en voz alta. Lea y Nilo organizaron las cartas para que sus destinatarios pudieran encontrarlas.',
      'Cuando el reloj volvió a funcionar, la estación se llenó de conversaciones y reencuentros. Lea guardó los planos en el taller y añadió uno nuevo: un mecanismo que solo podía construirse entre varias personas. La campana quedó en silencio, lista para sonar si alguien volvía a necesitar ayuda.',
    ],
  ),
];

abstract interface class ChallengeDataSource {
  Future<Map<String, Set<int>>> loadProgress();

  Future<void> saveChapter({
    required String bookId,
    required int chapter,
    required int totalChapters,
  });

  Future<void> resetProgress();
}

class ChallengeService implements ChallengeDataSource {
  ChallengeService({
    required this.session,
    http.Client? client,
    Uri? backendUri,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _backendUri = backendUri ?? Uri.parse(_defaultBackendUri);

  final AuthSession session;
  final http.Client _client;
  final bool _ownsClient;
  final Uri _backendUri;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (!kIsWeb && session.cookie.isNotEmpty) 'Cookie': session.cookie,
  };

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, Object>? body,
  }) async {
    final request = http.Request(method, _backendUri.resolve(path))
      ..headers.addAll(_headers);
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    try {
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      final result = await http.Response.fromStream(response);
      if (result.statusCode < 200 || result.statusCode >= 300) {
        throw ChallengeException(
          result.statusCode == 401
              ? 'Tu sesión expiró. Inicia sesión de nuevo para guardar el progreso.'
              : 'No se pudo completar la solicitud de progreso (HTTP ${result.statusCode}).',
        );
      }
      return result;
    } on ChallengeException {
      rethrow;
    } on TimeoutException {
      throw const ChallengeException(
        'El servidor tardó demasiado en responder. Inténtalo de nuevo.',
      );
    } on http.ClientException catch (error) {
      throw ChallengeException(
        'No se pudo conectar con Lectio: ${error.message}',
      );
    }
  }

  @override
  Future<Map<String, Set<int>>> loadProgress() async {
    final response = await _request('GET', '/api/progreso/mi-progreso');
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ChallengeException(
        'El servidor devolvió un progreso inválido.',
      );
    }
    var raw = decoded['capitulosPorLibro'];
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } on FormatException {
        throw const ChallengeException(
          'El formato del progreso guardado no es válido.',
        );
      }
    }
    if (raw == null) return const {};
    if (raw is! Map) {
      throw const ChallengeException(
        'El servidor devolvió un progreso inválido.',
      );
    }
    final progress = <String, Set<int>>{};
    for (final entry in raw.entries) {
      final values = entry.value;
      if (values is List) {
        progress[entry.key.toString()] = values
            .whereType<num>()
            .map((value) => value.toInt())
            .where((chapter) => chapter > 0)
            .toSet();
      } else if (values is Map) {
        progress[entry.key.toString()] = values.keys
            .map((key) => int.tryParse(key.toString()))
            .whereType<int>()
            .where((chapter) => chapter > 0)
            .toSet();
      }
    }
    return progress;
  }

  @override
  Future<void> saveChapter({
    required String bookId,
    required int chapter,
    required int totalChapters,
  }) async {
    await _request(
      'POST',
      '/api/progreso/guardar-capitulo',
      body: {
        'libroId': bookId,
        'capitulo': chapter,
        'totalCapitulos': totalChapters,
      },
    );
  }

  @override
  Future<void> resetProgress() async {
    await _request('DELETE', '/api/progreso/reiniciar');
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}

class ChallengeException implements Exception {
  const ChallengeException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LectioChallengePage extends StatefulWidget {
  const LectioChallengePage({
    super.key,
    required this.session,
    this.dataSource,
  });

  final AuthSession session;
  final ChallengeDataSource? dataSource;

  @override
  State<LectioChallengePage> createState() => _LectioChallengePageState();
}

class _LectioChallengePageState extends State<LectioChallengePage> {
  late final ChallengeService? _ownedService = widget.dataSource == null
      ? ChallengeService(session: widget.session)
      : null;
  late final ChallengeDataSource _service = widget.dataSource ?? _ownedService!;
  late Future<Map<String, Set<int>>> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _service.loadProgress();
  }

  @override
  void dispose() {
    _ownedService?.close();
    super.dispose();
  }

  void _reload() => setState(() {
    _progressFuture = _service.loadProgress();
  });

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Reiniciar el progreso?'),
        content: const Text(
          'Se borrará el avance de todos tus desafíos. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.resetProgress();
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Progreso reiniciado.')));
    } on ChallengeException catch (error) {
      if (mounted) _showError(error.message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        title: const Text('Desafío de lectura'),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        actions: [
          IconButton(
            tooltip: 'Actualizar progreso',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Reiniciar progreso',
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, Set<int>>>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 44,
                      color: _muted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error is ChallengeException
                          ? (snapshot.error! as ChallengeException).message
                          : 'No se pudo cargar tu progreso.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          return _ChallengeHome(
            progress: snapshot.data ?? const {},
            onSelect: _openBook,
          );
        },
      ),
    );
  }

  void _openBook(ChallengeBook book, Set<int> completed) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => _ChallengeBookPage(
              book: book,
              initialCompleted: completed,
              service: _service,
            ),
          ),
        )
        .then((_) {
          if (mounted) _reload();
        });
  }
}

class _ChallengeHome extends StatelessWidget {
  const _ChallengeHome({required this.progress, required this.onSelect});

  final Map<String, Set<int>> progress;
  final void Function(ChallengeBook book, Set<int> completed) onSelect;

  @override
  Widget build(BuildContext context) {
    final completedBooks = _books
        .where(
          (book) => (progress[book.id]?.length ?? 0) >= book.chapters.length,
        )
        .length;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_stories_rounded, color: _green, size: 34),
              const SizedBox(height: 10),
              Text(
                'Tu camino de lectura',
                style: GoogleFonts.instrumentSerif(color: _ink, fontSize: 32),
              ),
              const SizedBox(height: 6),
              const Text(
                'Elige un libro y avanza capítulo a capítulo. Tu progreso se guarda en tu cuenta.',
                style: TextStyle(color: _muted, height: 1.5),
              ),
              const SizedBox(height: 18),
              Text(
                '$completedBooks de ${_books.length} libros completados',
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Elige un desafío',
          style: GoogleFonts.instrumentSerif(color: _ink, fontSize: 27),
        ),
        const SizedBox(height: 12),
        for (final book in _books)
          _ChallengeBookCard(
            book: book,
            completed: progress[book.id] ?? const {},
            onTap: () => onSelect(book, progress[book.id] ?? const {}),
          ),
        const SizedBox(height: 18),
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(Icons.lightbulb_outline, color: _green),
            title: const Text('Historia del pensamiento'),
            subtitle: const Text('Conserva este acceso para explorar ideas.'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Historia del pensamiento se mantiene disponible desde Lectio.',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChallengeBookCard extends StatelessWidget {
  const _ChallengeBookCard({
    required this.book,
    required this.completed,
    required this.onTap,
  });

  final ChallengeBook book;
  final Set<int> completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = completed.length / book.chapters.length;
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _line),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: book.accent.withValues(alpha: .12),
          child: Text(
            book.icon,
            style: TextStyle(color: book.accent, fontSize: 22),
          ),
        ),
        title: Text(book.title, style: const TextStyle(color: _ink)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.description),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: ratio,
                color: _green,
                backgroundColor: _line,
              ),
              const SizedBox(height: 5),
              Text('${completed.length} de ${book.chapters.length} capítulos'),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: _muted),
        onTap: onTap,
      ),
    );
  }
}

class _ChallengeBookPage extends StatefulWidget {
  const _ChallengeBookPage({
    required this.book,
    required this.initialCompleted,
    required this.service,
  });

  final ChallengeBook book;
  final Set<int> initialCompleted;
  final ChallengeDataSource service;

  @override
  State<_ChallengeBookPage> createState() => _ChallengeBookPageState();
}

class _ChallengeBookPageState extends State<_ChallengeBookPage> {
  late final Set<int> _completed = {...widget.initialCompleted};
  int? _savingChapter;

  Future<void> _readChapter(int index) async {
    final chapterNumber = index + 1;
    final completed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.book.title} · Capítulo $chapterNumber'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'RELATO ORIGINAL',
                style: TextStyle(
                  color: _green,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.book.chapters[index],
                style: const TextStyle(height: 1.7),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              _completed.contains(chapterNumber) ? 'Cerrar' : 'Ahora no',
            ),
          ),
          if (!_completed.contains(chapterNumber))
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Marcar como leído'),
            ),
        ],
      ),
    );
    if (completed != true || !mounted) return;
    setState(() => _savingChapter = chapterNumber);
    try {
      await widget.service.saveChapter(
        bookId: widget.book.id,
        chapter: chapterNumber,
        totalChapters: widget.book.chapters.length,
      );
      if (!mounted) return;
      setState(() {
        _completed.add(chapterNumber);
        _savingChapter = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _completed.length == widget.book.chapters.length
                ? '¡Reto completado! Tu avance quedó guardado.'
                : 'Capítulo leído. Tu progreso quedó guardado.',
          ),
        ),
      );
    } on ChallengeException catch (error) {
      if (!mounted) return;
      setState(() => _savingChapter = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _completed.length / widget.book.chapters.length;
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        title: Text(widget.book.title),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: widget.book.accent.withValues(alpha: .12),
                  child: Text(
                    widget.book.icon,
                    style: TextStyle(color: widget.book.accent, fontSize: 30),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.book.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.instrumentSerif(color: _ink, fontSize: 30),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_completed.length} de ${widget.book.chapters.length} capítulos leídos',
                  style: const TextStyle(color: _muted),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress, color: _green),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'TU CAMINO DE LECTURA',
              style: GoogleFonts.jetBrainsMono(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < widget.book.chapters.length; index++) ...[
            _chapterNode(index),
            if (index < widget.book.chapters.length - 1)
              _chapterConnector(index),
          ],
          const SizedBox(height: 16),
          const Text(
            'Añade aquí textos propios o con licencia para acompañar cada capítulo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _chapterNode(int index) {
    final number = index + 1;
    final isRead = _completed.contains(number);
    final unlocked = number == 1 || _completed.contains(number - 1);
    final saving = _savingChapter == number;
    final offset = switch (index % 4) {
      0 => -34.0,
      1 => 20.0,
      2 => 34.0,
      _ => -20.0,
    };
    return Transform.translate(
      offset: Offset(offset, 0),
      child: Column(
        children: [
          Semantics(
            button: true,
            enabled: unlocked && !saving,
            label: isRead
                ? 'Capítulo $number, leído'
                : unlocked
                ? 'Leer capítulo $number'
                : 'Capítulo $number bloqueado',
            child: Tooltip(
              message: isRead
                  ? 'Capítulo $number completado'
                  : unlocked
                  ? 'Leer capítulo $number'
                  : 'Completa el capítulo anterior',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: unlocked && !saving ? () => _readChapter(index) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: isRead ? 78 : 70,
                  height: isRead ? 78 : 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRead
                        ? _green
                        : unlocked
                        ? widget.book.accent
                        : const Color(0xFFE5EAE7),
                    border: Border.all(
                      color: isRead
                          ? const Color(0xFF8DC9A5)
                          : unlocked
                          ? Colors.white
                          : _line,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isRead
                                    ? _green
                                    : unlocked
                                    ? widget.book.accent
                                    : Colors.black)
                                .withValues(alpha: unlocked ? .22 : .06),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: saving
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isRead
                                ? Icons.check_rounded
                                : unlocked
                                ? Icons.menu_book_rounded
                                : Icons.lock_rounded,
                            color: unlocked || isRead ? Colors.white : _muted,
                            size: 27,
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Capítulo $number',
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isRead
                ? 'Completado'
                : unlocked
                ? 'Toca para leer'
                : 'Bloqueado',
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _chapterConnector(int index) {
    final nextUnlocked = _completed.contains(index + 1);
    return Container(
      width: 5,
      height: 28,
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: nextUnlocked ? _green : _line,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

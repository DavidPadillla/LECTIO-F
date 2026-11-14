import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../data/offline_content.dart';
import '../data/offline_store.dart';

Future<bool> _save(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo guardar. Revisa el almacenamiento y vuelve a intentarlo.',
          ),
        ),
      );
    }
    return false;
  }
}

class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key, this.store});
  final OfflineStore? store;
  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  late final store = widget.store ?? OfflineStore();
  String topic = 'Todos', level = 'Todos';
  @override
  void initState() {
    super.initState();
    if (!store.ready) unawaited(store.load());
  }

  @override
  void dispose() {
    if (widget.store == null) store.close();
    super.dispose();
  }

  void _open(Widget page) => Navigator.of(context).push<void>(
    PageRouteBuilder(
      pageBuilder: (_, _, _) => _OfflineAppearance(store: store, child: page),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ),
  );

  Future<void> _read(OfflineReading r) async {
    if (await _save(context, () => store.visit(r.id)) && mounted) {
      _open(_ReadingPage(store: store, reading: r));
    }
  }

  @override
  Widget build(BuildContext context) => _OfflineAppearance(
    store: store,
    child: Builder(
      builder: (context) {
        _OfflineScope.watch(context);
        if (!store.ready) {
          return Scaffold(
            appBar: AppBar(title: const Text('Modo sin conexión')),
            body: Center(
              child: store.error == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(store.error!),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: store.load,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        }
        final current = offlineReadings
            .where((r) => r.id == store.currentId)
            .firstOrNull;
        final readings = offlineReadings.where(
          (r) =>
              (topic == 'Todos' || r.topic == topic) &&
              (level == 'Todos' || r.level == level),
        );
        return Scaffold(
          appBar: AppBar(
            title: const Text('Lectio sin conexión'),
            actions: [
              IconButton(
                tooltip: 'Configuración',
                onPressed: () => _open(_OfflineSettings(store: store)),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Un momento para leer',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lecturas originales y actividades disponibles sin internet ni cuenta. Tu progreso se guarda en este teléfono.',
                  ),
                  const SizedBox(height: 20),
                  if (current != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.bookmark_outline),
                        title: const Text('Continuar'),
                        subtitle: Text(current.title),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => _read(current),
                      ),
                    ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _open(
                          _ProgressPage(store: store, openReading: _read),
                        ),
                        icon: const Icon(Icons.insights),
                        label: const Text('Mi progreso'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _open(_MistakesPage(store: store)),
                        icon: const Icon(Icons.psychology_outlined),
                        label: const Text('Practicar mis errores'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Explorar lecturas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: topic,
                    decoration: const InputDecoration(
                      labelText: 'Tema',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        [
                              'Todos',
                              ...offlineReadings.map((r) => r.topic).toSet(),
                            ]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => topic = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: level,
                    decoration: const InputDecoration(
                      labelText: 'Dificultad',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Todos', 'Fácil', 'Intermedio', 'Avanzado']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => level = v!),
                  ),
                  const SizedBox(height: 12),
                  for (final r in readings)
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Icon(
                          store.complete(r)
                              ? Icons.task_alt
                              : Icons.menu_book_outlined,
                        ),
                        title: Text(r.title),
                        subtitle: Text(
                          '${r.topic} · ${r.level} · ${r.minutes} min\n${store.answers(r.id).length}/3 actividades respondidas',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _read(r),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _OfflineAppearance extends StatelessWidget {
  const _OfflineAppearance({required this.store, required this.child});
  final OfflineStore store;
  final Widget child;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final dark = store.background == 'dark';
      final surface = dark
          ? const Color(0xFF171D21)
          : store.background == 'sepia'
          ? const Color(0xFFF5ECD9)
          : Colors.white;
      final theme = ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF287A53),
          brightness: dark ? Brightness.dark : Brightness.light,
          surface: surface,
        ),
        scaffoldBackgroundColor: surface,
      );
      return _OfflineScope(
        store: store,
        child: Theme(data: theme, child: child),
      );
    },
  );
}

class _OfflineScope extends InheritedNotifier<OfflineStore> {
  const _OfflineScope({required OfflineStore store, required super.child})
    : super(notifier: store);
  static void watch(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<_OfflineScope>();
  }
}

class _ReadingPage extends StatefulWidget {
  const _ReadingPage({required this.store, required this.reading});
  final OfflineStore store;
  final OfflineReading reading;
  @override
  State<_ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<_ReadingPage>
    with WidgetsBindingObserver {
  final wordTap = TapGestureRecognizer();
  late final controller = ScrollController(
    initialScrollOffset:
        (widget.store.progress(widget.reading.id)['offset'] as num?)
            ?.toDouble() ??
        0,
  );
  Timer? timer;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.addListener(_scrolled);
    wordTap.onTap = _vocabulary;
  }

  void _vocabulary() {
    final r = widget.reading;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(r.word),
        content: Text('${r.definition}\n\nEjemplo: ${r.example}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _scrolled() {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 450), _remember);
  }

  void _remember() {
    if (!controller.hasClients) return;
    unawaited(
      _save(
        context,
        () => widget.store.visit(widget.reading.id, offset: controller.offset),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _remember();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    wordTap.dispose();
    WidgetsBinding.instance.removeObserver(this);
    // Capture the last position before detaching the scroll controller.
    if (controller.hasClients) {
      unawaited(
        widget.store
            .visit(widget.reading.id, offset: controller.offset)
            .catchError((Object _) {}),
      );
    }
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _OfflineScope.watch(context);
    final r = widget.reading;
    final store = widget.store;
    final parts = r.text.split(r.word);
    return Scaffold(
      appBar: AppBar(title: Text(r.title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Text('${r.topic} · ${r.level} · ${r.minutes} min'),
              const SizedBox(height: 18),
              Text(r.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  children: [
                    for (var i = 0; i < parts.length; i++) ...[
                      TextSpan(text: parts[i]),
                      if (i < parts.length - 1)
                        TextSpan(
                          text: r.word,
                          recognizer: wordTap,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                    ],
                  ],
                ),
                style: TextStyle(
                  fontSize: store.fontSize,
                  height: store.lineHeight,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.menu_book_outlined),
                label: Text('Vocabulario: ${r.word}'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(r.word),
                    content: Text('${r.definition}\n\nEjemplo: ${r.example}'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Entendido'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        timer?.cancel();
                        setState(() => busy = true);
                        final saved = await _save(
                          context,
                          () => store.visit(r.id, offset: controller.offset),
                        );
                        if (!context.mounted) return;
                        setState(() => busy = false);
                        if (saved) {
                          Navigator.of(context).push<void>(
                            PageRouteBuilder(
                              pageBuilder: (_, _, _) => _OfflineAppearance(
                                store: store,
                                child: _QuizPage(store: store, reading: r),
                              ),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.quiz_outlined),
                label: const Text('Preguntas de comprensión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizPage extends StatefulWidget {
  const _QuizPage({required this.store, required this.reading, this.review});
  final OfflineStore store;
  final OfflineReading reading;
  final List<int>? review;
  @override
  State<_QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<_QuizPage> {
  late final indices =
      widget.review ?? List.generate(widget.reading.exercises.length, (i) => i);
  late int position = _initialPosition();
  int? selected;
  List<int> order = [2, 0, 1];
  bool busy = false;
  final scroll = ScrollController();
  // Reviewing errors starts a fresh attempt without discarding previous results.
  final reviewed = <int>{};
  int _initialPosition() {
    if (widget.review != null) return 0;
    final a = widget.store.answers(widget.reading.id);
    final next = indices.indexWhere((i) => !a.containsKey('$i'));
    return next == -1 ? indices.length : next;
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void _next() {
    setState(() {
      position++;
      selected = null;
      order = [2, 0, 1];
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    _OfflineScope.watch(context);
    final r = widget.reading, store = widget.store;
    if (position >= indices.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultado')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.task_alt, size: 64),
            const SizedBox(height: 16),
            Text(r.title, style: Theme.of(context).textTheme.headlineSmall),
            Text(
              '${store.correct(r)} de ${r.exercises.length} respuestas correctas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              store.mistakes(r).isEmpty
                  ? '¡Buen trabajo! Puedes elegir otra lectura.'
                  : 'Puedes repasar los errores y volver al texto cuando quieras.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      final saved =
                          widget.review != null ||
                          await _save(context, () => store.restart(r.id));
                      if (!mounted) return;
                      setState(() {
                        busy = false;
                        if (saved) {
                          position = 0;
                          selected = null;
                          reviewed.clear();
                          order = [2, 0, 1];
                        }
                      });
                    },
              child: const Text('Volver a intentarlo'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver a la lectura'),
            ),
          ],
        ),
      );
    }
    final index = indices[position], q = r.exercises[index];
    final previous = store.answers(r.id)['$index'];
    final answered =
        previous != null && (widget.review == null || reviewed.contains(index));
    final options = List.generate(q.options.length, (i) => i);
    if (q.kind == ExerciseKind.choice) {
      final shift =
          r.id.codeUnits.fold<int>(0, (a, b) => a + b) % options.length;
      options.addAll(options.take(shift).toList());
      options.removeRange(0, shift);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.review == null ? 'Comprensión' : 'Repasar errores'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(24),
            children: [
              Text('${r.title} · Actividad ${position + 1}/${indices.length}'),
              const SizedBox(height: 12),
              Text(
                q.prompt,
                style: TextStyle(
                  fontSize: store.fontSize,
                  height: store.lineHeight,
                ),
              ),
              const SizedBox(height: 16),
              if (q.kind != ExerciseKind.order)
                for (final i in options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        backgroundColor:
                            (answered
                                ? (previous['selection'] as List).contains(i)
                                : selected == i)
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        padding: const EdgeInsets.all(16),
                      ),
                      onPressed: answered || busy
                          ? null
                          : () => setState(() => selected = i),
                      child: Text(
                        q.options[i],
                        style: TextStyle(fontSize: store.fontSize),
                      ),
                    ),
                  ),
              if (q.kind == ExerciseKind.order) ...[
                const Text('Usa las flechas para mover cada acontecimiento.'),
                for (var i = 0; i < order.length; i++)
                  Card(
                    child: ListTile(
                      leading: Text('${i + 1}'),
                      title: Text(
                        q.options[answered
                            ? (previous['selection'] as List)[i] as int
                            : order[i]],
                      ),
                      subtitle: answered
                          ? null
                          : Wrap(
                              children: [
                                IconButton(
                                  tooltip: 'Subir acontecimiento ${i + 1}',
                                  onPressed: i == 0 || busy
                                      ? null
                                      : () => setState(() {
                                          final value = order.removeAt(i);
                                          order.insert(i - 1, value);
                                        }),
                                  icon: const Icon(Icons.arrow_upward),
                                ),
                                IconButton(
                                  tooltip: 'Bajar acontecimiento ${i + 1}',
                                  onPressed: i == order.length - 1 || busy
                                      ? null
                                      : () => setState(() {
                                          final value = order.removeAt(i);
                                          order.insert(i + 1, value);
                                        }),
                                  icon: const Icon(Icons.arrow_downward),
                                ),
                              ],
                            ),
                    ),
                  ),
              ],
              if (!answered)
                FilledButton(
                  onPressed:
                      busy || (q.kind != ExerciseKind.order && selected == null)
                      ? null
                      : () async {
                          setState(() => busy = true);
                          final saved = await _save(
                            context,
                            () => store.answer(
                              r,
                              index,
                              q.kind == ExerciseKind.order
                                  ? List.of(order)
                                  : [selected!],
                            ),
                          );
                          if (!mounted) return;
                          setState(() {
                            busy = false;
                            if (saved) reviewed.add(index);
                          });
                        },
                  child: const Text('Comprobar respuesta'),
                ),
              if (answered) ...[
                const SizedBox(height: 16),
                Text(
                  previous['correct'] == true
                      ? '¡Correcto!'
                      : 'Vamos a repasarlo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(q.explanation, style: TextStyle(fontSize: store.fontSize)),
                const SizedBox(height: 12),
                const Text('En el texto:'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      q.evidence,
                      style: TextStyle(
                        fontSize: store.fontSize,
                        height: store.lineHeight,
                      ),
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: _next,
                  child: Text(
                    position == indices.length - 1
                        ? 'Ver resultado'
                        : 'Siguiente',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressPage extends StatelessWidget {
  const _ProgressPage({required this.store, required this.openReading});
  final OfflineStore store;
  final Future<void> Function(OfflineReading) openReading;
  @override
  Widget build(BuildContext context) {
    _OfflineScope.watch(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mi progreso')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${offlineReadings.where(store.complete).length}/${offlineReadings.length} lecturas completadas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            '${offlineReadings.fold<int>(0, (total, r) => total + store.correct(r))} respuestas correctas',
          ),
          const Text(
            'Una lectura se completa al responder sus tres actividades. Los resultados se actualizan al practicar.',
          ),
          const SizedBox(height: 20),
          for (final level in ['Fácil', 'Intermedio', 'Avanzado']) ...[
            Text(level, style: Theme.of(context).textTheme.titleMedium),
            LinearProgressIndicator(
              value:
                  offlineReadings
                      .where((r) => r.level == level && store.complete(r))
                      .length /
                  5,
            ),
            const SizedBox(height: 16),
          ],
          for (final r in offlineReadings.where(
            (r) => store.answers(r.id).isNotEmpty,
          ))
            ListTile(
              title: Text(r.title),
              subtitle: Text(
                '${store.correct(r)}/3 aciertos · ${store.complete(r) ? 'Completada' : 'En curso'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openReading(r),
            ),
        ],
      ),
    );
  }
}

class _MistakesPage extends StatelessWidget {
  const _MistakesPage({required this.store});
  final OfflineStore store;
  @override
  Widget build(BuildContext context) {
    _OfflineScope.watch(context);
    final readings = offlineReadings.where((r) => store.mistakes(r).isNotEmpty);
    return Scaffold(
      appBar: AppBar(title: const Text('Practicar mis errores')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Repite las preguntas falladas. Cada respuesta corregida actualiza tu progreso.',
          ),
          if (readings.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No tienes errores pendientes. ¡Puedes explorar otra lectura!',
              ),
            ),
          for (final r in readings)
            Card(
              child: ListTile(
                title: Text(r.title),
                subtitle: Text(
                  '${store.mistakes(r).length} preguntas para repasar',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push<void>(
                  PageRouteBuilder(
                    pageBuilder: (_, _, _) => _OfflineAppearance(
                      store: store,
                      child: _QuizPage(
                        store: store,
                        reading: r,
                        review: store.mistakes(r),
                      ),
                    ),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OfflineSettings extends StatelessWidget {
  const _OfflineSettings({required this.store});
  final OfflineStore store;
  Future<void> _confirm(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar el progreso sin conexión?'),
        content: const Text(
          'Se eliminarán los resultados y la posición de lectura guardados en este teléfono. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (accepted == true && context.mounted) {
      await _save(context, store.clearProgress);
    }
  }

  @override
  Widget build(BuildContext context) {
    _OfflineScope.watch(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración sin conexión')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Estas preferencias solo se aplican a esta zona. El tamaño y el espaciado se usan en las lecturas y sus explicaciones.',
          ),
          const SizedBox(height: 24),
          const Text('Fondo'),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in {
                'white': 'Blanco',
                'sepia': 'Sepia',
                'dark': 'Oscuro',
              }.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: store.background == entry.key,
                  onSelected: (_) => _save(
                    context,
                    () => store.settings(background: entry.key),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Tamaño de letra: ${store.fontSize.round()}'),
          Slider(
            min: 16,
            max: 28,
            divisions: 6,
            value: store.fontSize,
            label: '${store.fontSize.round()}',
            onChanged: (v) => _save(context, () => store.settings(fontSize: v)),
          ),
          Text('Espacio entre líneas: ${store.lineHeight.toStringAsFixed(1)}'),
          Slider(
            min: 1.2,
            max: 2,
            divisions: 4,
            value: store.lineHeight,
            label: store.lineHeight.toStringAsFixed(1),
            onChanged: (v) =>
                _save(context, () => store.settings(lineHeight: v)),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Cada lectura abre una puerta a la imaginación. Este es un ejemplo de cómo se verá el texto.',
                style: TextStyle(
                  fontSize: store.fontSize,
                  height: store.lineHeight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => _save(context, store.resetSettings),
            child: const Text('Restablecer preferencias'),
          ),
          TextButton(
            onPressed: () => _confirm(context),
            child: const Text('Borrar progreso sin conexión'),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../profile/data/local_profile_store.dart';
import 'offline_content.dart';

class OfflineStore extends ChangeNotifier {
  OfflineStore({ProfileStorage? storage})
    : _storage = storage ?? SecureProfileStorage();
  final ProfileStorage _storage;
  static const storageKey = 'lectio.offline.v1';
  Map<String, dynamic> _data = {};
  Future<void> _queue = Future.value();
  bool _closed = false;
  void close() {
    _closed = true;
    unawaitedClose();
  }

  Future<void> unawaitedClose() async {
    await _queue;
    dispose();
  }

  bool ready = false;
  String? error;
  String get background => _data['background'] as String? ?? 'white';
  double get fontSize => (_data['fontSize'] as num?)?.toDouble() ?? 18;
  double get lineHeight => (_data['lineHeight'] as num?)?.toDouble() ?? 1.6;
  String? get currentId => _data['current'] as String?;
  Map<String, dynamic> progress(String id) =>
      Map<String, dynamic>.from((_data['progress'] as Map?)?[id] as Map? ?? {});
  Map<String, dynamic> answers(String id) =>
      Map<String, dynamic>.from(progress(id)['answers'] as Map? ?? {});
  bool complete(OfflineReading r) => answers(r.id).length == r.exercises.length;
  int correct(OfflineReading r) =>
      answers(r.id).values.where((a) => a['correct'] == true).length;
  List<int> mistakes(OfflineReading r) =>
      answers(r.id).entries
          .where((e) => e.value['correct'] != true)
          .map((e) => int.parse(e.key))
          .toList()
        ..sort();

  Future<void> load() async {
    try {
      final raw = await _storage.read(storageKey);
      final data = raw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (data['progress'] != null && data['progress'] is! Map) {
        throw const FormatException();
      }
      final size = data['fontSize'];
      final height = data['lineHeight'];
      if (data['background'] != null &&
          !['white', 'sepia', 'dark'].contains(data['background'])) {
        throw const FormatException();
      }
      if (data['current'] != null && data['current'] is! String) {
        throw const FormatException();
      }
      if (size != null && (size is! num || size < 16 || size > 28)) {
        throw const FormatException();
      }
      if (height != null && (height is! num || height < 1.2 || height > 2)) {
        throw const FormatException();
      }
      for (final r in offlineReadings) {
        final p = (data['progress'] as Map?)?[r.id];
        if (p == null) continue;
        if (p is! Map ||
            (p['offset'] != null && (p['offset'] is! num || p['offset'] < 0))) {
          throw const FormatException();
        }
        if (p['answers'] != null) {
          for (final e in (p['answers'] as Map).entries) {
            final index = int.tryParse(e.key.toString());
            if (index == null ||
                index < 0 ||
                index >= r.exercises.length ||
                e.value is! Map ||
                e.value['correct'] is! bool) {
              throw const FormatException();
            }
            final selection = e.value['selection'];
            final q = r.exercises[index];
            if (selection is! List ||
                selection.length !=
                    (q.kind == ExerciseKind.order ? q.options.length : 1) ||
                selection.any(
                  (v) => v is! int || v < 0 || v >= q.options.length,
                ) ||
                selection.toSet().length != selection.length) {
              throw const FormatException();
            }
          }
        }
      }
      _data = data;
      ready = true;
      error = null;
    } catch (_) {
      ready = false;
      error = 'No se pudieron leer los datos locales. Reintenta para evitar perder tu progreso.';
    }
    if (!_closed) notifyListeners();
  }

  Future<void> _save(void Function(Map<String, dynamic>) edit) {
    final task = _queue.then((_) async {
      if (!ready) throw StateError('Los datos locales no están disponibles.');
      final next = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(_data)) as Map,
      );
      edit(next);
      await _storage.write(storageKey, jsonEncode(next));
      _data = next;
      if (!_closed) notifyListeners();
    });
    _queue = task.catchError((Object _) {});
    return task;
  }

  Future<void> settings({
    String? background,
    double? fontSize,
    double? lineHeight,
  }) => _save((d) {
    if (background != null) d['background'] = background;
    if (fontSize != null) d['fontSize'] = fontSize.clamp(16, 28);
    if (lineHeight != null) d['lineHeight'] = lineHeight.clamp(1.2, 2);
  });
  Future<void> visit(String id, {double? offset}) => _save((d) {
    d['current'] = id;
    final all = d['progress'] ??= <String, dynamic>{};
    final p = all[id] ??= <String, dynamic>{};
    if (offset != null) p['offset'] = offset;
  });
  Future<void> answer(OfflineReading r, int index, List<int> selection) =>
      _save((d) {
        final q = r.exercises[index];
        final correct = q.kind == ExerciseKind.order
            ? listEquals(selection, List.generate(q.options.length, (i) => i))
            : listEquals(selection, [q.correct]);
        d['current'] = r.id;
        final all = d['progress'] ??= <String, dynamic>{};
        final p = all[r.id] ??= <String, dynamic>{};
        final a = p['answers'] ??= <String, dynamic>{};
        a['$index'] = {'correct': correct, 'selection': selection};
      });
  Future<void> resetSettings() => _save((d) {
    d.remove('background');
    d.remove('fontSize');
    d.remove('lineHeight');
  });
  Future<void> clearProgress() => _save((d) {
    d.remove('progress');
    d.remove('current');
  });
  Future<void> restart(String id) => _save((d) {
    (d['progress'] as Map?)?.remove(id);
    d['current'] = id;
  });
}

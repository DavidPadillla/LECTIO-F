import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../notifications/data/lectio_notifications.dart';
import '../../notifications/data/notification_preferences.dart';

const readingGenres = [
  'Novelas',
  'Ciencia',
  'Historia',
  'Arte',
  'Fantasía',
  'Filosofía',
];
const readingStates = ['Por leer', 'Leyendo', 'Terminado'];

abstract interface class ProfileStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SecureProfileStorage implements ProfileStorage {
  final _storage = const FlutterSecureStorage();
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class SavedBook {
  const SavedBook({
    required this.url,
    required this.title,
    required this.category,
    this.author = '',
    this.favorite = false,
    this.status = 'Por leer',
    this.finishedAt,
  });
  final String url, title, category, author, status;
  final bool favorite;
  final DateTime? finishedAt;
  SavedBook copy({bool? favorite, String? status}) {
    final nextStatus = status ?? this.status;
    return SavedBook(
      url: url,
      title: title,
      category: category,
      author: author,
      favorite: favorite ?? this.favorite,
      status: nextStatus,
      finishedAt: nextStatus == 'Terminado'
          ? (this.status == 'Terminado' ? finishedAt : DateTime.now())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    'category': category,
    'author': author,
    'favorite': favorite,
    'status': status,
    'finishedAt': finishedAt?.toIso8601String(),
  };
  factory SavedBook.fromJson(Map<String, dynamic> j) => SavedBook(
    url: j['url'] as String,
    title: j['title'] as String,
    category: j['category'] as String? ?? '',
    author: j['author'] as String? ?? '',
    favorite: j['favorite'] == true,
    status: readingStates.contains(j['status'])
        ? j['status'] as String
        : 'Por leer',
    finishedAt: DateTime.tryParse(j['finishedAt'] as String? ?? ''),
  );
}

class LocalProfile {
  LocalProfile({
    this.photoBase64,
    Set<String>? genres,
    this.goal = 2,
    this.theme = 'light',
    this.textScale = 1,
    this.music = true,
    this.video = true,
    this.hideName = false,
    NotificationPreferences? notifications,
    this.goalNotifiedMonth,
    Map<String, SavedBook>? books,
  }) : genres = genres ?? {},
       books = books ?? {},
       notifications = notifications ?? NotificationPreferences();
  NotificationPreferences notifications;
  String? goalNotifiedMonth;
  String theme;
  String? photoBase64;
  Uint8List? get photoBytes {
    try {
      return photoBase64 == null ? null : base64Decode(photoBase64!);
    } on FormatException {
      return null;
    }
  }

  Set<String> genres;
  int goal;
  double textScale;
  bool music, video, hideName;
  Map<String, SavedBook> books;
  int completedIn(DateTime month) => books.values
      .where(
        (b) =>
            b.status == 'Terminado' &&
            b.finishedAt?.year == month.year &&
            b.finishedAt?.month == month.month,
      )
      .length;
  Map<String, dynamic> toJson() => {
    'photoBase64': photoBase64,
    'genres': genres.toList(),
    'goal': goal,
    'theme': theme,
    'textScale': textScale,
    'music': music,
    'video': video,
    'hideName': hideName,
    'notifications': notifications.toJson(),
    'goalNotifiedMonth': goalNotifiedMonth,
    'books': books.map((k, v) => MapEntry(k, v.toJson())),
  };
  factory LocalProfile.fromJson(Map<String, dynamic> j) => LocalProfile(
    photoBase64: j['photoBase64'] as String?,
    genres: (j['genres'] as List? ?? []).whereType<String>().toSet(),
    goal: ((j['goal'] as num?)?.toInt() ?? 2).clamp(1, 100),
    theme: ['system', 'light', 'dark'].contains(j['theme'])
        ? j['theme'] as String
        : 'light',
    textScale: ((j['textScale'] as num?)?.toDouble() ?? 1).clamp(1, 1.4),
    music: j['music'] != false,
    video: j['video'] != false,
    hideName: j['hideName'] == true,
    notifications: NotificationPreferences.fromJson(
      j['notifications'] as Map<String, dynamic>? ?? {},
    ),
    goalNotifiedMonth: j['goalNotifiedMonth'] as String?,
    books: (j['books'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, SavedBook.fromJson(v as Map<String, dynamic>)),
    ),
  );
}

/// Profile mutations are serialized and published only after a successful write.
class LocalProfileStore extends ChangeNotifier {
  LocalProfileStore({
    ProfileStorage? storage,
    LectioNotifications? notifications,
  }) : _storage = storage ?? SecureProfileStorage(),
       notifications = notifications ?? LectioNotifications();
  final LectioNotifications notifications;
  String? notificationError;
  static final instance = LocalProfileStore();
  final ProfileStorage _storage;
  LocalProfile _profile = LocalProfile();
  LocalProfile get profile => _profile;
  String? username;
  String? loadError;
  String displayNameFor(String user) => username != user
      ? user
      : _profile.hideName
      ? 'lector'
      : user;
  Future<void> _queue = Future.value();
  String _key(String user) =>
      'lectio.profile.v1.${base64Url.encode(utf8.encode(user))}';

  Future<void> initialize() async {
    try {
      final last = await _storage.read('lectio.last-profile');
      if (last != null) await openUser(last);
    } catch (_) {
      loadError = 'No se pudieron cargar las preferencias locales.';
    }
  }

  Future<void> openUser(String user) {
    final task = _queue.then((_) async {
      try {
        final raw = await _storage.read(_key(user));
        final loaded = raw == null
            ? LocalProfile()
            : LocalProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        await _storage.write('lectio.last-profile', user);
        username = user;
        _profile = loaded;
        loadError = null;
      } catch (_) {
        username = user;
        _profile = LocalProfile();
        loadError = 'No se pudieron leer tus datos locales. Reintenta antes de guardar cambios.';
      }
      notifyListeners();
    });
    _queue = task.catchError((Object _) {});
    return task;
  }

  Future<void> update(void Function(LocalProfile) edit) {
    final owner = username;
    final task = _queue.then((_) async {
      if (owner == null || owner != username || loadError != null) {
        throw StateError('No se pudo abrir el almacenamiento de este usuario.');
      }
      final next = LocalProfile.fromJson(_profile.toJson());
      edit(next);
      final now = DateTime.now();
      final month = '${now.year}-${now.month}';
      final finished = next.books.values.any(
        (book) =>
            book.status == 'Terminado' &&
            _profile.books[book.url]?.status != 'Terminado',
      );
      final goal =
          finished &&
          notifications.supported &&
          notifications.activeUser == owner &&
          next.notifications.enabled &&
          next.notifications.goals &&
          next.completedIn(now) > _profile.completedIn(now) &&
          next.completedIn(now) >= next.goal &&
          next.goalNotifiedMonth != month;
      if (goal) next.goalNotifiedMonth = month;
      final settingsChanged =
          jsonEncode(next.notifications.toJson()) !=
          jsonEncode(_profile.notifications.toJson());
      await _storage.write(_key(owner), jsonEncode(next.toJson()));
      _profile = next;
      notifyListeners();
      if (settingsChanged) await _syncNotifications();
      if (finished) {
        await _notificationAction(
          () => notifications.event(owner, next.notifications, 7300),
        );
      }
      if (goal) {
        await _notificationAction(
          () => notifications.event(owner, next.notifications, 7400),
        );
      }
    });
    _queue = task.catchError((Object _) {});
    return task;
  }

  Future<void> saveBook(SavedBook book) =>
      update((p) => p.books[book.url] = book);
  Future<void> resetSettings() => update((p) {
    p.theme = 'light';
    p.textScale = 1;
    p.music = true;
    p.video = true;
    p.hideName = false;
    p.notifications = NotificationPreferences();
  });
  Future<void> clearLocalData() => update((p) {
    final defaults = LocalProfile();
    p.photoBase64 = null;
    p.genres.clear();
    p.goal = defaults.goal;
    p.books.clear();
    p.theme = defaults.theme;
    p.textScale = 1;
    p.music = true;
    p.video = true;
    p.hideName = false;
    p.notifications = NotificationPreferences();
    p.goalNotifiedMonth = null;
  });

  Future<void> _notificationAction(
    Future<void> Function() action, {
    bool clearError = false,
  }) async {
    try {
      await action();
      if (clearError) notificationError = null;
    } catch (error) {
      notificationError = error is NotificationException ? error.message : 'No se pudieron configurar los avisos de Android. Reintenta desde Notificaciones.';
    }
    notifyListeners();
  }

  Future<void> _syncNotifications() async {
    if (username == null) return;
    await _notificationAction(
      () => notifications.configure(username!, _profile.notifications),
      clearError: true,
    );
  }

  Future<void> activateNotifications() {
    final user = username;
    final task = _queue.then((_) async {
      if (user == null || user != username) return;
      await _notificationAction(
        () => notifications.activate(
          user,
          loadError == null
              ? _profile.notifications
              : NotificationPreferences(),
        ),
        clearError: true,
      );
    });
    _queue = task.catchError((Object _) {});
    return task;
  }

  Future<void> refreshNotifications() {
    final task = _queue.then((_) => _syncNotifications());
    _queue = task.catchError((Object _) {});
    return task;
  }

  Future<void> deactivateNotifications() {
    final user = username;
    final task = _queue.then((_) async {
      if (user == null) return;
      try {
        await notifications.deactivate(user);
      } catch (_) {
        throw const NotificationException(
          'No se pudieron cancelar los recordatorios. Intenta cerrar sesión nuevamente.',
        );
      }
    });
    _queue = task.catchError((Object _) {});
    return task;
  }

  Future<void> notifyReservationConfirmed(String user) {
    if (user != username ||
        notifications.activeUser != user ||
        !_profile.notifications.enabled ||
        !_profile.notifications.reservations) {
      return Future.value();
    }
    final task = _queue.then((_) async {
      if (user != username) return;
      await _notificationAction(
        () => notifications.event(user, _profile.notifications, 7200),
      );
    });
    _queue = task.catchError((Object _) {});
    return task;
  }
}

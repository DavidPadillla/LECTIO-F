import 'dart:convert';

import 'package:app/features/profile/data/local_profile_store.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryProfileStorage implements ProfileStorage {
  final values = <String, String>{};
  bool fail = false;
  @override
  Future<String?> read(String key) async {
    if (fail) throw StateError('Storage unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (fail) throw StateError('Storage unavailable');
    values[key] = value;
  }
}

void main() {
  const book = SavedBook(
    url: 'https://example.test/book',
    title: 'Libro',
    category: 'Ciencia',
  );

  test(
    'profiles and preferences persist and remain isolated per username',
    () async {
      final storage = MemoryProfileStorage();
      final store = LocalProfileStore(storage: storage);
      await store.openUser('lector');
      await store.update((p) {
        p.photoBase64 = 'AQID';
        p.theme = 'dark';
        p.genres = {'Ciencia'};
      });
      await store.saveBook(book.copy(favorite: true));
      await store.openUser('otro');
      expect(store.profile.photoBase64, isNull);
      expect(store.profile.books, isEmpty);
      await store.update((p) => p.photoBase64 = 'BAUG');
      final reopened = LocalProfileStore(storage: storage);
      await reopened.openUser('lector');
      expect(reopened.profile.photoBase64, 'AQID');
      expect(reopened.profile.theme, 'dark');
      expect(reopened.profile.genres, {'Ciencia'});
      expect(reopened.profile.books[book.url]!.favorite, isTrue);
    },
  );

  test(
    'startup loads last user preferences and privacy controls display name',
    () async {
      final storage = MemoryProfileStorage();
      final store = LocalProfileStore(storage: storage);
      await store.openUser('lector');
      await store.update((p) {
        p.photoBase64 = 'AQID';
        p.hideName = true;
        p.music = false;
        p.video = false;
      });
      final reopened = LocalProfileStore(storage: storage);
      await reopened.initialize();
      expect(reopened.username, 'lector');
      expect(reopened.profile.music, isFalse);
      expect(reopened.profile.video, isFalse);
      expect(reopened.displayNameFor('lector'), 'lector');
      expect(reopened.displayNameFor('otro'), 'otro');
      await reopened.update((p) => p.hideName = false);
      expect(reopened.displayNameFor('lector'), 'lector');
    },
  );

  test(
    'completed books count once and retain original completion date',
    () async {
      final storage = MemoryProfileStorage();
      final store = LocalProfileStore(storage: storage);
      await store.openUser('lector');
      final finished = book.copy(status: 'Terminado');
      await store.saveBook(finished);
      await store.saveBook(finished.copy(status: 'Terminado', favorite: true));
      expect(store.profile.completedIn(DateTime.now()), 1);
      expect(store.profile.books[book.url]!.finishedAt, finished.finishedAt);
      expect(store.profile.completedIn(DateTime(2000)), 0);
      await store.saveBook(finished.copy(status: 'Leyendo'));
      expect(store.profile.completedIn(DateTime.now()), 0);
      expect(store.profile.books[book.url]!.finishedAt, isNull);
    },
  );

  test('reset preferences preserves profile and library, clear removes only current user', () async {
    final store = LocalProfileStore(storage: MemoryProfileStorage());
    await store.openUser('otro');
    await store.update((p) => p.photoBase64 = 'BAUG');
    await store.openUser('lector');
    await store.update((p) {
      p.photoBase64 = 'AQID';
      p.theme = 'dark';
      p.textScale = 1.4;
      p.goal = 7;
    });
    await store.saveBook(book);
    await store.resetSettings();
    expect(store.profile.theme, 'light');
    expect(store.profile.textScale, 1);
    expect(store.profile.photoBase64, 'AQID');
    expect(store.profile.books.length, 1);
    expect(store.profile.goal, 7);
    await store.clearLocalData();
    expect(store.profile.photoBase64, isNull);
    expect(store.profile.books, isEmpty);
    await store.openUser('otro');
    expect(store.profile.photoBase64, 'BAUG');
  });

  test('failed writes never publish unsaved data and queue recovers', () async {
    final storage = MemoryProfileStorage();
    final store = LocalProfileStore(storage: storage);
    await store.openUser('lector');
    storage.fail = true;
    await expectLater(
      store.update((p) => p.photoBase64 = 'BwgJ'),
      throwsStateError,
    );
    expect(store.profile.photoBase64, isNull);
    storage.fail = false;
    await store.update((p) => p.photoBase64 = 'CgsM');
    expect(store.profile.photoBase64, 'CgsM');
  });

  test('concurrent updates preserve both edits', () async {
    final store = LocalProfileStore(storage: MemoryProfileStorage());
    await store.openUser('lector');
    await Future.wait([
      store.update((p) => p.photoBase64 = 'AQID'),
      store.saveBook(book),
    ]);
    expect(store.profile.photoBase64, 'AQID');
    expect(store.profile.books.length, 1);
  });

  test(
    'corrupt storage is not silently overwritten and can be retried',
    () async {
      final storage = MemoryProfileStorage();
      final key =
          'lectio.profile.v1.${base64Url.encode(utf8.encode('lector'))}';
      storage.values[key] = 'invalid json';
      final store = LocalProfileStore(storage: storage);
      await store.openUser('lector');
      expect(store.loadError, isNotNull);
      await expectLater(
        store.update((p) => p.photoBase64 = 'AQID'),
        throwsStateError,
      );
      expect(storage.values[key], 'invalid json');
      storage.values.remove(key);
      await store.openUser('lector');
      expect(store.loadError, isNull);
      await store.update((p) => p.photoBase64 = 'AQID');
    },
  );
}

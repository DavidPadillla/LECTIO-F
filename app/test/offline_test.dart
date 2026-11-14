import 'dart:convert';

import 'package:app/features/offline/data/connection_probe.dart';
import 'package:app/features/offline/data/offline_content.dart';
import 'package:app/features/offline/data/offline_store.dart';
import 'package:app/features/offline/presentation/offline_page.dart';
import 'package:app/features/home/presentation/lectio_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'local_profile_store_test.dart' show MemoryProfileStorage;

void main() {
  test(
    'included content covers every topic and level with three valid exercises',
    () {
      expect(offlineReadings.length, 15);
      expect(offlineReadings.map((r) => r.id).toSet().length, 15);
      expect(
        offlineReadings.map((r) => '${r.topic}/${r.level}').toSet().length,
        15,
      );
      for (final r in offlineReadings) {
        expect(r.text.contains(r.word), isTrue, reason: r.title);
        expect(r.exercises.map((q) => q.kind).toSet().length, 3);
        expect(
          r.text.toLowerCase().contains(r.factEvidence.toLowerCase()),
          isTrue,
          reason: r.title,
        );
        expect(r.sequence.toSet().length, 3);
      }
    },
  );
  test('local preferences, position, answers and corrected mistakes survive reopening', () async {
    final storage = MemoryProfileStorage();
    final store = OfflineStore(storage: storage);
    await store.load();
    final r = offlineReadings.first;
    await store.settings(background: 'sepia', fontSize: 24, lineHeight: 1.8);
    await store.visit(r.id, offset: 130);
    await store.answer(r, 0, [1]);
    await store.answer(r, 1, [1]);
    await store.answer(r, 2, [0, 1, 2]);
    expect(store.complete(r), isTrue);
    expect(store.correct(r), 2);
    expect(store.mistakes(r), [0]);
    final reopened = OfflineStore(storage: storage);
    await reopened.load();
    expect(reopened.background, 'sepia');
    expect(reopened.fontSize, 24);
    expect(reopened.lineHeight, 1.8);
    expect(reopened.progress(r.id)['offset'], 130);
    expect(reopened.currentId, r.id);
    expect(reopened.mistakes(r), [0]);
    await reopened.answer(r, 0, [0]);
    expect(reopened.mistakes(r), isEmpty);
    expect(reopened.correct(r), 3);
    await reopened.resetSettings();
    expect(reopened.background, 'white');
    expect(reopened.correct(r), 3);
    await reopened.clearProgress();
    expect(reopened.currentId, isNull);
    expect(reopened.answers(r.id), isEmpty);
  });
  test('parallel updates preserve all answers and failed writes preserve previous state', () async {
    final storage = MemoryProfileStorage();
    final store = OfflineStore(storage: storage);
    await store.load();
    final r = offlineReadings.first;
    await Future.wait([
      store.answer(r, 0, [0]),
      store.answer(r, 1, [0]),
      store.answer(r, 2, [2, 0, 1]),
    ]);
    expect(store.answers(r.id).length, 3);
    expect(store.mistakes(r), [1, 2]);
    storage.fail = true;
    await expectLater(store.answer(r, 1, [1]), throwsStateError);
    expect(store.mistakes(r), [1, 2]);
    storage.fail = false;
    await store.answer(r, 1, [1]);
    expect(store.mistakes(r), [2]);
  });
  test('corrupt storage is not overwritten', () async {
    final storage = MemoryProfileStorage();
    storage.values[OfflineStore.storageKey] = jsonEncode({
      'progress': {
        'm1': {
          'answers': {
            '0': {
              'correct': true,
              'selection': [99],
            },
          },
        },
      },
    });
    final before = storage.values[OfflineStore.storageKey];
    final store = OfflineStore(storage: storage);
    await store.load();
    expect(store.ready, isFalse);
    expect(store.error, isNotNull);
    await expectLater(store.visit('m1'), throwsStateError);
    expect(storage.values[OfflineStore.storageKey], before);
  });
  test(
    'connection probe rejects captive portals and handles transport failures',
    () async {
      expect(
        await hasInternetConnection(
          client: MockClient((_) async => http.Response('', 204)),
        ),
        isTrue,
      );
      expect(
        await hasInternetConnection(
          client: MockClient((_) async => http.Response('Sign in', 200)),
        ),
        isFalse,
      );
      expect(
        await hasInternetConnection(
          client: MockClient(
            (_) async => throw http.ClientException('offline'),
          ),
        ),
        isFalse,
      );
    },
  );
  testWidgets(
    'home offers retry when offline and removes the dialog after connection recovers',
    (tester) async {
      var checks = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: LectioHomePage(
            enableVideo: false,
            connectionCheck: () async => ++checks > 1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No pudimos conectar a internet'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(checks, 2);
      expect(find.text('No pudimos conectar a internet'), findsNothing);
      expect(find.text('Sin conexión'), findsOneWidget);
    },
  );
  testWidgets(
    'reading, quiz and error review update immediately without a server',
    (tester) async {
      final store = OfflineStore(storage: MemoryProfileStorage());
      await store.load();
      await tester.pumpWidget(MaterialApp(home: OfflinePage(store: store)));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('La llave azul'), 200);
      await tester.tap(find.text('La llave azul'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Preguntas de comprensión'),
        200,
      );
      await tester.tap(find.text('Preguntas de comprensión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Un nombre escrito'));
      await tester.pump();
      await tester.tap(find.text('Comprobar respuesta'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Vamos a repasarlo'), 150);
      expect(find.text('Vamos a repasarlo'), findsOneWidget);
      expect(store.mistakes(offlineReadings.first), [0]);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Practicar mis errores'), -300);
      await tester.tap(find.text('Practicar mis errores'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('La llave azul'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('La cinta amarilla'));
      await tester.pump();
      await tester.tap(find.text('Comprobar respuesta'));
      await tester.pumpAndSettle();
      expect(find.text('¡Correcto!'), findsOneWidget);
      expect(store.mistakes(offlineReadings.first), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'offline theme stays scoped and settings update the live preview',
    (tester) async {
      final store = OfflineStore(storage: MemoryProfileStorage());
      await store.load();
      await tester.pumpWidget(MaterialApp(home: OfflinePage(store: store)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Configuración'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();
      expect(store.background, 'dark');
      expect(
        Theme.of(tester.element(find.text('Fondo'))).brightness,
        Brightness.dark,
      );
      await tester.tap(find.text('Sepia'));
      await tester.pumpAndSettle();
      expect(store.background, 'sepia');
      expect(
        Theme.of(tester.element(find.text('Fondo'))).brightness,
        Brightness.light,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'small Android layout completes true-false and ordering exercises',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = OfflineStore(storage: MemoryProfileStorage());
      await store.load();
      final r = offlineReadings.first;
      await store.answer(r, 0, [0]);
      await tester.pumpWidget(MaterialApp(home: OfflinePage(store: store)));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(r.title).last, 200);
      await tester.tap(find.text(r.title).last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Vocabulario: pistas'), 150);
      await tester.tap(find.text('Vocabulario: pistas'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Señales que ayudan'), findsOneWidget);
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Preguntas de comprensión'),
        150,
      );
      await tester.tap(find.text('Preguntas de comprensión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Falso'));
      await tester.pump();
      await tester.tap(find.text('Comprobar respuesta'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Siguiente'), 200);
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      // Initial order is [2,0,1]. Moving the first event down twice yields [0,1,2].
      await tester.tap(find.byTooltip('Bajar acontecimiento 1'));
      await tester.pump();
      await tester.tap(find.byTooltip('Bajar acontecimiento 2'));
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Comprobar respuesta'), 150);
      await tester.tap(find.text('Comprobar respuesta'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Ver resultado'), 200);
      await tester.tap(find.text('Ver resultado'));
      await tester.pumpAndSettle();
      expect(find.text('3 de 3 respuestas correctas'), findsOneWidget);
      expect(store.complete(r), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}

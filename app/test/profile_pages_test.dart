import 'package:app/features/auth/data/biometric_session_store.dart';

import 'dart:convert';
import 'dart:typed_data';

import 'package:app/features/profile/data/profile_photo_picker.dart';
import 'package:app/app/lectio_app.dart';
import 'package:app/features/auth/presentation/lectio_auth_page.dart';
import 'package:app/features/auth/data/lectio_auth_service.dart';
import 'package:app/features/auth/presentation/lectio_member_page.dart';
import 'package:app/features/analytics/data/lectio_ai_service.dart';
import 'package:app/features/virtual_books/data/libros_service.dart';
import 'package:app/features/virtual_books/presentation/libros.dart';
import 'package:app/features/profile/data/local_profile_store.dart';
import 'package:app/features/profile/presentation/profile_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'local_profile_store_test.dart' show MemoryProfileStorage;

class FakeBiometrics implements BiometricSessionStore {
  bool enabled = true;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<bool> hasSavedCredentials() async => enabled;
  @override
  Future<void> clearCredentials() async {
    enabled = false;
  }

  @override
  Future<bool> authenticate({required String reason}) async => true;
  @override
  Future<BiometricCredentials?> authenticateAndReadCredentials() async => null;
  @override
  Future<void> saveCredentials(BiometricCredentials credentials) async {}
}

class EmptyInsights implements LectioAiDataSource {
  @override
  Future<LectioPredictions> loadPredictions() async =>
      const LectioPredictions(horizonDays: 30, books: []);
  @override
  Future<LectioCategoryAnalytics> loadCategoryAnalytics() async =>
      const LectioCategoryAnalytics(
        categories: [],
        monthlyDemand: [],
        periodStart: null,
        periodEnd: null,
      );
}

class TestCatalog implements LibrosVirtualesDataSource {
  @override
  Future<List<LibroVirtual>> loadBooks() async => [
    LibroVirtual(
      titulo: 'Un libro de ciencia',
      categoria: 'Ciencia',
      autor: 'Autora',
      descripcion: 'Una descripción de lectura.',
      url: Uri.parse('https://example.test/book'),
    ),
  ];
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
    'profile accepts, changes and removes a local photo without a display name field',
    (tester) async {
      final storage = MemoryProfileStorage();
      final store = LocalProfileStore(storage: storage);
      await store.openUser('lector');
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      var choices = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(
            store: store,
            photoPicker: () async {
              choices++;
              return png;
            },
          ),
        ),
      );
      expect(find.text('Nombre para mostrar'), findsNothing);
      expect(find.text('Elige tu avatar'), findsNothing);
      await tester.tap(find.text('Elegir foto'));
      await tester.pumpAndSettle();
      expect(store.profile.photoBytes, png);
      final reopened = LocalProfileStore(storage: storage);
      await reopened.openUser('lector');
      expect(reopened.profile.photoBytes, png);
      expect(
        find.bySemanticsLabel('Foto de perfil del usuario'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cambiar foto'));
      await tester.pumpAndSettle();
      expect(choices, 2);
      await tester.tap(find.text('Quitar foto'));
      await tester.pumpAndSettle();
      expect(store.profile.photoBase64, isNull);
      expect(find.text('Elegir foto'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'canceling or rejecting a photo preserves the existing saved photo',
    (tester) async {
      final store = LocalProfileStore(storage: MemoryProfileStorage());
      await store.openUser('lector');
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      await store.update((p) => p.photoBase64 = base64Encode(png));
      Future<Uint8List?> Function() picker = () async => null;
      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(store: store, photoPicker: () => picker()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cambiar foto'));
      await tester.pumpAndSettle();
      expect(store.profile.photoBytes, png);
      picker = () async => throw const ProfilePhotoException('Foto inválida');
      await tester.tap(find.text('Cambiar foto'));
      await tester.pumpAndSettle();
      expect(store.profile.photoBytes, png);
      expect(find.text('Foto inválida'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('public pages remain light before and after dark member routes', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final store = LocalProfileStore(storage: MemoryProfileStorage());
    await store.openUser('lector');
    expect(store.profile.theme, 'light');
    await store.update((p) => p.theme = 'dark');
    await tester.pumpWidget(
      const LectioApp(enableIntroMusic: false, enableHeroVideo: false),
    );
    await tester.pump();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.light,
    );
    await tester.tapAt(const Offset(20, 120));
    await tester.pumpAndSettle();
    final publicContext = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(publicContext).brightness, Brightness.light);
    Navigator.of(publicContext).push(
      MaterialPageRoute<void>(
        builder: (_) => LectioMemberPage(
          session: const AuthSession(username: 'lector', cookie: 'test'),
          profileStore: store,
          lectioAiDataSource: EmptyInsights(),
          virtualBooksService: TestCatalog(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Hola, lector'))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.byTooltip('Abrir navegación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Libros Virtuales').last);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(LectioVirtualBooksPage))).brightness,
      Brightness.dark,
    );
    Navigator.of(publicContext).pop();
    await tester.pumpAndSettle();
    Navigator.of(publicContext).pop();
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.light,
    );
    Navigator.of(publicContext).push(
      MaterialPageRoute<void>(
        builder: (_) => LectioAuthPage(
          biometricSessionStore: FakeBiometrics()..enabled = false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(LectioAuthPage))).brightness,
      Brightness.light,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('member hamburger opens profile, settings and personal library', (
    tester,
  ) async {
    final store = LocalProfileStore(storage: MemoryProfileStorage());
    await store.openUser('lector');
    await tester.pumpWidget(
      MaterialApp(
        home: LectioMemberPage(
          session: const AuthSession(username: 'lector', cookie: 'test'),
          profileStore: store,
          lectioAiDataSource: EmptyInsights(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hola, lector'), findsOneWidget);
    expect(find.text('lector'), findsOneWidget);
    for (final entry in ['Perfil', 'Configuración', 'Mi biblioteca']) {
      await tester.tap(find.byTooltip('Abrir navegación'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry).last);
      await tester.pumpAndSettle();
      expect(
        find.byType(switch (entry) {
          'Perfil' => ProfilePage,
          'Configuración' => SettingsPage,
          _ => PersonalLibraryPage,
        }),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    await store.update((p) => p.hideName = true);
    await tester.pumpAndSettle();
    expect(find.text('Hola, lector'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mobile catalog supports dark theme, large text and preferred genres',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = LocalProfileStore(storage: MemoryProfileStorage());
      await store.openUser('lector');
      await store.update((p) => p.genres = {'Historia'});
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: LectioVirtualBooksPage(
            session: const AuthSession(username: 'lector', cookie: 'test'),
            profileStore: store,
            service: TestCatalog(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('Guardar en favoritos'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Guardar en favoritos'));
      await tester.pumpAndSettle();
      expect(store.profile.books.values.single.favorite, isTrue);
      await tester.scrollUntilVisible(
        find.text('Usar mis géneros favoritos'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usar mis géneros favoritos'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Quitar de favoritos'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('profile edits save and survive reopening', (tester) async {
    final storage = MemoryProfileStorage();
    final store = LocalProfileStore(storage: storage);
    await store.openUser('lector');
    await tester.pumpWidget(MaterialApp(home: ProfilePage(store: store)));
    await tester.tap(find.text('Ciencia'));
    await tester.scrollUntilVisible(find.text('Guardar perfil'), 250);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar perfil'));
    await tester.pumpAndSettle();
    final reopened = LocalProfileStore(storage: storage);
    await reopened.openUser('lector');
    expect(reopened.profile.genres, {'Ciencia'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings apply dark theme and text size without restarting', (
    tester,
  ) async {
    final store = LocalProfileStore(storage: MemoryProfileStorage());
    await store.openUser('lector');
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(store: store, biometricStore: FakeBiometrics()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reducir animaciones'), findsNothing);
    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oscuro').last);
    await tester.pumpAndSettle();
    expect(store.profile.theme, 'dark');
    expect(
      Theme.of(tester.element(find.text('Configuración'))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.text('Normal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Extra grande').last);
    await tester.pumpAndSettle();
    expect(store.profile.textScale, 1.4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('biometrics require confirmation and erase stored access', (
    tester,
  ) async {
    final store = LocalProfileStore(storage: MemoryProfileStorage());
    await store.openUser('lector');
    final biometrics = FakeBiometrics();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(store: store, biometricStore: biometrics),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Desactivar'), 250);
    await tester.tap(find.text('Desactivar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(biometrics.enabled, isTrue);
    await tester.tap(find.text('Desactivar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(biometrics.enabled, isFalse);
    expect(find.text('Desactivar'), findsNothing);
  });

  testWidgets(
    'book controls persist favorites and completion in the personal library',
    (tester) async {
      final store = LocalProfileStore(storage: MemoryProfileStorage());
      await store.openUser('lector');
      const book = SavedBook(
        url: 'https://example.test/book',
        title: 'Libro',
        category: 'Ciencia',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookProgressControls(store: store, book: book),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Guardar en favoritos'));
      await tester.pumpAndSettle();
      expect(store.profile.books[book.url]!.favorite, isTrue);
      await tester.tap(find.text('Por leer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terminado').last);
      await tester.pumpAndSettle();
      expect(store.profile.completedIn(DateTime.now()), 1);
      await tester.pumpWidget(
        MaterialApp(home: PersonalLibraryPage(store: store)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Libro'), findsOneWidget);
      expect(find.text('Terminado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

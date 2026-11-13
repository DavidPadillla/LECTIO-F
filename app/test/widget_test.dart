import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:app/app/lectio_app.dart';
import 'package:app/features/analytics/data/lectio_ai_service.dart';
import 'package:app/features/analytics/presentation/lectio_ai_insights.dart';
import 'package:app/features/auth/data/biometric_session_store.dart';
import 'package:app/features/auth/data/lectio_auth_service.dart';
import 'package:app/features/auth/presentation/lectio_auth_page.dart';
import 'package:app/features/auth/presentation/lectio_member_page.dart';
import 'package:app/features/challenges/presentation/desafio.dart';
import 'package:app/features/home/presentation/lectio_home_page.dart';
import 'package:app/features/reservations/data/reservas_service.dart';
import 'package:app/features/reservations/presentation/reservas.dart';
import 'package:app/features/virtual_books/data/libros_service.dart';
import 'package:app/features/virtual_books/presentation/libros.dart';

void main() {
  testWidgets('auth page switches to registration and validates its fields', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LectioAuthPage()));

    expect(find.textContaining('Hola de'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('¿No tienes cuenta? Crear cuenta'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('¿No tienes cuenta? Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Crea tu'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Confirmar contraseña'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Confirmar contraseña'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('CREAR CUENTA'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('CREAR CUENTA'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Usuario requerido'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Usuario requerido'), findsOneWidget);
    expect(find.text('Contraseña requerida'), findsOneWidget);
  });

  testWidgets('auth page keeps its two-panel layout on wide screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LectioAuthPage()));
    await tester.pumpAndSettle();

    expect(find.text('LECTIO'), findsNWidgets(2));
    expect(find.textContaining('Tu próxima'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home navigation opens the login and registration page', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: LectioHomePage(enableVideo: false)),
    );

    await tester.tap(find.byTooltip('Abrir navegación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar Sesión').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Hola de'), findsOneWidget);
    expect(find.text('¿No tienes cuenta? Crear cuenta'), findsOneWidget);
  });

  testWidgets('predictive books remain visible when analytics returns 503', (
    tester,
  ) async {
    final source = _FakeLectioAiDataSource(
      predictions: const LectioPredictions(
        horizonDays: 30,
        books: [
          LectioPrediction(
            bookId: 'lower-demand-id',
            title: 'Libro con menos demanda',
            category: 'Historia',
            status: 'PREDICCION_DISPONIBLE',
            demand30Days: 1.25,
          ),
          LectioPrediction(
            bookId: 'top-demand-id',
            title: 'Libro con más demanda',
            category: 'Novelas',
            status: 'PREDICCION_DISPONIBLE',
            demand30Days: 5.9,
          ),
          LectioPrediction(
            bookId: 'null-demand-id',
            title: 'Libro sin estimación',
            category: 'Ciencia',
            status: 'PREDICCION_DISPONIBLE',
            demand30Days: null,
          ),
          LectioPrediction(
            bookId: 'fourth-book-id',
            title: 'Libro del puesto cuatro',
            category: 'Arte',
            status: 'PREDICCION_DISPONIBLE',
            demand30Days: 4,
          ),
          LectioPrediction(
            bookId: 'third-book-id',
            title: 'Libro del puesto tres',
            category: 'Historia',
            status: 'PREDICCION_DISPONIBLE',
            demand30Days: 3,
          ),
          LectioPrediction(
            bookId: 'second-book-id',
            title: 'Libro del puesto dos',
            category: 'Filosofía',
            status: 'PREDICCION_DISPONIBLE',
            demand30Days: 2,
          ),
          LectioPrediction(
            bookId: 'sixth-book-id',
            title: 'Libro del puesto seis',
            category: 'Ciencia',
            status: 'PREDICCION_DISPONIBLE',
            demand30Days: 0.5,
          ),
        ],
      ),
      analyticsError: const LectioAiException(
        'Las tendencias por categoría no están disponibles por ahora.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(children: [LectioAiInsights(dataSource: source)]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Más solicitados próximamente'), findsOneWidget);
    expect(find.text('Libro con más demanda'), findsOneWidget);
    expect(find.text('Libro con menos demanda'), findsOneWidget);
    expect(find.text('Libro del puesto cuatro'), findsOneWidget);
    expect(find.text('Libro del puesto tres'), findsOneWidget);
    expect(find.text('Libro del puesto dos'), findsOneWidget);
    expect(find.text('Libro del puesto seis'), findsNothing);
    expect(find.text('Libro sin estimación'), findsNothing);
    expect(find.text('5.9'), findsNothing);
    expect(
      find.text('Las tendencias por categoría no están disponibles por ahora.'),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('Libro con más demanda')).dy,
      lessThan(tester.getTopLeft(find.text('Libro con menos demanda')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('accordion shows category and monthly real history graphs', (
    tester,
  ) async {
    final source = _FakeLectioAiDataSource(
      predictionsError: const LectioAiException(
        'No se pudieron cargar las predicciones.',
      ),
      analytics: const LectioCategoryAnalytics(
        categories: [
          CategoryDemand(category: 'Novelas', demand: 532),
          CategoryDemand(category: 'Fantasía', demand: 486),
          CategoryDemand(category: 'Ciencia', demand: 391),
        ],
        monthlyDemand: [
          MonthlyDemand(month: '2026-09', demand: 100),
          MonthlyDemand(month: '2026-10', demand: 95),
          MonthlyDemand(month: '2026-11', demand: 24),
        ],
        periodStart: '2024-11-11',
        periodEnd: '2026-11-09',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(children: [LectioAiInsights(dataSource: source)]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudieron cargar las predicciones.'),
      findsOneWidget,
    );
    expect(find.text('Novelas · 532'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('Gráfica radar de demanda histórica')),
      findsNothing,
    );
    await tester.tap(find.text('Demanda histórica por categoría'));
    await tester.pumpAndSettle();
    expect(find.text('Novelas · 532'), findsOneWidget);
    expect(find.text('Fantasía · 486'), findsOneWidget);
    expect(find.textContaining('2024-11-11 al 2026-11-09'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Gráfica radar de demanda histórica')),
      findsOneWidget,
    );
    expect(find.byType(RadarChart), findsOneWidget);

    await tester.ensureVisible(find.text('Demanda histórica por mes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demanda histórica por mes'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp('Gráfica de demanda histórica mensual')),
      findsOneWidget,
    );
    expect(find.byType(LineChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty prediction and category results are informational', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [LectioAiInsights(dataSource: _FakeLectioAiDataSource())],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Aún no hay libros con una predicción de demanda disponible.'),
      findsOneWidget,
    );
    expect(
      find.text('LECTIO-AI no tiene estadísticas históricas disponibles.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('challenge lists books and keeps history of thought visible', (
    tester,
  ) async {
    final source = _FakeChallengeDataSource();
    await tester.pumpWidget(
      MaterialApp(
        home: LectioChallengePage(
          session: const AuthSession(username: 'lector', cookie: ''),
          dataSource: source,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('El Principito'), findsOneWidget);
    expect(find.text('1984'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Harry Potter'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Harry Potter'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Historia del pensamiento'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Historia del pensamiento'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('challenge saves a chapter before unlocking the next one', (
    tester,
  ) async {
    final source = _FakeChallengeDataSource();
    await tester.pumpWidget(
      MaterialApp(
        home: LectioChallengePage(
          session: const AuthSession(username: 'lector', cookie: ''),
          dataSource: source,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('El Principito'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Leer capítulo 1'), findsOneWidget);
    expect(
      find.byTooltip('Completa el capítulo anterior').first,
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Leer capítulo 1'));
    await tester.pumpAndSettle();
    expect(find.text('Marcar como leído'), findsOneWidget);
    await tester.tap(find.text('Marcar como leído'));
    await tester.pumpAndSettle();

    expect(source.savedChapters, [('principito', 1, 5)]);
    expect(
      find.text('Capítulo leído. Tu progreso quedó guardado.'),
      findsOneWidget,
    );
    expect(find.text('Completado'), findsOneWidget);
    expect(find.byTooltip('Leer capítulo 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('member page opens virtual books, reservations and challenge', (
    tester,
  ) async {
    final reservationService = _FakeReservasService();
    final virtualBooksService = _FakeVirtualBooksService();
    await tester.pumpWidget(
      MaterialApp(
        home: LectioMemberPage(
          session: AuthSession(username: 'lector', cookie: 'JSESSIONID=test'),
          reservationService: reservationService,
          virtualBooksService: virtualBooksService,
          lectioAiDataSource: _FakeLectioAiDataSource(),
        ),
      ),
    );

    expect(find.text('Hola, lector'), findsOneWidget);
    expect(find.text('¡Queremos\nconocerte!'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Nuestra colección.'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Nuestra colección.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Autores destacados.'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Autores destacados.'), findsOneWidget);

    await tester.tap(find.byTooltip('Abrir navegación'));
    await tester.pumpAndSettle();
    expect(find.text('Optimizador'), findsNothing);
    expect(find.text('Colección'), findsNothing);
    expect(find.text('Autores'), findsNothing);
    expect(find.text('Ayuda'), findsNothing);
    await tester.tap(find.text('Libros Virtuales').last);
    await tester.pumpAndSettle();
    expect(find.byType(LectioVirtualBooksPage), findsOneWidget);
    expect(
      find.text('No se encontraron libros que coincidan con tu búsqueda.'),
      findsOneWidget,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Abrir navegación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reserva').last);
    await tester.pumpAndSettle();
    expect(find.byType(LectioReservationsPage), findsOneWidget);
    expect(find.text('No se encontraron libros'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Abrir navegación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desafío').last);
    await tester.pumpAndSettle();
    expect(find.byType(LectioChallengePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('virtual books search and category filters work', (tester) async {
    tester.view.physicalSize = const Size(1100, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = _FakeVirtualBooksService(
      books: [
        LibroVirtual(
          titulo: 'Cien años de soledad',
          categoria: 'Novelas',
          autor: 'Gabriel García Márquez',
          descripcion: 'Una novela de realismo mágico.',
          url: Uri.parse('https://example.test/novela'),
        ),
        LibroVirtual(
          titulo: 'El cosmos',
          categoria: 'Ciencia',
          autor: 'Autora de prueba',
          descripcion: 'Un viaje por el universo.',
          url: Uri.parse('https://example.test/cosmos'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LectioVirtualBooksPage(
          session: const AuthSession(username: 'lector', cookie: ''),
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cien años de soledad'), findsOneWidget);
    expect(find.text('El cosmos'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'cien ANOS');
    await tester.pumpAndSettle();
    expect(find.text('Cien años de soledad'), findsOneWidget);
    expect(find.text('El cosmos'), findsNothing);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Novelas'));
    await tester.pumpAndSettle();
    expect(find.text('El cosmos'), findsOneWidget);
    expect(find.text('Cien años de soledad'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reservation page validates and submits the selected book', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = _FakeReservasService(
      books: const [
        ReservaBook(
          id: 'book-1',
          titulo: 'El libro reservado',
          autor: 'Una autora',
          categoria: 'Novelas',
          stock: 2,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LectioReservationsPage(
          session: const AuthSession(
            username: 'lector',
            cookie: 'JSESSIONID=test',
          ),
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'initial reservation page');
    expect(find.text('El libro reservado'), findsOneWidget);
    await tester.tap(find.text('Reservar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'reservation dialog');
    await tester.enterText(
      find.byType(TextFormField).first,
      'Lector de Prueba',
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'lector@example.com',
    );
    expect(tester.takeException(), isNull, reason: 'reservation form input');
    await tester.tap(find.text('Confirmar reserva'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'reservation submitted');

    expect(service.lastReservation?['bookId'], 'book-1');
    expect(service.lastReservation?['fullName'], 'Lector de Prueba');
    expect(service.lastReservation?['email'], 'lector@example.com');
    expect(
      service.lastReservation?['date'],
      matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')),
    );
    expect(find.text('Reserva realizada con éxito.'), findsOneWidget);
  });

  testWidgets('logout keeps saved biometric access for the next login', (
    tester,
  ) async {
    final logoutService = LectioAuthService(
      client: _AuthResponseClient(statusCode: 302),
      backendUri: Uri.parse('https://example.test'),
    );
    addTearDown(logoutService.close);
    final loginClient = _AuthResponseClient(
      statusCode: 302,
      headers: {
        'location': '/api/home',
        'set-cookie': 'JSESSIONID=fresh-session; Path=/; HttpOnly',
      },
    );
    final loginService = LectioAuthService(
      client: loginClient,
      backendUri: Uri.parse('https://example.test'),
    );
    addTearDown(loginService.close);
    final biometricStore = _FakeBiometricSessionStore(
      credentials: const BiometricCredentials(
        username: 'lector',
        password: 'saved-password',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                const Text('Página pública'),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LectioMemberPage(
                        session: const AuthSession(
                          username: 'lector',
                          cookie: 'JSESSIONID=current-session',
                        ),
                        authService: logoutService,
                      ),
                    ),
                  ),
                  child: const Text('Abrir sesión autenticada'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LectioAuthPage(
                        authService: loginService,
                        biometricSessionStore: biometricStore,
                      ),
                    ),
                  ),
                  child: const Text('Abrir login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir sesión autenticada'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir navegación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Página pública'), findsOneWidget);
    expect(biometricStore.credentials?.username, 'lector');

    await tester.tap(find.text('Abrir login'));
    await tester.pumpAndSettle();

    expect(find.byType(LectioMemberPage), findsOneWidget);
    expect(biometricStore.authenticationCount, 1);
    expect(loginClient.lastRequest.bodyFields, {
      'username': 'lector',
      'password': 'saved-password',
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved biometric session prompts and signs in automatically', (
    tester,
  ) async {
    final client = _AuthResponseClient(
      statusCode: 302,
      headers: {
        'location': '/api/home',
        'set-cookie': 'JSESSIONID=fresh-session; Path=/; HttpOnly',
      },
    );
    final service = LectioAuthService(
      client: client,
      backendUri: Uri.parse('https://example.test'),
    );
    addTearDown(service.close);
    final biometricStore = _FakeBiometricSessionStore(
      credentials: const BiometricCredentials(
        username: 'lector',
        password: 'saved-password',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LectioAuthPage(
          authService: service,
          biometricSessionStore: biometricStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LectioMemberPage), findsOneWidget);
    expect(find.text('Hola, lector'), findsOneWidget);
    expect(biometricStore.authenticationCount, 1);
    expect(client.lastRequest.url.path, '/api/login');
    expect(client.lastRequest.bodyFields, {
      'username': 'lector',
      'password': 'saved-password',
    });
  });

  testWidgets('canceled fingerprint keeps password login available', (
    tester,
  ) async {
    final service = LectioAuthService(
      client: _AuthResponseClient(statusCode: 200),
      backendUri: Uri.parse('https://example.test'),
    );
    addTearDown(service.close);
    final biometricStore = _FakeBiometricSessionStore(
      credentials: const BiometricCredentials(
        username: 'lector',
        password: 'saved-password',
      ),
      cancelBiometric: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LectioAuthPage(
          authService: service,
          biometricSessionStore: biometricStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LectioMemberPage), findsNothing);
    expect(find.textContaining('No se completó la huella'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });

  testWidgets('successful login can enable biometric access', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = _AuthResponseClient(
      statusCode: 302,
      headers: {
        'location': '/api/home',
        'set-cookie': 'JSESSIONID=first-session; Path=/; HttpOnly',
      },
    );
    final service = LectioAuthService(
      client: client,
      backendUri: Uri.parse('https://example.test'),
    );
    addTearDown(service.close);
    final biometricStore = _FakeBiometricSessionStore();

    await tester.pumpWidget(
      MaterialApp(
        home: LectioAuthPage(
          authService: service,
          biometricSessionStore: biometricStore,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'lector');
    await tester.enterText(find.byType(TextFormField).last, 'password1');
    await tester.tap(find.text('Iniciar sesión y activar huella'));
    await tester.pumpAndSettle();

    expect(find.text('Huella activada'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(biometricStore.credentials?.username, 'lector');
    expect(biometricStore.credentials?.password, 'password1');
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(LectioMemberPage), findsOneWidget);
  });

  test('original arcade soundtrack is bundled', () async {
    final soundtrack = await rootBundle.load('assets/audio/lectio_arcade.wav');
    expect(soundtrack.lengthInBytes, greaterThan(1000));
  });

  test('local hero video is bundled', () async {
    final video = await rootBundle.load('lib/videos/Video3.mp4');
    expect(video.lengthInBytes, greaterThan(1000000));
  });

  test('local hero poster is bundled', () async {
    final poster = await rootBundle.load('lib/images/hero_poster.jpg');
    expect(poster.lengthInBytes, greaterThan(10000));
  });

  testWidgets('intro opens the Lectio home page when tapped', (tester) async {
    await tester.pumpWidget(
      const LectioApp(enableIntroMusic: false, enableHeroVideo: false),
    );
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(LectioHomePage), findsNothing);
    expect(find.text('LECTIO QUEST'), findsOneWidget);
    expect(find.text('Saltar'), findsNothing);
    expect(find.text('0/3'), findsNothing);

    expect(find.bySemanticsLabel('Aventura Lectio'), findsOneWidget);

    await tester.tapAt(const Offset(20, 120));
    await tester.pumpAndSettle();

    expect(find.byType(LectioHomePage), findsOneWidget);
    expect(find.text('Preparando tu biblioteca'), findsNothing);
    expect(find.textContaining('Explora nuestra'), findsOneWidget);
    expect(find.text('REC · 001'), findsNothing);
    expect(find.text('01 / 04'), findsNothing);
    expect(find.textContaining('Biblioteca en vivo'), findsNothing);
    expect(find.textContaining('BIBLIOTECA VIRTUAL · N° 001'), findsNothing);
    expect(
      find.textContaining('Miles de libros, autores y recursos'),
      findsNothing,
    );
    await tester.scrollUntilVisible(
      find.text('Libros seleccionados con cuidado.'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Libros seleccionados con cuidado.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Voces que importan.'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Voces que importan.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Escríbenos'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('servicios@bibliote.gov.co'), findsOneWidget);
  });

  testWidgets('intro keeps its bottom area free of jump messages', (
    tester,
  ) async {
    await tester.pumpWidget(
      const LectioApp(enableIntroMusic: false, enableHeroVideo: false),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));

    expect(find.text('¡SALTA AHORA!'), findsNothing);
    expect(find.text('¡SALTO AUTOMÁTICO!'), findsNothing);
    expect(find.text('ESQUIVANDO OBSTÁCULOS'), findsNothing);
    expect(find.text('TOCA LA PANTALLA PARA SALTAR'), findsNothing);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  testWidgets('intro advances automatically after seven seconds', (
    tester,
  ) async {
    await tester.pumpWidget(
      const LectioApp(enableIntroMusic: false, enableHeroVideo: false),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();

    expect(find.textContaining('Explora nuestra'), findsOneWidget);
  });

  testWidgets('tapping intro opens welcome immediately', (tester) async {
    await tester.pumpWidget(
      const LectioApp(enableIntroMusic: false, enableHeroVideo: false),
    );
    await tester.pump();

    await tester.tapAt(const Offset(20, 120));
    await tester.pumpAndSettle();

    expect(find.textContaining('Explora nuestra'), findsOneWidget);
  });
}

class _FakeBiometricSessionStore implements BiometricSessionStore {
  _FakeBiometricSessionStore({this.credentials, this.cancelBiometric = false});

  BiometricCredentials? credentials;
  final bool cancelBiometric;
  int authenticationCount = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> hasSavedCredentials() async => credentials != null;

  @override
  Future<bool> authenticate({required String reason}) async => true;

  @override
  Future<BiometricCredentials?> authenticateAndReadCredentials() async {
    authenticationCount++;
    if (cancelBiometric) return null;
    return credentials;
  }

  @override
  Future<void> saveCredentials(BiometricCredentials credentials) async {
    this.credentials = credentials;
  }

  @override
  Future<void> clearCredentials() async {
    credentials = null;
  }
}

class _FakeReservasService implements ReservaDataSource {
  _FakeReservasService({this.books = const []});

  final List<ReservaBook> books;
  Map<String, String>? lastReservation;

  @override
  Future<List<ReservaBook>> loadBooks({String? category}) async => books
      .where((book) => category == null || book.categoria == category)
      .toList();

  @override
  Future<void> createReservation({
    required String bookId,
    required String title,
    required String category,
    required String fullName,
    required String email,
    required String date,
  }) async {
    lastReservation = {
      'bookId': bookId,
      'title': title,
      'category': category,
      'fullName': fullName,
      'email': email,
      'date': date,
    };
  }
}

class _FakeVirtualBooksService implements LibrosVirtualesDataSource {
  _FakeVirtualBooksService({this.books = const []});

  final List<LibroVirtual> books;

  @override
  Future<List<LibroVirtual>> loadBooks() async => books;
}

class _FakeLectioAiDataSource implements LectioAiDataSource {
  _FakeLectioAiDataSource({
    this.predictions = const LectioPredictions(horizonDays: 30, books: []),
    this.analytics = const LectioCategoryAnalytics(
      categories: [],
      monthlyDemand: [],
      periodStart: null,
      periodEnd: null,
    ),
    this.predictionsError,
    this.analyticsError,
  });

  final LectioPredictions predictions;
  final LectioCategoryAnalytics analytics;
  final LectioAiException? predictionsError;
  final LectioAiException? analyticsError;

  @override
  Future<LectioPredictions> loadPredictions() async {
    if (predictionsError case final error?) throw error;
    return predictions;
  }

  @override
  Future<LectioCategoryAnalytics> loadCategoryAnalytics() async {
    if (analyticsError case final error?) throw error;
    return analytics;
  }
}

class _FakeChallengeDataSource implements ChallengeDataSource {
  final Map<String, Set<int>> progress = {};
  final List<(String, int, int)> savedChapters = [];

  @override
  Future<Map<String, Set<int>>> loadProgress() async => progress;

  @override
  Future<void> saveChapter({
    required String bookId,
    required int chapter,
    required int totalChapters,
  }) async {
    savedChapters.add((bookId, chapter, totalChapters));
    progress.putIfAbsent(bookId, () => <int>{}).add(chapter);
  }

  @override
  Future<void> resetProgress() async => progress.clear();
}

class _AuthResponseClient extends http.BaseClient {
  _AuthResponseClient({required this.statusCode, this.headers = const {}});

  final int statusCode;
  final Map<String, String> headers;
  late http.Request lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request as http.Request;
    return http.StreamedResponse(
      Stream.value(utf8.encode('')),
      statusCode,
      headers: headers,
    );
  }
}

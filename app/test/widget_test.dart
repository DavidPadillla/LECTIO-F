import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:app/app/lectio_app.dart';
import 'package:app/features/auth/data/biometric_session_store.dart';
import 'package:app/features/auth/data/lectio_auth_service.dart';
import 'package:app/features/auth/presentation/lectio_auth_page.dart';
import 'package:app/features/auth/presentation/lectio_member_page.dart';
import 'package:app/features/home/presentation/lectio_home_page.dart';

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

  testWidgets('member page shows account sections and future destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LectioMemberPage(
          session: AuthSession(username: 'lector', cookie: 'JSESSIONID=test'),
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
    await tester.tap(find.text('Reserva').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Reserva estará disponible próximamente.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
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

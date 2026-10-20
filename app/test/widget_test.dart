import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/app/lectio_app.dart';
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

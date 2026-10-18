import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/app/lectio_app.dart';

void main() {
  test('original arcade soundtrack is bundled', () async {
    final soundtrack = await rootBundle.load('assets/audio/lectio_arcade.wav');
    expect(soundtrack.lengthInBytes, greaterThan(1000));
  });

  test('local hero video is bundled', () async {
    final video = await rootBundle.load('lib/videos/Video3.mp4');
    expect(video.lengthInBytes, greaterThan(1000000));
  });

  testWidgets('intro opens the Lectio home page when tapped', (tester) async {
    await tester.pumpWidget(
      const LectioApp(enableIntroMusic: false, enableHeroVideo: false),
    );
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('LECTIO QUEST'), findsOneWidget);
    expect(find.text('Saltar'), findsNothing);
    expect(find.text('0/3'), findsNothing);

    expect(find.bySemanticsLabel('Aventura Lectio'), findsOneWidget);

    await tester.tapAt(const Offset(20, 120));
    await tester.pumpAndSettle();
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

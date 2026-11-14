import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app/features/profile/data/profile_photo_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'photos are resized while preserving aspect ratio and encoded as PNG',
    () async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 1600, 800),
        ui.Paint()..color = const ui.Color(0xFF27AE60),
      );
      final picture = recorder.endRecording();
      final source = await picture.toImage(1600, 800);
      final bytes = await source.toByteData(format: ui.ImageByteFormat.png);
      source.dispose();
      picture.dispose();
      final prepared = await prepareProfilePhoto(bytes!.buffer.asUint8List());
      final codec = await ui.instantiateImageCodec(prepared);
      final image = (await codec.getNextFrame()).image;
      expect(image.width, 512);
      expect(image.height, 256);
      expect(prepared.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      image.dispose();
      codec.dispose();
    },
  );

  test('invalid images and oversized files report a clear error', () async {
    await expectLater(
      prepareProfilePhoto(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<ProfilePhotoException>()),
    );
    await expectLater(
      prepareProfilePhoto(Uint8List(0)),
      throwsA(isA<ProfilePhotoException>()),
    );
    await expectLater(
      prepareProfilePhoto(Uint8List(maxProfilePhotoBytes + 1)),
      throwsA(isA<ProfilePhotoException>()),
    );
  });
}

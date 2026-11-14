import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';

class ProfilePhotoException implements Exception {
  const ProfilePhotoException(this.message);
  final String message;
}

const maxProfilePhotoBytes = 10 * 1024 * 1024;

Future<Uint8List?> pickProfilePhoto() async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Fotos',
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
        mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
        uniformTypeIdentifiers: [
          'public.jpeg',
          'public.png',
          'org.webmproject.webp',
        ],
      ),
    ],
  );
  if (file == null) return null;
  if (await file.length() > maxProfilePhotoBytes) {
    throw const ProfilePhotoException('Elige una foto de hasta 10 MB.');
  }
  return prepareProfilePhoto(await file.readAsBytes());
}

/// Validate and resize before persisting, so a full-resolution photo is not
/// decoded on every visit or stored in the profile preferences.
Future<Uint8List> prepareProfilePhoto(Uint8List bytes) async {
  if (bytes.isEmpty || bytes.length > maxProfilePhotoBytes) {
    throw const ProfilePhotoException('Elige una foto válida de hasta 10 MB.');
  }
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    if (descriptor.width * descriptor.height > 40000000) {
      throw const ProfilePhotoException(
        'La resolución de la foto es demasiado grande. Elige una imagen más pequeña.',
      );
    }
    final largest = descriptor.width > descriptor.height
        ? descriptor.width
        : descriptor.height;
    final scale = largest > 512 ? 512 / largest : 1.0;
    codec = await descriptor.instantiateCodec(
      targetWidth: (descriptor.width * scale).round().clamp(1, 512),
      targetHeight: (descriptor.height * scale).round().clamp(1, 512),
    );
    image = (await codec.getNextFrame()).image;
    final encoded = await image.toByteData(format: ui.ImageByteFormat.png);
    if (encoded == null) {
      throw const ProfilePhotoException('No se pudo preparar la foto.');
    }
    return encoded.buffer.asUint8List(
      encoded.offsetInBytes,
      encoded.lengthInBytes,
    );
  } on ProfilePhotoException {
    rethrow;
  } catch (_) {
    throw const ProfilePhotoException(
      'No se pudo leer esa imagen. Prueba con una foto JPG, PNG o WebP.',
    );
  } finally {
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}

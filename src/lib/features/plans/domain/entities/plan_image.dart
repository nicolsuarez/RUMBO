import 'dart:typed_data';

/// Imagen seleccionada por el organizador, sin dependencia de Flutter.
/// Aceptamos solo JPEG, PNG y WebP: se detectan por su contenido, no por el nombre.
class PlanImage {
  PlanImage._(this.bytes, this.mimeType, this.extension);

  static const maxBytes = 5 * 1024 * 1024;

  final Uint8List bytes;
  final String mimeType;
  final String extension;

  factory PlanImage.fromBytes(Uint8List original) {
    if (original.isEmpty) {
      throw ArgumentError('La imagen está vacía.');
    }
    if (original.length > maxBytes) {
      throw ArgumentError('La imagen no puede superar los 5 MB.');
    }

    final isJpeg =
        original.length >= 3 &&
        original[0] == 0xFF &&
        original[1] == 0xD8 &&
        original[2] == 0xFF;
    final isPng =
        original.length >= 8 &&
        original[0] == 0x89 &&
        original[1] == 0x50 &&
        original[2] == 0x4E &&
        original[3] == 0x47 &&
        original[4] == 0x0D &&
        original[5] == 0x0A &&
        original[6] == 0x1A &&
        original[7] == 0x0A;
    final isWebp =
        original.length >= 12 &&
        String.fromCharCodes(original.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(original.sublist(8, 12)) == 'WEBP';

    if (isJpeg) return PlanImage._(original, 'image/jpeg', 'jpg');
    if (isPng) return PlanImage._(original, 'image/png', 'png');
    if (isWebp) return PlanImage._(original, 'image/webp', 'webp');
    throw ArgumentError(
      'Formato no admitido. Selecciona una imagen JPG, PNG o WebP.',
    );
  }
}

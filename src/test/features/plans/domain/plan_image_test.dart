import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rumbo/features/plans/domain/entities/plan_image.dart';

void main() {
  test('reconoce JPEG por firma binaria', () {
    final image = PlanImage.fromBytes(
      Uint8List.fromList([0xff, 0xd8, 0xff, 0x00]),
    );
    expect(image.extension, 'jpg');
    expect(image.mimeType, 'image/jpeg');
  });

  test('reconoce PNG por firma binaria', () {
    final image = PlanImage.fromBytes(
      Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    );
    expect(image.extension, 'png');
    expect(image.mimeType, 'image/png');
  });

  test('reconoce WebP por firma binaria', () {
    final image = PlanImage.fromBytes(
      Uint8List.fromList([
        0x52,
        0x49,
        0x46,
        0x46,
        0,
        0,
        0,
        0,
        0x57,
        0x45,
        0x42,
        0x50,
      ]),
    );
    expect(image.extension, 'webp');
    expect(image.mimeType, 'image/webp');
  });

  test('rechaza archivos con extensiones fingidas', () {
    expect(
      () => PlanImage.fromBytes(Uint8List.fromList([1, 2, 3, 4])),
      throwsArgumentError,
    );
  });

  test('rechaza archivos mayores de 5 MiB', () {
    final bytes = Uint8List(PlanImage.maxBytes + 1);
    bytes.setRange(0, 3, [0xff, 0xd8, 0xff]);
    expect(() => PlanImage.fromBytes(bytes), throwsArgumentError);
  });
}

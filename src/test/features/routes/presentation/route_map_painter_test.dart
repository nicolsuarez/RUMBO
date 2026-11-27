import 'package:flutter_test/flutter_test.dart';
import 'package:rumbo/shared/painters/map_painter.dart';

void main() {
  test('el mapa se repinta cuando cambia el progreso', () {
    expect(const MapPainter(progressPercent: 50)
        .shouldRepaint(const MapPainter(progressPercent: 10)), isTrue);
    expect(const MapPainter(progressPercent: 50)
        .shouldRepaint(const MapPainter(progressPercent: 50)), isFalse);
    expect(const MapPainter().shouldRepaint(const MapPainter()), isFalse);
  });
}

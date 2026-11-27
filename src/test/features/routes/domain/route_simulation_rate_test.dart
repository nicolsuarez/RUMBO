import 'package:flutter_test/flutter_test.dart';
import 'package:rumbo/features/routes/domain/entities/route_simulation_rate.dart';

void main() {
  test('no se admiten distancias nulas, cero o negativas', () {
    expect(RouteSimulationRate.hasDistance(null), isFalse);
    expect(RouteSimulationRate.hasDistance(0), isFalse);
    expect(RouteSimulationRate.hasDistance(-1), isFalse);
    expect(RouteSimulationRate.hasDistance(double.nan), isFalse);
    expect(() => RouteSimulationRate.progressStepFor(0), throwsArgumentError);
  });
  test('100 metros equivalen a un porcentaje según distancia', () {
    expect(RouteSimulationRate.progressStepFor(1), 10);
    expect(RouteSimulationRate.progressStepFor(2), 5);
    expect(RouteSimulationRate.progressStepFor(5), 2);
    expect(RouteSimulationRate.progressStepFor(10), 1);
  });
  test('respeta límites y precisión del porcentaje persistido', () {
    expect(RouteSimulationRate.progressStepFor(0.01), 100);
    expect(RouteSimulationRate.progressStepFor(3), 3.33);
    expect(RouteSimulationRate.progressStepFor(9999), 0.01);
  });
}

import 'dart:math' as math;

/// Velocidad ilustrativa, no GPS. El porcentaje se guarda con 2 decimales.
class RouteSimulationRate {
  const RouteSimulationRate._();

  static const double kmPerTick = 0.1;

  static bool hasDistance(double? km) => km != null && km.isFinite && km > 0;

  static double progressStepFor(double km) {
    if (!hasDistance(km)) throw ArgumentError.value(km, 'km');
    final raw = kmPerTick * 100 / km;
    if (raw >= 100) return 100;
    // Evitar que un incremento se redondee a cero en PostgreSQL.
    return math.max(0.01, (raw * 100).round() / 100);
  }
}

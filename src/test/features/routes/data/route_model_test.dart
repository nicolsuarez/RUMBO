import 'package:flutter_test/flutter_test.dart';
import 'package:rumbo/features/routes/data/models/route_model.dart';
import 'package:rumbo/features/routes/domain/entities/route_entity.dart';

Map<String, dynamic> row({String status = 'activo', Object? end}) => {
  'id_recorrido': 'route-id',
  'id_inscripcion': 'enrollment-id',
  'id_usuario': 'user-id',
  'id_plan': 'plan-id',
  'inicio': '2026-11-26T12:00:00Z',
  'fin': end,
  'estado': status,
  'porcentaje_avance': 35,
  'distancia_recorrida': 2.45,
};

void main() {
  test('mapea identidad, fecha y valores numéricos persistidos', () {
    final route = RouteModel.fromJson(row());
    expect(route.id, 'route-id');
    expect(route.enrollmentId, 'enrollment-id');
    expect(route.userId, 'user-id');
    expect(route.planId, 'plan-id');
    expect(route.startedAt, DateTime.utc(2026, 11, 26, 12));
    expect(route.finishedAt, isNull);
    expect(route.progress, 35.0);
    expect(route.distanceKm, 2.45);
    expect(route.status, RouteStatus.active);
    expect(route.isInProgress, isTrue);
  });

  test('un recorrido pausado sigue en curso', () {
    final route = RouteModel.fromJson(row(status: 'pausado'));
    expect(route.status, RouteStatus.paused);
    expect(route.isInProgress, isTrue);
    expect(route.progress, 35.0);
  });

  test('finalizar conserva el porcentaje y fecha de fin', () {
    final route = RouteModel.fromJson(
      row(status: 'finalizado', end: '2026-11-26T12:10:00Z'),
    );
    expect(route.status, RouteStatus.finished);
    expect(route.isInProgress, isFalse);
    expect(route.progress, 35.0);
    expect(route.finishedAt, DateTime.utc(2026, 11, 26, 12, 10));
  });

  test('rechaza un estado desconocido', () {
    expect(
      () => RouteModel.fromJson(row(status: 'otro')),
      throwsFormatException,
    );
  });
}

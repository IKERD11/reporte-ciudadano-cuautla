import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:reporte_ciudadano/core/citizen_theme.dart';
import 'package:reporte_ciudadano/core/zone_storage.dart';
import 'package:reporte_ciudadano/features/auth/presentation/zone_screen.dart';
import 'package:reporte_ciudadano/features/auth/application/auth_controller.dart';
import 'package:reporte_ciudadano/features/notifications/notifications_screen.dart';
import 'package:reporte_ciudadano/features/reports/report_map.dart';
import 'package:reporte_ciudadano/features/reports/report_repository.dart';
import 'package:reporte_ciudadano/features/reports/report_tracking_screen.dart';
import 'fake_auth_repository.dart';

class ActivityRepository implements ReportRepository {
  int reads = 0;
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> values = const {},
  ]) async {
    if (action == 'notifications_read') {
      reads++;
      return {};
    }
    return {
      'total': 3,
      'items': [
        {
          'id': '1',
          'report_id': null,
          'type': 'comment',
          'title': 'Comentario público de prueba',
          'body': 'Actualización de prueba',
          'created_at': '2026-10-19T12:00:00Z',
          'read_at': null,
        },
        {
          'id': '2',
          'report_id': null,
          'type': 'alert',
          'title': 'Alerta de prueba',
          'body': 'Consulta de prueba',
          'created_at': '2026-10-18T12:00:00Z',
          'read_at': '2026-10-18T14:00:00Z',
        },
        {
          'id': '3',
          'report_id': 'r',
          'type': 'report_status',
          'title': 'Reporte actualizado',
          'body': 'Alumbrado de prueba',
          'created_at': '2026-10-19T14:00:00Z',
          'read_at': null,
        },
      ],
    };
  }
}

void main() {
  test(
    'zone persists separately per account and rejects malformed coordinates',
    () {
      const zone = CitizenZone(
        address: 'Parque público, Cuautla',
        point: LatLng(18.81, -98.95),
        radius: 5,
      );
      writeZone('one', zone.encode());
      expect(CitizenZone.decode(readZone('one')).radius, 5);
      expect(readZone('two'), isNull);
      expect(
        CitizenZone.decode(
          '{"lat":999,"lng":0,"radius":3,"address":"bad"}',
        ).address,
        'Cuautla, Morelos',
      );
    },
  );
  testWidgets(
    'zone editor saves selected point and radius without fabricating a geocoding match',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      CitizenZone? saved;
      await tester.pumpWidget(
        MaterialApp(
          theme: citizenTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  saved = await Navigator.push<CitizenZone>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ZoneScreen(
                        initial: const CitizenZone(),
                        geocode: (_) async => [],
                      ),
                    ),
                  );
                },
                child: const Text('Abrir zona'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir zona'));
      await tester.pumpAndSettle();
      tester.widget<ReportMap>(find.byType(ReportMap)).onSelected!(
        const LatLng(18.82, -98.96),
      );
      await tester.pumpAndSettle();
      tester.widget<Slider>(find.byType(Slider)).onChanged!(7);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Guardar zona'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar zona'));
      await tester.pumpAndSettle();
      expect(saved!.point.latitude, 18.82);
      expect(saved!.radius, 7);
      expect(saved!.address, 'Ubicación seleccionada en el mapa');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('activity filters types, unread state and text', (tester) async {
    final fake = FakeAuthRepository()
      ..current = user
      ..profile = citizen;
    final auth = AuthController(fake);
    await auth.start();
    await tester.pumpWidget(
      MaterialApp(
        theme: citizenTheme(),
        home: NotificationsScreen(
          repository: ActivityRepository(),
          auth: auth,
          activity: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Actividad'), findsOneWidget);
    await tester.tap(find.text('Comentarios'));
    await tester.pumpAndSettle();
    expect(find.text('Comentario público de prueba'), findsOneWidget);
    expect(find.text('Alerta de prueba'), findsNothing);
    await tester.tap(find.text('Alertas'));
    await tester.pumpAndSettle();
    expect(find.text('Alerta de prueba'), findsOneWidget);
    await tester.tap(find.text('Solo no leídas'));
    await tester.pumpAndSettle();
    expect(find.text('Alerta de prueba'), findsNothing);
    expect(
      find.text('No encontramos actividad con estos criterios.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Todo'));
    await tester.tap(find.byTooltip('Buscar en actividad'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Alumbrado');
    await tester.pumpAndSettle();
    expect(find.text('Reporte actualizado'), findsOneWidget);
    expect(find.text('Comentario público de prueba'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
    await fake.events.close();
  });
  testWidgets(
    'tracking displays only recorded history and no fabricated progress percentage',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: citizenTheme(),
          home: const ReportTrackingScreen(
            report: {
              'folio': 'RC-TEST',
              'status': 'Recibido',
              'category': 'Alumbrado',
              'timeline': [
                {'status': 'Recibido', 'created_at': '2026-10-19T12:24:00Z'},
              ],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Seguimiento del reporte'), findsOneWidget);
      expect(find.text('El municipio revisó la información.'), findsNothing);
      expect(find.text('40%'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

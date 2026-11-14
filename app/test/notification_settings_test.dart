import 'package:app/features/notifications/data/lectio_notifications.dart';
import 'package:app/features/notifications/presentation/notification_settings.dart';
import 'package:app/features/profile/data/local_profile_store.dart';
import 'package:app/features/auth/data/lectio_auth_service.dart';
import 'package:app/features/reservations/data/reservas_service.dart';
import 'package:app/features/reservations/presentation/reservas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'notification_test_support.dart';
import 'local_profile_store_test.dart' show MemoryProfileStorage;

class ReservationSource implements ReservaDataSource {
  bool fail = true;
  @override
  Future<List<ReservaBook>> loadBooks({String? category}) async => const [
    ReservaBook(id: '1', titulo: 'Libro', stock: 2, categoria: 'Novelas'),
  ];
  @override
  Future<void> createReservation({
    required String bookId,
    required String title,
    required String category,
    required String fullName,
    required String email,
    required String date,
  }) async {
    if (fail) throw const ReservaApiException('Reserva rechazada');
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
    'Android controls request permissions, schedule days, send a test and disable all',
    (tester) async {
      final gateway = FakeNotificationGateway();
      final store = LocalProfileStore(
        storage: MemoryProfileStorage(),
        notifications: LectioNotifications(gateway: gateway),
      );
      await store.openUser('lector');
      await store.activateNotifications();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: NotificationSettings(store: store),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activar notificaciones'));
      await tester.pumpAndSettle();
      expect(store.profile.notifications.enabled, isTrue);
      expect(gateway.requests, 1);
      await tester.tap(find.text('Recordar leer'));
      await tester.pumpAndSettle();
      expect(gateway.scheduled, hasLength(7));
      await tester.ensureVisible(find.text('Lun'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lun'));
      await tester.pumpAndSettle();
      expect(gateway.scheduled.containsKey(1), isFalse);
      await tester.scrollUntilVisible(
        find.text('Enviar notificación de prueba'),
        250,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar notificación de prueba'));
      await tester.pumpAndSettle();
      expect(gateway.delivered, contains(7100));
      await tester.scrollUntilVisible(
        find.text('Activar notificaciones'),
        -300,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activar notificaciones'));
      await tester.pumpAndSettle();
      expect(store.profile.notifications.enabled, isFalse);
      expect(gateway.scheduled, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('denied Android permissions do not save an enabled switch', (
    tester,
  ) async {
    final gateway = FakeNotificationGateway()..allowed = false;
    final store = LocalProfileStore(
      storage: MemoryProfileStorage(),
      notifications: LectioNotifications(gateway: gateway),
    );
    await store.openUser('lector');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NotificationSettings(store: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activar notificaciones'));
    await tester.pumpAndSettle();
    expect(store.profile.notifications.enabled, isFalse);
    expect(find.textContaining('Android no permitió'), findsOneWidget);
    expect(gateway.scheduled, isEmpty);
  });

  testWidgets('reservation notice is emitted only after the server accepts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gateway = FakeNotificationGateway();
    final store = LocalProfileStore(
      storage: MemoryProfileStorage(),
      notifications: LectioNotifications(gateway: gateway),
    );
    await store.openUser('lector');
    await store.update((p) => p.notifications.enabled = true);
    await store.activateNotifications();
    final source = ReservationSource();
    await tester.pumpWidget(
      MaterialApp(
        home: LectioReservationsPage(
          session: const AuthSession(username: 'lector', cookie: 'test'),
          service: source,
          profileStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reservar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Lector de prueba',
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'lector@example.com',
    );
    await tester.tap(find.text('Confirmar reserva'));
    await tester.pumpAndSettle();
    expect(find.text('Reserva rechazada'), findsOneWidget);
    expect(gateway.delivered, isEmpty);
    source.fail = false;
    await tester.tap(find.text('Confirmar reserva'));
    await tester.pumpAndSettle();
    expect(gateway.delivered, [7200]);
    expect(tester.takeException(), isNull);
  });
}

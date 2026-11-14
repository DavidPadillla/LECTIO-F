import 'package:app/features/notifications/data/lectio_notifications.dart';
import 'package:app/features/notifications/data/notification_preferences.dart';
import 'package:app/features/profile/data/local_profile_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as zones;
import 'package:timezone/timezone.dart' as tz;

import 'notification_test_support.dart';
import 'local_profile_store_test.dart' show MemoryProfileStorage;

void main() {
  setUpAll(zones.initializeTimeZones);

  test(
    'next reminder uses the local weekday/time and never schedules in the past',
    () {
      final location = tz.getLocation('America/Bogota');
      final now = tz.TZDateTime(location, 2026, 11, 16, 20, 0); // Monday
      expect(
        nextReadingReminder(now, 1, 20, 0),
        tz.TZDateTime(location, 2026, 11, 23, 20),
      );
      expect(
        nextReadingReminder(now, 1, 21, 30),
        tz.TZDateTime(location, 2026, 11, 16, 21, 30),
      );
      expect(
        nextReadingReminder(now, 3, 9, 15),
        tz.TZDateTime(location, 2026, 11, 18, 9, 15),
      );
      final ny = tz.getLocation('America/New_York');
      final beforeDst = tz.TZDateTime(ny, 2026, 3, 7, 18);
      final afterDst = nextReadingReminder(beforeDst, 7, 9, 0);
      expect(afterDst.hour, 9);
      expect(afterDst.timeZoneOffset, const Duration(hours: -4));
    },
  );

  test(
    'replacing days/time removes old schedules, disabled reminders cancel all',
    () async {
      final gateway = FakeNotificationGateway();
      final service = LectioNotifications(gateway: gateway);
      final p = NotificationPreferences(
        enabled: true,
        reminder: true,
        days: {1, 3},
        hour: 19,
        minute: 15,
      );
      await service.activate('lector', p);
      expect(gateway.scheduled.keys.toSet(), {1, 3});
      p.days = {5};
      p.hour = 8;
      p.minute = 30;
      await service.configure('lector', p);
      expect(gateway.scheduled, {5: (hour: 8, minute: 30)});
      p.enabled = false;
      await service.configure('lector', p);
      expect(gateway.scheduled, isEmpty);
    },
  );

  test(
    'permissions are explicit and denied permissions prevent reminders',
    () async {
      final gateway = FakeNotificationGateway()..allowed = false;
      final service = LectioNotifications(gateway: gateway);
      await expectLater(
        service.requestPermissions(reminders: false),
        throwsA(isA<NotificationException>()),
      );
      gateway.allowed = true;
      gateway.exactAllowed = false;
      await expectLater(
        service.requestPermissions(reminders: true),
        throwsA(isA<NotificationException>()),
      );
      expect(gateway.exactRequests, 1);
      await expectLater(
        service.activate(
          'lector',
          NotificationPreferences(enabled: true, reminder: true),
        ),
        throwsA(isA<NotificationException>()),
      );
      expect(gateway.scheduled, isEmpty);
    },
  );

  test(
    'a partial scheduling failure removes every partially installed reminder',
    () async {
      final gateway = FakeNotificationGateway()..failDay = 3;
      final service = LectioNotifications(gateway: gateway);
      await expectLater(
        service.activate(
          'lector',
          NotificationPreferences(enabled: true, reminder: true, days: {1, 3}),
        ),
        throwsStateError,
      );
      expect(gateway.scheduled, isEmpty);
    },
  );

  test('logout and account switches cancel schedules, old user cannot emit notices', () async {
    final gateway = FakeNotificationGateway();
    final service = LectioNotifications(gateway: gateway);
    final p = NotificationPreferences(enabled: true, reminder: true, days: {1});
    await service.activate('uno', p);
    await service.activate('dos', NotificationPreferences());
    expect(gateway.scheduled, isEmpty);
    await service.event('uno', p, 7200);
    expect(gateway.delivered, isEmpty);
    await service.activate('uno', p);
    await service.deactivate('uno');
    expect(gateway.scheduled, isEmpty);
    expect(service.activeUser, isNull);
    await service.event('uno', p, 7200);
    expect(gateway.delivered, isEmpty);
  });

  test('only successful saved transitions emit completion and one goal notice per month', () async {
    final gateway = FakeNotificationGateway();
    final storage = MemoryProfileStorage();
    final service = LectioNotifications(gateway: gateway);
    final store = LocalProfileStore(storage: storage, notifications: service);
    await store.openUser('lector');
    await store.update((p) {
      p.notifications.enabled = true;
      p.goal = 1;
    });
    await store.activateNotifications();
    final finished = const SavedBook(
      url: 'https://example.test/1',
      title: 'Libro',
      category: 'Historia',
    ).copy(status: 'Terminado');
    storage.fail = true;
    await expectLater(store.saveBook(finished), throwsStateError);
    expect(gateway.delivered, isEmpty);
    storage.fail = false;
    await store.saveBook(finished);
    expect(gateway.delivered, [7300, 7400]);
    await store.saveBook(finished.copy(favorite: true));
    expect(gateway.delivered, [7300, 7400]);
    await store.saveBook(finished.copy(status: 'Leyendo'));
    await store.saveBook(finished);
    expect(gateway.delivered.where((id) => id == 7400).length, 1);
    final reopened = LocalProfileStore(
      storage: storage,
      notifications: service,
    );
    await reopened.openUser('lector');
    expect(reopened.profile.goalNotifiedMonth, isNotNull);
    await reopened.activateNotifications();
    await reopened.saveBook(
      const SavedBook(
        url: 'https://example.test/2',
        title: 'Otro',
        category: '',
      ).copy(status: 'Terminado'),
    );
    expect(gateway.delivered.where((id) => id == 7400).length, 1);
  });

  test(
    'settings persist per user, reset cancels reminders without deleting books',
    () async {
      final gateway = FakeNotificationGateway();
      final storage = MemoryProfileStorage();
      final store = LocalProfileStore(
        storage: storage,
        notifications: LectioNotifications(gateway: gateway),
      );
      await store.openUser('uno');
      await store.activateNotifications();
      await store.update((p) {
        p.notifications.enabled = true;
        p.notifications.reminder = true;
        p.notifications.hour = 7;
        p.notifications.minute = 45;
        p.notifications.days = {2, 4};
      });
      expect(gateway.scheduled.keys.toSet(), {2, 4});
      await store.openUser('dos');
      await store.activateNotifications();
      expect(store.profile.notifications.enabled, isFalse);
      expect(gateway.scheduled, isEmpty);
      await store.openUser('uno');
      await store.activateNotifications();
      expect(store.profile.notifications.hour, 7);
      await store.saveBook(
        const SavedBook(
          url: 'https://example.test/1',
          title: 'Libro',
          category: '',
        ),
      );
      await store.resetSettings();
      expect(gateway.scheduled, isEmpty);
      expect(store.profile.books, hasLength(1));
    },
  );

  test(
    'event preferences and master switch suppress individual alerts',
    () async {
      final gateway = FakeNotificationGateway();
      final service = LectioNotifications(gateway: gateway);
      final p = NotificationPreferences(
        enabled: true,
        reservations: false,
        goals: false,
      );
      await service.activate('lector', p);
      await service.event('lector', p, 7200);
      await service.event('lector', p, 7400);
      await service.event('lector', p, 7300);
      expect(gateway.delivered, [7300]);
      p.enabled = false;
      await service.event('lector', p, 7300);
      expect(gateway.delivered, [7300]);
    },
  );
}

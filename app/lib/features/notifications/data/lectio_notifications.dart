import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as zones;
import 'package:timezone/timezone.dart' as tz;

import 'notification_preferences.dart';

class NotificationException implements Exception {
  const NotificationException(this.message);
  final String message;
}

abstract interface class NotificationGateway {
  bool get supported;
  Future<bool> permission({bool request = false});
  Future<bool> exactPermission({bool request = false});
  Future<void> cancelAll();
  Future<void> scheduleWeekly({
    required int day,
    required int hour,
    required int minute,
  });
  Future<void> show(int id, String title, String body);
}

tz.TZDateTime nextReadingReminder(
  tz.TZDateTime now,
  int day,
  int hour,
  int minute,
) {
  for (var offset = 0; offset <= 7; offset++) {
    final candidate = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + offset,
      hour,
      minute,
    );
    if (candidate.weekday == day && candidate.isAfter(now)) return candidate;
  }
  throw StateError('No se pudo calcular el recordatorio.');
}

class AndroidNotificationGateway implements NotificationGateway {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;
  @override
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  AndroidFlutterLocalNotificationsPlugin get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()!;

  Future<void> _initialize() => _initializing ??= _initializePlugin();
  Future<void> _initializePlugin() async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_lectio_notification'),
        ),
      );
      zones.initializeTimeZones();
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  @override
  Future<bool> permission({bool request = false}) async {
    if (!supported) return false;
    await _initialize();
    if (await _android.areNotificationsEnabled() == true) return true;
    return request && await _android.requestNotificationsPermission() == true;
  }

  @override
  Future<bool> exactPermission({bool request = false}) async {
    if (!supported) return false;
    await _initialize();
    if (await _android.canScheduleExactNotifications() == true) return true;
    return request && await _android.requestExactAlarmsPermission() == true;
  }

  @override
  Future<void> cancelAll() async {
    if (!supported) return;
    await _initialize();
    await _plugin.cancelAll();
  }

  static const _reminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'lectio_reading_reminders',
      'Recordatorios de lectura',
      channelDescription: 'Tu horario personal para leer',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.private,
      icon: 'ic_lectio_notification',
    ),
  );
  static const _activityDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'lectio_activity',
      'Actividad de Lectio',
      channelDescription: 'Reservas, libros terminados y metas personales',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      visibility: NotificationVisibility.private,
      icon: 'ic_lectio_notification',
    ),
  );

  @override
  Future<void> scheduleWeekly({
    required int day,
    required int hour,
    required int minute,
  }) async {
    await _initialize();
    final deviceZone = await FlutterTimezone.getLocalTimezone();
    final location = tz.getLocation(deviceZone.identifier);
    await _plugin.zonedSchedule(
      id: 7000 + day,
      title: 'Tu momento de lectura',
      body:
          'Dedica un momento a leer. Tu próxima historia te espera en Lectio.',
      scheduledDate: nextReadingReminder(
        tz.TZDateTime.now(location),
        day,
        hour,
        minute,
      ),
      notificationDetails: _reminderDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  @override
  Future<void> show(int id, String title, String body) async {
    await _initialize();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _activityDetails,
    );
  }
}

class LectioNotifications {
  LectioNotifications({NotificationGateway? gateway})
    : gateway = gateway ?? AndroidNotificationGateway();
  final NotificationGateway gateway;
  String? activeUser;
  bool get supported => gateway.supported;

  Future<void> requestPermissions({required bool reminders}) async {
    if (!supported) {
      throw const NotificationException(
        'Las notificaciones están disponibles en la aplicación Android.',
      );
    }
    if (!await gateway.permission(request: true)) {
      throw const NotificationException(
        'Android no permitió las notificaciones. Actívalas en los ajustes del teléfono.',
      );
    }
    if (reminders && !await gateway.exactPermission(request: true)) {
      throw const NotificationException(
        'Permite las alarmas y recordatorios de Lectio en Android para usar la hora elegida.',
      );
    }
  }

  Future<void> activate(
    String user,
    NotificationPreferences preferences,
  ) async {
    await gateway.cancelAll();
    activeUser = user;
    await configure(user, preferences);
  }

  Future<void> configure(
    String user,
    NotificationPreferences preferences,
  ) async {
    if (!supported || activeUser != user) return;
    // Replace the whole schedule; removed days and previous hours cannot linger.
    await gateway.cancelAll();
    if (!preferences.enabled) return;
    if (!await gateway.permission()) {
      throw const NotificationException(
        'Las notificaciones están bloqueadas en Android. Revisa los permisos del teléfono.',
      );
    }
    if (!preferences.reminder) return;
    if (preferences.days.isEmpty) {
      throw const NotificationException(
        'Selecciona al menos un día para recordar leer.',
      );
    }
    if (!await gateway.exactPermission()) {
      throw const NotificationException(
        'Falta el permiso de alarmas y recordatorios. Revisa los permisos de Android.',
      );
    }
    try {
      for (final day in preferences.days.toList()..sort()) {
        await gateway.scheduleWeekly(
          day: day,
          hour: preferences.hour,
          minute: preferences.minute,
        );
      }
    } catch (_) {
      await gateway.cancelAll();
      rethrow;
    }
  }

  Future<void> deactivate(String user) async {
    if (activeUser != user) return;
    await gateway.cancelAll();
    activeUser = null;
  }

  Future<void> event(
    String user,
    NotificationPreferences preferences,
    int id,
  ) async {
    if (!supported ||
        activeUser != user ||
        !preferences.enabled ||
        !await gateway.permission()) {
      return;
    }
    switch (id) {
      case 7200:
        if (preferences.reservations) {
          await gateway.show(
            id,
            'Reserva confirmada',
            'Tu reserva se guardó correctamente en Lectio.',
          );
        }
      case 7300:
        if (preferences.finishedBooks) {
          await gateway.show(
            id,
            '¡Libro terminado!',
            'Tu avance de lectura quedó guardado. ¡Sigue así!',
          );
        }
      case 7400:
        if (preferences.goals) {
          await gateway.show(
            id,
            '¡Meta mensual alcanzada!',
            'Completaste tu objetivo de lectura de este mes.',
          );
        }
    }
  }

  Future<void> test(String user, NotificationPreferences preferences) async {
    if (activeUser != user || !preferences.enabled) {
      throw const NotificationException(
        'Activa las notificaciones para enviar una prueba.',
      );
    }
    await requestPermissions(reminders: false);
    await gateway.show(
      7100,
      'Notificaciones de Lectio',
      'Esta es una notificación de prueba. Ya puedes recibir avisos en tu Android.',
    );
  }
}

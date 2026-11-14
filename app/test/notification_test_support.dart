import 'package:app/features/notifications/data/lectio_notifications.dart';

class FakeNotificationGateway implements NotificationGateway {
  @override
  bool supported = true;
  bool allowed = true, exactAllowed = true, failCancel = false;
  int requests = 0, exactRequests = 0, cancellations = 0;
  int? failDay;
  final scheduled = <int, ({int hour, int minute})>{};
  final delivered = <int>[];
  @override
  Future<bool> permission({bool request = false}) async {
    if (request) requests++;
    return allowed;
  }

  @override
  Future<bool> exactPermission({bool request = false}) async {
    if (request) exactRequests++;
    return exactAllowed;
  }

  @override
  Future<void> cancelAll() async {
    if (failCancel) throw StateError('Cancel failed');
    cancellations++;
    scheduled.clear();
  }

  @override
  Future<void> scheduleWeekly({
    required int day,
    required int hour,
    required int minute,
  }) async {
    if (failDay == day) throw StateError('Schedule failed');
    scheduled[day] = (hour: hour, minute: minute);
  }

  @override
  Future<void> show(int id, String title, String body) async {
    delivered.add(id);
  }
}

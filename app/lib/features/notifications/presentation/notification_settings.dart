import 'package:flutter/material.dart';

import '../../profile/data/local_profile_store.dart';
import '../data/lectio_notifications.dart';
import '../data/notification_preferences.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key, required this.store});
  final LocalProfileStore store;
  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings>
    with WidgetsBindingObserver {
  bool _busy = false;
  bool? _permission;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _readPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _readPermission();
  }

  Future<void> _readPermission() async {
    try {
      final allowed = await widget.store.notifications.gateway.permission();
      if (mounted) setState(() => _permission = allowed);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudieron consultar los permisos de Android.',
        );
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is NotificationException ? error.message : 'No se pudo guardar la configuración de notificaciones. Reintenta.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      await _readPermission();
    }
  }

  Future<void> _set(void Function(NotificationPreferences) edit) =>
      _run(() async {
        final next = NotificationPreferences.fromJson(
          widget.store.profile.notifications.toJson(),
        );
        edit(next);
        if (next.enabled && next.reminder && next.days.isEmpty) {
          throw const NotificationException(
            'Selecciona al menos un día para recordar leer.',
          );
        }
        if (next.enabled) {
          await widget.store.notifications.requestPermissions(
            reminders: next.reminder,
          );
        }
        if (widget.store.notifications.activeUser != widget.store.username) {
          await widget.store.activateNotifications();
        }
        await widget.store.update((p) => p.notifications = next);
      });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final p = widget.store.profile.notifications;
      final supported = widget.store.notifications.supported;
      final enabled = supported && p.enabled && !_busy;
      final error = _error ?? widget.store.notificationError;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notificaciones', style: Theme.of(context).textTheme.titleLarge),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Activar notificaciones'),
            subtitle: Text(
              !supported
                  ? 'Disponibles en la aplicación instalada en Android.'
                  : _permission == null
                  ? 'Consultando permisos de Android…'
                  : _permission!
                  ? 'Permiso de Android concedido.'
                  : 'Android pedirá permiso al activarlas.',
            ),
            value: p.enabled,
            onChanged: !supported || _busy || widget.store.loadError != null
                ? null
                : (v) => _set((p) => p.enabled = v),
          ),
          if (p.enabled && supported) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recordar leer'),
              subtitle: const Text(
                'Recibe el recordatorio aunque Lectio esté cerrada.',
              ),
              value: p.reminder,
              onChanged: enabled ? (v) => _set((p) => p.reminder = v) : null,
            ),
            if (p.reminder) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: const Text('Hora del recordatorio'),
                trailing: Text(
                  TimeOfDay(hour: p.hour, minute: p.minute).format(context),
                ),
                onTap: !enabled
                    ? null
                    : () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: p.hour,
                            minute: p.minute,
                          ),
                        );
                        if (time != null && mounted) {
                          await _set((p) {
                            p.hour = time.hour;
                            p.minute = time.minute;
                          });
                        }
                      },
              ),
              const Text('Días de lectura'),
              Wrap(
                spacing: 6,
                children: [
                  for (var day = 1; day <= 7; day++)
                    FilterChip(
                      label: Text(
                        const [
                          'Lun',
                          'Mar',
                          'Mié',
                          'Jue',
                          'Vie',
                          'Sáb',
                          'Dom',
                        ][day - 1],
                      ),
                      selected: p.days.contains(day),
                      onSelected: !enabled
                          ? null
                          : (value) => _set((p) {
                              if (value) {
                                p.days.add(day);
                              } else {
                                p.days.remove(day);
                              }
                            }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Se usa la hora local del teléfono. Android puede pedir permiso para alarmas y recordatorios. Las restricciones de batería o forzar la detención de Lectio pueden impedir los avisos.',
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reservas confirmadas'),
              subtitle: const Text(
                'Después de que el servidor acepte una reserva realizada aquí.',
              ),
              value: p.reservations,
              onChanged: enabled
                  ? (v) => _set((p) => p.reservations = v)
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Libros terminados'),
              value: p.finishedBooks,
              onChanged: enabled
                  ? (v) => _set((p) => p.finishedBooks = v)
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Meta mensual alcanzada'),
              subtitle: const Text(
                'Un aviso al mes cuando alcances tu objetivo.',
              ),
              value: p.goals,
              onChanged: enabled ? (v) => _set((p) => p.goals = v) : null,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Enviar notificación de prueba'),
              onPressed: !enabled
                  ? null
                  : () => _run(() async {
                      await widget.store.notifications.test(
                        widget.store.username!,
                        p,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Notificación enviada. Revisa la barra de notificaciones de Android.',
                            ),
                          ),
                        );
                      }
                    }),
            ),
            const Text(
              'Los avisos no incluyen tu nombre ni el título del libro. Cerrar sesión cancela los recordatorios de este dispositivo.',
            ),
          ],
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: _busy || !supported
                        ? null
                        : () => _run(() async {
                            await widget.store.notifications.requestPermissions(
                              reminders: p.enabled && p.reminder,
                            );
                            await widget.store.refreshNotifications();
                          }),
                    child: const Text('Revisar permisos y reintentar'),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
}

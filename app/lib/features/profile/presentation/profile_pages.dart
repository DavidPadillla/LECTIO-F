import 'dart:convert';
import 'dart:typed_data';

import '../data/profile_photo_picker.dart';
import '../../notifications/presentation/notification_settings.dart';
import 'member_appearance.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/data/biometric_session_store.dart';
import '../data/local_profile_store.dart';

Future<void> runProfileAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el cambio. Inténtalo de nuevo.'),
        ),
      );
    }
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.store, this.photoPicker});
  final LocalProfileStore store;
  final Future<Uint8List?> Function()? photoPicker;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final _genres = {...widget.store.profile.genres};
  late int _goal = widget.store.profile.goal;
  bool _saving = false;
  bool _photoBusy = false;

  Future<void> _pickPhoto() async {
    if (_photoBusy || _saving) return;
    final owner = widget.store.username;
    setState(() => _photoBusy = true);
    try {
      final bytes = await (widget.photoPicker ?? pickProfilePhoto)();
      if (bytes == null || !mounted || widget.store.username != owner) return;
      await widget.store.update((p) => p.photoBase64 = base64Encode(bytes));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ProfilePhotoException
                  ? error.message
                  : 'No se pudo guardar la foto. Inténtalo de nuevo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _removePhoto() async {
    if (_photoBusy || _saving) return;
    setState(() => _photoBusy = true);
    await runProfileAction(
      context,
      () => widget.store.update((p) => p.photoBase64 = null),
    );
    if (mounted) setState(() => _photoBusy = false);
  }

  Future<void> _save() async {
    if (_saving || _photoBusy) return;
    setState(() => _saving = true);
    await runProfileAction(context, () async {
      await widget.store.update((p) {
        p.genres = {..._genres};
        p.goal = _goal;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Perfil guardado')));
      }
    });
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => MemberAppearance(
    store: widget.store,
    builder: (context, _) {
      if (widget.store.loadError != null) {
        return _Page(
          title: 'Mi perfil',
          children: [_StorageNotice(store: widget.store)],
        );
      }
      final p = widget.store.profile;
      final completed = p.completedIn(DateTime.now());
      return _Page(
        title: 'Mi perfil',
        children: [
          _StorageNotice(store: widget.store),
          Text(
            'Tu espacio de lectura',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('Usuario de acceso: ${widget.store.username ?? ""}'),
          const SizedBox(height: 20),
          Text(
            'Foto de perfil',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ClipOval(
              child: p.photoBytes == null
                  ? const SizedBox(
                      width: 112,
                      height: 112,
                      child: Icon(Icons.person_outline, size: 72),
                    )
                  : Image.memory(
                      p.photoBytes!,
                      width: 112,
                      height: 112,
                      fit: BoxFit.cover,
                      semanticLabel: 'Foto de perfil del usuario',
                      errorBuilder: (context, error, stack) => const SizedBox(
                        width: 112,
                        height: 112,
                        child: Icon(Icons.person_outline, size: 72),
                      ),
                    ),
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _photoBusy || _saving ? null : _pickPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  _photoBusy
                      ? 'Guardando foto…'
                      : p.photoBase64 == null
                      ? 'Elegir foto'
                      : 'Cambiar foto',
                ),
              ),
              if (p.photoBase64 != null)
                TextButton(
                  onPressed: _photoBusy || _saving ? null : _removePhoto,
                  child: const Text('Quitar foto'),
                ),
            ],
          ),
          const Text(
            'La foto se guarda automáticamente solo en este dispositivo. JPG, PNG o WebP, hasta 10 MB.',
          ),
          const SizedBox(height: 20),
          Text(
            'Géneros favoritos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text(
            'Podrás aplicar estas preferencias en el catálogo virtual.',
          ),
          Wrap(
            spacing: 8,
            children: readingGenres
                .map(
                  (genre) => FilterChip(
                    label: Text(genre),
                    selected: _genres.contains(genre),
                    onSelected: _saving
                        ? null
                        : (selected) => setState(() {
                            selected
                                ? _genres.add(genre)
                                : _genres.remove(genre);
                          }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Text('Meta de libros por mes')),
              IconButton(
                tooltip: 'Reducir meta',
                onPressed: _goal > 1 && !_saving
                    ? () => setState(() => _goal--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Text('$_goal'),
              IconButton(
                tooltip: 'Aumentar meta',
                onPressed: _goal < 100 && !_saving
                    ? () => setState(() => _goal++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving || _photoBusy || widget.store.loadError != null
                ? null
                : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Guardando…' : 'Guardar perfil'),
          ),
          const SizedBox(height: 28),
          Text('Tu actividad', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text('$completed de ${p.goal} libros terminados este mes'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (completed / p.goal).clamp(0, 1)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(
                  '${p.books.values.where((b) => b.favorite).length} favoritos',
                ),
              ),
              Chip(
                label: Text(
                  '${p.books.values.where((b) => b.status == "Leyendo").length} leyendo',
                ),
              ),
              Chip(
                label: Text(
                  '${p.books.values.where((b) => b.status == "Terminado").length} terminados',
                ),
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              PageRouteBuilder<void>(
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (_, _, _) =>
                    PersonalLibraryPage(store: widget.store),
              ),
            ),
            icon: const Icon(Icons.library_books_outlined),
            label: const Text('Abrir mi biblioteca'),
          ),
          const Text(
            'El progreso cuenta los libros que marcas como terminados en este dispositivo.',
          ),
        ],
      );
    },
  );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store, this.biometricStore});
  final LocalProfileStore store;
  final BiometricSessionStore? biometricStore;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final _biometrics =
      widget.biometricStore ?? SecureBiometricSessionStore();
  bool? _enabled;
  bool _busy = false;
  String? _biometricError;
  @override
  void initState() {
    super.initState();
    _readBiometrics();
  }

  Future<void> _readBiometrics() async {
    try {
      final available = await _biometrics.isAvailable();
      final enabled = available && await _biometrics.hasSavedCredentials();
      if (mounted) {
        setState(() {
          _enabled = enabled;
          _biometricError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _biometricError =
              'No se pudo consultar la biometría. Toca para reintentar.',
        );
      }
    }
  }

  Future<void> _change(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    await runProfileAction(context, action);
    if (mounted) setState(() => _busy = false);
  }

  Future<bool> _confirm(String title, String explanation) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(explanation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;
  @override
  Widget build(BuildContext context) => MemberAppearance(
    store: widget.store,
    builder: (context, _) {
      final p = widget.store.profile;
      return _Page(
        title: 'Configuración',
        children: [
          _StorageNotice(store: widget.store),
          Text(
            'Apariencia y accesibilidad',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('theme-${p.theme}'),
            initialValue: p.theme,
            decoration: const InputDecoration(
              labelText: 'Tema',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'system',
                child: Text('Según el sistema'),
              ),
              DropdownMenuItem(value: 'light', child: Text('Claro')),
              DropdownMenuItem(value: 'dark', child: Text('Oscuro')),
            ],
            onChanged: _busy
                ? null
                : (value) => _change(
                    () => widget.store.update((p) => p.theme = value!),
                  ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<double>(
            key: ValueKey('scale-${p.textScale}'),
            initialValue: p.textScale,
            decoration: const InputDecoration(
              labelText: 'Tamaño del texto',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Normal')),
              DropdownMenuItem(value: 1.2, child: Text('Grande')),
              DropdownMenuItem(value: 1.4, child: Text('Extra grande')),
            ],
            onChanged: _busy
                ? null
                : (value) => _change(
                    () => widget.store.update((p) => p.textScale = value!),
                  ),
          ),
          const Divider(),
          Text('Sonido y video', style: Theme.of(context).textTheme.titleLarge),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Música de inicio'),
            subtitle: const Text(
              'Se aplica la próxima vez que abras la aplicación.',
            ),
            value: p.music,
            onChanged: _busy
                ? null
                : (v) => _change(() => widget.store.update((p) => p.music = v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Video de bienvenida'),
            subtitle: const Text('Al desactivarlo se muestra una imagen.'),
            value: p.video,
            onChanged: _busy
                ? null
                : (v) => _change(() => widget.store.update((p) => p.video = v)),
          ),
          const Divider(),
          NotificationSettings(store: widget.store),
          const Divider(),
          Text(
            'Privacidad y acceso',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ocultar nombre en el saludo'),
            value: p.hideName,
            onChanged: _busy
                ? null
                : (v) =>
                      _change(() => widget.store.update((p) => p.hideName = v)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.fingerprint),
            title: const Text('Acceso biométrico'),
            subtitle: Text(
              _biometricError ??
                  (_enabled == null
                      ? 'Consultando…'
                      : _enabled!
                      ? 'Activado en este dispositivo'
                      : 'Desactivado. Puedes activarlo al iniciar sesión en un dispositivo compatible.'),
            ),
            onTap: _biometricError != null ? _readBiometrics : null,
            trailing: _enabled == true
                ? TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            if (await _confirm(
                              '¿Desactivar biometría?',
                              'Se borrarán las credenciales biométricas guardadas en este dispositivo.',
                            )) {
                              await _change(() async {
                                await _biometrics.clearCredentials();
                                await _readBiometrics();
                              });
                            }
                          },
                    child: const Text('Desactivar'),
                  )
                : null,
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.restore),
            title: const Text('Restablecer preferencias'),
            subtitle: const Text('Conserva tu perfil y biblioteca personal.'),
            onTap: _busy
                ? null
                : () async {
                    if (await _confirm(
                      '¿Restablecer preferencias?',
                      'Se restaurarán el tema, texto, música, video, notificaciones y privacidad a sus valores iniciales.',
                    )) {
                      await _change(widget.store.resetSettings);
                    }
                  },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline),
            title: const Text('Borrar mis datos de este dispositivo'),
            subtitle: const Text(
              'Borra el perfil local, favoritos, progreso, ajustes y acceso biométrico. Tu cuenta y reservas del servidor seguirán existiendo.',
            ),
            onTap: _busy
                ? null
                : () async {
                    if (await _confirm(
                      '¿Borrar tus datos locales?',
                      'Esta acción no se puede deshacer. No elimina tu cuenta de Lectio ni tus reservas del servidor.',
                    )) {
                      await _change(() async {
                        await _biometrics.clearCredentials();
                        await widget.store.clearLocalData();
                        await _readBiometrics();
                      });
                    }
                  },
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de Lectio'),
            subtitle: const Text('Versión 1.0.0+1'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Lectio',
              applicationVersion: '1.0.0+1',
              children: const [
                Text(
                  'Tu espacio personal para descubrir libros y cultivar la lectura.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tus preferencias y tu biblioteca se guardan por usuario en este dispositivo. No se sincronizan con otros equipos y pueden perderse al borrar el almacenamiento de la aplicación.',
          ),
        ],
      );
    },
  );
}

class PersonalLibraryPage extends StatelessWidget {
  const PersonalLibraryPage({super.key, required this.store});
  final LocalProfileStore store;
  @override
  Widget build(BuildContext context) => MemberAppearance(
    store: store,
    builder: (context, _) => _Page(
      title: 'Mi biblioteca',
      children: [
        _StorageNotice(store: store),
        if (store.profile.books.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Todavía no guardaste libros. Abre Libros Virtuales y toca el corazón o elige un estado de lectura.',
            ),
          ),
        ...store.profile.books.values.map(
          (book) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    [
                      book.author,
                      book.category,
                    ].where((s) => s.isNotEmpty).join(' · '),
                  ),
                  BookProgressControls(store: store, book: book),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Leer'),
                        onPressed: () => runProfileAction(context, () async {
                          final uri = Uri.tryParse(book.url);
                          if (uri == null ||
                              !['http', 'https'].contains(uri.scheme) ||
                              !await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              )) {
                            throw StateError('Enlace inválido');
                          }
                        }),
                      ),
                      TextButton(
                        onPressed: () async {
                          final remove = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('¿Quitar este libro?'),
                              content: const Text(
                                'También se borrará su estado y dejará de contar para tu meta.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Quitar'),
                                ),
                              ],
                            ),
                          );
                          if (remove == true && context.mounted) {
                            await runProfileAction(
                              context,
                              () =>
                                  store.update((p) => p.books.remove(book.url)),
                            );
                          }
                        },
                        child: const Text('Quitar de mi biblioteca'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class BookProgressControls extends StatelessWidget {
  const BookProgressControls({
    super.key,
    required this.store,
    required this.book,
  });
  final LocalProfileStore store;
  final SavedBook book;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final saved = store.profile.books[book.url];
      final current = saved ?? book;
      return Row(
        children: [
          IconButton(
            tooltip: current.favorite
                ? 'Quitar de favoritos'
                : 'Guardar en favoritos',
            icon: Icon(
              current.favorite ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: () => runProfileAction(
              context,
              () => store.update((p) {
                final latest = p.books[book.url] ?? book;
                p.books[book.url] = latest.copy(favorite: !latest.favorite);
              }),
            ),
          ),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: saved?.status,
              hint: const Text(
                'Estado de lectura',
                overflow: TextOverflow.ellipsis,
              ),
              items: readingStates
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (status) {
                if (status != null) {
                  runProfileAction(
                    context,
                    () => store.update((p) {
                      p.books[book.url] = (p.books[book.url] ?? book).copy(
                        status: status,
                      );
                    }),
                  );
                }
              },
            ),
          ),
        ],
      );
    },
  );
}

class _StorageNotice extends StatelessWidget {
  const _StorageNotice({required this.store});
  final LocalProfileStore store;
  @override
  Widget build(BuildContext context) => store.loadError == null
      ? const SizedBox.shrink()
      : Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(store.loadError!),
                TextButton(
                  onPressed: () => store.openUser(store.username!),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
}

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(padding: const EdgeInsets.all(24), children: children),
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../data/local_profile_store.dart';

/// User preferences apply only inside authenticated routes.
class MemberAppearance extends StatelessWidget {
  const MemberAppearance({
    super.key,
    required this.store,
    required this.builder,
  });
  final LocalProfileStore store;
  final TransitionBuilder builder;

  @override
  Widget build(BuildContext context) {
    if (context.dependOnInheritedWidgetOfExactType<_MemberScope>()?.store ==
        store) {
      return ListenableBuilder(listenable: store, builder: builder);
    }
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = store.profile;
        final media = MediaQuery.of(context);
        final brightness = switch (p.theme) {
          'dark' => Brightness.dark,
          'system' => media.platformBrightness,
          _ => Brightness.light,
        };
        final theme = brightness == Brightness.light
            ? ThemeData(
                brightness: Brightness.light,
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF27AE60),
                  surface: const Color(0xFFF5F6FA),
                ),
              )
            : ThemeData(
                brightness: Brightness.dark,
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF27AE60),
                  brightness: Brightness.dark,
                ),
                scaffoldBackgroundColor: const Color(0xFF101B16),
              );
        return _MemberScope(
          store: store,
          child: Theme(
            data: theme,
            child: MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(
                  media.textScaler.scale(1) * p.textScale,
                ),
                disableAnimations: true,
              ),
              child: Builder(builder: (context) => builder(context, null)),
            ),
          ),
        );
      },
    );
  }
}

class _MemberScope extends InheritedWidget {
  const _MemberScope({required this.store, required super.child});
  final LocalProfileStore store;
  @override
  bool updateShouldNotify(_MemberScope oldWidget) => store != oldWidget.store;
}

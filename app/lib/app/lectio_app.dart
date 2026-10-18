import 'package:flutter/material.dart';

import '../features/onboarding/presentation/lectio_entry_flow.dart';

class LectioApp extends StatelessWidget {
  const LectioApp({
    super.key,
    this.enableIntroMusic = true,
    this.enableHeroVideo = true,
  });

  final bool enableIntroMusic;
  final bool enableHeroVideo;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF2C3E50);

    return MaterialApp(
      title: 'Lectio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF27AE60),
          surface: const Color(0xFFF5F6FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: ink,
          displayColor: ink,
        ),
      ),
      home: LectioLibraryIntro(
        enableMusic: enableIntroMusic,
        enableHeroVideo: enableHeroVideo,
      ),
    );
  }
}

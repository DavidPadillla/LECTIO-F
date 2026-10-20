import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Shares one preloaded hero controller between the intro and the home page.
class LectioHeroMedia {
  LectioHeroMedia._();

  static const videoPath = 'lib/videos/Video3.mp4';
  static const posterPath = 'lib/images/hero_poster.jpg';

  static Future<VideoPlayerController?>? _loading;

  static Future<VideoPlayerController?> preload() => _loading ??= _load();

  static Future<VideoPlayerController?> _load() async {
    final controller = VideoPlayerController.asset(
      videoPath,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      try {
        await controller.play();
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'Lectio hero media',
            context: ErrorDescription(
              'while attempting muted autoplay; the poster remains visible',
            ),
          ),
        );
      }
      return controller;
    } catch (error, stackTrace) {
      await controller.dispose();
      _loading = null;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Lectio hero media',
          context: ErrorDescription('while preloading the hero video'),
        ),
      );
      return null;
    }
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../home/presentation/lectio_hero_media.dart';
import '../../home/presentation/lectio_home_page.dart';

const _ink = Color(0xFFF3F8F3);
const _cream = Color(0xFFFFFFFF);
const _gold = Color(0xFF27AE60);
const _greenDark = Color(0xFF219150);
const _textGreen = Color(0xFF174B2B);
const _gameDuration = Duration(seconds: 7);
const _obstacleMoments = [.23, .43, .63, .82];

class LectioLibraryIntro extends StatefulWidget {
  const LectioLibraryIntro({
    super.key,
    this.onFinished,
    this.enableMusic = true,
    this.enableHeroVideo = true,
  });

  final VoidCallback? onFinished;
  final bool enableMusic;
  final bool enableHeroVideo;

  @override
  State<LectioLibraryIntro> createState() => _LectioLibraryIntroState();
}

class _LectioLibraryIntroState extends State<LectioLibraryIntro>
    with TickerProviderStateMixin {
  late final AnimationController _game;
  late final AnimationController _jump;
  final AudioPlayer _music = AudioPlayer();
  bool _finished = false;
  bool _muted = false;
  bool _musicUnavailable = false;
  final Set<int> _jumpedObstacles = {};
  final Set<int> _triggeredObstacles = {};
  final Set<int> _hitObstacles = {};

  @override
  void initState() {
    super.initState();
    _game = AnimationController(vsync: this, duration: _gameDuration);
    _jump = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );
    _game.addListener(_handleGameTick);
    if (widget.enableHeroVideo) unawaited(LectioHeroMedia.preload());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        precacheImage(const AssetImage(LectioHeroMedia.posterPath), context),
      );
      if (MediaQuery.disableAnimationsOf(context)) {
        _game.value = 1;
        _finish();
        return;
      }
      if (widget.enableMusic) unawaited(_startMusic());
      _game.forward().whenComplete(_finish);
    });
  }

  Future<void> _startMusic() async {
    try {
      await _music.setReleaseMode(ReleaseMode.stop);
      await _playMusic();
    } catch (error, stackTrace) {
      if (mounted) setState(() => _musicUnavailable = true);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Lectio intro audio',
          context: ErrorDescription('while starting the intro soundtrack'),
        ),
      );
    }
  }

  Future<void> _playMusic() async {
    try {
      await _music.play(
        AssetSource('audio/lectio_arcade.wav'),
        volume: _muted ? 0 : .45,
      );
      if (mounted) setState(() => _musicUnavailable = false);
    } catch (error, stackTrace) {
      if (mounted) setState(() => _musicUnavailable = true);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Lectio intro audio',
          context: ErrorDescription(
            'while playing the intro soundtrack; use the music button to retry',
          ),
        ),
      );
    }
  }

  Future<void> _toggleMusic() async {
    if (_musicUnavailable) {
      _muted = false;
      await _playMusic();
      return;
    }
    final nextMuted = !_muted;
    setState(() => _muted = nextMuted);
    try {
      if (nextMuted) {
        await _music.pause();
      } else {
        await _playMusic();
      }
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _musicUnavailable = true);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Lectio intro audio',
          context: ErrorDescription('while changing intro soundtrack state'),
        ),
      );
    }
  }

  void _handleGameTick() {
    if (_finished) return;
    final progress = _game.value;
    var changed = false;
    for (var i = 0; i < _obstacleMoments.length; i++) {
      final moment = _obstacleMoments[i];
      if (!_triggeredObstacles.contains(i) && progress >= moment - .065) {
        _triggeredObstacles.add(i);
        _jump.forward(from: 0);
      }
      if (progress >= moment && !_jumpedObstacles.contains(i)) {
        if (i % 3 == 1 && _jump.value < .32) {
          _hitObstacles.add(i);
        }
        _jumpedObstacles.add(i);
        changed = true;
      }
    }
    if (changed && mounted) setState(() {});
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    final callback = widget.onFinished;
    if (callback != null) {
      unawaited(_music.stop());
      callback();
      return;
    }
    unawaited(_goHome());
  }

  Future<void> _goHome() async {
    if (widget.enableHeroVideo) {
      await LectioHeroMedia.preload().timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () => null,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) =>
            LectioHomePage(enableVideo: widget.enableHeroVideo),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  void _openWelcomeImmediately() {
    if (_finished) return;
    _game.stop();
    _finish();
  }

  @override
  void dispose() {
    _game.removeListener(_handleGameTick);
    _game.dispose();
    _jump.dispose();
    unawaited(_music.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: GestureDetector(
        key: const ValueKey('intro-screen'),
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: _openWelcomeImmediately,
        child: AnimatedBuilder(
          animation: Listenable.merge([_game, _jump]),
          builder: (context, _) {
            final progress = _game.value;
            final pages = (progress * 3.15).floor().clamp(0, 3);
            return Stack(
              fit: StackFit.expand,
              children: [
                Semantics(
                  key: const ValueKey('pixel-platform-game'),
                  label: 'Aventura Lectio',
                  hint: 'El personaje salta automáticamente los obstáculos',
                  child: CustomPaint(
                    painter: _PixelGamePainter(
                      progress: progress,
                      jump: _jump.value,
                      pages: pages,
                      jumpedObstacles: _jumpedObstacles,
                      hitObstacles: _hitObstacles,
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 14, 0),
                        child: Row(
                          children: [
                            const _GameBadge(),
                            const Spacer(),
                            IconButton.filledTonal(
                              tooltip: _musicUnavailable
                                  ? 'Tocar para reintentar música'
                                  : _muted
                                  ? 'Activar música'
                                  : 'Silenciar música',
                              onPressed: widget.enableMusic
                                  ? _toggleMusic
                                  : null,
                              style: IconButton.styleFrom(
                                foregroundColor: _cream,
                                backgroundColor: const Color(0xEFFFFFFF),
                              ),
                              icon: Icon(
                                _musicUnavailable
                                    ? Icons.music_off_rounded
                                    : _muted
                                    ? Icons.volume_off_rounded
                                    : Icons.music_note_rounded,
                                size: 19,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _WorldTitle(progress: progress),
                      const SizedBox(height: 17),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 22),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: const Color(0xFFDBE8DC),
                            valueColor: const AlwaysStoppedAnimation(
                              _greenDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (progress > .86)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _PixelFinalePainter(
                          progress: ((progress - .86) / .14).clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GameBadge extends StatelessWidget {
  const _GameBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFF),
        border: Border.all(color: const Color(0x5527AE60)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_rounded, color: _greenDark, size: 16),
          SizedBox(width: 7),
          Text(
            'LECTIO QUEST',
            style: TextStyle(
              color: _textGreen,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldTitle extends StatelessWidget {
  const _WorldTitle({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final stage = progress < .25
        ? ('BIBLIOTECA DEL BOSQUE', 'Una aventura entre libros y naturaleza')
        : progress < .5
        ? ('MUNDO DE FANTASÍA', '¡Salta hacia la siguiente historia!')
        : progress < .75
        ? ('MUNDO DE MISTERIO', 'Sigue las pistas entre las páginas')
        : ('MUNDO DE CIENCIA', 'El portal de Lectio te espera');
    return Column(
      children: [
        Text(
          stage.$1,
          style: const TextStyle(
            color: _greenDark,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
            shadows: [Shadow(color: Colors.white, blurRadius: 8)],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          stage.$2,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _textGreen,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.white, blurRadius: 8)],
          ),
        ),
      ],
    );
  }
}

class _PixelGamePainter extends CustomPainter {
  _PixelGamePainter({
    required this.progress,
    required this.jump,
    required this.pages,
    required this.jumpedObstacles,
    required this.hitObstacles,
  });

  final double progress;
  final double jump;
  final int pages;
  final Set<int> jumpedObstacles;
  final Set<int> hitObstacles;

  static const _sky = [
    Color(0xFFBFE9FF),
    Color(0xFFA9DDF8),
    Color(0xFFC5E8F6),
    Color(0xFFA9E3D4),
  ];
  static const _blocks = [
    Color(0xFF58B86A),
    Color(0xFF43A85C),
    Color(0xFF68BD75),
    Color(0xFF27AE60),
  ];
  static const _player = <String>[
    '.....KKKKKK.....',
    '....KHHHHHHK....',
    '...KHHHHHHHHK...',
    '...KHHHHHHHHK...',
    '..KSSSSSSSSSSK..',
    '..KSESSSSSSSEK..',
    '..KSSSSSSSSSSK..',
    '...KSSSSSSSSK...',
    '....KSSMMSSK....',
    '.....KMMMMK.....',
    '....KKGGGGKK....',
    '...KGGGGGGGGK...',
    '..KPVVGGGGVVPK..',
    '..KPVVVGGVVVPK..',
    '..KPVVGGGGVVPK..',
    '...KDDDDDDDDK...',
    '...KDDDDDDDDK...',
    '...KBB....BBK...',
    '...KBB....BBK...',
    '..KKBBK..KBBKK..',
    '..KFFFK..KFFFK..',
    '..KKKKK..KKKKK..',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final u = (size.width / 180).clamp(1.4, 3.2);
    final world = (progress * 4).floor().clamp(0, 3);
    final nextWorld = math.min(world + 1, 3);
    final local = progress >= 1 ? 1.0 : (progress * 4) - world;
    final worldSky = Color.lerp(
      _sky[world],
      _sky[nextWorld],
      Curves.easeInOut.transform(local),
    )!;
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            worldSky,
            Color.lerp(worldSky, const Color(0xFFE8F8E7), .58)!,
          ],
        ).createShader(bounds),
    );

    _drawDaylight(canvas, size, u, local);
    _drawParallax(canvas, size, u, world, local);
    _drawPlatforms(canvas, size, u, world, local);
    _drawPage(canvas, size, u, local);
    _drawWorldTransition(canvas, size, u, local);

    final jumpArc = math.sin(jump * math.pi).abs();
    final runBounce = jump > 0 ? 0.0 : math.sin(progress * math.pi * 48).abs();
    final characterX =
        size.width *
        (.25 +
            .17 *
                Curves.easeInOut.transform(
                  ((progress - .72) / .18).clamp(0.0, 1.0),
                ));
    final groundY = size.height * .76;
    final characterY =
        groundY - jumpArc * size.height * .18 - runBounce * 2 * u;
    _drawObstacles(canvas, size, u);
    _drawShadow(canvas, characterX, groundY, u, jumpArc);
    final isHit = hitObstacles.any(
      (index) =>
          progress >= _obstacleMoments[index] &&
          progress - _obstacleMoments[index] < .08,
    );
    _drawCharacter(
      canvas,
      Offset(characterX, characterY),
      u,
      jump: jump,
      hit: isHit,
    );
    _drawParticles(canvas, size, u, progress, pages);
    _drawPortal(canvas, size, u, progress);
    _drawObstacleEffects(canvas, size, u);
  }

  void _drawDaylight(Canvas canvas, Size size, double u, double local) {
    final sunCenter = Offset(size.width * .82, size.height * .18);
    canvas.drawCircle(
      sunCenter,
      28 * u,
      Paint()..color = const Color(0x55FFF3B0),
    );
    canvas.drawCircle(
      sunCenter,
      18 * u,
      Paint()..color = const Color(0xFFFFF3BD),
    );
    for (var i = 0; i < 4; i++) {
      final x =
          ((i * size.width * .31 - progress * size.width * .12) %
                  (size.width + 100 * u))
              .toDouble();
      final y = size.height * (.15 + (i % 2) * .12);
      final cloudPaint = Paint()..color = const Color(0xDFFFFFFF);
      canvas.drawRect(Rect.fromLTWH(x, y + 8 * u, 48 * u, 12 * u), cloudPaint);
      canvas.drawRect(Rect.fromLTWH(x + 10 * u, y, 19 * u, 13 * u), cloudPaint);
      canvas.drawRect(
        Rect.fromLTWH(x + 27 * u, y + 3 * u, 15 * u, 11 * u),
        cloudPaint,
      );
    }
  }

  void _drawParallax(
    Canvas canvas,
    Size size,
    double u,
    int world,
    double local,
  ) {
    final far = Paint()
      ..color = [
        const Color(0xFF83C990),
        const Color(0xFF73B982),
        const Color(0xFF92CA8D),
        const Color(0xFF66B99B),
      ][world];
    final near = Paint()
      ..color = [
        const Color(0xFF43885A),
        const Color(0xFF3D8055),
        const Color(0xFF548B50),
        const Color(0xFF35856C),
      ][world];
    for (var i = 0; i < 7; i++) {
      final x = i * size.width / 4 - progress * size.width * .2;
      final width = size.width * .22;
      final base = size.height * (.68 + (i.isEven ? .035 : 0));
      canvas.drawRect(Rect.fromLTWH(x, base - 105 * u, width, 105 * u), far);
      canvas.drawRect(
        Rect.fromLTWH(x + width * .17, base - 127 * u, width * .66, 28 * u),
        far,
      );
      final windowColor = world == 0
          ? const Color(0xFFFFF7D6)
          : const Color(0xFFE9F8E8);
      for (var row = 0; row < 3; row++) {
        for (var col = 0; col < 2; col++) {
          canvas.drawRect(
            Rect.fromLTWH(
              x + (18 + col * 26) * u,
              base - (83 - row * 25) * u,
              10 * u,
              13 * u,
            ),
            Paint()..color = windowColor,
          );
        }
      }
      if (world == 0 && i == 1) {
        final library = Rect.fromLTWH(
          x + width * .19,
          base - 88 * u,
          width * .62,
          88 * u,
        );
        canvas.drawRect(library, Paint()..color = const Color(0xFFFFF9E8));
        canvas.drawRect(
          Rect.fromLTWH(
            library.left - 5 * u,
            library.top - 5 * u,
            library.width + 10 * u,
            7 * u,
          ),
          Paint()..color = _greenDark,
        );
        canvas.drawRect(
          Rect.fromLTWH(
            library.left + 7 * u,
            library.top + 9 * u,
            library.width - 14 * u,
            20 * u,
          ),
          Paint()..color = const Color(0xFFE4F1D8),
        );
        for (var book = 0; book < 7; book++) {
          final colors = [
            const Color(0xFF27AE60),
            const Color(0xFFE6A454),
            const Color(0xFF638BB2),
            const Color(0xFFD67561),
          ];
          canvas.drawRect(
            Rect.fromLTWH(
              library.left + (10 + book * 8) * u,
              library.top + (book.isEven ? 12 : 15) * u,
              5 * u,
              15 * u,
            ),
            Paint()..color = colors[book % colors.length],
          );
        }
        canvas.drawRect(
          Rect.fromLTWH(
            library.left + library.width * .38,
            base - 37 * u,
            library.width * .24,
            37 * u,
          ),
          Paint()..color = const Color(0xFF9B704E),
        );
        canvas.drawRect(
          Rect.fromLTWH(
            library.left + library.width * .47,
            base - 16 * u,
            3 * u,
            3 * u,
          ),
          Paint()..color = const Color(0xFFFFE6A1),
        );
      }
      final treeX = x + width * .72;
      canvas.drawRect(
        Rect.fromLTWH(treeX + 12 * u, base - 42 * u, 8 * u, 42 * u),
        Paint()..color = const Color(0xFF79583D),
      );
      for (var layer = 0; layer < 3; layer++) {
        canvas.drawRect(
          Rect.fromLTWH(
            treeX + layer * 4 * u,
            base - (79 - layer * 20) * u,
            32 * u - layer * 8 * u,
            25 * u,
          ),
          near,
        );
      }
    }
  }

  void _drawPlatforms(
    Canvas canvas,
    Size size,
    double u,
    int world,
    double local,
  ) {
    final color = _blocks[world];
    final scroll = progress * size.width * 2.7;
    for (var i = 0; i < 14; i++) {
      final column = i % 7;
      final row = (i ~/ 7);
      final x = ((column * 39 * u) - scroll % (size.width + 39 * u)).toDouble();
      final y = size.height * (.63 + row * .14 + ((column + world) % 3) * .018);
      final blockSize = 18 * u;
      final rect = Rect.fromLTWH(x, y, blockSize, blockSize);
      canvas.drawRect(rect, Paint()..color = color);
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, 3 * u),
        Paint()..color = const Color(0xFFFFD785),
      );
      canvas.drawRect(
        Rect.fromLTWH(rect.left + 3 * u, rect.top + 6 * u, 3 * u, 3 * u),
        Paint()..color = const Color(0x557A3D51),
      );
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.bottom - 3 * u, rect.width, 3 * u),
        Paint()..color = const Color(0xAA392943),
      );
    }

    final groundY = size.height * .77;
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, size.height - groundY),
      Paint()..color = const Color(0xFF73BD68),
    );
    for (var i = 0; i < (size.width / (14 * u)).ceil() + 2; i++) {
      final x = i * 14 * u - scroll % (14 * u);
      canvas.drawRect(
        Rect.fromLTWH(x, groundY, 13 * u, 4 * u),
        Paint()..color = const Color(0xFFB5E58A),
      );
      canvas.drawRect(
        Rect.fromLTWH(x, groundY + 4 * u, 13 * u, 4 * u),
        Paint()..color = const Color(0xFF589E58),
      );
    }
  }

  void _drawPage(Canvas canvas, Size size, double u, double local) {
    final pulse = .84 + .16 * math.sin(progress * math.pi * 16);
    final x = size.width * (.57 + .16 * math.sin(local * math.pi * 2));
    final y = size.height * (.57 - .045 * math.sin(progress * math.pi * 12));
    final w = 12 * u * pulse;
    final h = 16 * u * pulse;
    canvas.drawRect(
      Rect.fromLTWH(x - 4 * u, y - 4 * u, w + 8 * u, h + 8 * u),
      Paint()..color = const Color(0x44FFD36F),
    );
    canvas.drawRect(
      Rect.fromLTWH(x, y, w, h),
      Paint()..color = const Color(0xFFFFF0C8),
    );
    canvas.drawRect(
      Rect.fromLTWH(x + w * .5, y, w * .5, h),
      Paint()..color = const Color(0xFFFFD36F),
    );
    canvas.drawRect(
      Rect.fromLTWH(x + w * .22, y + h * .25, w * .18, h * .42),
      Paint()..color = const Color(0xFFAE8052),
    );
  }

  void _drawWorldTransition(Canvas canvas, Size size, double u, double local) {
    final flash = ((local - .84) / .16).clamp(0.0, 1.0);
    if (flash <= 0) return;
    final color = _gold.withValues(alpha: flash * .16);
    final paint = Paint()..color = color;
    for (var i = 0; i < 9; i++) {
      final x = ((i * 47 * u + progress * size.width) % size.width).toDouble();
      final height = (18 + (i % 4) * 11) * u * flash;
      canvas.drawRect(
        Rect.fromLTWH(x, size.height * .58 - height / 2, 3 * u, height),
        paint,
      );
    }
  }

  void _drawShadow(Canvas canvas, double x, double y, double u, double jump) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y + 3 * u),
        width: 25 * u * (1 - jump * .35),
        height: 5 * u,
      ),
      Paint()..color = const Color(0x770A0B18),
    );
  }

  void _drawObstacles(Canvas canvas, Size size, double u) {
    final groundY = size.height * .76;
    for (var i = 0; i < _obstacleMoments.length; i++) {
      if (jumpedObstacles.contains(i)) continue;
      final characterX =
          .25 +
          .17 *
              Curves.easeInOut.transform(
                ((progress - .72) / .18).clamp(0.0, 1.0),
              );
      final x =
          size.width * (characterX + (_obstacleMoments[i] - progress) * 2.1);
      if (x < -20 * u || x > size.width + 20 * u) continue;
      final shadow = Paint()..color = const Color(0x44376137);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, groundY - 1 * u),
          width: 31 * u,
          height: 4 * u,
        ),
        shadow,
      );
      switch (i % 3) {
        case 0:
          _drawDemonObstacle(canvas, x, groundY, u);
        case 1:
          _drawBookObstacle(canvas, x, groundY, u);
        case 2:
          _drawCrateObstacle(canvas, x, groundY, u);
      }
    }
  }

  void _drawBookObstacle(Canvas canvas, double x, double groundY, double u) {
    final books = [
      (x - 13 * u, groundY - 12 * u, 25 * u, 10 * u, const Color(0xFF328C60)),
      (x - 9 * u, groundY - 23 * u, 20 * u, 10 * u, const Color(0xFFD56C50)),
      (x - 14 * u, groundY - 34 * u, 23 * u, 10 * u, const Color(0xFF557FB1)),
    ];
    for (final (left, top, width, height, color) in books) {
      canvas.drawRect(
        Rect.fromLTWH(left, top, width, height),
        Paint()..color = color,
      );
      canvas.drawRect(
        Rect.fromLTWH(left, top, 3 * u, height),
        Paint()..color = const Color(0xFF245D45),
      );
      canvas.drawRect(
        Rect.fromLTWH(left + 5 * u, top + 2 * u, width - 8 * u, 2 * u),
        Paint()..color = const Color(0xFFFFF3D2),
      );
    }
  }

  void _drawDemonObstacle(Canvas canvas, double x, double groundY, double u) {
    final body = Paint()..color = const Color(0xFFD94B42);
    final shadow = Paint()..color = const Color(0xFF9F303A);
    final horn = Paint()..color = const Color(0xFF533B53);
    final wing = Paint()..color = const Color(0xFFB63849);
    final eye = Paint()..color = const Color(0xFFFFFFFF);
    final pupil = Paint()..color = const Color(0xFF342B3D);

    // Small original book imp: horns, pointed ears, wings and a curled tail.
    canvas.drawRect(
      Rect.fromLTWH(x - 17 * u, groundY - 33 * u, 7 * u, 11 * u),
      horn,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 14 * u, groundY - 39 * u, 5 * u, 8 * u),
      horn,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 10 * u, groundY - 33 * u, 7 * u, 11 * u),
      horn,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 9 * u, groundY - 39 * u, 5 * u, 8 * u),
      horn,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 24 * u, groundY - 24 * u, 10 * u, 16 * u),
      wing,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 29 * u, groundY - 19 * u, 8 * u, 11 * u),
      wing,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 14 * u, groundY - 24 * u, 10 * u, 16 * u),
      wing,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 21 * u, groundY - 19 * u, 8 * u, 11 * u),
      wing,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 13 * u, groundY - 24 * u, 26 * u, 21 * u),
      body,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 16 * u, groundY - 28 * u, 8 * u, 10 * u),
      shadow,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 8 * u, groundY - 28 * u, 8 * u, 10 * u),
      shadow,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 8 * u, groundY - 18 * u, 5 * u, 6 * u),
      eye,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 3 * u, groundY - 18 * u, 5 * u, 6 * u),
      eye,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 6 * u, groundY - 17 * u, 2 * u, 4 * u),
      pupil,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 5 * u, groundY - 17 * u, 2 * u, 4 * u),
      pupil,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 5 * u, groundY - 9 * u, 10 * u, 2 * u),
      horn,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 7 * u, groundY - 4 * u, 5 * u, 4 * u),
      shadow,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 3 * u, groundY - 4 * u, 5 * u, 4 * u),
      shadow,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 13 * u, groundY - 9 * u, 7 * u, 3 * u),
      body,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 18 * u, groundY - 13 * u, 4 * u, 6 * u),
      body,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 18 * u, groundY - 16 * u, 5 * u, 4 * u),
      horn,
    );
  }

  void _drawCrateObstacle(Canvas canvas, double x, double groundY, double u) {
    final rect = Rect.fromLTWH(x - 15 * u, groundY - 30 * u, 30 * u, 28 * u);
    canvas.drawRect(rect, Paint()..color = const Color(0xFFA86D3F));
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, 4 * u),
      Paint()..color = const Color(0xFFD9A665),
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 2 * u, rect.top + 4 * u, 4 * u, rect.height - 4 * u),
      Paint()..color = const Color(0xFF75492F),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left + 4 * u,
        groundY - 15 * u,
        rect.width - 8 * u,
        4 * u,
      ),
      Paint()..color = const Color(0xFF75492F),
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left, groundY - 4 * u, 4 * u, 4 * u),
      Paint()..color = const Color(0xFF6F472F),
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.right - 4 * u, groundY - 4 * u, 4 * u, 4 * u),
      Paint()..color = const Color(0xFF6F472F),
    );
  }

  void _drawObstacleEffects(Canvas canvas, Size size, double u) {
    for (final moment in _obstacleMoments) {
      final distance = (moment - progress).abs();
      if (distance > .055 || jump <= 0) continue;
      final characterX =
          .25 +
          .17 *
              Curves.easeInOut.transform(
                ((progress - .72) / .18).clamp(0.0, 1.0),
              );
      final x = size.width * (characterX + (moment - progress) * 2.1);
      for (var i = 0; i < 3; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            x - (7 + i * 5) * u,
            size.height * .76 - 4 * u,
            2 * u,
            2 * u,
          ),
          Paint()..color = _gold.withValues(alpha: .8 - i * .2),
        );
      }
    }
  }

  void _drawCharacter(
    Canvas canvas,
    Offset feet,
    double u, {
    required double jump,
    required bool hit,
  }) {
    final pixel = 1.55 * u;
    final runFrame = (progress * 12).floor().isEven;
    canvas.save();
    canvas.translate(
      feet.dx - _player.first.length * pixel / 2 + (hit ? -9 * u : 0),
      feet.dy - _player.length * pixel + (hit ? 5 * u : 0),
    );
    final colorMap = <String, Color>{
      'K': const Color(0xFF322232),
      'H': const Color(0xFF54384A),
      'S': const Color(0xFFE7AE83),
      'E': const Color(0xFFFFF2DA),
      'M': const Color(0xFF442B2E),
      'G': const Color(0xFF398B78),
      'P': const Color(0xFFE5B758),
      'V': const Color(0xFF7657A6),
      'D': const Color(0xFF40517D),
      'B': const Color(0xFF364166),
      'F': const Color(0xFF392B3F),
    };
    for (var row = 0; row < _player.length; row++) {
      final line = _player[row];
      for (var col = 0; col < line.length; col++) {
        var cell = line[col];
        if (row >= 17 && (cell == 'B' || cell == 'F')) {
          final legToggle = col < line.length / 2 ? runFrame : !runFrame;
          if (!legToggle && jump == 0) continue;
        }
        if (cell == '.') continue;
        final baseColor = colorMap[cell];
        final color = hit && baseColor != null
            ? Color.lerp(baseColor, const Color(0xFFE34B4B), .72)
            : baseColor;
        if (color == null) continue;
        canvas.drawRect(
          Rect.fromLTWH(col * pixel, row * pixel, pixel + .3, pixel + .3),
          Paint()..color = color,
        );
        if (cell == 'P') {
          canvas.drawRect(
            Rect.fromLTWH(col * pixel, row * pixel, pixel, pixel * .25),
            Paint()..color = const Color(0xFFFFE3A0),
          );
        }
      }
    }
    final bookX = 12 * pixel;
    final bookY = 11 * pixel;
    canvas.drawRect(
      Rect.fromLTWH(bookX, bookY, 4 * pixel, 5 * pixel),
      Paint()..color = const Color(0xFFB95858),
    );
    canvas.drawRect(
      Rect.fromLTWH(bookX + pixel, bookY + pixel, 2 * pixel, 3 * pixel),
      Paint()..color = const Color(0xFFFFE7B2),
    );
    canvas.drawRect(
      Rect.fromLTWH(bookX + 2 * pixel, bookY + pixel, pixel, 3 * pixel),
      Paint()..color = const Color(0xFFFFD36F),
    );
    canvas.restore();
  }

  void _drawParticles(Canvas canvas, Size size, double u, double t, int pages) {
    if (pages == 0) return;
    final count = pages * 3;
    for (var i = 0; i < count; i++) {
      final phase = t * math.pi * 10 + i * 1.7;
      final center = Offset(
        size.width * .26 + math.sin(phase) * 25 * u,
        size.height * .56 - (phase % (math.pi * 2)) * 5 * u,
      );
      canvas.drawRect(
        Rect.fromCenter(center: center, width: 2 * u, height: 2 * u),
        Paint()..color = _gold.withValues(alpha: .75),
      );
    }
  }

  void _drawPortal(Canvas canvas, Size size, double u, double t) {
    final appear = ((t - .82) / .18).clamp(0.0, 1.0);
    if (appear <= 0) return;
    final rect = Rect.fromCenter(
      center: Offset(size.width * .5, size.height * .56),
      width: size.width * .34 * appear,
      height: size.height * .39 * appear,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(36 * u)),
      Paint()
        ..color = const Color(0x8827AE60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * u,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(6 * u), Radius.circular(30 * u)),
      Paint()
        ..color = const Color(0x99FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * u,
    );
  }

  @override
  bool shouldRepaint(covariant _PixelGamePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.jump != jump ||
      oldDelegate.pages != pages ||
      oldDelegate.jumpedObstacles != jumpedObstacles ||
      oldDelegate.hitObstacles != hitObstacles;
}

class _PixelFinalePainter extends CustomPainter {
  const _PixelFinalePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final reveal = Curves.easeInOutCubic.transform(progress.clamp(0.0, 1.0));
    final curtainWidth = size.width * .5 * (1 - reveal);
    canvas.drawRect(Offset.zero & size, Paint()..color = _gold);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, curtainWidth, size.height),
      Paint()..color = _cream,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - curtainWidth, 0, curtainWidth, size.height),
      Paint()..color = _cream,
    );

    final center = Offset(size.width / 2, size.height * .49);
    final textOpacity = ((progress - .3) / .48).clamp(0.0, 1.0);
    if (textOpacity == 0) return;
    final title = TextPainter(
      text: TextSpan(
        text: 'LECTIO',
        style: TextStyle(
          color: _cream.withValues(alpha: textOpacity),
          fontSize: math.min(size.width * .13, 58),
          fontWeight: FontWeight.w900,
          letterSpacing: 5,
          shadows: const [
            Shadow(
              color: Color(0x44204B2D),
              offset: Offset(0, 3),
              blurRadius: 8,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * .9);
    title.paint(
      canvas,
      Offset(
        center.dx - title.width / 2,
        center.dy - title.height / 2 + (1 - textOpacity) * 20,
      ),
    );

    final subtitle = TextPainter(
      text: TextSpan(
        text: 'TU PRÓXIMA HISTORIA COMIENZA AQUÍ',
        style: TextStyle(
          color: _cream.withValues(alpha: textOpacity * .9),
          fontSize: math.max(9, size.width * .023),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * .9);
    subtitle.paint(
      canvas,
      Offset(center.dx - subtitle.width / 2, center.dy + title.height * .8),
    );
  }

  @override
  bool shouldRepaint(covariant _PixelFinalePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class LectioWelcomePage extends StatelessWidget {
  const LectioWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF4),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE9DDF8), Color(0xFFFFEAC7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    size: 48,
                    color: Color(0xFF7256A8),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Bienvenido a Lectio',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF25243B),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tu próxima historia favorita empieza aquí.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF777487), fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

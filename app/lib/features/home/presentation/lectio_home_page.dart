import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

const _lectioGreen = Color(0xFF27AE60);
const _lectioGreenDark = Color(0xFF219150);
const _lectioNavy = Color(0xFF2C3E50);
const _lectioBackground = Color(0xFFF5F6FA);
const _contentWidth = 1320.0;

class LectioHomePage extends StatefulWidget {
  const LectioHomePage({super.key, this.enableVideo = true});

  final bool enableVideo;

  @override
  State<LectioHomePage> createState() => _LectioHomePageState();
}

class _LectioHomePageState extends State<LectioHomePage> {
  final _scrollController = ScrollController();
  final _homeKey = GlobalKey();
  final _collectionKey = GlobalKey();
  final _authorsKey = GlobalKey();
  final _helpKey = GlobalKey();

  static const _books = [
    _Book(
      title: 'Cuentos de hadas clásicos',
      category: 'Clásico',
      volume: 'Vol. 01',
      author: 'Anónimo',
      description: 'Exploración profunda de los temas más importantes de la literatura universal.',
      image: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=600&q=80',
      link: 'https://www.gutenberg.org/cache/epub/11036/pg11036-images.html',
      accent: Color(0xFFB87548),
    ),
    _Book(
      title: 'Cuentos de los Hermanos Grimm',
      category: 'Fantasía',
      volume: 'Vol. 02',
      author: 'Hnos. Grimm',
      description: 'Una guía fascinante sobre los cuentos populares alemanes.',
      image: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=600&q=80',
      link: 'https://www.gutenberg.org/cache/epub/2591/pg2591-images.html',
      accent: Color(0xFF5D8B70),
    ),
    _Book(
      title: 'Cuentos de Edgar Allan Poe',
      category: 'Terror',
      volume: 'Vol. 03',
      author: 'E. A. Poe',
      description: 'Relatos impresionantes sobre lo macabro y lo humano.',
      image: 'https://images.unsplash.com/photo-1509248961158-e54f6934749c?auto=format&fit=crop&w=600&q=80',
      link: 'https://www.gutenberg.org/cache/epub/1064/pg1064-images.html',
      accent: Color(0xFF61769A),
    ),
    _Book(
      title: 'Clásicos de aventura',
      category: 'Aventura',
      volume: 'Vol. 04',
      author: 'Varios',
      description:
          'Grandes viajes y exploraciones narrados por sus protagonistas.',
      image: 'https://images.unsplash.com/photo-1533561052604-c3beb6d55b8d?auto=format&fit=crop&w=600&q=80',
      link: 'https://www.gutenberg.org/',
      accent: Color(0xFF8A6849),
    ),
  ];

  static const _authors = [
    _Author(
      name: 'Gabriel García Márquez',
      role: 'Realismo mágico',
      detail:
          'Autor de "Cien Años de Soledad", premio Nobel de Literatura 1982.',
      initials: 'GM',
      color: Color(0xFFDAA16B),
    ),
    _Author(
      name: 'Isabel Allende',
      role: 'Narrativa contemporánea',
      detail: 'Autora de "La Casa de los Espíritus", una de las voces más leídas en español.',
      initials: 'IA',
      color: Color(0xFF7EAA85),
    ),
    _Author(
      name: 'Jorge Luis Borges',
      role: 'Literatura fantástica',
      detail: 'Autor de "Ficciones", maestro del cuento y de la literatura especulativa.',
      initials: 'JB',
      color: Color(0xFF8396B5),
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
      alignment: .02,
    );
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Esta opción estará disponible próximamente.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openBook(String url) {
    _comingSoon();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lectioBackground,
      body: DefaultTextStyle(
        style: GoogleFonts.inter(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 1,
              backgroundColor: Colors.white,
              toolbarHeight: 76,
              titleSpacing: 0,
              title: _ConstrainedContent(
                child: _NavigationBar(
                  onHome: () => _goTo(_homeKey),
                  onCollection: () => _goTo(_collectionKey),
                  onAuthors: () => _goTo(_authorsKey),
                  onHelp: () => _goTo(_helpKey),
                  onVirtualBooks: () => _goTo(_collectionKey),
                  onLogin: _comingSoon,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _HeroSection(
                key: _homeKey,
                onExplore: () => _goTo(_collectionKey),
                onAuthors: () => _goTo(_authorsKey),
                enableVideo: widget.enableVideo,
              ),
            ),
            const SliverToBoxAdapter(child: _Ticker()),
            SliverToBoxAdapter(
              child: _CollectionSection(
                key: _collectionKey,
                books: _books,
                onRead: _openBook,
              ),
            ),
            SliverToBoxAdapter(
              child: _AuthorsSection(key: _authorsKey, authors: _authors),
            ),
            const SliverToBoxAdapter(child: _StatsSection()),
            SliverToBoxAdapter(child: _HelpSection(key: _helpKey)),
            SliverToBoxAdapter(
              child: _SubscribeSection(onSubscribe: _comingSoon),
            ),
            const SliverToBoxAdapter(child: _Footer()),
          ],
        ),
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({
    required this.onHome,
    required this.onCollection,
    required this.onAuthors,
    required this.onHelp,
    required this.onVirtualBooks,
    required this.onLogin,
  });

  final VoidCallback onHome;
  final VoidCallback onCollection;
  final VoidCallback onAuthors;
  final VoidCallback onHelp;
  final VoidCallback onVirtualBooks;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 850;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              InkWell(
                onTap: onHome,
                borderRadius: BorderRadius.circular(12),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LectioMark(size: 42),
                    SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lectio',
                          style: TextStyle(
                            color: _lectioNavy,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                        Text(
                          'BIBLIOTECA',
                          style: TextStyle(
                            color: _lectioGreenDark,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (compact)
                PopupMenuButton<String>(
                  tooltip: 'Abrir navegación',
                  icon: const Icon(Icons.menu_rounded, color: _lectioNavy),
                  onSelected: (value) {
                    switch (value) {
                      case 'Inicio':
                        onHome();
                      case 'Colección':
                        onCollection();
                      case 'Autores':
                        onAuthors();
                      case 'Ayuda':
                        onHelp();
                      case 'Libros Virtuales':
                        onVirtualBooks();
                      case 'Iniciar Sesión':
                        onLogin();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Inicio', child: Text('Inicio')),
                    PopupMenuItem(value: 'Colección', child: Text('Colección')),
                    PopupMenuItem(value: 'Autores', child: Text('Autores')),
                    PopupMenuItem(value: 'Ayuda', child: Text('Ayuda')),
                    PopupMenuItem(
                      value: 'Libros Virtuales',
                      child: Text('Libros Virtuales'),
                    ),
                    PopupMenuItem(
                      value: 'Iniciar Sesión',
                      child: Text('Iniciar Sesión'),
                    ),
                  ],
                )
              else ...[
                _NavLink(label: 'Inicio', onTap: onHome),
                _NavLink(label: 'Colección', onTap: onCollection),
                _NavLink(label: 'Autores', onTap: onAuthors),
                _NavLink(label: 'Ayuda', onTap: onHelp),
                _NavLink(label: 'Libros Virtuales', onTap: onVirtualBooks),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: onLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: _lectioGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Iniciar Sesión'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: _lectioNavy,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

class _HeroSection extends StatefulWidget {
  const _HeroSection({
    super.key,
    required this.onExplore,
    required this.onAuthors,
    required this.enableVideo,
  });

  final VoidCallback onExplore;
  final VoidCallback onAuthors;
  final bool enableVideo;

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  VideoPlayerController? _videoController;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.enableVideo) {
      _videoController = VideoPlayerController.asset('lib/videos/Video3.mp4');
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      final controller = _videoController!;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Lectio home hero',
          context: ErrorDescription('while initializing the local hero video'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 960;
        return SizedBox(
          height: compact ? 940 : 700,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF163B2A)),
              if (_videoReady && _videoController != null)
                ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xD90D2B1D),
                      Color(0xB30D2B1D),
                      Color(0x280D2B1D),
                    ],
                    stops: [0, .43, 1],
                  ),
                ),
              ),
              _ConstrainedContent(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 22 : 40,
                    vertical: compact ? 34 : 46,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: compact
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: _HeroCopy(
                                  onExplore: widget.onExplore,
                                  onAuthors: widget.onAuthors,
                                  compact: true,
                                ),
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _HeroCopy(
                                      onExplore: widget.onExplore,
                                      onAuthors: widget.onAuthors,
                                      compact: false,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      _HeroStats(compact: compact),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.onExplore,
    required this.onAuthors,
    required this.compact,
  });

  final VoidCallback onExplore;
  final VoidCallback onAuthors;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 42.0 : 66.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bienvenido a Lectio',
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            text: 'Explora nuestra\n',
            children: [
              TextSpan(
                text: 'colección',
                style: GoogleFonts.instrumentSerif(
                  color: const Color(0xFF7FC9A0),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const TextSpan(text: ' virtual.'),
            ],
          ),
          style: GoogleFonts.instrumentSerif(
            color: Colors.white,
            fontSize: titleSize,
            height: .98,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Text(
            'Accede a miles de libros y recursos de tus autores favoritos desde la comodidad de tu hogar. Un catálogo curado, siempre disponible.',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: .9),
              fontSize: 15,
              height: 1.75,
            ),
          ),
        ),
        const SizedBox(height: 27),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onExplore,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Explorar Colección'),
              style: FilledButton.styleFrom(
                backgroundColor: _lectioGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 21,
                  vertical: 16,
                ),
                shape: const RoundedRectangleBorder(),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onAuthors,
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
              label: const Text('Ver Autores'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _lectioGreenDark,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(
                  horizontal: 21,
                  vertical: 16,
                ),
                shape: const RoundedRectangleBorder(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroStats extends StatelessWidget {
  const _HeroStats({required this.compact});

  final bool compact;

  static const _stats = [
    ('LIBROS', '12.500', '+'),
    ('AUTORES', '480', '+'),
    ('ACCESO', '24', '/7'),
    ('TRAYECTORIA', '15', ' años'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 22),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: .3)),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _stats.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: compact ? 8 : 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stats[i].$1,
                      style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFFB9DCC7),
                        fontSize: compact ? 8 : 9,
                        letterSpacing: compact ? .4 : 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        text: _stats[i].$2,
                        children: [
                          TextSpan(
                            text: _stats[i].$3,
                            style: const TextStyle(color: Color(0xFF7FC9A0)),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: GoogleFonts.instrumentSerif(
                        color: Colors.white,
                        fontSize: compact ? 19 : 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatelessWidget {
  const _PulsingDot({this.color = const Color(0xFF34A06C)});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .35), blurRadius: 7),
        ],
      ),
    );
  }
}

class _Ticker extends StatelessWidget {
  const _Ticker();

  @override
  Widget build(BuildContext context) {
    const items = [
      'LECTIO',
      'BIBLIOTECA VIRTUAL',
      'MILES DE LIBROS',
      'AUTORES ÚNICOS',
      'SIEMPRE GRATIS',
      'ACCESO 24/7',
    ];
    return Container(
      color: const Color(0xFFE6F3EB),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var repeat = 0; repeat < 2; repeat++)
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        item,
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF0F4A2E),
                          fontSize: 10,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 18),
                      const SizedBox(
                        width: 7,
                        height: 7,
                        child: ColoredBox(color: _lectioGreen),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _CollectionSection extends StatelessWidget {
  const _CollectionSection({
    super.key,
    required this.books,
    required this.onRead,
  });

  final List<_Book> books;
  final ValueChanged<String> onRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _lectioBackground,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 76),
      child: _ConstrainedContent(
        child: Column(
          children: [
            const _SectionHeading(
              eyebrow: 'CATÁLOGO · 01',
              title: 'Libros seleccionados con cuidado.',
              description: 'Encuentra los mejores títulos de nuestra colección permanente. Cada semana sumamos nuevas lecturas.',
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 480
                    ? 1
                    : constraints.maxWidth < 850
                    ? 2
                    : constraints.maxWidth < 1100
                    ? 3
                    : 4;
                final width =
                    (constraints.maxWidth - (columns - 1) * 22) / columns;
                return Wrap(
                  spacing: 22,
                  runSpacing: 22,
                  children: [
                    for (final book in books)
                      SizedBox(
                        width: width,
                        child: _BookCard(book: book, onRead: onRead),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.onRead});

  final _Book book;
  final ValueChanged<String> onRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x102C3E50),
            blurRadius: 24,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  book.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: book.accent.withValues(alpha: .18),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      size: 58,
                      color: book.accent,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: .62),
                      ],
                      stops: const [.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 15,
                  left: 15,
                  child: _BookTag(label: book.category),
                ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: Text(
                    book.volume,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 5),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.volume.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFFB9DCC7),
                          fontSize: 9,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.instrumentSerif(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.description,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B8377),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        book.author.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF0F4A2E),
                          fontSize: 9,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => onRead(book.link),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                      label: const Text('Leer'),
                      style: TextButton.styleFrom(
                        foregroundColor: _lectioGreenDark,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        textStyle: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookTag extends StatelessWidget {
  const _BookTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _lectioGreen,
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _AuthorsSection extends StatelessWidget {
  const _AuthorsSection({super.key, required this.authors});

  final List<_Author> authors;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 76),
      child: _ConstrainedContent(
        child: Column(
          children: [
            const _SectionHeading(
              eyebrow: 'TALENTO · 02',
              title: 'Voces que importan.',
              description: 'Una selección de autores cuya obra ha marcado generaciones enteras de lectores.',
            ),
            Column(
              children: [
                for (var index = 0; index < authors.length; index++)
                  _AuthorCard(author: authors[index], number: index + 1),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard({required this.author, required this.number});

  final _Author author;
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFD4E5D9))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Row(
              children: [
                const _PulsingDot(color: _lectioGreen),
                const SizedBox(width: 9),
                Text(
                  number.toString().padLeft(2, '0'),
                  style: GoogleFonts.jetBrainsMono(
                    color: _lectioGreenDark,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              author.name,
              style: GoogleFonts.instrumentSerif(
                color: const Color(0xFF0D2B1D),
                fontSize: 26,
                height: 1.05,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author.role.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    color: _lectioGreenDark,
                    fontSize: 9,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  author.detail,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B8377),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    const stats = [
      ('01', '12.500+', 'Libros disponibles'),
      ('02', '480+', 'Autores destacados'),
      ('03', '24/7', 'Horas de acceso'),
      ('04', '15+', 'Años de trayectoria'),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: _ConstrainedContent(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 600 ? 2 : 4;
            final width = (constraints.maxWidth - (columns - 1) * 1) / columns;
            return Wrap(
              spacing: 1,
              runSpacing: 1,
              children: [
                for (final stat in stats)
                  SizedBox(
                    width: width,
                    child: Container(
                      color: _lectioBackground,
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                stat.$1,
                                style: GoogleFonts.jetBrainsMono(
                                  color: _lectioGreenDark,
                                  fontSize: 9,
                                ),
                              ),
                              const Spacer(),
                              const _PulsingDot(color: _lectioGreen),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            stat.$2,
                            style: GoogleFonts.instrumentSerif(
                              color: const Color(0xFF0F4A2E),
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            stat.$3.toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(
                              color: const Color(0xFF6B8377),
                              fontSize: 9,
                              letterSpacing: .6,
                            ),
                          ),
                        ],
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

class _HelpSection extends StatelessWidget {
  const _HelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _lectioBackground,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 76),
      child: _ConstrainedContent(
        child: Column(
          children: [
            const _SectionHeading(
              eyebrow: 'SOPORTE · 03',
              title: 'Estamos para ayudarte.',
              description: '¿Tienes dudas o necesitas asistencia? Elige el canal que prefieras, respondemos rápido.',
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 650 ? 1 : 3;
                final width =
                    (constraints.maxWidth - (columns - 1) * 18) / columns;
                return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    SizedBox(
                      width: width,
                      child: const _HelpCard(
                        icon: Icons.mail_outline_rounded,
                        title: 'Escríbenos',
                        value: 'servicios@bibliote.gov.co',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: const _HelpCard(
                        icon: Icons.phone_outlined,
                        title: 'Llámanos',
                        value: '(+57 601) 3424100',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: const _HelpCard(
                        icon: Icons.location_on_outlined,
                        title: 'Visítanos',
                        value: 'Calle 24 No. 5 - 60, Bogotá',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D2C3E50),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _lectioGreen, size: 25),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: _lectioNavy,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF73808C), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SubscribeSection extends StatelessWidget {
  const _SubscribeSection({required this.onSubscribe});

  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE6F3EB),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 55),
      child: _ConstrainedContent(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final message = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: 'Recibe nuestras ',
                    children: [
                      TextSpan(
                        text: 'novedades.',
                        style: GoogleFonts.instrumentSerif(
                          color: _lectioGreenDark,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  style: GoogleFonts.instrumentSerif(
                    color: const Color(0xFF0D2B1D),
                    fontSize: 38,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Suscríbete y obtén acceso anticipado a nuevos títulos, autores y recursos exclusivos de la biblioteca.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF496456),
                    height: 1.6,
                  ),
                ),
              ],
            );
            final form = Row(
              children: [
                const Expanded(
                  child: TextField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'tu@correo.com',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Color(0xFFBCD8C6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Color(0xFFBCD8C6)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onSubscribe,
                  style: FilledButton.styleFrom(
                    backgroundColor: _lectioGreenDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 19,
                    ),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: const Text('Suscribirme'),
                ),
              ],
            );
            return compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [message, const SizedBox(height: 22), form],
                  )
                : Row(
                    children: [
                      Expanded(child: message),
                      const SizedBox(width: 36),
                      SizedBox(width: constraints.maxWidth * .43, child: form),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _lectioNavy,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      child: _ConstrainedContent(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            final brand = Row(
              mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
              children: [
                const _LectioMark(size: 38),
                const SizedBox(width: 12),
                Text(
                  'LECTIO / BIBLIOTECA',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            );
            final copyright = Text(
              '© 2025 Lectio Biblioteca · Todos los derechos reservados',
              textAlign: compact ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .76),
                fontSize: 12,
              ),
            );
            return compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [brand, const SizedBox(height: 16), copyright],
                  )
                : Row(
                    children: [
                      brand,
                      const Spacer(),
                      Flexible(child: copyright),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final labelParts = eyebrow.split('·');
    final label = labelParts.first.trim();
    final number = labelParts.length > 1 ? labelParts.last.trim() : '';

    Widget headingText({required bool compact}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: TextAlign.left,
          style: GoogleFonts.instrumentSerif(
            color: const Color(0xFF0D2B1D),
            fontSize: compact ? 36 : 44,
            height: 1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Text(
            description,
            textAlign: TextAlign.left,
            style: GoogleFonts.inter(
              color: const Color(0xFF6B8377),
              fontSize: 14,
              height: 1.65,
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final kicker = Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    color: _lectioGreenDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.3,
                  ),
                ),
                if (number.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    number,
                    style: GoogleFonts.instrumentSerif(
                      color: const Color(0xFF7FC9A0),
                      fontSize: compact ? 42 : 58,
                      height: .9,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            if (compact) const SizedBox(width: 22),
            if (compact)
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(width: 7, height: 7, color: _lectioGreen),
                ),
              ),
          ],
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 28),
          margin: const EdgeInsets.only(bottom: 44),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFD4E5D9))),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    kicker,
                    const SizedBox(height: 20),
                    headingText(compact: true),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(width: 140, child: kicker),
                    const SizedBox(width: 50),
                    Expanded(child: headingText(compact: false)),
                  ],
                ),
        );
      },
    );
  }
}

class _LectioMark extends StatelessWidget {
  const _LectioMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _lectioGreen.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: Icon(
        Icons.menu_book_rounded,
        color: _lectioGreenDark,
        size: size * .58,
      ),
    );
  }
}

class _ConstrainedContent extends StatelessWidget {
  const _ConstrainedContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentWidth),
        child: child,
      ),
    );
  }
}

class _Book {
  const _Book({
    required this.title,
    required this.category,
    required this.volume,
    required this.author,
    required this.description,
    required this.image,
    required this.link,
    required this.accent,
  });

  final String title;
  final String category;
  final String volume;
  final String author;
  final String description;
  final String image;
  final String link;
  final Color accent;
}

class _Author {
  const _Author({
    required this.name,
    required this.role,
    required this.detail,
    required this.initials,
    required this.color,
  });

  final String name;
  final String role;
  final String detail;
  final String initials;
  final Color color;
}

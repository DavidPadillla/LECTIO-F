import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/lectio_auth_service.dart';

const _ink = Color(0xFF0D2B1D);
const _inkSoft = Color(0xFF2D4A3A);
const _muted = Color(0xFF6B8377);
const _line = Color(0xFFD4E5D9);
const _green = Color(0xFF1A6B45);
const _paper = Color(0xFFF7FAF8);
const _contentWidth = 1240.0;

class LectioMemberPage extends StatefulWidget {
  const LectioMemberPage({
    super.key,
    required this.session,
    this.authService,
  });

  final AuthSession session;
  final LectioAuthService? authService;

  @override
  State<LectioMemberPage> createState() => _LectioMemberPageState();
}

class _LectioMemberPageState extends State<LectioMemberPage> {
  final _scrollController = ScrollController();
  final _homeKey = GlobalKey();
  final _collectionKey = GlobalKey();
  final _authorsKey = GlobalKey();
  final _helpKey = GlobalKey();
  late final bool _ownsAuthService = widget.authService == null;
  late final LectioAuthService _authService =
      widget.authService ?? LectioAuthService();
  bool _isLoggingOut = false;

  static const _books = [
    _MemberBook(
      title: 'Cuentos de hadas clásicos',
      category: 'Clásico',
      description: 'Explora temas esenciales de la historia humana.',
      image: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=700&q=80',
      accent: Color(0xFFB87548),
    ),
    _MemberBook(
      title: 'El cosmos y sus misterios',
      category: 'Ciencia',
      description: 'Una mirada fascinante a los secretos del cosmos.',
      image: 'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?auto=format&fit=crop&w=700&q=80',
      accent: Color(0xFF61769A),
    ),
    _MemberBook(
      title: 'Relatos de la humanidad',
      category: 'Historia',
      description: 'Civilizaciones que marcaron la historia.',
      image: 'https://images.unsplash.com/photo-1507842217343-583bb7270b66?auto=format&fit=crop&w=700&q=80',
      accent: Color(0xFF8A6849),
    ),
  ];

  static const _authors = [
    _MemberAuthor(
      name: 'Gabriel García Márquez',
      description: 'Premio Nobel y autor de Cien años de soledad.',
      initials: 'GM',
      color: Color(0xFFDAA16B),
    ),
    _MemberAuthor(
      name: 'Isabel Allende',
      description: 'Una de las voces más leídas de la narrativa en español.',
      initials: 'IA',
      color: Color(0xFF7EAA85),
    ),
    _MemberAuthor(
      name: 'Jorge Luis Borges',
      description: 'Maestro del cuento y de la literatura fantástica.',
      initials: 'JB',
      color: Color(0xFF8396B5),
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    if (_ownsAuthService) _authService.close();
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

  void _showUnavailable(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature estará disponible próximamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _confirmLogout() async {
    if (_isLoggingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Se cerrará tu sesión y volverás a la página pública de Lectio. '
          'El acceso con huella seguirá disponible en este dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      await _authService.logout(session: widget.session);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 76,
            elevation: 0,
            backgroundColor: Colors.white,
            titleSpacing: 0,
            title: _MemberNavigation(
              username: widget.session.username,
              onHome: () => _goTo(_homeKey),
              onCollection: () => _goTo(_collectionKey),
              onAuthors: () => _goTo(_authorsKey),
              onHelp: () => _goTo(_helpKey),
              onFuturePage: _showUnavailable,
              onLogout: _confirmLogout,
              loggingOut: _isLoggingOut,
            ),
          ),
          SliverToBoxAdapter(
            child: _MemberHero(
              key: _homeKey,
              username: widget.session.username,
              onProfile: () =>
                  _showUnavailable('El formulario de preferencias'),
              onExplore: () => _goTo(_collectionKey),
            ),
          ),
          SliverToBoxAdapter(
            child: _MemberCollection(
              key: _collectionKey,
              books: _books,
              onRead: () => _showUnavailable('La lectura de libros'),
            ),
          ),
          SliverToBoxAdapter(
            child: _MemberAuthors(key: _authorsKey, authors: _authors),
          ),
          SliverToBoxAdapter(
            child: _MemberHelp(
              key: _helpKey,
              onAssistant: () => _showUnavailable('El asistente Lectio'),
            ),
          ),
          SliverToBoxAdapter(
            child: _MemberReview(
              onSubmit: () => _showUnavailable('El envío de reseñas'),
            ),
          ),
          const SliverToBoxAdapter(child: _MemberFooter()),
        ],
      ),
    );
  }
}

class _MemberNavigation extends StatelessWidget {
  const _MemberNavigation({
    required this.username,
    required this.onHome,
    required this.onCollection,
    required this.onAuthors,
    required this.onHelp,
    required this.onFuturePage,
    required this.onLogout,
    required this.loggingOut,
  });

  final String username;
  final VoidCallback onHome;
  final VoidCallback onCollection;
  final VoidCallback onAuthors;
  final VoidCallback onHelp;
  final ValueChanged<String> onFuturePage;
  final VoidCallback onLogout;
  final bool loggingOut;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1400;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              InkWell(
                onTap: onHome,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_stories, color: _green, size: 30),
                    const SizedBox(width: 9),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LECTIO',
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 24,
                            height: 1,
                            color: _ink,
                          ),
                        ),
                        Text(
                          'BIBLIOTECA',
                          style: GoogleFonts.jetBrainsMono(
                            color: _green,
                            fontSize: 8,
                            letterSpacing: 1.4,
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
                  icon: const Icon(Icons.menu_rounded, color: _ink),
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
                      case 'Reserva':
                      case 'Optimizador':
                      case 'Desafío':
                        onFuturePage(value);
                      case 'Cerrar sesión':
                        onLogout();
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
                    PopupMenuItem(value: 'Reserva', child: Text('Reserva')),
                    PopupMenuItem(
                      value: 'Optimizador',
                      child: Text('Optimizador'),
                    ),
                    PopupMenuItem(value: 'Desafío', child: Text('Desafío')),
                    PopupMenuItem(
                      value: 'Cerrar sesión',
                      child: Text('Cerrar sesión'),
                    ),
                  ],
                )
              else ...[
                _MemberNavLink(label: 'Inicio', onTap: onHome),
                _MemberNavLink(label: 'Colección', onTap: onCollection),
                _MemberNavLink(label: 'Autores', onTap: onAuthors),
                _MemberNavLink(label: 'Ayuda', onTap: onHelp),
                _MemberNavLink(
                  label: 'Libros Virtuales',
                  onTap: () => onFuturePage('Libros Virtuales'),
                ),
                _MemberNavLink(
                  label: 'Reserva',
                  onTap: () => onFuturePage('Reservas'),
                ),
                _MemberNavLink(
                  label: 'Optimizador',
                  onTap: () => onFuturePage('Optimizador'),
                ),
                _MemberNavLink(
                  label: 'Desafío',
                  onTap: () => onFuturePage('Desafío'),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: username,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: const Color(0xFFE6F3EB),
                    child: Text(
                      username.isEmpty ? '?' : username[0].toUpperCase(),
                      style: const TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: loggingOut ? null : onLogout,
                  icon: loggingOut
                      ? const SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout_rounded, size: 17),
                  label: const Text('Salir'),
                  style: TextButton.styleFrom(foregroundColor: _green),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MemberNavLink extends StatelessWidget {
  const _MemberNavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: _inkSoft,
        padding: const EdgeInsets.symmetric(horizontal: 9),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _MemberHero extends StatelessWidget {
  const _MemberHero({
    super.key,
    required this.username,
    required this.onProfile,
    required this.onExplore,
  });

  final String username;
  final VoidCallback onProfile;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return SizedBox(
          height: compact ? 1000 : 680,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?auto=format&fit=crop&w=2000&q=85',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: Color(0xFF163B2A)),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xE60D2B1D),
                      Color(0xB30D2B1D),
                      Color(0x351A3C2B),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 26 : 72,
                  vertical: 54,
                ),
                child: _ConstrainedMemberContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _Eyebrow(
                        icon: Icons.circle,
                        label: 'EN LÍNEA · SESIÓN ACTIVA',
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Hola, $username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: .8),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¡Queremos\nconocerte!',
                        style: GoogleFonts.instrumentSerif(
                          color: Colors.white,
                          fontSize: compact ? 60 : 88,
                          height: .98,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 530),
                        child: Text(
                          'Cuéntanos un poco sobre ti para personalizar tu experiencia y recomendarte lecturas que realmente disfrutes.',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: .83),
                            fontSize: 16,
                            height: 1.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: onProfile,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Ir al formulario'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF34A06C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 17,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: onExplore,
                            icon: const Icon(Icons.auto_stories_outlined),
                            label: const Text('Explorar colección'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: .55),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      const Wrap(
                        spacing: 26,
                        runSpacing: 14,
                        children: [
                          _MemberStat(value: '12.500+', label: 'LIBROS'),
                          _MemberStat(value: '480+', label: 'AUTORES'),
                          _MemberStat(value: '24/7', label: 'DESCUBRIMIENTO'),
                        ],
                      ),
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

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: const Color(0xFF7FC9A0)),
        const SizedBox(width: 9),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: const Color(0xFFD0E8D9),
            fontSize: 10,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _MemberStat extends StatelessWidget {
  const _MemberStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.instrumentSerif(color: Colors.white, fontSize: 27),
        ),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: const Color(0xFFD0E8D9),
            fontSize: 9,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _MemberCollection extends StatelessWidget {
  const _MemberCollection({
    super.key,
    required this.books,
    required this.onRead,
  });

  final List<_MemberBook> books;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    return _MemberSection(
      background: _paper,
      eyebrow: 'CATÁLOGO · 01',
      title: 'Nuestra colección.',
      description: 'Encuentra los mejores libros seleccionados para ti, disponibles al instante.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 520
              ? 1
              : constraints.maxWidth < 900
              ? 2
              : 3;
          final width = (constraints.maxWidth - (columns - 1) * 22) / columns;
          return Wrap(
            spacing: 22,
            runSpacing: 22,
            children: [
              for (final book in books)
                SizedBox(
                  width: width,
                  child: _MemberBookCard(book: book, onRead: onRead),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MemberBookCard extends StatelessWidget {
  const _MemberBookCard({required this.book, required this.onRead});

  final _MemberBook book;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.55,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  book.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      ColoredBox(color: book.accent),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: .55),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  bottom: 16,
                  child: Text(
                    book.category.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: GoogleFonts.instrumentSerif(color: _ink, fontSize: 25),
                ),
                const SizedBox(height: 7),
                Text(
                  book.description,
                  style: GoogleFonts.inter(
                    color: _muted,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 15),
                TextButton.icon(
                  onPressed: onRead,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Leer'),
                  style: TextButton.styleFrom(
                    foregroundColor: _green,
                    padding: EdgeInsets.zero,
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

class _MemberAuthors extends StatelessWidget {
  const _MemberAuthors({super.key, required this.authors});

  final List<_MemberAuthor> authors;

  @override
  Widget build(BuildContext context) {
    return _MemberSection(
      background: const Color(0xFFEEF7F1),
      eyebrow: 'TALENTO · 02',
      title: 'Autores destacados.',
      description: 'Voces que han marcado generaciones enteras de lectores.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 580 ? 1 : 3;
          final width = (constraints.maxWidth - (columns - 1) * 18) / columns;
          return Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              for (var i = 0; i < authors.length; i++)
                SizedBox(
                  width: width,
                  child: _MemberAuthorCard(author: authors[i], index: i + 1),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MemberAuthorCard extends StatelessWidget {
  const _MemberAuthorCard({required this.author, required this.index});

  final _MemberAuthor author;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: author.color,
                child: Text(
                  author.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                index.toString().padLeft(2, '0'),
                style: GoogleFonts.jetBrainsMono(color: _muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 23),
          Text(
            author.name,
            style: GoogleFonts.instrumentSerif(fontSize: 25, color: _ink),
          ),
          const SizedBox(height: 8),
          Text(
            author.description,
            style: GoogleFonts.inter(color: _muted, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _MemberHelp extends StatelessWidget {
  const _MemberHelp({super.key, required this.onAssistant});

  final VoidCallback onAssistant;

  @override
  Widget build(BuildContext context) {
    return _MemberSection(
      background: _paper,
      eyebrow: 'SOPORTE · 03',
      title: 'Centro de ayuda.',
      description: '¿Tienes dudas? Estamos para ayudarte.',
      footer: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: OutlinedButton.icon(
          onPressed: onAssistant,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Hablar con el asistente Lectio'),
          style: OutlinedButton.styleFrom(foregroundColor: _green),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 580 ? 1 : 3;
          final width = (constraints.maxWidth - (columns - 1) * 18) / columns;
          const items = [
            (
              icon: Icons.mail_outline_rounded,
              title: 'Escríbenos',
              detail: 'servicios@booklab.gov.co',
            ),
            (
              icon: Icons.phone_outlined,
              title: 'Llámanos',
              detail: '(+57 601) 342 4100',
            ),
            (
              icon: Icons.location_on_outlined,
              title: 'Visítanos',
              detail: 'San Pedro Martin · Cra 64 A',
            ),
          ];
          return Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              for (final item in items)
                SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.icon, color: _green),
                        const SizedBox(height: 15),
                        Text(
                          item.title,
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 23,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.detail,
                          style: GoogleFonts.inter(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MemberReview extends StatelessWidget {
  const _MemberReview({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _MemberSection(
      background: const Color(0xFFEEF7F1),
      eyebrow: 'OPINIÓN · 04',
      title: 'Deja tu reseña.',
      description:
          'Tu opinión nos ayuda a mejorar nuestra biblioteca para todos.',
      footer: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: FilledButton(
          onPressed: onSubmit,
          style: FilledButton.styleFrom(backgroundColor: _green),
          child: const Text('Enviar reseña'),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: TextField(
          minLines: 4,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: 'Comentario',
            alignLabelWithHint: true,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: _line),
              borderRadius: BorderRadius.circular(4),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _line),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberSection extends StatelessWidget {
  const _MemberSection({
    required this.background,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
    this.footer,
  });

  final Color background;
  final String eyebrow;
  final String title;
  final String description;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 70),
        child: _ConstrainedMemberContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: GoogleFonts.jetBrainsMono(
                  color: _green,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.instrumentSerif(
                  color: _ink,
                  fontSize: 42,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 610),
                child: Text(
                  description,
                  style: GoogleFonts.inter(color: _muted, height: 1.6),
                ),
              ),
              const SizedBox(height: 30),
              child,
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberFooter extends StatelessWidget {
  const _MemberFooter();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0D2B1D),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: _ConstrainedMemberContent(
          child: Row(
            children: [
              Text(
                'LECTIO',
                style: GoogleFonts.instrumentSerif(
                  color: Colors.white,
                  fontSize: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tu biblioteca virtual de confianza.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: .72),
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '© 2026 Lectio Biblioteca',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white.withValues(alpha: .62),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConstrainedMemberContent extends StatelessWidget {
  const _ConstrainedMemberContent({required this.child});

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

class _MemberBook {
  const _MemberBook({
    required this.title,
    required this.category,
    required this.description,
    required this.image,
    required this.accent,
  });

  final String title;
  final String category;
  final String description;
  final String image;
  final Color accent;
}

class _MemberAuthor {
  const _MemberAuthor({
    required this.name,
    required this.description,
    required this.initials,
    required this.color,
  });

  final String name;
  final String description;
  final String initials;
  final Color color;
}

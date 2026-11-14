import '../../profile/presentation/member_appearance.dart';
import '../../notifications/data/lectio_notifications.dart';
import '../../profile/data/local_profile_store.dart';
import '../../profile/presentation/profile_pages.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/lectio_auth_service.dart';
import '../../analytics/data/lectio_ai_service.dart';
import '../../analytics/presentation/lectio_ai_insights.dart';
import '../../challenges/presentation/desafio.dart';
import '../../reservations/data/reservas_service.dart';
import '../../reservations/presentation/reservas.dart';
import '../../virtual_books/data/libros_service.dart';
import '../../virtual_books/presentation/libros.dart';

const _contentWidth = 1240.0;

class LectioMemberPage extends StatefulWidget {
  const LectioMemberPage({
    super.key,
    required this.session,
    this.authService,
    this.reservationService,
    this.virtualBooksService,
    this.lectioAiDataSource,
    this.profileStore,
  });

  final AuthSession session;
  final LectioAuthService? authService;
  final ReservaDataSource? reservationService;
  final LibrosVirtualesDataSource? virtualBooksService;
  final LectioAiDataSource? lectioAiDataSource;
  final LocalProfileStore? profileStore;

  @override
  State<LectioMemberPage> createState() => _LectioMemberPageState();
}

class _LectioMemberPageState extends State<LectioMemberPage>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  final _collectionKey = GlobalKey();
  final _authorsKey = GlobalKey();
  final _helpKey = GlobalKey();
  late final bool _ownsAuthService = widget.authService == null;
  late final LectioAuthService _authService =
      widget.authService ?? LectioAuthService();
  bool _isLoggingOut = false;
  late final _profileStore = widget.profileStore ?? LocalProfileStore.instance;
  bool _profileReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await _profileStore.openUser(widget.session.username);
    if (!mounted) return;
    await _profileStore.activateNotifications();
    if (mounted) setState(() => _profileReady = true);
  }

  Future<void> _openLocalPage(int page) async {
    if (!_profileReady) await _loadProfile();
    if (!mounted) return;
    _openPage(switch (page) {
      0 => ProfilePage(store: _profileStore),
      1 => SettingsPage(store: _profileStore),
      _ => PersonalLibraryPage(store: _profileStore),
    });
  }

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
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    if (_ownsAuthService) _authService.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _profileReady && !_isLoggingOut) {
      _profileStore.refreshNotifications();
    }
  }

  void _goTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 550),
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

  void _openPage(Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, _, _) => MemberAppearance(
          store: _profileStore,
          builder: (context, _) => page,
        ),
      ),
    );
  }

  void _openProfile() => _openLocalPage(0);

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
      if (!_profileReady) await _loadProfile();
      await _profileStore.deactivateNotifications();
      await _authService.logout(session: widget.session);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      await _profileStore.activateNotifications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on NotificationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MemberAppearance(
      store: _profileStore,
      builder: (context, _) {
        final profile = _profileReady ? _profileStore.profile : LocalProfile();
        final displayName = profile.hideName
            ? 'lector'
            : widget.session.username;
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                toolbarHeight: 76,
                elevation: 0,
                backgroundColor: Theme.of(context).colorScheme.surface,
                automaticallyImplyLeading: false,
                titleSpacing: 0,
                title: _MemberNavigation(
                  username: displayName,
                  onProfile: _openProfile,
                  onSettings: () => _openLocalPage(1),
                  onLibrary: () => _openLocalPage(2),
                  onCollection: () => _goTo(_collectionKey),
                  onAuthors: () => _goTo(_authorsKey),
                  onHelp: () => _goTo(_helpKey),
                  onVirtualBooks: () => _openPage(
                    LectioVirtualBooksPage(
                      session: widget.session,
                      service: widget.virtualBooksService,
                      profileStore: _profileStore,
                    ),
                  ),
                  onReservations: () => _openPage(
                    LectioReservationsPage(
                      session: widget.session,
                      service: widget.reservationService,
                      profileStore: _profileStore,
                    ),
                  ),
                  onChallenge: () =>
                      _openPage(LectioChallengePage(session: widget.session)),
                  onLogout: _confirmLogout,
                  loggingOut: _isLoggingOut,
                ),
              ),
              SliverToBoxAdapter(
                child: _MemberHero(
                  username: displayName,
                  onProfile: _openProfile,
                  onExplore: () => _goTo(_collectionKey),
                ),
              ),
              SliverToBoxAdapter(
                child: LectioAiInsights(dataSource: widget.lectioAiDataSource),
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
      },
    );
  }
}

class _MemberNavigation extends StatelessWidget {
  const _MemberNavigation({
    required this.username,
    required this.onProfile,
    required this.onSettings,
    required this.onLibrary,
    required this.onCollection,
    required this.onAuthors,
    required this.onHelp,
    required this.onVirtualBooks,
    required this.onReservations,
    required this.onChallenge,
    required this.onLogout,
    required this.loggingOut,
  });

  final String username;
  final VoidCallback onProfile;
  final VoidCallback onSettings;
  final VoidCallback onLibrary;
  final VoidCallback onCollection;
  final VoidCallback onAuthors;
  final VoidCallback onHelp;
  final VoidCallback onVirtualBooks;
  final VoidCallback onReservations;
  final VoidCallback onChallenge;
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_stories,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
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
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'BIBLIOTECA',
                        style: GoogleFonts.jetBrainsMono(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 8,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              if (compact)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: TextButton(
                    onPressed: onProfile,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * .34,
                      ),
                      child: Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              if (compact)
                PopupMenuButton<String>(
                  tooltip: 'Abrir navegación',
                  icon: Icon(
                    Icons.menu_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'Configuración':
                        onSettings();
                      case 'Mi biblioteca':
                        onLibrary();
                      case 'Perfil':
                        onProfile();
                      case 'Libros Virtuales':
                        onVirtualBooks();
                      case 'Reserva':
                        onReservations();
                      case 'Desafío':
                        onChallenge();
                      case 'Cerrar sesión':
                        onLogout();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Perfil', child: Text('Perfil')),
                    PopupMenuItem(
                      value: 'Mi biblioteca',
                      child: Text('Mi biblioteca'),
                    ),
                    PopupMenuItem(
                      value: 'Configuración',
                      child: Text('Configuración'),
                    ),
                    PopupMenuItem(
                      value: 'Libros Virtuales',
                      child: Text('Libros Virtuales'),
                    ),
                    PopupMenuItem(value: 'Reserva', child: Text('Reserva')),
                    PopupMenuItem(value: 'Desafío', child: Text('Desafío')),
                    PopupMenuItem(
                      value: 'Cerrar sesión',
                      child: Text('Cerrar sesión'),
                    ),
                  ],
                )
              else ...[
                IconButton(
                  tooltip: 'Mi biblioteca',
                  onPressed: onLibrary,
                  icon: const Icon(Icons.library_books_outlined),
                ),
                IconButton(
                  tooltip: 'Configuración',
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings_outlined),
                ),
                _MemberNavLink(label: 'Colección', onTap: onCollection),
                _MemberNavLink(label: 'Autores', onTap: onAuthors),
                _MemberNavLink(label: 'Ayuda', onTap: onHelp),
                _MemberNavLink(
                  label: 'Libros Virtuales',
                  onTap: onVirtualBooks,
                ),
                _MemberNavLink(label: 'Reserva', onTap: onReservations),
                _MemberNavLink(label: 'Desafío', onTap: onChallenge),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onProfile,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
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
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 9),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _MemberHero extends StatelessWidget {
  const _MemberHero({
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
      background: Theme.of(context).colorScheme.surface,
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
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                  style: GoogleFonts.instrumentSerif(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  book.description,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    foregroundColor: Theme.of(context).colorScheme.primary,
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
      background: Theme.of(context).colorScheme.surfaceContainerLow,
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
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                style: GoogleFonts.jetBrainsMono(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 23),
          Text(
            author.name,
            style: GoogleFonts.instrumentSerif(
              fontSize: 25,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            author.description,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.6,
            ),
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
      background: Theme.of(context).colorScheme.surface,
      eyebrow: 'SOPORTE · 03',
      title: 'Centro de ayuda.',
      description: '¿Tienes dudas? Estamos para ayudarte.',
      footer: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: OutlinedButton.icon(
          onPressed: onAssistant,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Hablar con el asistente Lectio'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
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
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          item.icon,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          item.title,
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 23,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.detail,
                          style: GoogleFonts.inter(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 12,
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
    );
  }
}

class _MemberReview extends StatelessWidget {
  const _MemberReview({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _MemberSection(
      background: Theme.of(context).colorScheme.surfaceContainerLow,
      eyebrow: 'OPINIÓN · 04',
      title: 'Deja tu reseña.',
      description:
          'Tu opinión nos ayuda a mejorar nuestra biblioteca para todos.',
      footer: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: FilledButton(
          onPressed: onSubmit,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
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
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
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
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.instrumentSerif(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 42,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 610),
                child: Text(
                  description,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
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
      color: const Color(0xFF10261C),
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

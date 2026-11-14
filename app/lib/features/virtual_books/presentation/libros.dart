import '../../profile/data/local_profile_store.dart';
import '../../profile/presentation/profile_pages.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/data/lectio_auth_service.dart';
import '../data/libros_service.dart';

const _categories = [
  'Novelas',
  'Ciencia',
  'Historia',
  'Arte',
  'Fantasía',
  'Filosofía',
];
const _itemsPerPage = 12;

class LectioVirtualBooksPage extends StatefulWidget {
  const LectioVirtualBooksPage({
    super.key,
    required this.session,
    this.service,
    this.profileStore,
  });

  final AuthSession session;
  final LibrosVirtualesDataSource? service;
  final LocalProfileStore? profileStore;

  @override
  State<LectioVirtualBooksPage> createState() => _LectioVirtualBooksPageState();
}

class _LectioVirtualBooksPageState extends State<LectioVirtualBooksPage> {
  late final LibrosVirtualesService? _ownedService = widget.service == null
      ? LibrosVirtualesService(session: widget.session)
      : null;
  late final LibrosVirtualesDataSource _service =
      widget.service ?? _ownedService!;
  final _searchController = TextEditingController();
  final _selectedCategories = _categories.toSet();
  List<LibroVirtual> _books = [];
  String? _loadError;
  bool _isLoading = true;
  int _currentPage = 1;
  late final _profileStore = widget.profileStore ?? LocalProfileStore.instance;
  bool _useFavoriteGenres = false;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ownedService?.close();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _currentPage = 1;
    });
    try {
      final books = await _service.loadBooks();
      if (!mounted) return;
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } on LibrosVirtualesException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _isLoading = false;
      });
    }
  }

  List<LibroVirtual> get _filteredBooks {
    final term = _normalizeText(_searchController.text.trim());
    return _books
        .where(
          (book) =>
              _selectedCategories.contains(book.categoria) &&
              (!_useFavoriteGenres ||
                  _profileStore.profile.genres.contains(book.categoria)) &&
              (term.isEmpty || _normalizeText(book.titulo).contains(term)),
        )
        .toList(growable: false);
  }

  Future<void> _readBook(LibroVirtual book) async {
    try {
      final opened = await launchUrl(
        book.url,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        _showMessage('No se pudo abrir el enlace de lectura.');
      }
    } catch (error) {
      if (mounted) _showMessage('No se pudo abrir el libro: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _goToPage(int totalPages) async {
    final controller = TextEditingController(text: '$_currentPage');
    final selectedPage = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ir a la página'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Número de página (1–$totalPages)',
          ),
          onSubmitted: (value) =>
              Navigator.of(context).pop(int.tryParse(value)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(int.tryParse(controller.text)),
            child: const Text('Ir'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || selectedPage == null) return;
    if (selectedPage < 1 || selectedPage > totalPages) {
      _showMessage('Ingresa una página entre 1 y $totalPages.');
      return;
    }
    setState(() => _currentPage = selectedPage);
  }

  @override
  Widget build(BuildContext context) {
    final books = _filteredBooks;
    final totalPages = (books.length / _itemsPerPage).ceil();
    final safePage = totalPages == 0 ? 1 : _currentPage.clamp(1, totalPages);
    final pageBooks = books
        .skip((safePage - 1) * _itemsPerPage)
        .take(_itemsPerPage)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 22,
        title: Row(
          children: [
            Icon(
              Icons.auto_stories_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Text(
              'LECTIO',
              style: GoogleFonts.instrumentSerif(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 25,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBooks,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _VirtualBooksHero(
              username: _profileStore.displayNameFor(widget.session.username),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 30, 22, 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() => _currentPage = 1),
                        decoration: InputDecoration(
                          hintText: 'Buscar libros por título...',
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpiar búsqueda',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _currentPage = 1);
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: _categories.map((category) {
                          final selected = _selectedCategories.contains(
                            category,
                          );
                          return FilterChip(
                            label: Text(category),
                            selected: selected,
                            showCheckmark: true,
                            selectedColor: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            checkmarkColor: Theme.of(context)
                                .colorScheme
                                .primary,
                            side: BorderSide(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                            ),
                            labelStyle: TextStyle(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (value) {
                              setState(() {
                                if (value) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                                _currentPage = 1;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Usar mis géneros favoritos'),
                        subtitle: Text(
                          _profileStore.profile.genres.isEmpty
                              ? 'Selecciona tus géneros en Mi perfil.'
                              : _profileStore.profile.genres.join(' · '),
                        ),
                        value: _useFavoriteGenres,
                        onChanged: _profileStore.profile.genres.isEmpty
                            ? null
                            : (v) => setState(() {
                                _useFavoriteGenres = v;
                                _currentPage = 1;
                              }),
                      ),
                      const SizedBox(height: 22),
                      if (_isLoading)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 90),
                          child: Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Cargando catálogo...',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_loadError != null)
                        _CatalogError(message: _loadError!, onRetry: _loadBooks)
                      else if (books.isEmpty)
                        const _NoVirtualBooks()
                      else ...[
                        Text(
                          '${books.length} ${books.length == 1 ? 'libro encontrado' : 'libros encontrados'}',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 15),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 900
                                ? 3
                                : constraints.maxWidth >= 560
                                ? 2
                                : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pageBooks.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisExtent:
                                        410 *
                                        MediaQuery.textScalerOf(context)
                                            .scale(1),
                                    crossAxisSpacing: 17,
                                    mainAxisSpacing: 17,
                                  ),
                              itemBuilder: (context, index) => _VirtualBookCard(
                                book: pageBooks[index],
                                profileStore: _profileStore,
                                onRead: () => _readBook(pageBooks[index]),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 22),
                        _CatalogPagination(
                          currentPage: safePage,
                          totalPages: totalPages,
                          onPageChanged: (page) =>
                              setState(() => _currentPage = page),
                          onJump: () => _goToPage(totalPages),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VirtualBooksHero extends StatelessWidget {
  const _VirtualBooksHero({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 42),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 8,
                  spacing: 24,
                  children: [
                    const _HeroStatus(
                      icon: Icons.circle,
                      text: 'CATÁLOGO ACTIVO',
                    ),
                    const _HeroStatus(
                      icon: Icons.auto_stories_outlined,
                      text: 'LECTIO · BIBLIOTECA DIGITAL',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'LIBROS VIRTUALES',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 14),
                Text.rich(
                  TextSpan(
                    style: GoogleFonts.instrumentSerif(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 54,
                      height: .98,
                    ),
                    children: [
                      TextSpan(text: 'Encuentra tu próxima '),
                      TextSpan(
                        text: 'lectura.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Text(
                    'Explora, filtra y busca por título entre nuestra colección '
                    'de libros virtuales. Hola, $username: elige una categoría '
                    'y empieza a leer.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.6,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroStatus extends StatelessWidget {
  const _HeroStatus({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}

class _VirtualBookCard extends StatelessWidget {
  const _VirtualBookCard({
    required this.book,
    required this.onRead,
    required this.profileStore,
  });

  final LibroVirtual book;
  final VoidCallback onRead;
  final LocalProfileStore profileStore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0D2B1D),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  book.categoria.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            book.titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.instrumentSerif(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 27,
              height: 1.04,
            ),
          ),
          if (book.autor.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              book.autor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              book.descripcion,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          BookProgressControls(
            store: profileStore,
            book: SavedBook(
              url: book.url.toString(),
              title: book.titulo,
              category: book.categoria,
              author: book.autor,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRead,
              icon: const Icon(Icons.open_in_new_rounded, size: 17),
              label: const Text('Leer'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoVirtualBooks extends StatelessWidget {
  const _NoVirtualBooks();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 90),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 52,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 14),
          Text(
            'No se encontraron libros que coincidan con tu búsqueda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Prueba con otro título o activa más categorías.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 50,
            color: Color(0xFFC8464A),
          ),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Intentar de nuevo'),
          ),
        ],
      ),
    );
  }
}

class _CatalogPagination extends StatelessWidget {
  const _CatalogPagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onJump,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    var startPage = math.max(1, currentPage - 1);
    final endPage = math.min(totalPages, startPage + 2);
    if (endPage - startPage < 2) {
      startPage = math.max(1, endPage - 2);
    }
    final pages = [for (var page = startPage; page <= endPage; page++) page];

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 5,
      children: [
        IconButton(
          tooltip: 'Página anterior',
          onPressed: currentPage > 1
              ? () => onPageChanged(currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        ...pages.map(
          (page) => page == currentPage
              ? FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: Text('$page'),
                )
              : TextButton(
                  onPressed: () => onPageChanged(page),
                  child: Text('$page'),
                ),
        ),
        IconButton(
          tooltip: 'Página siguiente',
          onPressed: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        TextButton.icon(
          onPressed: onJump,
          icon: const Icon(Icons.last_page_rounded, size: 18),
          label: const Text('Ir a página'),
        ),
      ],
    );
  }
}

String _normalizeText(String value) =>
    value.normalizeDiacritics().toLowerCase();

extension on String {
  String normalizeDiacritics() {
    const replacements = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    return replaceAllMapped(
      RegExp('[áéíóúüñ]', caseSensitive: false),
      (match) => replacements[match[0]!.toLowerCase()]!,
    );
  }
}

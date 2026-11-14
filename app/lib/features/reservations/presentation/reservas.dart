import '../../profile/data/local_profile_store.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/data/lectio_auth_service.dart';
import '../data/reservas_service.dart';

const _categories = [
  'Novelas',
  'Ciencia',
  'Historia',
  'Arte',
  'Fantasía',
  'Filosofía',
];
const _itemsPerPage = 8;

class LectioReservationsPage extends StatefulWidget {
  const LectioReservationsPage({
    super.key,
    required this.session,
    this.service,
    this.profileStore,
  });

  final AuthSession session;
  final ReservaDataSource? service;
  final LocalProfileStore? profileStore;

  @override
  State<LectioReservationsPage> createState() => _LectioReservationsPageState();
}

class _LectioReservationsPageState extends State<LectioReservationsPage> {
  late final ReservasService? _ownedService = widget.service == null
      ? ReservasService(session: widget.session)
      : null;
  late final ReservaDataSource _service = widget.service ?? _ownedService!;
  final _searchController = TextEditingController();
  List<ReservaBook> _books = [];
  String? _selectedCategory;
  String? _loadError;
  bool _isLoading = true;
  int _currentPage = 1;

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
      final books = await _service.loadBooks(category: _selectedCategory);
      if (!mounted) return;
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } on ReservaApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _isLoading = false;
      });
    }
  }

  List<ReservaBook> get _filteredBooks {
    final term = _searchController.text.trim().toLowerCase();
    if (term.isEmpty) return _books;
    return _books
        .where(
          (book) =>
              book.titulo.toLowerCase().contains(term) ||
              book.autor.toLowerCase().contains(term),
        )
        .toList(growable: false);
  }

  Future<void> _openReservation(ReservaBook book) async {
    final reserved = await showDialog<bool>(
      context: context,
      builder: (context) => _ReservationDialog(
        book: book,
        onSubmit: ({required fullName, required email, required date}) async {
          await _service.createReservation(
            bookId: book.id,
            title: book.titulo,
            category: book.categoria,
            fullName: fullName,
            email: email,
            date: date,
          );
          await (widget.profileStore ?? LocalProfileStore.instance)
              .notifyReservationConfirmed(widget.session.username);
        },
      ),
    );
    if (reserved != true || !mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Reserva realizada con éxito.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    await _loadBooks();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBooks = _filteredBooks;
    final totalPages = (filteredBooks.length / _itemsPerPage).ceil();
    final safePage = totalPages == 0 ? 1 : _currentPage.clamp(1, totalPages);
    final startIndex = (safePage - 1) * _itemsPerPage;
    final pageBooks = filteredBooks
        .skip(startIndex)
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
            _ReservationHero(
              username: LocalProfileStore.instance.displayNameFor(
                widget.session.username,
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 52),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 620;
                          final categoryField =
                              DropdownButtonFormField<String?>(
                                initialValue: _selectedCategory,
                                isExpanded: true,
                                decoration: _inputDecoration(
                                  context,
                                  label: 'Categoría',
                                  icon: Icons.category_outlined,
                                ),
                                hint: const Text('Todas las categorías'),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Todas las categorías'),
                                  ),
                                  ..._categories.map(
                                    (category) => DropdownMenuItem<String?>(
                                      value: category,
                                      child: Text(category),
                                    ),
                                  ),
                                ],
                                onChanged: (category) {
                                  setState(() => _selectedCategory = category);
                                  _loadBooks();
                                },
                              );
                          final searchField = TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {
                              _currentPage = 1;
                            }),
                            decoration:
                                _inputDecoration(
                                  context,
                                  label: 'Buscar libro por título o autor',
                                  icon: Icons.search_rounded,
                                ).copyWith(
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
                                ),
                          );

                          if (compact) {
                            return Column(
                              children: [
                                categoryField,
                                const SizedBox(height: 12),
                                searchField,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: categoryField),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: searchField),
                            ],
                          );
                        },
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
                                  'Cargando libros...',
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
                        _LoadError(message: _loadError!, onRetry: _loadBooks)
                      else if (filteredBooks.isEmpty)
                        const _EmptyBooks()
                      else ...[
                        Text(
                          '${filteredBooks.length} ${filteredBooks.length == 1 ? 'libro disponible' : 'libros disponibles'}',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 760 ? 2 : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pageBooks.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisExtent:
                                        300 *
                                        MediaQuery.textScalerOf(context)
                                            .scale(1),
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemBuilder: (context, index) => _BookCard(
                                book: pageBooks[index],
                                onReserve: () =>
                                    _openReservation(pageBooks[index]),
                              ),
                            );
                          },
                        ),
                        if (totalPages > 1) ...[
                          const SizedBox(height: 24),
                          _Pagination(
                            currentPage: safePage,
                            totalPages: totalPages,
                            onPageChanged: (page) =>
                                setState(() => _currentPage = page),
                          ),
                        ],
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

class _ReservationHero extends StatelessWidget {
  const _ReservationHero({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 34),
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
          constraints: const BoxConstraints(maxWidth: 1120),
          child: LayoutBuilder(
            builder: (context, constraints) => Flex(
              direction: constraints.maxWidth < 960
                  ? Axis.vertical
                  : Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: constraints.maxWidth < 960
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reserva de',
                      style: GoogleFonts.instrumentSerif(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 42,
                        height: 1.05,
                      ),
                    ),
                    Text(
                      'libros físicos.',
                      style: GoogleFonts.instrumentSerif(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 42,
                        fontStyle: FontStyle.italic,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Hola, $username. Encuentra un libro y resérvalo.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(
                    top: constraints.maxWidth < 960 ? 18 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 9, color: Color(0xFF34A06C)),
                      SizedBox(width: 9),
                      Text(
                        'CATÁLOGO ACTIVO',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.onReserve});

  final ReservaBook book;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    final available = book.stock > 0;
    final lowStock = book.stock <= 3;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                color: available
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: !available
                      ? const Color(0xFFFBEAEA)
                      : lowStock
                      ? const Color(0xFFFFF3E0)
                      : Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  available ? 'Stock: ${book.stock}' : 'Agotado',
                  style: TextStyle(
                    color: !available
                        ? const Color(0xFFC8464A)
                        : lowStock
                        ? const Color(0xFF9B651F)
                        : Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            book.titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.instrumentSerif(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 25,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          if (book.autor.isNotEmpty)
            _BookMetadata(label: 'Autor', value: book.autor),
          if (book.categoria.isNotEmpty)
            _BookMetadata(label: 'Categoría', value: book.categoria),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: available ? onReserve : null,
              icon: Icon(
                available ? Icons.arrow_forward_rounded : Icons.block_rounded,
                size: 18,
              ),
              label: Text(available ? 'Reservar' : 'Sin disponibilidad'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                disabledBackgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                disabledForegroundColor: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookMetadata extends StatelessWidget {
  const _BookMetadata({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
          children: [
            TextSpan(
              text: '$label  ',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _EmptyBooks extends StatelessWidget {
  const _EmptyBooks();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 84),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 14),
          Text(
            'No se encontraron libros',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Prueba con otra búsqueda o categoría.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: Color(0xFFC8464A),
          ),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
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

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Página anterior',
          onPressed: currentPage > 1
              ? () => onPageChanged(currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text(
          'Página $currentPage de $totalPages',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        IconButton(
          tooltip: 'Página siguiente',
          onPressed: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _ReservationDialog extends StatefulWidget {
  const _ReservationDialog({required this.book, required this.onSubmit});

  final ReservaBook book;
  final Future<void> Function({
    required String fullName,
    required String email,
    required String date,
  })
  onSubmit;

  @override
  State<_ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<_ReservationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime _date = DateTime.now();
  String? _error;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime(now.year, now.month, now.day))
          ? DateTime(now.year, now.month, now.day)
          : _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
      locale: const Locale('es'),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.onSubmit(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        date:
            '${_date.year.toString().padLeft(4, '0')}-'
            '${_date.month.toString().padLeft(2, '0')}-'
            '${_date.day.toString().padLeft(2, '0')}',
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ReservaApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isSubmitting = false;
        });
      }
    } finally {
      if (mounted && _isSubmitting && _error == null) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Reservar libro',
        style: GoogleFonts.instrumentSerif(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 30,
        ),
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.book.titulo,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    context,
                    label: 'Nombre completo',
                    icon: Icons.person_outline_rounded,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe tu nombre completo.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    context,
                    label: 'Correo electrónico',
                    icon: Icons.email_outlined,
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Escribe tu correo electrónico.';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(email)) {
                      return 'Escribe un correo electrónico válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _isSubmitting ? null : _chooseDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: _inputDecoration(
                      context,
                      label: 'Fecha de reserva',
                      icon: Icons.calendar_month_outlined,
                    ),
                    child: Text(
                      '${_date.day.toString().padLeft(2, '0')}/'
                      '${_date.month.toString().padLeft(2, '0')}/'
                      '${_date.year}',
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFC8464A),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.arrow_forward_rounded, size: 18),
          label: Text(_isSubmitting ? 'Enviando...' : 'Confirmar reserva'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(
      icon,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    filled: true,
    fillColor: Theme.of(context).colorScheme.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 1.5,
      ),
    ),
  );
}

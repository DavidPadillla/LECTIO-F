import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/lectio_auth_service.dart';
import 'lectio_member_page.dart';

class LectioAuthPage extends StatefulWidget {
  const LectioAuthPage({super.key, this.authService});

  final LectioAuthService? authService;

  @override
  State<LectioAuthPage> createState() => _LectioAuthPageState();
}

class _LectioAuthPageState extends State<LectioAuthPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  late final AnimationController _entrance;
  late final LectioAuthService _authService;
  late final bool _ownsAuthService;
  bool _isRegistering = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _showSuccess = false;
  String? _successTitle;
  String? _successMessage;
  String? _message;

  @override
  void initState() {
    super.initState();
    _ownsAuthService = widget.authService == null;
    _authService = widget.authService ?? LectioAuthService();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    _entrance.dispose();
    if (_ownsAuthService) _authService.close();
    super.dispose();
  }

  void _setMode(bool registering) {
    if (_isLoading || registering == _isRegistering) return;
    setState(() {
      _isRegistering = registering;
      _message = null;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      if (_isRegistering) {
        await _authService.register(
          username: _usernameController.text,
          password: _passwordController.text,
        );
        if (!mounted) return;
        setState(() {
          _isRegistering = false;
          _isLoading = false;
          _successTitle = '¡Cuenta creada!';
          _successMessage = 'Tu viaje como lector comienza aquí.';
          _showSuccess = true;
          _passwordController.clear();
          _confirmationController.clear();
        });
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 2300), () {
            if (mounted) setState(() => _showSuccess = false);
          }),
        );
        return;
      }

      final session = await _authService.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _successTitle = '¡Bienvenido, ${session.username}!';
        _successMessage = 'PREPARANDO TU BIBLIOTECA...';
        _showSuccess = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) =>
              LectioMemberPage(session: session),
          transitionDuration: const Duration(milliseconds: 650),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final transition = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: transition,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, .025),
                  end: Offset.zero,
                ).animate(transition),
                child: child,
              ),
            );
          },
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 820;
              final content = compact
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height: constraints.maxHeight < 700 ? 220 : 270,
                            child: _LectioBrandPanel(
                              isRegistering: _isRegistering,
                            ),
                          ),
                          _buildFormPanel(compact: true),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _LectioBrandPanel(
                            isRegistering: _isRegistering,
                          ),
                        ),
                        Expanded(child: _buildFormPanel(compact: false)),
                      ],
                    );

              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entrance,
                  curve: Curves.easeOut,
                ),
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, .012),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _entrance,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: content,
                ),
              );
            },
          ),
          _LectioSuccessOverlay(
            visible: _showSuccess,
            title: _successTitle ?? '',
            message: _successMessage ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel({required bool compact}) {
    const ink = Color(0xFF0D2B1D);
    const muted = Color(0xFF6B8377);
    const line = Color(0xFFD4E5D9);

    final formContent = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 24 : 52,
        vertical: compact ? 38 : 50,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  button: true,
                  label: 'Volver a Lectio Biblioteca',
                  child: InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back, size: 15, color: muted),
                          const SizedBox(width: 9),
                          Text(
                            'VOLVER',
                            style: GoogleFonts.jetBrainsMono(
                              color: muted,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 24 : 34),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 560),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, .045),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(_isRegistering),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: _isRegistering ? 'Crea tu ' : 'Hola de ',
                          children: [
                            TextSpan(
                              text: _isRegistering ? 'cuenta.' : 'nuevo.',
                              style: const TextStyle(
                                color: Color(0xFF2A8055),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        style: GoogleFonts.instrumentSerif(
                          color: ink,
                          fontSize: compact ? 39 : 43,
                          height: 1,
                          letterSpacing: -1.1,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        _isRegistering
                            ? 'Solo toma un momento.'
                            : 'Ingresa para continuar.',
                        style: GoogleFonts.inter(color: muted, fontSize: 13),
                      ),
                      const SizedBox(height: 27),
                      if (_message case final message?) ...[
                        _AuthAlert(message: message),
                        const SizedBox(height: 16),
                      ],
                      _AuthTextField(
                        controller: _usernameController,
                        enabled: !_isLoading,
                        hint: 'Usuario',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Usuario requerido'
                            : null,
                      ),
                      const SizedBox(height: 15),
                      _AuthTextField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        hint: 'Contraseña',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        textInputAction: _isRegistering
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_isRegistering) _submit();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Contraseña requerida';
                          }
                          if (_isRegistering && value.length < 6) {
                            return 'Usa al menos 6 caracteres.';
                          }
                          return null;
                        },
                        trailing: IconButton(
                          tooltip: _obscurePassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 19,
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeInOutCubic,
                        child: _isRegistering
                            ? Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: _AuthTextField(
                                  controller: _confirmationController,
                                  enabled: !_isLoading,
                                  hint: 'Confirmar contraseña',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscureConfirmation,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _submit(),
                                  validator: (value) =>
                                      value != _passwordController.text
                                      ? 'Las contraseñas no coinciden.'
                                      : null,
                                  trailing: IconButton(
                                    tooltip: _obscureConfirmation
                                        ? 'Mostrar contraseña'
                                        : 'Ocultar contraseña',
                                    onPressed: () => setState(
                                      () => _obscureConfirmation =
                                          !_obscureConfirmation,
                                    ),
                                    icon: Icon(
                                      _obscureConfirmation
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 19,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 20),
                      _AuthSubmitButton(
                        label: _isRegistering ? 'Crear cuenta' : 'Entrar',
                        loading: _isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 19),
                      Container(height: 1, color: line),
                      const SizedBox(height: 15),
                      Center(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => _setMode(!_isRegistering),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0F4A2E),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                          ),
                          child: Text(
                            _isRegistering
                                ? '¿Ya tienes cuenta? Inicia sesión'
                                : '¿No tienes cuenta? Crear cuenta',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              letterSpacing: .35,
                            ),
                          ),
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

    return ColoredBox(
      color: Colors.white,
      child: compact ? formContent : SingleChildScrollView(child: formContent),
    );
  }
}

class _LectioBrandPanel extends StatelessWidget {
  const _LectioBrandPanel({required this.isRegistering});

  final bool isRegistering;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 820;
    const accent = Color(0xFF7FC9A0);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF0F4A2E)),
          Image.network(
            'https://images.unsplash.com/photo-1507842217343-583bb7270b66?auto=format&fit=crop&w=1400&q=80',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xE00F4A2E),
                  Color(0x990F4A2E),
                  Color(0xD91A6B45),
                ],
              ),
            ),
          ),
          Positioned(
            left: compact ? -18 : -26,
            bottom: compact ? -27 : -58,
            child: IgnorePointer(
              child: Text(
                'LECTIO',
                style: GoogleFonts.instrumentSerif(
                  color: Colors.white.withValues(alpha: .075),
                  fontSize: compact ? 120 : 250,
                  height: .8,
                  letterSpacing: -10,
                ),
              ),
            ),
          ),
          Stack(
            children: [
              _FloatingSquare(
                left: compact ? .16 : .14,
                top: .22,
                size: 7,
                offset: const Offset(14, -18),
              ),
              _FloatingSquare(
                left: .78,
                top: .68,
                size: 5,
                offset: const Offset(-16, 14),
              ),
              _FloatingSquare(
                left: .27,
                top: .81,
                size: 4,
                offset: const Offset(10, -14),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 25 : 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _BrandSquare(),
                    const SizedBox(width: 11),
                    Text(
                      'LECTIO',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, .12),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text.rich(
                    TextSpan(
                      text: isRegistering ? 'Empieza tu ' : 'Tu próxima\n',
                      children: [
                        TextSpan(
                          text: isRegistering ? 'viaje' : 'lectura',
                          style: const TextStyle(
                            color: accent,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (!isRegistering)
                          const TextSpan(text: ' te está esperando.'),
                        if (isRegistering)
                          const TextSpan(text: ' como lector.'),
                      ],
                    ),
                    key: ValueKey(isRegistering),
                    style: GoogleFonts.instrumentSerif(
                      color: Colors.white,
                      fontSize: compact ? 29 : 42,
                      height: 1.08,
                      letterSpacing: -.6,
                    ),
                  ),
                ),
                if (!compact)
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: accent, blurRadius: 10)],
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        'EN LÍNEA',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white.withValues(alpha: .6),
                          fontSize: 9,
                          letterSpacing: 1.6,
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

class _FloatingSquare extends StatelessWidget {
  const _FloatingSquare({
    required this.left,
    required this.top,
    required this.size,
    required this.offset,
  });

  final double left;
  final double top;
  final double size;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: MediaQuery.sizeOf(context).width * left,
      top: MediaQuery.sizeOf(context).height * top,
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(begin: Offset.zero, end: offset),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (context, position, child) =>
            Transform.translate(offset: position, child: child),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF7FC9A0).withValues(alpha: .65),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7FC9A0).withValues(alpha: .45),
                blurRadius: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandSquare extends StatefulWidget {
  const _BrandSquare();

  @override
  State<_BrandSquare> createState() => _BrandSquareState();
}

class _BrandSquareState extends State<_BrandSquare> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedRotation(
        turns: _hovered ? .125 : 0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(color: Color(0xFF7FC9A0)),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.enabled,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
    this.trailing,
  });

  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0D2B1D);
    const muted = Color(0xFF6B8377);
    const green = Color(0xFF34A06C);
    const border = Color(0xFFD4E5D9);

    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      validator: validator,
      style: GoogleFonts.inter(color: ink, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: muted.withValues(alpha: .68),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: muted, size: 19),
        suffixIcon: trailing,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: const OutlineInputBorder(borderSide: BorderSide(color: border)),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: green, width: 1.4),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFC8464A)),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFC8464A), width: 1.4),
        ),
        errorStyle: GoogleFonts.jetBrainsMono(
          color: const Color(0xFFC8464A),
          fontSize: 9,
          letterSpacing: .1,
        ),
      ),
    );
  }
}

class _AuthSubmitButton extends StatefulWidget {
  const _AuthSubmitButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  State<_AuthSubmitButton> createState() => _AuthSubmitButtonState();
}

class _AuthSubmitButtonState extends State<_AuthSubmitButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: FilledButton(
        onPressed: widget.loading ? null : widget.onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1A6B45),
          disabledBackgroundColor: const Color(0xFF1A6B45)
              .withValues(alpha: .6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: const RoundedRectangleBorder(),
          elevation: _hovered ? 6 : 0,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: widget.loading
              ? const SizedBox(
                  key: ValueKey('auth-loading'),
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  key: ValueKey(widget.label),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedSlide(
                      offset: _hovered ? const Offset(.25, 0) : Offset.zero,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(Icons.arrow_forward, size: 16),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AuthAlert extends StatelessWidget {
  const _AuthAlert({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFFBEAEA),
          border: Border(left: BorderSide(color: Color(0xFFC8464A), width: 3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFC8464A), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: const Color(0xFF8F2A2E),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LectioSuccessOverlay extends StatelessWidget {
  const _LectioSuccessOverlay({
    required this.visible,
    required this.title,
    required this.message,
  });

  final bool visible;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 400),
          child: ColoredBox(
            color: const Color(0xF5F7FAF8),
            child: Center(
              child: AnimatedScale(
                scale: visible ? 1 : .92,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 94,
                        height: 94,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE6F3EB),
                          border: Border.all(
                            color: const Color(0xFF1A6B45),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF34A06C)
                                  .withValues(alpha: .18),
                              blurRadius: 28,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF1A6B45),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.instrumentSerif(
                          color: const Color(0xFF0D2B1D),
                          fontSize: 38,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF6B8377),
                          fontSize: 10,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

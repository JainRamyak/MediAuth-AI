import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';
import '../auth/auth_service.dart';
import '../auth/forgot_password_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// s02_login.dart  —  Premium Login Screen
// Dark gradient hero + frosted glass form sheet
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onSignUp;
  const LoginScreen({super.key, required this.onLogin, required this.onSignUp});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  final _formKey  = GlobalKey<FormState>();
  final _idCtrl   = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();

  bool _obscure     = true;
  bool _loading     = false;
  bool _showSuccess = false;
  String? _error;

  late AnimationController _heroCtl;
  late AnimationController _sheetCtl;
  late Animation<double>   _heroFade;
  late Animation<Offset>   _sheetSlide;
  late Animation<double>   _sheetFade;

  @override
  void initState() {
    super.initState();

    _heroCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _sheetCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _heroFade = CurvedAnimation(parent: _heroCtl, curve: Curves.easeOut);
    _sheetSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _sheetCtl, curve: Curves.easeOutCubic));
    _sheetFade = CurvedAnimation(parent: _sheetCtl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _heroCtl.forward();
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _sheetCtl.forward();
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await AuthService.instance.signInWithEmail(
      email: _idCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _loading = false;
        _error = result.errorMessage?.contains('Incorrect') == true
            ? 'Incorrect email or password. Please try again.'
            : result.errorMessage;
      });
      return;
    }
    setState(() { _loading = false; _showSuccess = true; });
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) widget.onLogin();
  }

  @override
  void dispose() {
    _idCtrl.dispose(); _passCtrl.dispose();
    _emailFocus.dispose(); _passFocus.dispose();
    _heroCtl.dispose(); _sheetCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(children: [

        // ── 1. Full-screen dark gradient background ────────────────────────
        const _MeshBackground(),

        // ── 2. Floating geometric elements ────────────────────────────────
        const _GeometricOverlay(),

        // ── 3. Main layout ─────────────────────────────────────────────────
        SafeArea(
          bottom: false,
          child: Column(children: [

            // Hero section — top ~40%
            Expanded(
              flex: 40,
              child: FadeTransition(
                opacity: _heroFade,
                child: Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                    // Glowing icon with double ring
                    Stack(alignment: Alignment.center, children: [
                      // Outer glow ring
                      Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: C.teal500.withValues(alpha: 0.2), width: 1.5),
                        ),
                      ),
                      // Inner ring
                      Container(
                        width: 74, height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: C.teal500.withValues(alpha: 0.4), width: 1),
                        ),
                      ),
                      // Core
                      Container(
                        width: 58, height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: C.teal500,
                          boxShadow: [
                            BoxShadow(
                              color: C.teal500.withValues(alpha: 0.45),
                              blurRadius: 24, spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.health_and_safety_rounded,
                            size: 28, color: Colors.white),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    Text('MediAuth AI',
                      style: GoogleFonts.outfit(
                        fontSize: 32, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text('Autonomous Insurance Authorization',
                      style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.white54,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Trust badge
                    _TrustBadge(),
                  ]),
                ),
              ),
            ),

            // Form sheet — bottom ~60%
            Expanded(
              flex: 60,
              child: FadeTransition(
                opacity: _sheetFade,
                child: SlideTransition(
                  position: _sheetSlide,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC).withValues(alpha: 0.97),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                          border: Border(
                            top: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1),
                          ),
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            28, 10, 28,
                            MediaQuery.of(context).viewInsets.bottom + 32,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                              // Drag handle
                              Center(
                                child: Container(
                                  width: 44, height: 4,
                                  margin: const EdgeInsets.only(bottom: 26, top: 14),
                                  decoration: BoxDecoration(
                                    color: C.surf3,
                                    borderRadius: BorderRadius.circular(2)),
                                ),
                              ),

                              Text('Welcome back',
                                style: GoogleFonts.outfit(
                                  fontSize: 28, fontWeight: FontWeight.w800,
                                  color: C.textPrimary, letterSpacing: -0.6)),
                              const SizedBox(height: 6),
                              Text('Sign in to manage your authorizations.',
                                style: GoogleFonts.inter(
                                  fontSize: 14, color: C.textSecondary, height: 1.5)),
                              const SizedBox(height: 24),

                              // Error
                              AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                child: _error != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: InfoBanner(
                                        message: _error!,
                                        bgColor: C.red50,
                                        accentColor: C.red500,
                                        textColor: C.red700,
                                        icon: Icons.error_outline_rounded,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                              ),

                              // Email
                              _AnimatedField(
                                child: TextFormField(
                                  controller: _idCtrl,
                                  focusNode: _emailFocus,
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.emailAddress,
                                  onFieldSubmitted: (_) =>
                                      FocusScope.of(context).requestFocus(_passFocus),
                                  decoration: const InputDecoration(
                                    labelText: 'Email Address',
                                    hintText: 'you@example.com',
                                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Please enter your email' : null,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Password
                              _AnimatedField(
                                child: TextFormField(
                                  controller: _passCtrl,
                                  focusNode: _passFocus,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _login(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                        size: 20, color: C.textTertiary),
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Please enter your password' : null,
                                ),
                              ),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => showForgotPasswordSheet(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
                                  child: Text('Forgot password?',
                                    style: GoogleFonts.inter(
                                      fontSize: 13, color: C.teal600,
                                      fontWeight: FontWeight.w600)),
                                ),
                              ),

                              const SizedBox(height: 4),

                              // Sign in button
                              _PressableButton(
                                label: 'Sign In',
                                loading: _loading || _showSuccess,
                                icon: Icons.arrow_forward_rounded,
                                onPressed: _login,
                              ),

                              // Success state
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                child: _showSuccess
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 14),
                                      child: _SuccessPill(
                                        email: AuthService.instance.currentUser?.email ?? ''),
                                    )
                                  : const SizedBox.shrink(),
                              ),

                              const SizedBox(height: 20),

                              // Divider
                              Row(children: [
                                Expanded(child: Divider(color: C.surf3)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('New to MediAuth?',
                                    style: GoogleFonts.inter(
                                      fontSize: 12, color: C.textTertiary)),
                                ),
                                Expanded(child: Divider(color: C.surf3)),
                              ]),

                              const SizedBox(height: 14),

                              // Sign up CTA
                              SizedBox(
                                width: double.infinity, height: 52,
                                child: OutlinedButton.icon(
                                  onPressed: widget.onSignUp,
                                  icon: const Icon(Icons.person_add_outlined, size: 18),
                                  label: Text('Create a Patient Account',
                                    style: GoogleFonts.inter(
                                      fontSize: 14, fontWeight: FontWeight.w600,
                                      color: C.textPrimary)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: C.textPrimary,
                                    side: const BorderSide(color: C.surf3, width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Mesh & Geometric Background ─────────────────────────────────────────────

class _MeshBackground extends StatelessWidget {
  const _MeshBackground();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment(-0.8, -1),
        end: Alignment(0.8, 1),
        colors: [
          Color(0xFF0B1628), // very deep navy
          Color(0xFF0D2618), // deep teal-green
          Color(0xFF0B1628), // back to navy
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    ),
  );
}

class _GeometricOverlay extends StatelessWidget {
  const _GeometricOverlay();

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.infinite,
    painter: _GeoPainter(),
  );
}

class _GeoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0A9E7A).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Concentric circles top-right
    for (int i = 1; i <= 8; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.12),
        i * 40.0,
        paint,
      );
    }

    // Dot grid
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    for (double x = spacing; x < size.width * 0.5; x += spacing) {
      for (double y = 0; y < size.height * 0.42; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }

    // Horizontal guide lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    for (double y = 0; y < size.height * 0.42; y += 56) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(_GeoPainter old) => false;
}

// ─── Trust Badge ─────────────────────────────────────────────────────────────

class _TrustBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 7, height: 7,
        decoration: const BoxDecoration(color: C.teal400, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text('HIPAA Compliant · 50,000+ Patients',
        style: GoogleFonts.inter(
          fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ─── Animated Field Wrapper ───────────────────────────────────────────────────

class _AnimatedField extends StatefulWidget {
  final Widget child;
  const _AnimatedField({required this.child});

  @override
  State<_AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<_AnimatedField>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.985).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp:   (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: widget.child,
    ),
  );
}

// ─── Pressable Primary Button ─────────────────────────────────────────────────

class _PressableButton extends StatefulWidget {
  final String label;
  final bool   loading;
  final IconData icon;
  final VoidCallback onPressed;
  const _PressableButton({
    required this.label, required this.loading,
    required this.icon,  required this.onPressed,
  });

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: GestureDetector(
      onTapDown:   (_) { _ctrl.forward(); if (!widget.loading) widget.onPressed(); },
      onTapUp:     (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: SizedBox(
        width: double.infinity, height: 54,
        child: ElevatedButton(
          onPressed: widget.loading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: C.teal500,
            disabledBackgroundColor: C.teal500.withValues(alpha: 0.6),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: widget.loading
              ? const SizedBox(key: ValueKey('l'),
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(
                  key: const ValueKey('t'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(width: 10),
                    Icon(widget.icon, size: 18, color: Colors.white),
                  ],
                ),
          ),
        ),
      ),
    ),
  );
}

// ─── Success Pill ─────────────────────────────────────────────────────────────

class _SuccessPill extends StatelessWidget {
  final String email;
  const _SuccessPill({required this.email});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: C.teal50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: C.teal500.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_rounded, size: 16, color: C.teal600),
        const SizedBox(width: 8),
        Text(
          email.isNotEmpty ? email : 'Signed in!',
          style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500, color: C.teal700)),
      ]),
    ),
  );
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';
import '../auth/auth_service.dart';
import '../auth/forgot_password_dialog.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onSignUp;
  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onSignUp,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey  = GlobalKey<FormState>();
  final _idCtrl   = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure   = true;
  bool _loading   = false;
  String? _error;
  bool _showSuccess = false;

  late AnimationController _sheetCtl;
  late Animation<Offset> _sheetAnim;

  @override
  void initState() {
    super.initState();
    _sheetCtl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
    _sheetAnim = Tween<Offset>(
      begin: const Offset(0, 0.08), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sheetCtl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _sheetCtl.forward();
    });
  }

  // ── Email / Password login ──────────────────────────────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await AuthService.instance.signInWithEmail(
      email: _idCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    if (!result.success) {
      setState(() { _loading = false; _error = result.errorMessage; });
      return;
    }
    setState(() { _loading = false; _showSuccess = true; });
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) widget.onLogin();
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────────
  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; });
    final result = await AuthService.instance.signInWithGoogle();
    if (!mounted) return;
    if (!result.success) {
      setState(() { _loading = false; _error = result.errorMessage; });
      return;
    }
    setState(() { _loading = false; _showSuccess = true; });
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) widget.onLogin();
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _passCtrl.dispose();
    _sheetCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.textPrimary,
      body: Column(children: [
        // ── Top hero 36% ──────────────────────────────────────────────────────
        Expanded(
          flex: 36,
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(
                  painter: _DotGridPainter())),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: const BoxDecoration(
                          color: C.teal500,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          size: 30, color: C.white),
                      ),
                      const SizedBox(height: 14),
                      Text('MediAuth AI',
                        style: GoogleFonts.inter(
                          fontSize: 24, fontWeight: FontWeight.w700,
                          color: C.white, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('Patient Portal',
                        style: GoogleFonts.inter(
                          fontSize: 13, color: C.ink300,
                          fontWeight: FontWeight.w400)),
                      const SizedBox(height: 16),
                      // Trust badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_rounded,
                              size: 13,
                              color: C.teal400),
                            const SizedBox(width: 6),
                            Text('HIPAA Compliant · 50K+ Patients',
                              style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w500,
                                color: C.ink300)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Bottom form 64% ───────────────────────────────────────────────────
        Expanded(
          flex: 64,
          child: SlideTransition(
            position: _sheetAnim,
            child: Container(
              decoration: const BoxDecoration(
                color: C.surf0,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          margin: const EdgeInsets.only(bottom: 24, top: 12),
                          decoration: BoxDecoration(
                            color: C.surf3,
                            borderRadius: BorderRadius.circular(2)),
                        ),
                      ),

                      Text('Welcome back',
                        style: GoogleFonts.inter(
                          fontSize: 26, fontWeight: FontWeight.w800,
                          color: C.textPrimary, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('Sign in to track your health authorizations.',
                        style: GoogleFonts.inter(
                          fontSize: 14, color: C.textSecondary, height: 1.4)),
                      const SizedBox(height: 24),

                      // Error banner
                      AnimatedSize(
                        duration: const Duration(milliseconds: 240),
                        child: _error != null
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: InfoBanner(
                                message: _error!,
                                bgColor: C.red50,
                                borderColor: C.red500,
                                textColor: C.red700,
                                icon: Icons.error_outline_rounded),
                            )
                          : const SizedBox.shrink(),
                      ),

                      // Email
                      TextFormField(
                        controller: _idCtrl,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'e.g. margaret@example.com',
                          prefixIcon: Icon(
                            Icons.email_outlined, size: 20),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your email address' : null,
                      ),
                      const SizedBox(height: 12),

                      // Password
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                              size: 20, color: C.textTertiary),
                            onPressed: () =>
                              setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                          ? 'Enter your password' : null,
                      ),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => showForgotPasswordSheet(context),
                          child: Text('Forgot password?',
                            style: GoogleFonts.inter(
                              fontSize: 13, color: C.teal600,
                              fontWeight: FontWeight.w500)),
                        ),
                      ),

                      // Sign in CTA
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: C.teal500,
                            disabledBackgroundColor: C.teal500,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _loading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: C.white))
                            : Text('Sign in',
                                style: GoogleFonts.inter(
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: C.white)),
                        ),
                      ),

                      // Success pill
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        child: _showSuccess
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: C.teal50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: C.teal500.withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                        size: 16, color: C.teal600),
                                      const SizedBox(width: 8),
                                      Text(
                                        AuthService.instance.currentUser?.email
                                          ?? 'Signed in successfully',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: C.teal700)),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 20),
                      // Divider row
                      Row(children: [
                        Expanded(child: Container(height: 0.5, color: C.surf3)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or',
                            style: GoogleFonts.inter(
                              fontSize: 12, color: C.textTertiary)),
                        ),
                        Expanded(child: Container(height: 0.5, color: C.surf3)),
                      ]),
                      const SizedBox(height: 20),

                      // Google Sign-In button
                      GestureDetector(
                        onTap: _loading ? null : _googleSignIn,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: C.surf1,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: C.surf3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('G',
                                style: GoogleFonts.inter(
                                  fontSize: 18, fontWeight: FontWeight.w800,
                                  color: const Color(0xFF4285F4))),
                              const SizedBox(width: 10),
                              Text('Continue with Google',
                                style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600,
                                  color: C.textPrimary)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // New user
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: OutlinedButton(
                          onPressed: widget.onSignUp,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: C.surf3, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('New patient? Get Started →',
                            style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: C.textPrimary)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    const spacing = 24.0;
    const radius  = 1.5;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
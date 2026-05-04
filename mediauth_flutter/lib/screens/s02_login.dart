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

class _LoginScreenState extends State<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _idCtrl   = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure     = true;
  bool _loading     = false;
  bool _rememberMe  = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; });

    final result = await AuthService.instance.signInWithEmail(
      email: _idCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    if (!result.success) {
      setState(() => _loading = false);
      showMediToast(context, result.errorMessage ?? 'Login failed', kind: ToastKind.error);
      return;
    }
    widget.onLogin();
  }

  @override
  void dispose() {
    _idCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              _buildLogo(),
              const SizedBox(height: 40),
              
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Sign in with your account',
                  style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w800,
                    color: C.textPrimary, letterSpacing: -0.5)),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('All That Fights for Every Patient Approval',
                  style: GoogleFonts.inter(
                    fontSize: 14, color: C.textSecondary, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: C.textPrimary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _idCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'you@example.com'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text('Password', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: C.textPrimary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 24, height: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Remember me?', style: GoogleFonts.inter(fontSize: 13, color: C.textSecondary)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => showForgotPasswordSheet(context),
                    child: Text('Forgot password?', style: GoogleFonts.inter(fontSize: 13, color: C.textSecondary)),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              PrimaryButton(
                onPressed: _login,
                loading: _loading,
                label: 'Sign in to MediAuth',
              ),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: GoogleFonts.inter(fontSize: 13, color: C.textSecondary)),
                  GestureDetector(
                    onTap: widget.onSignUp,
                    child: Text("Create Account", style: GoogleFonts.inter(fontSize: 13, color: C.green600, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: C.surf3)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR WITH', style: GoogleFonts.inter(fontSize: 11, color: C.textTertiary, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: Divider(color: C.surf3)),
                ],
              ),
              
              const SizedBox(height: 24),
              _SocialButton(
                label: 'Sign up with Google',
                icon: Icons.g_mobiledata_rounded,
                bgColor: Colors.white,
                textColor: C.textPrimary,
                borderColor: C.surf3,
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Sign up with iOS',
                icon: Icons.apple,
                bgColor: Colors.black,
                textColor: Colors.white,
                onPressed: () {},
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: C.primary500,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 12),
        Text('MediAuth', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: C.textPrimary)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          side: borderColor != null ? BorderSide(color: borderColor!) : BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
          ],
        ),
      ),
    );
  }
}

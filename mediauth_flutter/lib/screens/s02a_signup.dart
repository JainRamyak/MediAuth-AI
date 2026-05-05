import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';
import '../auth/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// s02a_signup.dart  —  Premium Sign Up Screen
// ─────────────────────────────────────────────────────────────────────────────

class SignUpScreen extends StatefulWidget {
  final VoidCallback onSignUpSuccess;
  final VoidCallback onSignIn;

  const SignUpScreen({
    super.key,
    required this.onSignUpSuccess,
    required this.onSignIn,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _rememberMe = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmPassCtrl.text) {
      showMediToast(context, 'Passwords do not match', kind: ToastKind.error);
      return;
    }
    
    setState(() => _loading = true);

    final result = await AuthService.instance.signUpWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.success) {
      showMediToast(context, result.errorMessage ?? 'Sign-up failed.', kind: ToastKind.error);
      return;
    }
    widget.onSignUpSuccess();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmPassCtrl.dispose();
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
              _buildLogo(),
              const SizedBox(height: 40),
              
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Create Your MediAuth\nAccount',
                  style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w800,
                    color: C.textPrimary, letterSpacing: -0.5, height: 1.2)),
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
                    Text('Full Name', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: C.textPrimary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(hintText: 'John Doe'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 20),
                    Text('Email', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: C.textPrimary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
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
                      validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 20),
                    Text('Confirm Password', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: C.textPrimary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscure,
                      decoration: const InputDecoration(hintText: '••••••••'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Confirm password' : null,
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
                  Text('Forgot password?', style: GoogleFonts.inter(fontSize: 13, color: C.textSecondary)),
                ],
              ),
              
              const SizedBox(height: 24),
              PrimaryButton(
                onPressed: _signUp,
                loading: _loading,
                label: 'Sign Up to MediAuth',
              ),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ", style: GoogleFonts.inter(fontSize: 13, color: C.textSecondary)),
                  GestureDetector(
                    onTap: widget.onSignIn,
                    child: Text("Sign In", style: GoogleFonts.inter(fontSize: 13, color: C.green600, fontWeight: FontWeight.w600)),
                  ),
                ],
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

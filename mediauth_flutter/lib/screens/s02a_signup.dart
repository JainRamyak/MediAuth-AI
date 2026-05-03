import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';
import '../auth/auth_service.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _policyCtrl = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();

  DateTime? _dob;
  String? _insurer;
  final _insurers = [
    'UnitedHealth', 'Blue Cross Blue Shield', 'Aetna Health',
    'Cigna Healthcare', 'Humana', 'Medicare', 'Other'
  ];

  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
  }

  void _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: C.teal500, onPrimary: C.white, surface: C.surf0),
        ),
        child: child!,
      ),
    );
    if (dt != null) setState(() => _dob = dt);
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      showMediToast(context, 'Please select your Date of Birth',
        kind: ToastKind.error);
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
      showMediToast(context, result.errorMessage ?? 'Sign-up failed.',
        kind: ToastKind.error);
      return;
    }

    widget.onSignUpSuccess();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _policyCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Premium Gradient Background ─────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // Deep Slate
                  Color(0xFF005F4F), // Deep Teal
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(
                    color: C.teal500, shape: BoxShape.circle),
                  child: const Icon(Icons.health_and_safety_rounded,
                    size: 22, color: C.white),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create Account',
                      style: GoogleFonts.outfit(
                        fontSize: 22, fontWeight: FontWeight.w700,
                        color: C.white, letterSpacing: -0.3)),
                    Text('MediAuth Patient Portal',
                      style: GoogleFonts.inter(
                        fontSize: 13, color: C.teal50)),
                  ],
                ),
                const Spacer(),
                // Step badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Step 1 of 1',
                    style: GoogleFonts.inter(
                      fontSize: 11, color: C.teal400,
                      fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // ── Form ──────────────────────────────────────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: C.surf0.withValues(alpha: 0.95), // minimal glass
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border(
                      top: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1),
                    ),
                  ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Personal ──────────────────────────────────────────
                      SectionLabel('About You',
                        Icons.face_retouching_natural_rounded),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Full Legal Name',
                          hintText: 'e.g. Margaret Thompson',
                          prefixIcon: Icon(Icons.person_outline, size: 20)),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // DOB picker
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                          decoration: BoxDecoration(
                            color: C.surf1,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: C.surf3, width: 0.5),
                          ),
                          child: Row(children: [
                            const Icon(Icons.calendar_today_rounded,
                              size: 20, color: C.textTertiary),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _dob == null
                                  ? 'Date of Birth'
                                  : DateFormat.yMMMd().format(_dob!),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _dob == null
                                    ? C.textTertiary : C.textPrimary),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                              size: 18, color: C.textTertiary),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Insurance ─────────────────────────────────────────
                      SectionLabel('Insurance Details',
                        Icons.verified_user_rounded),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        initialValue: _insurer,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: C.textTertiary),
                        decoration: const InputDecoration(
                          labelText: 'Insurance Provider',
                          prefixIcon: Icon(Icons.business_outlined, size: 20)),
                        items: _insurers.map((i) => DropdownMenuItem(
                          value: i,
                          child: Text(i, overflow: TextOverflow.ellipsis, maxLines: 1),
                        )).toList(),
                        onChanged: (v) => setState(() => _insurer = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _policyCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Member / Policy Number',
                          hintText: 'Check your insurance card',
                          prefixIcon: Icon(Icons.badge_outlined, size: 20)),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),

                        // ── Account ───────────────────────────────────────────
                        SectionLabel('Secure Your Account',
                          Icons.lock_person_rounded),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'e.g. margaret@example.com',
                            prefixIcon: Icon(Icons.email_outlined, size: 20)),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _signUp(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Minimum 8 characters',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                                color: C.textTertiary, size: 20),
                              onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 32),

                      PrimaryButton(
                        label: 'Create Account',
                        onPressed: _loading ? null : _signUp,
                        loading: _loading,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity, height: 52,
                        child: OutlinedButton(
                          onPressed: widget.onSignIn,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: C.surf3, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Already have an account? Sign in',
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
      ),
          ],
        ),
      ),
        ],
      ),
    );
  }
}
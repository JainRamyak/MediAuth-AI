import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _policyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  DateTime? _dob;
  String?   _insurer;
  final _insurers = [
    'UnitedHealth', 'Blue Cross Blue Shield', 'Aetna Health',
    'Cigna Healthcare', 'Humana', 'Medicare', 'Medicaid', 'Other',
  ];

  bool _obscure = true;
  bool _loading = false;

  late AnimationController _sheetCtl;
  late Animation<Offset>   _sheetSlide;

  @override
  void initState() {
    super.initState();
    _sheetCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _sheetSlide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _sheetCtl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _sheetCtl.forward();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _policyCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose();
    _sheetCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: C.teal500, onPrimary: Colors.white, surface: C.surf0),
        ),
        child: child!,
      ),
    );
    if (dt != null) setState(() => _dob = dt);
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      showMediToast(context, 'Please select your Date of Birth', kind: ToastKind.error);
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
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(children: [

        // Dark gradient — same as login
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.8, -1),
              end: Alignment(0.8, 1),
              colors: [
                Color(0xFF0B1628),
                Color(0xFF0D2618),
                Color(0xFF0B1628),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),

        SafeArea(
          bottom: false,
          child: Column(children: [

            // ── Top header strip ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(color: C.teal500, shape: BoxShape.circle),
                  child: const Icon(Icons.health_and_safety_rounded,
                      size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Create Account',
                    style: GoogleFonts.outfit(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: Colors.white, letterSpacing: -0.3)),
                  Text('MediAuth Patient Portal',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
                ]),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onSignIn,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Text('Sign In',
                      style: GoogleFonts.inter(
                        fontSize: 12, color: C.teal400, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),

            // ── Scrollable form sheet ───────────────────────────────
            Expanded(
              child: SlideTransition(
                position: _sheetSlide,
                child: Container(
                  decoration: const BoxDecoration(
                    color: C.surf0,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border(
                      top: BorderSide(color: Color(0x1A0A9E7A), width: 1),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                        24, 24, 24,
                        MediaQuery.of(context).viewInsets.bottom + 40),
                    child: Form(
                      key: _formKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        // Drag handle
                        Center(
                          child: Container(
                            width: 40, height: 4,
                            margin: const EdgeInsets.only(bottom: 22),
                            decoration: BoxDecoration(
                              color: C.surf3,
                              borderRadius: BorderRadius.circular(2)),
                          ),
                        ),

                        // ── Section: Personal ─────────────────────────
                        _SectionHeader(icon: Icons.person_outline_rounded, label: 'About You'),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Full Legal Name',
                            hintText: 'e.g. Margaret Thompson',
                            prefixIcon: Icon(Icons.person_outline, size: 20)),
                          validator: (v) => v!.isEmpty ? 'Full name is required' : null,
                        ),
                        const SizedBox(height: 12),

                        // DOB picker
                        _PickerTile(
                          icon: Icons.calendar_today_rounded,
                          label: _dob == null
                              ? 'Date of Birth'
                              : DateFormat.yMMMd().format(_dob!),
                          filled: _dob != null,
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 24),

                        // ── Section: Insurance ────────────────────────
                        _SectionHeader(icon: Icons.verified_user_rounded, label: 'Insurance Details'),
                        const SizedBox(height: 14),

                        // Insurer dropdown
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
                            child: Text(i, overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (v) => setState(() => _insurer = v),
                          validator: (v) => v == null ? 'Please select your insurer' : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _policyCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Member / Policy Number',
                            hintText: 'Check your insurance card',
                            prefixIcon: Icon(Icons.badge_outlined, size: 20)),
                          validator: (v) => v!.isEmpty ? 'Policy number is required' : null,
                        ),
                        const SizedBox(height: 24),

                        // ── Section: Account ──────────────────────────
                        _SectionHeader(icon: Icons.lock_person_rounded, label: 'Secure Your Account'),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'you@example.com',
                            prefixIcon: Icon(Icons.email_outlined, size: 20)),
                          validator: (v) => v!.isEmpty ? 'Email is required' : null,
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
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                                color: C.textTertiary, size: 20),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => v!.length < 6 ? 'Minimum 6 characters' : null,
                        ),
                        const SizedBox(height: 28),

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
                            child: Text('Already have an account? Sign In',
                              style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: C.textPrimary)),
                          ),
                        ),
                      ]),
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

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 30, height: 30,
      decoration: BoxDecoration(color: C.teal50, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: C.teal500),
    ),
    const SizedBox(width: 10),
    Text(label,
      style: GoogleFonts.outfit(
        fontSize: 15, fontWeight: FontWeight.w700,
        color: C.textPrimary, letterSpacing: -0.2)),
    const SizedBox(width: 10),
    Expanded(child: Container(height: 0.5, color: C.surf3)),
  ]);
}

// ─── Picker Tile ─────────────────────────────────────────────────────────────

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     filled;
  final VoidCallback onTap;
  const _PickerTile({
    required this.icon, required this.label,
    required this.filled, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: C.surf2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.surf3, width: 0.5),
      ),
      child: Row(children: [
        Icon(icon, size: 20, color: C.textTertiary),
        const SizedBox(width: 14),
        Expanded(child: Text(label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: filled ? C.textPrimary : C.textTertiary))),
        const Icon(Icons.chevron_right_rounded, size: 18, color: C.textTertiary),
      ]),
    ),
  );
}
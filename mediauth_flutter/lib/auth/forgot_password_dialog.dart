/// ---------------------------------------------------------------------------
/// forgot_password_dialog.dart
/// ---------------------------------------------------------------------------
/// Bottom-sheet dialog for password reset emails via Supabase.
/// Call: showForgotPasswordSheet(context)
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import 'auth_service.dart';

Future<void> showForgotPasswordSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ForgotPasswordSheet(),
  );
}

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet();

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _emailCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool   _loading  = false;
  String? _error;
  bool   _sent     = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    // Mocking network delay since custom FastAPI does not support password recovery right now.
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() { _loading = false; _sent = true; });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 32 + bottom),
      decoration: const BoxDecoration(
        color: C.surf0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20, top: 12),
              decoration: BoxDecoration(
                color: C.surf3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          if (_sent) ...[
            // ── Success state ─────────────────────────────────────────────
            const Icon(Icons.mark_email_read_outlined,
                size: 48, color: C.teal500),
            const SizedBox(height: 16),
            Text('Check your inbox',
              style: GoogleFonts.inter(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: C.textPrimary, letterSpacing: -0.4)),
            const SizedBox(height: 8),
            Text(
              'We sent a password reset link to ${_emailCtrl.text.trim()}.\n'
              'Check your spam folder if it doesn\'t appear.',
              style: GoogleFonts.inter(
                fontSize: 14, color: C.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.teal500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Done',
                  style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: C.white)),
              ),
            ),
          ] else ...[
            // ── Form state ────────────────────────────────────────────────
            Text('Reset password',
              style: GoogleFonts.inter(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: C.textPrimary, letterSpacing: -0.4)),
            const SizedBox(height: 6),
            Text('Enter your email and we\'ll send you a reset link.',
              style: GoogleFonts.inter(
                fontSize: 14, color: C.textSecondary, height: 1.4)),
            const SizedBox(height: 20),

            // Error banner
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              child: _error != null
                ? Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: C.red50,
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(
                        left: BorderSide(color: C.red500, width: 3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                        size: 16, color: C.red500),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                          style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: C.red700)),
                      ),
                    ]),
                  )
                : const SizedBox.shrink(),
            ),

            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'e.g. margaret@example.com',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter your email address';
                  }
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
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
                  : Text('Send Reset Link',
                      style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: C.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

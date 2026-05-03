import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  final VoidCallback onDone;
  const ResetPasswordScreen({super.key, required this.onDone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  Future<void> _submit() async {
    final pw = _passwordController.text.trim();
    if (pw.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pw),
      );
      if (mounted) {
        showMediToast(context, 'Password updated successfully.', kind: ToastKind.success);
        widget.onDone();
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        backgroundColor: C.surf0,
        surfaceTintColor: Colors.transparent,
        leading: const SizedBox.shrink(),
        title: Text('Reset Password',
          style: GoogleFonts.outfit(
            fontSize: 20, fontWeight: FontWeight.w700, color: C.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: C.surf0,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: C.surf3, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Create a new password',
                    style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700, color: C.textPrimary)),
                  const SizedBox(height: 6),
                  Text('Your new password must be at least 6 characters long.',
                    style: GoogleFonts.inter(fontSize: 13, color: C.textSecondary)),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: C.textTertiary),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    InfoBanner(
                      message: _error!,
                      icon: Icons.error_outline_rounded,
                      bgColor: C.red50,
                      accentColor: C.red500,
                      textColor: C.red700,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            PrimaryButton(
              label: 'Update Password',
              icon: Icons.check_circle_outline_rounded,
              loading: _loading,
              onPressed: _loading ? null : _submit,
            ),
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: _loading ? null : widget.onDone,
              style: TextButton.styleFrom(foregroundColor: C.textSecondary),
              child: Text('Cancel and return to login',
                style: GoogleFonts.inter(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
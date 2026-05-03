import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';

// ── Profile Screen ────────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  String get _name {
    final m = Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    return (m['full_name'] ?? m['name'] ?? '').toString();
  }

  String get _email =>
      Supabase.instance.client.auth.currentUser?.email ?? '';

  String get _initials {
    final parts = _name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        backgroundColor: C.surf0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text('Profile',
          style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w700, color: C.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + name card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: C.surf0,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: C.surf3, width: 0.5),
              ),
              child: Column(children: [
                Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: C.teal500),
                  child: Center(
                    child: Text(_initials,
                      style: GoogleFonts.outfit(
                        fontSize: 28, fontWeight: FontWeight.w700,
                        color: Colors.white))),
                ),
                const SizedBox(height: 14),
                if (_name.isNotEmpty)
                  Text(_name,
                    style: GoogleFonts.outfit(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: C.textPrimary, letterSpacing: -0.2)),
                const SizedBox(height: 4),
                Text(_email,
                  style: GoogleFonts.inter(fontSize: 14, color: C.textSecondary)),
              ]),
            ),
            const SizedBox(height: 24),

            // Settings section
            Text('Account',
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: C.textTertiary, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              label: 'Edit Profile',
              onTap: () => showMediToast(context, 'Coming soon'),
            ),
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              onTap: () => showMediToast(context, 'Coming soon'),
            ),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () => showMediToast(context, 'Coming soon'),
            ),
            const SizedBox(height: 20),

            Text('App',
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: C.textTertiary, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              label: 'About MediAuth AI',
              subtitle: 'v1.0.0 — Hackathon Build',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.policy_outlined,
              label: 'Privacy Policy',
              onTap: () {},
            ),
            const SizedBox(height: 32),

            // Sign out
            OutlinedButton.icon(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                onLogout();
              },
              icon: const Icon(Icons.logout_rounded, size: 18, color: C.red500),
              label: Text('Sign Out',
                style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600, color: C.red500)),
              style: OutlinedButton.styleFrom(
                foregroundColor: C.red500,
                side: const BorderSide(color: C.red500, width: 0.8),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon, required this.label,
    required this.onTap, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: C.surf0,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.surf3, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: C.textSecondary, size: 22),
        title: Text(label,
          style: GoogleFonts.inter(fontSize: 14, color: C.textPrimary)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: GoogleFonts.inter(fontSize: 12, color: C.textTertiary))
            : null,
        trailing: const Icon(Icons.chevron_right_rounded,
            color: C.textTertiary, size: 20),
        onTap: onTap,
      ),
    );
  }
}

// ── Reset Password Screen ─────────────────────────────────────────────────────

class ResetPasswordScreen extends StatefulWidget {
  final VoidCallback onDone;
  const ResetPasswordScreen({super.key, required this.onDone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _pwdCtrl   = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  bool get _valid =>
      _pwdCtrl.text.length >= 8 &&
      _pwdCtrl.text == _confirmCtrl.text;

  Future<void> _update() async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _pwdCtrl.text.trim()));
      if (mounted) showMediToast(context, 'Password updated');
      widget.onDone();
    } catch (e) {
      if (mounted) {
        showMediToast(context, 'Failed: ${e.toString()}', kind: ToastKind.error);
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() { _pwdCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        backgroundColor: C.surf0,
        surfaceTintColor: Colors.transparent,
        title: Text('Set New Password',
          style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700, color: C.textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose a new password for your MediAuth account.',
              style: GoogleFonts.inter(fontSize: 14, color: C.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _pwdCtrl,
              obscureText: _obscure,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18, color: C.textTertiary),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline_rounded, size: 18)),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Update Password',
              loading: _loading,
              onPressed: _valid ? _update : null,
            ),
          ],
        ),
      ),
    );
  }
}

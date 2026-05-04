import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';
import '../auth/auth_service.dart';
import '../api/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// s00_profile.dart  —  Profile Screen
// Navy hero card + grouped settings + premium sign-out
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String get _name  => (AuthService.instance.currentUser?.fullName ?? '').toString();
  String get _email => AuthService.instance.currentUser?.email ?? '';

  String get _initials {
    final parts = _name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  int _totalRequests = 0;
  int _approved = 0;
  bool _isLoading = true;
  String _successRate = '—';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    List<dynamic> items = [];
    try {
      items = await ApiService.fetchHistory(limit: 50);
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getStringList('auth_history') ?? [];
        items = raw.map((e) => jsonDecode(e)).toList();
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _totalRequests = items.length;
      _approved = items.where((item) {
        final status = (item['workflow_status'] ?? item['status'] ?? '').toString().toLowerCase();
        return status == 'approved';
      }).length;
      if (_totalRequests > 0) {
        final rate = (_approved / _totalRequests * 100).toStringAsFixed(0);
        _successRate = '$rate%';
      } else {
        _successRate = '—';
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: C.surf1,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Navy hero header ──────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [C.navy900, C.navy800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 28),
            child: Column(children: [

              // Avatar + name
              Stack(alignment: Alignment.center, children: [
                // Subtle ring
                Container(
                  width: 92, height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: C.teal500.withValues(alpha: 0.3), width: 2),
                  ),
                ),
                FloatingAnimation(
                  child: Container(
                    width: 78, height: 78,
                    decoration: const BoxDecoration(color: C.teal500, shape: BoxShape.circle),
                    child: Center(child: Text(_initials,
                      style: GoogleFonts.outfit(
                        fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
                ),
              ]),

              const SizedBox(height: 16),
              if (_name.isNotEmpty)
                Text(_name,
                  style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: -0.3)),
              const SizedBox(height: 4),
              Text(_email,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white54)),
              const SizedBox(height: 16),

              // HIPAA badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.verified_user_rounded, size: 13, color: C.teal400),
                  const SizedBox(width: 7),
                  Text('HIPAA Compliant',
                    style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                ]),
              ),
            ]),
          ),

          // ── Stats row ────────────────────────────────────────────────
          Container(
            color: C.surf0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(children: [
              _isLoading ? const SkeletonShimmer(width: 80, height: 44, borderRadius: 8) : _StatPill(label: 'Total Requests',  value: '$_totalRequests'),
              _Divider(),
              _isLoading ? const SkeletonShimmer(width: 80, height: 44, borderRadius: 8) : _StatPill(label: 'Approved',  value: '$_approved'),
              _Divider(),
              _isLoading ? const SkeletonShimmer(width: 80, height: 44, borderRadius: 8) : _StatPill(label: 'Success Rate', value: _successRate),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Account section ───────────────────────────────────────────
          _SectionTitle('Account'),
          _SettingsGroup(tiles: [
            _Tile(
              icon: Icons.person_outline_rounded,
              label: 'Edit Profile',
              onTap: () => showMediToast(context, 'Coming soon'),
            ),
            _Tile(
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              onTap: () => showMediToast(context, 'Coming soon'),
            ),
            _Tile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () => showMediToast(context, 'Coming soon'),
            ),
          ]),

          const SizedBox(height: 16),

          // ── App section ───────────────────────────────────────────────
          _SectionTitle('About'),
          _SettingsGroup(tiles: [
            _Tile(
              icon: Icons.info_outline_rounded,
              label: 'About MediAuth AI',
              subtitle: 'v1.0.0 · Hackathon Build',
              onTap: () {},
            ),
            _Tile(
              icon: Icons.policy_outlined,
              label: 'Privacy Policy',
              onTap: () {},
            ),
            _Tile(
              icon: Icons.help_outline_rounded,
              label: 'Support',
              onTap: () => showMediToast(context, 'Coming soon'),
            ),
          ]),

          const SizedBox(height: 28),

          // ── Sign out ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity, height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await AuthService.instance.signOut();
                  widget.onLogout();
                },
                icon: const Icon(Icons.logout_rounded, size: 18, color: C.red500),
                label: Text('Sign Out',
                  style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600, color: C.red500)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.red500,
                  side: const BorderSide(color: C.red500, width: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 36),
        ]),
      ),
    );
  }
}

// ─── Stat pill (in the top stats row) ────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value,
        style: GoogleFonts.outfit(
          fontSize: 22, fontWeight: FontWeight.w800,
          color: C.textPrimary, letterSpacing: -0.5)),
      const SizedBox(height: 3),
      Text(label,
        style: GoogleFonts.inter(fontSize: 11, color: C.textTertiary),
        textAlign: TextAlign.center),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 0.5, height: 32, color: C.surf3);
}

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Text(label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: C.textTertiary, letterSpacing: 0.8)),
  );
}

// ─── Settings group ───────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final List<_Tile> tiles;
  const _SettingsGroup({required this.tiles});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: C.surf0,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: C.surf3, width: 0.5),
    ),
    child: Column(children: List.generate(tiles.length, (i) {
      final tile = tiles[i];
      return Column(children: [
        tile,
        if (i < tiles.length - 1)
          Padding(
            padding: const EdgeInsets.only(left: 54),
            child: Divider(color: C.surf3, height: 0.5, thickness: 0.5),
          ),
      ]);
    })),
  );
}

// ─── Settings tile ────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String?  subtitle;
  final VoidCallback onTap;

  const _Tile({required this.icon, required this.label, required this.onTap, this.subtitle});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      splashColor: C.teal50,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: C.surf1,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: C.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w500, color: C.textPrimary)),
            if (subtitle != null) ...[ const SizedBox(height: 2),
              Text(subtitle!,
                style: GoogleFonts.inter(fontSize: 12, color: C.textTertiary)),
            ],
          ])),
          const Icon(Icons.chevron_right_rounded, size: 18, color: C.textTertiary),
        ]),
      ),
    ),
  );
}

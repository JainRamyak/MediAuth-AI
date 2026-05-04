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

          // ── Primary blue hero header ──────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [C.primary600, C.primary500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, topPad + 24, 20, 32),
            child: Column(children: [

              // Avatar + name
              Stack(alignment: Alignment.center, children: [
                // Subtle ring
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 3),
                  ),
                ),
                FloatingAnimation(
                  child: Container(
                    width: 80, height: 80,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Center(child: Text(_initials,
                      style: GoogleFonts.inter(
                        fontSize: 28, fontWeight: FontWeight.w800, color: C.primary600))),
                  ),
                ),
              ]),

              const SizedBox(height: 20),
              if (_name.isNotEmpty)
                Text(_name,
                  style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text(_email,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),

              // HIPAA badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.verified_user_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('HIPAA Compliant',
                    style: GoogleFonts.inter(
                      fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),

          // ── Stats row ────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(children: [
              _isLoading ? const SkeletonShimmer(width: 80, height: 44, borderRadius: 8) : _StatPill(label: 'Total Requests',  value: '$_totalRequests'),
              _Divider(),
              _isLoading ? const SkeletonShimmer(width: 80, height: 44, borderRadius: 8) : _StatPill(label: 'Approved',  value: '$_approved'),
              _Divider(),
              _isLoading ? const SkeletonShimmer(width: 80, height: 44, borderRadius: 8) : _StatPill(label: 'Success Rate', value: _successRate),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Account section ───────────────────────────────────────────
          _SectionTitle('Account settings'),
          _SettingsGroup(tiles: [
            _Tile(
              icon: Icons.person_outline_rounded,
              label: 'Edit Profile',
              onTap: () => showMediToast(context, 'Feature available in next update'),
            ),
            _Tile(
              icon: Icons.lock_outline_rounded,
              label: 'Security & Privacy',
              onTap: () => showMediToast(context, 'Feature available in next update'),
            ),
            _Tile(
              icon: Icons.notifications_outlined,
              label: 'Push Notifications',
              onTap: () => showMediToast(context, 'Feature available in next update'),
            ),
          ]),

          const SizedBox(height: 24),

          // ── App section ───────────────────────────────────────────────
          _SectionTitle('About'),
          _SettingsGroup(tiles: [
            _Tile(
              icon: Icons.info_outline_rounded,
              label: 'About MediAuth AI',
              subtitle: 'v1.1.0 · Premium Build',
              onTap: () {},
            ),
            _Tile(
              icon: Icons.policy_outlined,
              label: 'Privacy Policy',
              onTap: () {},
            ),
            _Tile(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () => showMediToast(context, 'Connecting to support...'),
            ),
          ]),

          const SizedBox(height: 32),

          // ── Sign out ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity, height: 56,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await AuthService.instance.signOut();
                  widget.onLogout();
                },
                icon: const Icon(Icons.logout_rounded, size: 18, color: C.red500),
                label: Text('Sign Out',
                  style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700, color: C.red500)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.red500,
                  side: const BorderSide(color: C.red500, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 100),
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
        style: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w800,
          color: C.primary600, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text(label,
        style: GoogleFonts.inter(fontSize: 12, color: C.textTertiary, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1.0, height: 32, color: C.surf3.withValues(alpha: 0.5));
}

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Text(label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w800,
        color: C.primary600, letterSpacing: 1.2)),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: C.surf3.withValues(alpha: 0.5), width: 1.0),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
      ],
    ),
    child: Column(children: List.generate(tiles.length, (i) {
      final tile = tiles[i];
      return Column(children: [
        tile,
        if (i < tiles.length - 1)
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Divider(color: C.surf3.withValues(alpha: 0.5), height: 1.0, thickness: 1.0),
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
      borderRadius: BorderRadius.circular(24),
      splashColor: C.primary100.withValues(alpha: 0.5),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: C.primary100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: C.primary600),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
              style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700, color: C.textPrimary)),
            if (subtitle != null) ...[ const SizedBox(height: 3),
              Text(subtitle!,
                style: GoogleFonts.inter(fontSize: 13, color: C.textTertiary, fontWeight: FontWeight.w500)),
            ],
          ])),
          const Icon(Icons.chevron_right_rounded, size: 20, color: C.textTertiary),
        ]),
      ),
    ),
  );
}


// ─────────────────────────────────────────────────────────────────────────────
// dashboard_screen.dart  –  Layout fixes
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';
import '../api/api_service.dart';
import '../auth/auth_service.dart';

TextStyle _inter(double size, FontWeight w, Color color, {double ls = 0, double h = 1}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: w, color: color, letterSpacing: ls, height: h);

TextStyle _outfit(double size, FontWeight w, Color color, {double ls = 0}) =>
    GoogleFonts.outfit(fontSize: size, fontWeight: w, color: color, letterSpacing: ls);

// ─── MODEL ────────────────────────────────────────────────────────────────────

class AuthRequest {
  final String id;
  final String treatment;
  final String insurer;
  final String policyNumber;
  final String status;
  final DateTime date;
  final Map<String, dynamic> raw;

  const AuthRequest({
    required this.id,
    required this.treatment,
    required this.insurer,
    required this.policyNumber,
    required this.status,
    required this.date,
    required this.raw,
  });

  factory AuthRequest.fromMap(Map<String, dynamic> m) => AuthRequest(
    id:           m['auth_request_id'] ?? m['id'] ?? '',
    treatment:    m['requested_treatment'] ?? m['treatment'] ?? 'Treatment',
    insurer:      m['insurer'] ?? 'Insurer',
    policyNumber: m['policy_number'] ?? '',
    status:       (m['workflow_status'] ?? m['status'] ?? 'pending').toString().toLowerCase(),
    date:         DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
    raw:          m,
  );
}

// ─── DASHBOARD ───────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNewRequest;
  final void Function(Map<String, dynamic>) onRequestTap;
  final VoidCallback onProfileTap;

  const DashboardScreen({
    super.key,
    required this.onNewRequest,
    required this.onRequestTap,
    required this.onProfileTap,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  List<AuthRequest> _all = [];
  String _filter = 'All';
  bool _loading = true;
  bool _fromCache = false;
  bool _backendReachable = true;

  static const _filters = ['All', 'Approved', 'Pending', 'Denied', 'Appealing'];

  late AnimationController _listCtrl;

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _load();
  }

  @override
  void dispose() { _listCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _fromCache = false; _backendReachable = true; });
    try {
      final items = await ApiService.fetchHistory(limit: 50);
      final reqs = items.map((m) => AuthRequest.fromMap(_normalise(m))).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() { _all = reqs; _loading = false; });
      _listCtrl.forward(from: 0);
    } on ApiException catch (e) {
      _backendReachable = e.statusCode != null; // null = network timeout
      await _loadCache();
    } catch (_) {
      _backendReachable = false;
      await _loadCache();
    }
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('auth_history') ?? [];
      final items = raw
          .map((s) { try { return AuthRequest.fromMap(jsonDecode(s)); } catch (_) { return null; } })
          .whereType<AuthRequest>().toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() { _all = items; _loading = false; _fromCache = true; });
      _listCtrl.forward(from: 0);
    } catch (_) {
      if (mounted) setState(() { _all = []; _loading = false; _fromCache = true; });
    }
  }

  Map<String, dynamic> _normalise(Map<String, dynamic> r) => {
    'auth_request_id': r['auth_request_id'],
    'workflow_status': r['workflow_status'],
    'appeal_level': r['appeal_level'],
    'justification_letter': r['justification_letter'],
    'denial_reason': r['denial_reason'],
    'created_at': r['created_at'],
    'insurer': r['insurer'] ?? '',
    'policy_number': r['policy_number'] ?? '',
    'requested_treatment': _treatmentLabel(r),
  };

  String _treatmentLabel(Map<String, dynamic> r) {
    final p = (r['patient_name'] ?? '').toString();
    return p.isNotEmpty ? 'Authorization — $p' : 'Authorization (${r['workflow_status'] ?? 'unknown'})';
  }

  List<AuthRequest> get _filtered => _filter == 'All'
      ? _all : _all.where((r) => r.status == _filter.toLowerCase()).toList();

  int _count(String status) => status == 'Total'
      ? _all.length : _all.where((r) => r.status == status.toLowerCase()).length;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _userName {
    final name = (AuthService.instance.currentUser?.fullName ?? '').trim();
    if (name.isNotEmpty) return name.split(' ').first;
    final email = AuthService.instance.currentUser?.email ?? '';
    return email.isNotEmpty ? email.split('@').first : 'there';
  }

  String get _initials {
    final name = (AuthService.instance.currentUser?.fullName ?? '').trim();
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final hasPending = _all.any((r) => r.status == 'pending');

    return Scaffold(
      backgroundColor: C.surf1,
      body: RefreshIndicator(
        onRefresh: _load,
        color: C.teal500,
        displacement: 80,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [

            // ── HERO APP BAR with "New Request" inline ────────────────────
            SliverAppBar(
              expandedHeight: 148,
              collapsedHeight: 64,
              pinned: true,
              elevation: 0,
              backgroundColor: C.navy800,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              flexibleSpace: _HeroAppBar(
                top: MediaQuery.of(context).padding.top,
                greeting: _greeting,
                userName: _userName,
                initials: _initials,
                onProfileTap: widget.onProfileTap,
                onNewRequest: widget.onNewRequest,  // ← passed in here
              ),
            ),

            // ── OFFLINE BANNER ────────────────────────────────────────────


            // ── STATS 2×2 GRID + FILTERS ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasPending) ...[
                      _PendingBanner(onTap: widget.onNewRequest),
                      const SizedBox(height: 16),
                    ],

                    // ── 2×2 stat grid (FIX: was 4-in-a-row) ──────────────
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.1,    // wider than tall
                      children: [
                        _StatCard('Total',    _count('Total'),    C.navy700,  Icons.folder_copy_outlined),
                        _StatCard('Approved', _count('Approved'), C.green500, Icons.check_circle_outline_rounded),
                        _StatCard('Pending',  _count('Pending'),  C.amber500, Icons.hourglass_top_rounded),
                        _StatCard('Denied',   _count('Denied'),   C.red500,   Icons.cancel_outlined),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Section header
                    Row(children: [
                      Text('Requests',
                        style: _outfit(19, FontWeight.w700, C.textPrimary, ls: -0.4)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {},
                        child: Text('See all →',
                          style: _inter(13, FontWeight.w600, C.teal600)),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // Filter pills
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 7),
                        itemBuilder: (_, i) {
                          final f = _filters[i];
                          final active = _filter == f;
                          return GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: active ? C.teal500 : C.surf0,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: active ? C.teal500 : C.surf3, width: 0.5),
                              ),
                              child: Text(f,
                                style: _inter(12, FontWeight.w600,
                                  active ? Colors.white : C.textSecondary)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // ── CONTENT ───────────────────────────────────────────────────
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: _SkeletonList()),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(fromCache: _fromCache, onNewRequest: widget.onNewRequest),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final r = filtered[i];
                      return FadeSlide(
                        delay: Duration(milliseconds: 40 * i),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RequestCard(request: r, onTap: () => widget.onRequestTap(r.raw)),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── HERO APP BAR  (now includes compact "New Request" button) ────────────────

class _HeroAppBar extends StatelessWidget {
  final double top;
  final String greeting, userName, initials;
  final VoidCallback onProfileTap;
  final VoidCallback onNewRequest;   // ← NEW

  const _HeroAppBar({
    required this.top,
    required this.greeting,
    required this.userName,
    required this.initials,
    required this.onProfileTap,
    required this.onNewRequest,
  });

  @override
  Widget build(BuildContext context) => FlexibleSpaceBar(
    background: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [C.navy900, C.navy800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Greeting row
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('$greeting, ', style: _inter(18, FontWeight.w400, Colors.white70)),
                  Text('$userName 👋',
                    style: _outfit(18, FontWeight.w700, Colors.white)),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: const BoxDecoration(color: C.teal400, shape: BoxShape.circle),
                  ),
                  Text('MediAuth AI', style: _inter(12, FontWeight.w500, Colors.white38)),
                ]),
              ],
            )),
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: C.teal500,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                ),
                child: Center(
                  child: Text(initials, style: _inter(15, FontWeight.w700, Colors.white))),
              ),
            ),
          ]),

          const SizedBox(height: 14),

          // ── Bottom Row: Security Badge & Action ────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: C.teal800.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: C.teal500.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded, size: 12, color: C.teal400),
                    const SizedBox(width: 4),
                    Text('HIPAA Compliant', style: _inter(11, FontWeight.w600, C.teal100)),
                  ],
                ),
              ),

              // Much smaller than the old full-width FAB — sits neatly in the bar
              GestureDetector(
                onTap: onNewRequest,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: C.teal500,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15), width: 0.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text('New Request',
                      style: _inter(13, FontWeight.w700, Colors.white)),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ─── PENDING BANNER ───────────────────────────────────────────────────────────

class _PendingBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _PendingBanner({required this.onTap});
  @override State<_PendingBanner> createState() => _PendingBannerState();
}

class _PendingBannerState extends State<_PendingBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.35, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    child: AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: C.amber50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: C.amber500.withValues(alpha: _pulse.value), width: 1),
        ),
        child: child,
      ),
      child: Row(children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Container(
            width: 9, height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: C.amber500.withValues(alpha: _pulse.value),
              boxShadow: [
                BoxShadow(
                  color: C.amber500.withValues(alpha: _pulse.value * 0.4),
                  blurRadius: 6)]),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Processing', style: _inter(13, FontWeight.w700, C.amber700)),
          const SizedBox(height: 1),
          Text('AI agents are working · tap to watch live',
            style: _inter(12, FontWeight.w400, C.amber600)),
        ])),
        Icon(Icons.arrow_forward_ios_rounded, size: 13, color: C.amber500),
      ]),
    ),
  );
}

// ─── STAT CARD  (2×2 grid version) ───────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color accent;
  final IconData icon;

  const _StatCard(this.label, this.count, this.accent, this.icon);

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Container(
      decoration: BoxDecoration(
        color: C.surf0,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.surf3.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent stripe
          Container(height: 3, color: accent),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Big number
                  Text('$count',
                    style: _outfit(28, FontWeight.w800, C.textPrimary, ls: -1)),
                  const Spacer(),
                  // Icon badge top-right
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 16, color: accent),
                  ),
                ],
              ),
            ),
          ),
          // Label at the bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(label,
              style: _inter(11, FontWeight.w600, C.textTertiary, ls: 0.1)),
          ),
        ],
      ),
    ),
  );
}

// ─── REQUEST CARD ─────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final AuthRequest request;
  final VoidCallback onTap;
  const _RequestCard({required this.request, required this.onTap});

  (Color, Color, Color, IconData) get _meta => switch (request.status) {
    'approved'  => (C.green50,  C.green500,  C.green700,  Icons.check_circle_outline_rounded),
    'denied'    => (C.red50,    C.red500,    C.red700,    Icons.cancel_outlined),
    'appealing' => (C.violet50, C.violet500, C.violet700, Icons.gavel_rounded),
    'submitted' => (C.blue50,   C.blue500,   C.blue700,   Icons.send_rounded),
    _           => (C.amber50,  C.amber500,  C.amber700,  Icons.hourglass_top_rounded),
  };

  AuthStatus get _pill => switch (request.status) {
    'approved'  => AuthStatus.approved,
    'denied'    => AuthStatus.denied,
    'appealing' => AuthStatus.appealing,
    'submitted' => AuthStatus.submitted,
    _           => AuthStatus.pending,
  };

  String get _dateLabel {
    final now = DateTime.now();
    final diff = now.difference(request.date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7)  return '$diff days ago';
    return '${request.date.day}/${request.date.month}/${request.date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final (iconBg, accent, fg, icon) = _meta;
    return Material(
      color: C.surf0,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: accent.withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.surf3.withValues(alpha: 0.5), width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(children: [
              Positioned(left: 0, top: 0, bottom: 0,
                child: Container(width: 3, color: accent)),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                    child: Icon(icon, color: fg, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.treatment,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: _inter(14, FontWeight.w600, C.textPrimary)),
                      const SizedBox(height: 3),
                      Text(
                        [request.insurer, request.policyNumber]
                            .where((s) => s.isNotEmpty).join(' · '),
                        style: _inter(12, FontWeight.w400, C.textSecondary)),
                      const SizedBox(height: 8),
                      Row(children: [
                        StatusPill(_pill),
                        const Spacer(),
                        Text(_dateLabel, style: _inter(11, FontWeight.w400, C.textTertiary)),
                      ]),
                    ],
                  )),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, color: C.textTertiary, size: 17),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── EMPTY STATE ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool fromCache;
  final VoidCallback onNewRequest;
  const _EmptyState({required this.fromCache, required this.onNewRequest});

  @override
  Widget build(BuildContext context) => fromCache
      ? _OfflineEmpty()
      : _WelcomeEmpty(onNewRequest: onNewRequest);
}

class _OfflineEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 76, height: 76,
          decoration: const BoxDecoration(color: C.teal50, shape: BoxShape.circle),
          child: const Icon(Icons.history_rounded, size: 36, color: C.teal500),
        ),
        const SizedBox(height: 18),
        Text('No Local History Yet', style: _inter(18, FontWeight.w700, C.textPrimary)),
        const SizedBox(height: 7),
        Text(
          'Submit your first authorization request to see results here.',
          textAlign: TextAlign.center,
          style: _inter(13, FontWeight.w400, C.textSecondary, h: 1.55)),
      ]),
    ),
  );
}

class _WelcomeEmpty extends StatelessWidget {
  final VoidCallback onNewRequest;
  const _WelcomeEmpty({required this.onNewRequest});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 36, 24, 40),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Column(children: [
        Container(
          width: 96, height: 96,
          decoration: const BoxDecoration(color: C.teal50, shape: BoxShape.circle),
          child: const Icon(Icons.health_and_safety_outlined, size: 48, color: C.teal500),
        ),
        const SizedBox(height: 20),
        Text('Welcome to MediAuth AI',
          textAlign: TextAlign.center,
          style: _outfit(22, FontWeight.w800, C.textPrimary)),
        const SizedBox(height: 8),
        Text(
          'Let the AI handle prior authorizations\nfrom intake to appeal — automatically.',
          textAlign: TextAlign.center,
          style: _inter(14, FontWeight.w400, C.textSecondary, h: 1.6)),
      ])),
      const SizedBox(height: 32),
      Text('How it works', style: _inter(11, FontWeight.w700, C.teal600, ls: 1.0)),
      const SizedBox(height: 10),
      _Step(n: '1', title: 'Enter Patient Details',
        subtitle: 'Name, DOB, insurer, diagnoses and medications.',
        icon: Icons.person_outline_rounded),
      const SizedBox(height: 8),
      _Step(n: '2', title: 'Describe the Treatment',
        subtitle: 'The procedure or medication needing approval.',
        icon: Icons.medical_services_outlined),
      const SizedBox(height: 8),
      _Step(n: '3', title: 'AI Does the Rest',
        subtitle: '7-agent pipeline writes, submits & appeals in 30 s.',
        icon: Icons.auto_awesome_rounded),
      const SizedBox(height: 32),
      SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton.icon(
          onPressed: onNewRequest,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text('Start My First Request',
            style: _inter(15, FontWeight.w700, Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: C.teal500, foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
      ),
      const SizedBox(height: 12),
      Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock_outline_rounded, size: 12, color: C.textTertiary),
        const SizedBox(width: 5),
        Text('End-to-end encrypted', style: _inter(12, FontWeight.w400, C.textTertiary)),
      ])),
    ]),
  );
}

class _Step extends StatelessWidget {
  final String n, title, subtitle;
  final IconData icon;
  const _Step({required this.n, required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: C.surf0,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: C.surf3.withValues(alpha: 0.5), width: 0.5),
    ),
    child: Row(children: [
      Container(
        width: 34, height: 34,
        decoration: const BoxDecoration(color: C.teal50, shape: BoxShape.circle),
        child: Center(child: Text(n, style: _inter(15, FontWeight.w800, C.teal600))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: _inter(13, FontWeight.w700, C.textPrimary)),
        const SizedBox(height: 2),
        Text(subtitle, style: _inter(12, FontWeight.w400, C.textSecondary, h: 1.4)),
      ])),
      const SizedBox(width: 8),
      Icon(icon, color: C.teal400, size: 20),
    ]),
  );
}

// ─── SKELETON ────────────────────────────────────────────────────────────────

class _SkeletonList extends StatefulWidget {
  @override State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _shimmer = Tween<double>(begin: 0.25, end: 0.75)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _block(double w, double h, {double r = 8}) => AnimatedBuilder(
    animation: _shimmer,
    builder: (_, __) => Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: C.surf3.withValues(alpha: _shimmer.value),
        borderRadius: BorderRadius.circular(r)),
    ),
  );

  Widget _statSkeleton() => GridView.count(
    crossAxisCount: 2, shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10, mainAxisSpacing: 10,
    childAspectRatio: 2.1,
    children: List.generate(4, (_) => ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            color: C.surf3.withValues(alpha: _shimmer.value * 0.5),
            borderRadius: BorderRadius.circular(14)),
        ),
      ),
    )),
  );

  Widget _card() => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: C.surf0,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: C.surf3.withValues(alpha: 0.5), width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _block(42, 42, r: 21),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _block(160, 13),
          const SizedBox(height: 7),
          _block(100, 11),
        ])),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        _block(60, 22, r: 11),
        const Spacer(),
        _block(50, 11),
      ]),
    ]),
  );

  @override
  Widget build(BuildContext context) => Column(children: [
    _statSkeleton(),
    const SizedBox(height: 22),
    ...List.generate(3, (_) => _card()),
  ]);
}
// ─────────────────────────────────────────────────────────────────────────────
// dashboard_screen.dart
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

  static const _filters = ['All', 'Approved', 'Pending', 'Denied', 'Appealing'];

  late AnimationController _listCtrl;

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _load();
  }

  @override
  void dispose() { _listCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _fromCache = false; });
    try {
      final items = await ApiService.fetchHistory(limit: 50);
      final reqs = items.map((m) => AuthRequest.fromMap(_normalise(m))).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() { _all = reqs; _loading = false; });
      _listCtrl.forward(from: 0);
    } on ApiException catch (_) {
      await _loadCache();
    } catch (_) {
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
    'auth_request_id':    r['auth_request_id'],
    'workflow_status':    r['workflow_status'],
    'appeal_level':       r['appeal_level'],
    'justification_letter': r['justification_letter'],
    'denial_reason':      r['denial_reason'],
    'created_at':         r['created_at'],
    'insurer':            r['insurer'] ?? '',
    'policy_number':      r['policy_number'] ?? '',
    'requested_treatment': _treatmentLabel(r),
  };

  String _treatmentLabel(Map<String, dynamic> r) {
    final p = (r['patient_name'] ?? '').toString();
    return p.isNotEmpty
        ? 'Authorization — $p'
        : 'Authorization (${r['workflow_status'] ?? 'unknown'})';
  }

  List<AuthRequest> get _filtered => _filter == 'All'
      ? _all
      : _all.where((r) => r.status == _filter.toLowerCase()).toList();

  int _count(String status) => status == 'Total'
      ? _all.length
      : _all.where((r) => r.status == status.toLowerCase()).length;

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
    final filtered   = _filtered;
    final hasPending = _all.any((r) => r.status == 'pending');
    final botPad     = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: RefreshIndicator(
            onRefresh: _load,
            color: C.teal500,
            backgroundColor: C.surf0,
            displacement: 90,
            child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── HUGE OVERLAPPING HEADER ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Navy background block
                  Container(
                    height: 280,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [C.navy900, C.navy800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

                  // Header Content (Greeting + Profile)
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(30, 24, 30, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$_greeting,',
                                  style: _inter(13, FontWeight.w400, Colors.white54, ls: 0.2)),
                                const SizedBox(height: 2),
                                Text(_userName,
                                  style: _outfit(26, FontWeight.w700, Colors.white)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onProfileTap,
                            child: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: C.teal500,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
                              ),
                              child: Center(
                                child: Text(_initials,
                                  style: _inter(15, FontWeight.w700, Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Overlapping unified stats card
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 100,
                    left: 20, right: 20,
                    child: _UnifiedStatsCard(
                      total:    _count('Total'),
                      approved: _count('Approved'),
                      pending:  _count('Pending'),
                      denied:   _count('Denied'),
                    ),
                  ),
                ],
              ),
            ),

            // Spacer to account for the overlapping card
            const SliverToBoxAdapter(child: SizedBox(height: 120)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasPending) ...[
                      _ProcessingHero(onTap: widget.onNewRequest),
                      const SizedBox(height: 24),
                    ],

                    Row(children: [
                      Text('Activity Stream',
                        style: _outfit(18, FontWeight.w700, C.textPrimary, ls: -0.2)),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onNewRequest,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: C.teal500,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(children: [
                            const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('New', style: _inter(13, FontWeight.w600, Colors.white)),
                          ]),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Filter Pills
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        clipBehavior: Clip.none,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final f      = _filters[i];
                          final active = _filter == f;
                          return GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: active ? C.teal500 : C.surf0,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: active ? C.teal500 : C.surf3, width: 0.5),
                                boxShadow: active ? [
                                  BoxShadow(color: C.teal500.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
                                ] : [],
                              ),
                              child: Center(
                                child: Text(f,
                                  style: _inter(13, FontWeight.w600,
                                    active ? Colors.white : C.textSecondary, ls: 0.2)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── CONTENT ───────────────────────────────────────────────────
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(child: _SkeletonList()),
              )
            else if (filtered.isEmpty)
              SliverPadding(
                padding: EdgeInsets.only(bottom: botPad + 100),
                sliver: SliverToBoxAdapter(
                  child: _EmptyState(fromCache: _fromCache, onNewRequest: widget.onNewRequest),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, botPad + 100), // padding for FAB
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final r = filtered[i];
                      return FadeSlide(
                        delay: Duration(milliseconds: 40 * i),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _InteractiveRequestCard(
                            request: r,
                            onTap:   () => widget.onRequestTap(r.raw),
                          ),
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
    ),
  ),
);
  }
}

// ─── UNIFIED STATS CARD ───────────────────────────────────────────────────────

class _UnifiedStatsCard extends StatelessWidget {
  final int total, approved, pending, denied;

  const _UnifiedStatsCard({
    required this.total,
    required this.approved,
    required this.pending,
    required this.denied,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: C.surf3.withValues(alpha: 0.7), width: 0.5),
      boxShadow: [
        BoxShadow(
          color: C.navy900.withValues(alpha: 0.08),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: C.navy50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.folder_copy_rounded, color: C.navy700, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Submissions',
                  style: _inter(13, FontWeight.w500, C.textSecondary)),
                Text('$total',
                  style: _outfit(32, FontWeight.w800, C.navy900)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(height: 1, color: C.surf2),
        const SizedBox(height: 16),
        Row(
          children: [
            _MiniStat('Approved', approved, C.green500, Icons.check_circle_rounded),
            Container(width: 1, height: 30, color: C.surf2),
            _MiniStat('Pending', pending, C.amber500, Icons.hourglass_top_rounded),
            Container(width: 1, height: 30, color: C.surf2),
            _MiniStat('Denied', denied, C.red500, Icons.cancel_rounded),
          ],
        ),
      ],
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _MiniStat(this.label, this.count, this.color, this.icon);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 6),
        Text('$count', style: _outfit(20, FontWeight.w700, C.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: _inter(11, FontWeight.w500, C.textTertiary)),
      ],
    ),
  );
}

// ─── PROCESSING HERO BANNER ───────────────────────────────────────────────────

class _ProcessingHero extends StatefulWidget {
  final VoidCallback onTap;
  const _ProcessingHero({required this.onTap});
  @override State<_ProcessingHero> createState() => _ProcessingHeroState();
}

class _ProcessingHeroState extends State<_ProcessingHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _pulse;

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: C.amber50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: C.amber500.withValues(alpha: _pulse.value * 0.8), width: 1),
        ),
        child: child,
      ),
      child: Row(children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: C.amber500.withValues(alpha: _pulse.value),
              boxShadow: [BoxShadow(
                color: C.amber500.withValues(alpha: _pulse.value * 0.5),
                blurRadius: 8)]),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI Agents Actively Processing', style: _inter(14, FontWeight.w700, C.amber700)),
          const SizedBox(height: 2),
          Text('Tap to watch live activity stream',
            style: _inter(12, FontWeight.w500, C.amber600)),
        ])),
        Icon(Icons.arrow_forward_rounded, size: 18, color: C.amber500),
      ]),
    ),
  );
}

// ─── INTERACTIVE REQUEST CARD ─────────────────────────────────────────────────

class _InteractiveRequestCard extends StatelessWidget {
  final AuthRequest  request;
  final VoidCallback onTap;
  const _InteractiveRequestCard({required this.request, required this.onTap});

  (Color, Color, Color, IconData) get _meta => switch (request.status) {
    'approved'  => (C.green50,  C.green500,  C.green700,  Icons.check_circle_rounded),
    'denied'    => (C.red50,    C.red500,    C.red700,    Icons.cancel_rounded),
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
    final now  = DateTime.now();
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: accent.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.surf3.withValues(alpha: 0.5), width: 1.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: fg, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(request.treatment,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: _inter(15, FontWeight.w700, C.textPrimary)),
                      ),
                      const SizedBox(width: 10),
                      Text(_dateLabel,
                        style: _inter(11, FontWeight.w500, C.textTertiary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [request.insurer, request.policyNumber]
                        .where((s) => s.isNotEmpty).join(' · '),
                    style: _inter(13, FontWeight.w400, C.textSecondary)),
                  const SizedBox(height: 12),
                  Row(children: [
                    StatusPill(_pill),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, color: C.surf3, size: 20),
                  ]),
                ],
              )),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── SKELETON & EMPTY STATE ───────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(4, (i) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FadeSlide(
        delay: Duration(milliseconds: 100 * i),
        child: PulseOpacity(
          child: Container(
            height: 84,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: C.surf3.withValues(alpha: 0.5), width: 1.0),
            ),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: const BoxDecoration(color: C.surf1, shape: BoxShape.circle)),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: double.infinity, height: 14, decoration: BoxDecoration(color: C.surf1, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(width: 140, height: 12, decoration: BoxDecoration(color: C.surf1, borderRadius: BorderRadius.circular(4))),
                ]
              )),
            ]),
          ),
        ),
      ),
    )),
  );
}

class _EmptyState extends StatelessWidget {
  final bool fromCache;
  final VoidCallback onNewRequest;
  const _EmptyState({required this.fromCache, required this.onNewRequest});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60, height: 60,
          decoration: const BoxDecoration(color: C.surf2, shape: BoxShape.circle),
          child: const Icon(Icons.document_scanner_rounded, size: 28, color: C.textTertiary),
        ),
        const SizedBox(height: 10),
        Text('No Submissions',
          style: _inter(16, FontWeight.w700, C.textPrimary)),
        const SizedBox(height: 4),
        Text(
          fromCache
              ? 'Unable to sync with server. Showing cached history.'
              : 'Your authorization history is clean. Tap below to initiate an AI-powered submission.',
          textAlign: TextAlign.center,
          style: _inter(13, FontWeight.w400, C.textSecondary, h: 1.5),
        ),
        if (!fromCache) ...[
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onNewRequest,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: C.teal500,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(color: C.teal500.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Text('Create New Request',
                style: _inter(14, FontWeight.w600, Colors.white)),
            ),
          ),
        ],
      ],
    ),
  );
}
